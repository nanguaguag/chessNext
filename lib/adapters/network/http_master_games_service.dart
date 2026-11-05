import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../ports/master_games_service.dart';

const _maxRequestBytes = 32 * 1024;
const _maxResponseBytes = 2 * 1024 * 1024;
final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Bounded transport for an explicitly configured operator managed index.
final class HttpMasterGamesService implements MasterGamesService {
  HttpMasterGamesService({
    HttpClient? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;

  void close() => _client.close(force: true);

  @override
  Future<MasterGamesPage> query({
    required Uri endpoint,
    required MasterGamesQuery query,
  }) async {
    if (!_validEndpoint(endpoint)) throw const MasterGamesInvalidResponse();
    final payload = jsonEncode({
      'schema': 1,
      'fen': query.fen.trim(),
      'history': query.history,
      'category': query.category?.name,
      'text': query.text.trim(),
      'fromYear': query.fromYear,
      'toYear': query.toYear,
      'results': query.results.map(_resultName).toList()..sort(),
      'page': query.page,
      'pageSize': query.pageSize,
    });
    final bytes = utf8.encode(payload);
    if (bytes.length > _maxRequestBytes) {
      throw const MasterGamesInvalidResponse();
    }
    final uri = endpoint.replace(
      path:
          '${endpoint.path.replaceFirst(RegExp(r'/+$'), '')}/v1/master-games/query',
      query: null,
      fragment: null,
    );
    try {
      final request = await _client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(bytes);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        if (response.statusCode == HttpStatus.badRequest) {
          throw const MasterGamesInvalidResponse();
        }
        throw MasterGamesRejected(response.statusCode);
      }
      if (response.contentLength > _maxResponseBytes) {
        await response.drain<void>();
        throw const MasterGamesInvalidResponse();
      }
      final body = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        if (body.length + chunk.length > _maxResponseBytes) {
          throw const MasterGamesInvalidResponse();
        }
        body.addAll(chunk);
      }
      return _decode(utf8.decode(body), query);
    } on MasterGamesServiceException {
      rethrow;
    } on TimeoutException {
      throw const MasterGamesUnavailable();
    } on SocketException {
      throw const MasterGamesUnavailable();
    } on HttpException {
      throw const MasterGamesUnavailable();
    } on FormatException {
      throw const MasterGamesInvalidResponse();
    }
  }

  static bool _validEndpoint(Uri uri) {
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return false;
    }
    if (uri.scheme == 'https') return uri.host.isNotEmpty;
    return uri.scheme == 'http' &&
        {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
  }

  static String _resultName(MasterGameResult result) => switch (result) {
    MasterGameResult.redWin => 'red_win',
    MasterGameResult.draw => 'draw',
    MasterGameResult.blackWin => 'black_win',
  };

  static MasterGamesPage _decode(String body, MasterGamesQuery query) {
    final value = jsonDecode(body);
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference({
          'schema',
          'dataset',
          'page',
          'pageSize',
          'total',
          'records',
        }).isNotEmpty ||
        value['schema'] != 1 ||
        value['page'] != query.page ||
        value['pageSize'] != query.pageSize ||
        value['total'] is! int ||
        (value['total'] as int) < 0 ||
        value['records'] is! List ||
        (value['records'] as List).length > query.pageSize) {
      throw const FormatException('Invalid master games response');
    }
    final dataset = value['dataset'];
    if (dataset is! Map<String, dynamic> ||
        dataset.keys.toSet().difference({
          'id',
          'license',
          'attribution',
        }).isNotEmpty ||
        dataset['id'] is! String ||
        !_idPattern.hasMatch(dataset['id'] as String) ||
        dataset['license'] is! String ||
        (dataset['license'] as String).trim().isEmpty ||
        (dataset['license'] as String).runes.length > 120 ||
        dataset['attribution'] is! String ||
        (dataset['attribution'] as String).runes.length > 200) {
      throw const FormatException('Invalid master games provenance');
    }
    final records = (value['records'] as List)
        .map((raw) {
          if (raw is! Map<String, dynamic> ||
              raw.keys.toSet().difference({
                'id',
                'category',
                'red',
                'black',
                'event',
                'year',
                'result',
              }).isNotEmpty ||
              raw['id'] is! String ||
              !_idPattern.hasMatch(raw['id'] as String) ||
              raw['red'] is! String ||
              (raw['red'] as String).trim().isEmpty ||
              (raw['red'] as String).runes.length > 120 ||
              raw['black'] is! String ||
              (raw['black'] as String).trim().isEmpty ||
              (raw['black'] as String).runes.length > 120 ||
              raw['event'] is! String ||
              (raw['event'] as String).trim().isEmpty ||
              (raw['event'] as String).runes.length > 200 ||
              raw['year'] is! int ||
              (raw['year'] as int) < 1 ||
              (raw['year'] as int) > 9999) {
            throw const FormatException('Invalid master game record');
          }
          final category = switch (raw['category']) {
            'game' => MasterGameCategory.game,
            'chessbook' => MasterGameCategory.chessbook,
            _ => throw const FormatException('Invalid master game category'),
          };
          final result = switch (raw['result']) {
            'red_win' => MasterGameResult.redWin,
            'draw' => MasterGameResult.draw,
            'black_win' => MasterGameResult.blackWin,
            _ => throw const FormatException('Invalid master game result'),
          };
          return MasterGameRecord(
            id: raw['id'] as String,
            category: category,
            red: raw['red'] as String,
            black: raw['black'] as String,
            event: raw['event'] as String,
            year: raw['year'] as int,
            result: result,
          );
        })
        .toList(growable: false);
    if (records.map((record) => record.id).toSet().length != records.length ||
        records.length > (value['total'] as int)) {
      throw const FormatException('Inconsistent master games page');
    }
    return MasterGamesPage(
      datasetId: dataset['id'] as String,
      license: dataset['license'] as String,
      attribution: dataset['attribution'] as String,
      page: value['page'] as int,
      pageSize: value['pageSize'] as int,
      total: value['total'] as int,
      records: List.unmodifiable(records),
    );
  }
}
