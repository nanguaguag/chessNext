import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../ports/book_service.dart';

const _maxBookResponseBytes = 32 * 1024;

/// Bounded HTTP adapter for the self-hosted public book query endpoint.
final class HttpBookService implements BookService {
  HttpBookService({
    HttpClient? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;

  void close() => _client.close(force: true);

  @override
  Future<BookLookup> query({
    required Uri endpoint,
    required BookPositionKey position,
  }) async {
    if (!_validEndpoint(endpoint) ||
        position.fen.trim().isEmpty ||
        position.fen.length > 256 ||
        position.history.length > 512 ||
        position.history.any((move) => !_move.hasMatch(move))) {
      throw const BookServiceInvalidResponse();
    }
    final uri = endpoint.replace(
      path: '${endpoint.path.replaceFirst(RegExp(r'/+$'), '')}/v1/book/query',
      query: null,
      fragment: null,
    );
    final body = jsonEncode({
      'kind': position.kind.name,
      'fen': position.fen.trim(),
      'history': position.history,
    });
    if (utf8.encode(body).length > _maxBookResponseBytes) {
      throw const BookServiceInvalidResponse();
    }
    try {
      final request = await _client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(body));
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        if (response.statusCode == HttpStatus.badRequest) {
          throw const BookServiceInvalidResponse();
        }
        throw BookServiceRejected(response.statusCode);
      }
      if (response.contentLength > _maxBookResponseBytes) {
        await response.drain<void>();
        throw const BookServiceInvalidResponse();
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        if (bytes.length + chunk.length > _maxBookResponseBytes) {
          throw const BookServiceInvalidResponse();
        }
        bytes.addAll(chunk);
      }
      return _decode(utf8.decode(bytes), position);
    } on BookServiceException {
      rethrow;
    } on TimeoutException {
      throw const BookServiceUnavailable();
    } on SocketException {
      throw const BookServiceUnavailable();
    } on HttpException {
      throw const BookServiceUnavailable();
    } on FormatException {
      throw const BookServiceInvalidResponse();
    }
  }

  static final _move = RegExp(r'^[a-i][0-9][a-i][0-9]$');

  static bool _validEndpoint(Uri uri) {
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return false;
    }
    if (uri.scheme == 'https') return uri.host.isNotEmpty;
    return uri.scheme == 'http' &&
        {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
  }

  static BookLookup _decode(String body, BookPositionKey requested) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic> ||
        json.keys.toSet().difference({
          'schema',
          'status',
          'kind',
          'fen',
          'history',
          'dataset',
          'moves',
        }).isNotEmpty ||
        json['schema'] != 1 ||
        json['kind'] != requested.kind.name ||
        json['fen'] != requested.fen.trim() ||
        jsonEncode(json['history']) != jsonEncode(requested.history) ||
        (json['status'] != 'hit' && json['status'] != 'miss') ||
        json['dataset'] is! Map<String, dynamic> ||
        json['moves'] is! List) {
      throw const FormatException('Invalid book response');
    }
    final dataset = json['dataset'] as Map<String, dynamic>;
    if (dataset.keys.toSet().difference({
          'id',
          'license',
          'attribution',
        }).isNotEmpty ||
        dataset['id'] is! String ||
        (dataset['id'] as String).isEmpty ||
        dataset['license'] is! String ||
        (dataset['license'] as String).isEmpty ||
        dataset['attribution'] is! String) {
      throw const FormatException('Invalid book provenance');
    }
    final rawMoves = json['moves'] as List;
    if (rawMoves.length > 32 ||
        (json['status'] == 'hit' && rawMoves.isEmpty) ||
        (json['status'] == 'miss' && rawMoves.isNotEmpty)) {
      throw const FormatException('Invalid book result');
    }
    final moves = rawMoves
        .map((raw) {
          if (raw is! Map<String, dynamic> ||
              raw.keys.toSet().difference({
                'move',
                'scoreCp',
                'weight',
              }).isNotEmpty ||
              raw['move'] is! String ||
              !_move.hasMatch(raw['move'] as String) ||
              raw['scoreCp'] is! int ||
              (raw['scoreCp'] as int).abs() > 1000000 ||
              raw['weight'] is! int ||
              (raw['weight'] as int) < 1 ||
              (raw['weight'] as int) > 1000000000) {
            throw const FormatException('Invalid book candidate');
          }
          return BookMoveCandidate(
            uci: raw['move'] as String,
            scoreCp: raw['scoreCp'] as int,
            weight: raw['weight'] as int,
          );
        })
        .toList(growable: false);
    if (moves.map((move) => move.uci).toSet().length != moves.length) {
      throw const FormatException('Duplicate book candidate');
    }
    return BookLookup(
      hit: json['status'] == 'hit',
      candidates: List.unmodifiable(moves),
      datasetId: dataset['id'] as String,
      license: dataset['license'] as String,
      attribution: dataset['attribution'] as String,
    );
  }
}
