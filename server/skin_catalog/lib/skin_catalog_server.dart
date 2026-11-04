import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _maxManifestBytes = 4 * 1024 * 1024;
const _maxPageSize = 100;
const _maxPackageBytes = 8 * 1024 * 1024;
final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

enum SkinCatalogSort { defaultOrder, likes, name, author, recent }

final class PublicSkin {
  const PublicSkin({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.likes,
    required this.publishedAt,
    required this.license,
    required this.attribution,
    required this.packageSha256,
  });

  final String id;
  final String name;
  final String author;
  final String description;
  final int likes;
  final DateTime publishedAt;
  final String license;
  final String attribution;
  final String packageSha256;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'description': description,
    'likes': likes,
    'publishedAt': publishedAt.toUtc().toIso8601String(),
    'license': license,
    'attribution': attribution,
    'packageSha256': packageSha256,
  };

  factory PublicSkin.fromJson(Object? value) {
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
      throw const FormatException('Invalid skin catalog entry');
    }
    final id = value['id'];
    final name = value['name'];
    final author = value['author'];
    final description = value['description'];
    final likes = value['likes'];
    final publishedAt = value['publishedAt'];
    final license = value['license'];
    final attribution = value['attribution'];
    final packageSha256 = value['packageSha256'];
    if (id is! String ||
        !_idPattern.hasMatch(id) ||
        name is! String ||
        !_boundedText(name, 1, 120) ||
        author is! String ||
        !_boundedText(author, 1, 120) ||
        description is! String ||
        !_boundedText(description, 0, 2000) ||
        likes is! int ||
        likes < 0 ||
        publishedAt is! String ||
        license is! String ||
        !_boundedText(license, 1, 120) ||
        attribution is! String ||
        !_boundedText(attribution, 0, 500) ||
        packageSha256 is! String ||
        !_sha256Pattern.hasMatch(packageSha256)) {
      throw const FormatException('Invalid skin catalog entry');
    }
    final timestamp = DateTime.tryParse(publishedAt);
    if (timestamp == null) {
      throw const FormatException('Invalid skin catalog date');
    }
    return PublicSkin(
      id: id,
      name: name,
      author: author,
      description: description,
      likes: likes,
      publishedAt: timestamp.toUtc(),
      license: license,
      attribution: attribution,
      packageSha256: packageSha256,
    );
  }
}

bool _boundedText(String value, int minRunes, int maxRunes) {
  final length = value.trim().runes.length;
  return length >= minRunes &&
      length <= maxRunes &&
      !value.runes.any(
        (rune) =>
            rune == 0 || (rune < 32 && rune != 9 && rune != 10 && rune != 13),
      );
}

final class SkinCatalogStore {
  SkinCatalogStore._(this.root, this.skins);

  final Directory root;
  final List<PublicSkin> skins;

