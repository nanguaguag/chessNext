import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../ports/piece_skin_catalog.dart';

const _maxCatalogResponseBytes = 2 * 1024 * 1024;
const _maxSkinPackageBytes = 8 * 1024 * 1024;

/// HTTP implementation for a public, read-only self-hosted catalog.
final class HttpPieceSkinCatalog implements PieceSkinCatalog, BoardSkinCatalog {
  HttpPieceSkinCatalog({
    HttpClient? client,
    this.cache,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? HttpClient(),
       _catalogPath = '/v1/catalog';

  HttpPieceSkinCatalog.forBoards({
    HttpClient? client,
    this.cache,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? HttpClient(),
       _catalogPath = '/v1/board-catalog';

  final HttpClient _client;
  final PieceSkinCatalogCache? cache;
  final Duration timeout;
  final String _catalogPath;

  void close() => _client.close(force: true);

  @override
  Future<PieceSkinCatalogPage> search({
    required Uri endpoint,
    required String query,
    required PublicPieceSkinSort sort,
    int page = 1,
    int pageSize = 24,
  }) async {
    if (!_validEndpoint(endpoint) ||
        page < 1 ||
        page > 10000 ||
        pageSize < 1 ||
        pageSize > 100 ||
        query.runes.length > 120) {
      throw const PieceSkinCatalogInvalidResponse();
    }
    final uri = endpoint.replace(
      path: '${endpoint.path.replaceFirst(RegExp(r'/+$'), '')}$_catalogPath',
      queryParameters: {
        'q': query,
        'sort': switch (sort) {
          PublicPieceSkinSort.defaultOrder => 'default',
          PublicPieceSkinSort.likes => 'likes',
          PublicPieceSkinSort.name => 'name',
          PublicPieceSkinSort.author => 'author',
          PublicPieceSkinSort.recent => 'recent',
        },
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );
    try {
      final request = await _client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw PieceSkinCatalogRejected(response.statusCode);
      }
      if (response.contentLength > _maxCatalogResponseBytes) {
        await response.drain<void>();
        throw const PieceSkinCatalogInvalidResponse();
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        if (bytes.length + chunk.length > _maxCatalogResponseBytes) {
          throw const PieceSkinCatalogInvalidResponse();
        }
        bytes.addAll(chunk);
      }
      final body = utf8.decode(bytes);
      final pageResult = _decode(body);
      try {
        await cache?.write(uri.toString(), body, DateTime.now().toUtc());
      } catch (_) {
        // A cache write must never turn a successful online response into an
        // unavailable result.
      }
      return pageResult;
    } on PieceSkinCatalogException {
      rethrow;
    } on TimeoutException {
      return _cachedOrUnavailable(uri);
    } on SocketException {
      return _cachedOrUnavailable(uri);
    } on HttpException {
      return _cachedOrUnavailable(uri);
    } on FormatException {
      throw const PieceSkinCatalogInvalidResponse();
    }
  }

  Future<PieceSkinCatalogPage> _cachedOrUnavailable(Uri uri) async {
    if (cache != null) {
      try {
        final saved = await cache!.read(uri.toString());
        if (saved != null) {
          final page = _decode(saved.body);
          return PieceSkinCatalogPage(
            items: page.items,
            page: page.page,
            pageSize: page.pageSize,
            total: page.total,
            isStale: true,
            cachedAt: saved.cachedAt,
          );
        }
      } catch (_) {
        // Corrupt/unreadable cache is treated as a miss.
      }
    }
    throw const PieceSkinCatalogUnavailable();
  }

  @override
  Future<Uint8List> downloadPackage({
    required Uri endpoint,
    required String id,
    required String expectedSha256,
  }) async {
    if (!_validEndpoint(endpoint) ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$').hasMatch(id) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedSha256)) {
      throw const PieceSkinCatalogInvalidResponse();
    }
    final basePath = endpoint.path.replaceFirst(RegExp(r'/+$'), '');
    final uri = endpoint.replace(path: '$basePath$_catalogPath/$id/package');
    try {
      final request = await _client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/zip');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw PieceSkinCatalogRejected(response.statusCode);
      }
      if (response.contentLength > _maxSkinPackageBytes) {
        await response.drain<void>();
        throw const PieceSkinCatalogInvalidResponse();
      }
      final bytes = BytesBuilder(copy: false);
      var length = 0;
      await for (final chunk in response.timeout(timeout)) {
        length += chunk.length;
        if (length > _maxSkinPackageBytes) {
          throw const PieceSkinCatalogInvalidResponse();
        }
        bytes.add(chunk);
      }
      final package = bytes.takeBytes();
      if (sha256.convert(package).toString() != expectedSha256) {
        throw const PieceSkinCatalogInvalidResponse();
      }
      return package;
    } on PieceSkinCatalogException {
      rethrow;
    } on TimeoutException {
      throw const PieceSkinCatalogUnavailable();
    } on SocketException {
      throw const PieceSkinCatalogUnavailable();
    } on HttpException {
      throw const PieceSkinCatalogUnavailable();
    }
  }

  PieceSkinCatalogPage _decode(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic> ||
        json.keys.toSet().difference({
          'schema',
          'page',
          'pageSize',
          'count',
          'total',
          'items',
        }).isNotEmpty ||
        json['schema'] != 1 ||
        json['page'] is! int ||
        json['pageSize'] is! int ||
        json['count'] is! int ||
        json['total'] is! int ||
        json['items'] is! List ||
        (json['items'] as List).length != json['count'] ||
        json['total'] < 0 ||
        json['total'] > 10000) {
      throw const PieceSkinCatalogInvalidResponse();
    }
    final items = (json['items'] as List)
        .map(_decodeItem)
        .toList(growable: false);
    return PieceSkinCatalogPage(
      items: List.unmodifiable(items),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  }

  PublicPieceSkin _decodeItem(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference({
          'id',
          'name',
          'author',
          'description',
          'likes',
          'publishedAt',
          'license',
          'attribution',
          'packageSha256',
        }).isNotEmpty) {
      throw const PieceSkinCatalogInvalidResponse();
    }
    final id = value['id'];
    final name = value['name'];
    final author = value['author'];
    final description = value['description'];
    final likes = value['likes'];
    final publishedAt = value['publishedAt'];
    final license = value['license'];
    final attribution = value['attribution'];
    final hash = value['packageSha256'];
    if (id is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$').hasMatch(id) ||
        name is! String ||
        !_text(name, 1, 120) ||
        author is! String ||
        !_text(author, 1, 120) ||
        description is! String ||
        !_text(description, 0, 2000) ||
        likes is! int ||
        likes < 0 ||
        publishedAt is! String ||
        DateTime.tryParse(publishedAt) == null ||
        license is! String ||
        !_text(license, 1, 120) ||
        attribution is! String ||
        !_text(attribution, 0, 500) ||
        hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const PieceSkinCatalogInvalidResponse();
    }
    return PublicPieceSkin(
      id: id,
      name: name,
      author: author,
      description: description,
      likes: likes,
      publishedAt: DateTime.parse(publishedAt).toUtc(),
      license: license,
      attribution: attribution,
      packageSha256: hash,
    );
  }

  bool _text(String value, int min, int max) {
    final length = value.trim().runes.length;
    return length >= min &&
        length <= max &&
        !value.runes.any(
          (rune) =>
              rune == 0 || (rune < 32 && rune != 9 && rune != 10 && rune != 13),
        );
  }

  bool _validEndpoint(Uri uri) {
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return false;
    }
    if (uri.scheme == 'https' && uri.host.isNotEmpty) return true;
    return uri.scheme == 'http' &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '::1');
  }
}
