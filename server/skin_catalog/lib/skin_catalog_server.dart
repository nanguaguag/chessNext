import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _maxManifestBytes = 4 * 1024 * 1024;
const _maxPageSize = 100;
const _maxPackageBytes = 8 * 1024 * 1024;
const _maxBookManifestBytes = 128 * 1024 * 1024;
const _maxBookRequestBytes = 32 * 1024;
const _maxBookEntries = 2000000;
const _maxReleaseManifestBytes = 1024 * 1024;
const _maxReleaseEntries = 100;
final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final _xiangqiMovePattern = RegExp(r'^[a-i][0-9][a-i][0-9]$');
final _releaseVersionPattern = RegExp(r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$');

final class ReleaseEntry {
  const ReleaseEntry({
    required this.version,
    required this.build,
    required this.publishedAt,
    required this.notes,
  });

  final String version;
  final int build;
  final DateTime publishedAt;
  final String notes;

  Map<String, Object> toJson() => {
    'version': version,
    'build': build,
    'publishedAt': publishedAt.toUtc().toIso8601String(),
    'notes': notes,
  };

  factory ReleaseEntry.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference({
          'version',
          'build',
          'publishedAt',
          'notes',
        }).isNotEmpty ||
        value['version'] is! String ||
        !_releaseVersionPattern.hasMatch(value['version'] as String) ||
        value['build'] is! int ||
        (value['build'] as int) < 1 ||
        value['publishedAt'] is! String ||
        value['notes'] is! String ||
        (value['notes'] as String).length > 4000 ||
        (value['notes'] as String).contains(
          RegExp(r'[\u0000-\u0008\u000b\u000c\u000e-\u001f]'),
        )) {
      throw const FormatException('Invalid release entry');
    }
    final publishedAt = DateTime.tryParse(value['publishedAt'] as String);
    if (publishedAt == null || !publishedAt.isUtc) {
      throw const FormatException('Invalid release date');
    }
    return ReleaseEntry(
      version: value['version'] as String,
      build: value['build'] as int,
      publishedAt: publishedAt,
      notes: value['notes'] as String,
    );
  }
}

/// Operator-supplied read-only release notes and version metadata.
final class ReleaseManifest {
  ReleaseManifest._(this.releases);

  final List<ReleaseEntry> releases;
  ReleaseEntry get current => releases.first;

  static Future<ReleaseManifest> load(
    Directory root, {
    String fileName = 'releases.json',
  }) async {
    if (await FileSystemEntity.type(root.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,63}\.json$').hasMatch(fileName)) {
      throw const FormatException('Invalid release data root');
    }
    final file = File('${root.path}/$fileName');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() > _maxReleaseManifestBytes) {
      throw const FormatException('Release manifest unavailable or too large');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({'schema', 'releases'}).isNotEmpty ||
        decoded['schema'] != 1 ||
        decoded['releases'] is! List ||
        (decoded['releases'] as List).isEmpty ||
        (decoded['releases'] as List).length > _maxReleaseEntries) {
      throw const FormatException('Invalid release manifest');
    }
    final releases = (decoded['releases'] as List)
        .map(ReleaseEntry.fromJson)
        .toList(growable: false);
    final identities = releases.map((item) => '${item.version}+${item.build}');
    if (identities.toSet().length != releases.length) {
      throw const FormatException('Duplicate release identity');
    }
    for (var i = 1; i < releases.length; i++) {
      if (!releases[i - 1].publishedAt.isAfter(releases[i].publishedAt)) {
        throw const FormatException('Release history must be newest first');
      }
    }
    return ReleaseManifest._(List.unmodifiable(releases));
  }

  Map<String, Object> toJson() => {
    'schema': 1,
    'current': current.toJson(),
    'history': releases.map((release) => release.toJson()).toList(),
  };
}

enum BookKind { opening, endgame }

final class BookCandidate {
  const BookCandidate({
    required this.move,
    required this.scoreCp,
    required this.weight,
  });
  final String move;
  final int scoreCp;
  final int weight;

  Map<String, Object> toJson() => {
    'move': move,
    'scoreCp': scoreCp,
    'weight': weight,
  };