  static Future<SkinCatalogStore> load(Directory root) async {
    if (await FileSystemEntity.type(root.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FormatException('Catalog root must be a real directory');
    }
    final manifest = File('${root.path}/catalog.json');
    if (await FileSystemEntity.type(manifest.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FormatException('Catalog manifest must be a regular file');
    }
    final length = await manifest.length();
    if (length > _maxManifestBytes) {
      throw const FormatException('Catalog manifest is too large');
    }
    final decoded = jsonDecode(await manifest.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({'schema', 'skins'}).isNotEmpty ||
        decoded['schema'] != 1 ||
        decoded['skins'] is! List) {
      throw const FormatException('Invalid catalog manifest');
    }
    final list = (decoded['skins'] as List)
        .map(PublicSkin.fromJson)
        .toList(growable: false);
    if (list.length > 10000 ||
        list.map((item) => item.id).toSet().length != list.length) {
      throw const FormatException(
        'Catalog contains duplicate or excessive entries',
      );
    }
    return SkinCatalogStore._(root, List.unmodifiable(list));
  }

  List<PublicSkin> search({
    required String query,
    required SkinCatalogSort sort,
    required int page,
    required int pageSize,
  }) {
    final normalized = query.trim().toLowerCase();
    final filtered = skins.where((skin) {
      return normalized.isEmpty ||
          skin.name.toLowerCase().contains(normalized) ||
          skin.author.toLowerCase().contains(normalized) ||
          skin.description.toLowerCase().contains(normalized);
    }).toList();
    if (sort != SkinCatalogSort.defaultOrder) {
      filtered.sort((a, b) {
        final comparison = switch (sort) {
          SkinCatalogSort.defaultOrder => 0,
          SkinCatalogSort.likes => b.likes.compareTo(a.likes),
          SkinCatalogSort.name => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
          SkinCatalogSort.author => a.author.toLowerCase().compareTo(
            b.author.toLowerCase(),
          ),
          SkinCatalogSort.recent => b.publishedAt.compareTo(a.publishedAt),
        };
        return comparison != 0 ? comparison : a.id.compareTo(b.id);
      });
    }
    final start = (page - 1) * pageSize;
    if (start >= filtered.length) return const [];
    return List.unmodifiable(filtered.skip(start).take(pageSize));
  }

  int countMatches(String query) {
    final normalized = query.trim().toLowerCase();
    return skins.where((skin) {
      return normalized.isEmpty ||
          skin.name.toLowerCase().contains(normalized) ||
          skin.author.toLowerCase().contains(normalized) ||
          skin.description.toLowerCase().contains(normalized);
    }).length;
  }

  Future<Uint8List?> readPackage(PublicSkin skin) async {
    try {
      final packageDirectory = Directory('${root.path}/packages');
      if (await FileSystemEntity.type(
            packageDirectory.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.directory) {
        return null;
      }
      final file = File('${packageDirectory.path}/${skin.id}.zip');
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file) {
        return null;
      }
      final length = await file.length();
      if (length < 1 || length > _maxPackageBytes) return null;
      final bytes = await file.readAsBytes();
      if (bytes.length != length) return null;
      // The manifest pins the exact file contents. This detects accidental or
      // unauthorized mutation before a package is served.
      final digest = _sha256(bytes);
      if (digest != skin.packageSha256) return null;
      return Uint8List.fromList(bytes);
    } on FileSystemException {
      return null;
    }
  }
}

String _sha256(List<int> bytes) {
  return sha256.convert(bytes).toString();
}

final class SkinCatalogHttpServer {
  SkinCatalogHttpServer._(this._server, this._store);

  final HttpServer _server;
  final SkinCatalogStore _store;
  StreamSubscription<HttpRequest>? _subscription;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<SkinCatalogHttpServer> bind({
    required SkinCatalogStore store,
    InternetAddress? address,
    int port = 8087,
  }) async {
    final server = await HttpServer.bind(
      address ?? InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    final service = SkinCatalogHttpServer._(server, store);
    service._subscription = server.listen(service._handle);
    return service;
  }

  Future<void> close({bool force = true}) async {
    await _subscription?.cancel();
    await _server.close(force: force);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      await _route(request);
    } catch (_) {
      try {
        final response = request.response;
        response.headers
          ..set(HttpHeaders.cacheControlHeader, 'no-store')
          ..set('X-Content-Type-Options', 'nosniff');
        await _json(response, HttpStatus.internalServerError, {
          'error': {'code': 'internal_error'},
        });
      } catch (_) {
        // A client may have closed the socket while the request was handled.
      }
    }
  }

  Future<void> _route(HttpRequest request) async {
    final response = request.response;
    response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      response.headers
        ..set(HttpHeaders.accessControlAllowMethodsHeader, 'GET, HEAD, OPTIONS')
        ..set(HttpHeaders.accessControlAllowHeadersHeader, 'If-None-Match');
      await response.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD, OPTIONS');
      await _json(response, HttpStatus.methodNotAllowed, {
        'error': {'code': 'method_not_allowed'},
      });
      return;
    }
    final path = request.uri.path;
    if (path == '/healthz') {
      await _json(response, HttpStatus.ok, {'status': 'ok'});
    } else if (path == '/v1/catalog') {
      await _list(request);
    } else if (path.startsWith('/v1/catalog/')) {
      await _entry(request, path.substring('/v1/catalog/'.length));
    } else {
      await _json(response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
    }
  }

  Future<void> _list(HttpRequest request) async {
    final queryValues = request.uri.queryParametersAll;
    if (request.uri.query.length > 512 ||
        queryValues.values.any((values) => values.length != 1)) {
      await _badRequest(request.response);
      return;
    }
    final query = request.uri.queryParameters['q'] ?? '';
    final pageText = request.uri.queryParameters['page'] ?? '1';
    final sizeText = request.uri.queryParameters['pageSize'] ?? '24';
    final page = int.tryParse(pageText);
    final pageSize = int.tryParse(sizeText);
    final sort = _parseSort(request.uri.queryParameters['sort'] ?? 'default');
    if (query.runes.length > 120 ||
        page == null ||
        page < 1 ||
        page > 10000 ||
        pageSize == null ||
        pageSize < 1 ||
        pageSize > _maxPageSize ||
        sort == null) {
      await _badRequest(request.response);
      return;
    }
    final results = _store.search(
      query: query,
      sort: sort,
      page: page,
      pageSize: pageSize,
    );
    final count = _store.countMatches(query);
    await _json(request.response, HttpStatus.ok, {
      'schema': 1,
      'page': page,
      'pageSize': pageSize,
      'count': results.length,
      'total': count,
      'items': results.map((skin) => skin.toJson()).toList(),
    });
  }

  Future<void> _entry(HttpRequest request, String pathTail) async {
    final segments = pathTail.split('/');
    if (segments.length == 2 && segments[1] == 'package') {
      await _package(request, segments[0]);
      return;
    }
    if (segments.length != 1 || !_idPattern.hasMatch(segments.single)) {
      await _json(request.response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
      return;
    }
    final skin = _store.skins
        .where((item) => item.id == segments.single)
        .firstOrNull;
    if (skin == null) {
      await _json(request.response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
      return;
    }
    request.response.headers
      ..set(HttpHeaders.cacheControlHeader, 'public, max-age=60')
      ..set(HttpHeaders.etagHeader, '"${skin.packageSha256}"');
    await _json(request.response, HttpStatus.ok, {
      'schema': 1,
      'item': skin.toJson(),
    });
  }

  Future<void> _package(HttpRequest request, String id) async {
    if (!_idPattern.hasMatch(id)) {
      await _json(request.response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
      return;
    }
    final skin = _store.skins.where((item) => item.id == id).firstOrNull;
    if (skin == null) {
      await _json(request.response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
      return;
    }
    final etag = '"${skin.packageSha256}"';
    final response = request.response;
    response.headers
      ..set(HttpHeaders.etagHeader, etag)
      ..contentType = ContentType('application', 'zip');
    final bytes = await _store.readPackage(skin);
    if (bytes == null) {
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await _json(response, HttpStatus.notFound, {
        'error': {'code': 'package_unavailable'},
      });
      return;
    }
    response.headers.set(
      HttpHeaders.cacheControlHeader,
      'public, max-age=31536000, immutable',
    );
    if (request.headers.value(HttpHeaders.ifNoneMatchHeader) == etag) {
      response.statusCode = HttpStatus.notModified;
      await response.close();
      return;
    }
    response.statusCode = HttpStatus.ok;
    response.contentLength = bytes.length;
    if (request.method != 'HEAD') response.add(bytes);
    await response.close();
  }

  Future<void> _badRequest(HttpResponse response) =>
      _json(response, HttpStatus.badRequest, {
        'error': {'code': 'invalid_query'},
      });

  Future<void> _json(HttpResponse response, int status, Object body) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    final bytes = utf8.encode(jsonEncode(body));
    response.contentLength = bytes.length;
    if (response.statusCode != HttpStatus.notModified &&
        response.statusCode != HttpStatus.noContent) {
      response.add(bytes);
    }
    await response.close();
  }
}

SkinCatalogSort? _parseSort(String value) => switch (value) {
  'default' => SkinCatalogSort.defaultOrder,
  'likes' => SkinCatalogSort.likes,
  'name' => SkinCatalogSort.name,
  'author' => SkinCatalogSort.author,
  'recent' => SkinCatalogSort.recent,
  _ => null,
};