  factory BookCandidate.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference({
          'move',
          'scoreCp',
          'weight',
        }).isNotEmpty ||
        value['move'] is! String ||
        !_xiangqiMovePattern.hasMatch(value['move'] as String) ||
        value['scoreCp'] is! int ||
        (value['scoreCp'] as int).abs() > 1000000 ||
        value['weight'] is! int ||
        (value['weight'] as int) < 1 ||
        (value['weight'] as int) > 1000000000) {
      throw const FormatException('Invalid book candidate');
    }
    return BookCandidate(
      move: value['move'] as String,
      scoreCp: value['scoreCp'] as int,
      weight: value['weight'] as int,
    );
  }
}

final class BookEntry {
  const BookEntry({
    required this.kind,
    required this.fen,
    required this.history,
    required this.moves,
  });
  final BookKind kind;
  final String fen;
  final List<String> history;
  final List<BookCandidate> moves;

  factory BookEntry.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.keys.toSet().difference({
          'kind',
          'fen',
          'history',
          'moves',
        }).isNotEmpty ||
        value['kind'] is! String ||
        value['fen'] is! String ||
        (value['fen'] as String).isEmpty ||
        (value['fen'] as String).length > 256 ||
        value['history'] is! List ||
        (value['history'] as List).length > 512 ||
        (value['history'] as List).any(
          (move) => move is! String || !_xiangqiMovePattern.hasMatch(move),
        ) ||
        value['moves'] is! List ||
        (value['moves'] as List).isEmpty ||
        (value['moves'] as List).length > 32) {
      throw const FormatException('Invalid book entry');
    }
    final kind = switch (value['kind']) {
      'opening' => BookKind.opening,
      'endgame' => BookKind.endgame,
      _ => throw const FormatException('Invalid book kind'),
    };
    final moves = (value['moves'] as List)
        .map(BookCandidate.fromJson)
        .toList(growable: false);
    if (moves.map((candidate) => candidate.move).toSet().length !=
        moves.length) {
      throw const FormatException('Duplicate book move');
    }
    return BookEntry(
      kind: kind,
      fen: (value['fen'] as String).trim(),
      history: List.unmodifiable((value['history'] as List).cast<String>()),
      moves: List.unmodifiable(moves),
    );
  }
}

final class BookQueryResult {
  const BookQueryResult({
    required this.kind,
    required this.fen,
    required this.history,
  });
  final BookKind kind;
  final String fen;
  final List<String> history;
}

/// Operator supplied, exact-position book data. No third-party corpus ships
/// with this package and the service never writes user queries to disk.
final class BookDatabase {
  BookDatabase._({
    required this.id,
    required this.license,
    required this.attribution,
    required List<BookEntry> entries,
  }) : _entries = Map.unmodifiable({
         for (final entry in entries)
           _key(entry.kind, entry.fen, entry.history): entry,
       });

  final String id;
  final String license;
  final String attribution;
  final Map<String, BookEntry> _entries;
  int get entryCount => _entries.length;

  static Future<BookDatabase> load(
    Directory root, {
    String fileName = 'book.json',
  }) async {
    if (await FileSystemEntity.type(root.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,63}\.json$').hasMatch(fileName)) {
      throw const FormatException('Invalid book data root');
    }
    final file = File('${root.path}/$fileName');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() > _maxBookManifestBytes) {
      throw const FormatException('Book manifest unavailable or too large');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({
          'schema',
          'dataset',
          'entries',
        }).isNotEmpty ||
        decoded['schema'] != 1 ||
        decoded['dataset'] is! Map<String, dynamic> ||
        decoded['entries'] is! List) {
      throw const FormatException('Invalid book manifest');
    }
    final dataset = decoded['dataset'] as Map<String, dynamic>;
    if (dataset.keys.toSet().difference({
          'id',
          'license',
          'attribution',
        }).isNotEmpty ||
        dataset['id'] is! String ||
        !RegExp(
          r'^[a-z0-9][a-z0-9-]{0,63}$',
        ).hasMatch(dataset['id'] as String) ||
        !_boundedText(
          dataset['license'] is String ? dataset['license'] as String : '',
          1,
          120,
        ) ||
        !_boundedText(
          dataset['attribution'] is String
              ? dataset['attribution'] as String
              : '',
          0,
          500,
        )) {
      throw const FormatException('Book license metadata is required');
    }
    final rawEntries = decoded['entries'] as List;
    if (rawEntries.length > _maxBookEntries) {
      throw const FormatException('Book manifest has too many entries');
    }
    final entries = rawEntries.map(BookEntry.fromJson).toList(growable: false);
    final keys = entries.map((e) => _key(e.kind, e.fen, e.history)).toSet();
    if (keys.length != entries.length) {
      throw const FormatException('Duplicate book position');
    }
    return BookDatabase._(
      id: dataset['id'] as String,
      license: dataset['license'] as String,
      attribution: dataset['attribution'] as String,
      entries: entries,
    );
  }

  BookEntry? query(BookKind kind, String fen, List<String> history) =>
      _entries[_key(kind, fen, history)];

  static String _key(BookKind kind, String fen, List<String> history) =>
      jsonEncode([kind.name, fen.trim(), history]);
}

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
  SkinCatalogStore._(this.root, this.packageDirectoryName, this.skins);

  final Directory root;
  final String packageDirectoryName;
  final List<PublicSkin> skins;

  static Future<SkinCatalogStore> load(
    Directory root, {
    String manifestName = 'catalog.json',
    String packageDirectoryName = 'packages',
  }) async {
    if (await FileSystemEntity.type(root.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FormatException('Catalog root must be a real directory');
    }
    if (!RegExp(r'^[a-z][a-z0-9_-]{0,63}\.json$').hasMatch(manifestName) ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,63}$').hasMatch(packageDirectoryName)) {
      throw const FormatException('Invalid catalog layout');
    }
    final manifest = File('${root.path}/$manifestName');
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
    return SkinCatalogStore._(
      root,
      packageDirectoryName,
      List.unmodifiable(list),
    );
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
      final packageDirectory = Directory('${root.path}/$packageDirectoryName');
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
  SkinCatalogHttpServer._(
    this._server,
    this._store,
    this._boardStore,
    this._bookDatabase,
    this._releaseManifest,
  );

  final HttpServer _server;
  final SkinCatalogStore _store;
  final SkinCatalogStore? _boardStore;
  final BookDatabase? _bookDatabase;
  final ReleaseManifest? _releaseManifest;
  StreamSubscription<HttpRequest>? _subscription;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<SkinCatalogHttpServer> bind({
    required SkinCatalogStore store,
    SkinCatalogStore? boardStore,
    BookDatabase? bookDatabase,
    ReleaseManifest? releaseManifest,
    InternetAddress? address,
    int port = 8087,
  }) async {
    final server = await HttpServer.bind(
      address ?? InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    final service = SkinCatalogHttpServer._(
      server,
      store,
      boardStore,
      bookDatabase,
      releaseManifest,
    );
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
        ..set(
          HttpHeaders.accessControlAllowMethodsHeader,
          'GET, HEAD, POST, OPTIONS',
        )
        ..set(
          HttpHeaders.accessControlAllowHeadersHeader,
          'If-None-Match, Content-Type',
        );
      await response.close();
      return;
    }
    if (request.method == 'POST' &&
        request.uri.path == '/v1/book/query' &&
        _bookDatabase != null) {
      await _bookQuery(request, _bookDatabase);
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      response.headers.set(
        HttpHeaders.allowHeader,
        request.uri.path == '/v1/book/query' && _bookDatabase != null
            ? 'POST, OPTIONS'
            : 'GET, HEAD, OPTIONS',
      );
      await _json(response, HttpStatus.methodNotAllowed, {
        'error': {'code': 'method_not_allowed'},
      });
      return;
    }
    final path = request.uri.path;
    if (path == '/healthz') {
      await _json(response, HttpStatus.ok, {'status': 'ok'});
    } else if (path == '/v1/releases/latest' && _releaseManifest != null) {
      await _json(response, HttpStatus.ok, _releaseManifest.toJson());
    } else if (path == '/v1/catalog') {
      await _list(request, _store);
    } else if (path.startsWith('/v1/catalog/')) {
      await _entry(request, path.substring('/v1/catalog/'.length), _store);
    } else if (path == '/v1/board-catalog' && _boardStore != null) {
      await _list(request, _boardStore);
    } else if (path.startsWith('/v1/board-catalog/') && _boardStore != null) {
      await _entry(
        request,
        path.substring('/v1/board-catalog/'.length),
        _boardStore,
      );
    } else {
      await _json(response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
    }
  }

  Future<void> _bookQuery(HttpRequest request, BookDatabase database) async {
    final response = request.response;
    if (request.headers.contentType?.mimeType != 'application/json' ||
        request.contentLength == 0 ||
        request.contentLength > _maxBookRequestBytes) {
      await _json(response, HttpStatus.badRequest, {
        'error': {'code': 'invalid_request'},
      });
      return;
    }
    final bytes = <int>[];
    await for (final chunk in request) {
      if (bytes.length + chunk.length > _maxBookRequestBytes) {
        await _json(response, 413, {
          'error': {'code': 'request_too_large'},
        });
        return;
      }
      bytes.addAll(chunk);
    }
    try {
      final body = jsonDecode(utf8.decode(bytes));
      if (body is! Map<String, dynamic> ||
          body.keys.toSet().difference({
            'schema',
            'kind',
            'fen',
            'history',
          }).isNotEmpty ||
          body['schema'] != 1 ||
          body['kind'] is! String ||
          body['fen'] is! String ||
          (body['fen'] as String).trim().isEmpty ||
          (body['fen'] as String).length > 256 ||
          body['history'] is! List ||
          (body['history'] as List).length > 512 ||
          (body['history'] as List).any(
            (move) => move is! String || !_xiangqiMovePattern.hasMatch(move),
          )) {
        throw const FormatException('Invalid book query');
      }
      final kind = switch (body['kind']) {
        'opening' => BookKind.opening,
        'endgame' => BookKind.endgame,
        _ => throw const FormatException('Invalid book kind'),
      };
      final history = List<String>.from(body['history'] as List);
      final entry = database.query(kind, body['fen'] as String, history);
      await _json(response, HttpStatus.ok, {
        'schema': 1,
        'status': entry == null ? 'miss' : 'hit',
        'kind': kind.name,
        'fen': body['fen'],
        'history': history,
        'dataset': {
          'id': database.id,
          'license': database.license,
          'attribution': database.attribution,
        },
        'moves': entry?.moves.map((move) => move.toJson()).toList() ?? [],
      });
    } on FormatException {
      await _json(response, HttpStatus.badRequest, {
        'error': {'code': 'invalid_request'},
      });
    }
  }

  Future<void> _list(HttpRequest request, SkinCatalogStore store) async {
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
    final results = store.search(
      query: query,
      sort: sort,
      page: page,
      pageSize: pageSize,
    );
    final count = store.countMatches(query);
    await _json(request.response, HttpStatus.ok, {
      'schema': 1,
      'page': page,
      'pageSize': pageSize,
      'count': results.length,
      'total': count,
      'items': results.map((skin) => skin.toJson()).toList(),
    });
  }

  Future<void> _entry(
    HttpRequest request,
    String pathTail,
    SkinCatalogStore store,
  ) async {
    final segments = pathTail.split('/');
    if (segments.length == 2 && segments[1] == 'package') {
      await _package(request, segments[0], store);
      return;
    }
    if (segments.length != 1 || !_idPattern.hasMatch(segments.single)) {
      await _json(request.response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
      return;
    }
    final skin = store.skins
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

  Future<void> _package(
    HttpRequest request,
    String id,
    SkinCatalogStore store,
  ) async {
    if (!_idPattern.hasMatch(id)) {
      await _json(request.response, HttpStatus.notFound, {
        'error': {'code': 'not_found'},
      });
      return;
    }
    final skin = store.skins.where((item) => item.id == id).firstOrNull;
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
    final bytes = await store.readPackage(skin);
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
