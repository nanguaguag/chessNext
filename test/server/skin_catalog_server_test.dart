import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skin_catalog_server/skin_catalog_server.dart';

final packageBytes = <String, List<int>>{
  'alpha': [1, 3, 3, 7],
  'beta': [2, 4, 6, 8],
  'gamma': [9, 7, 5, 3],
};

void main() {
  late Directory root;
  late Directory boardRoot;
  late Directory releaseRoot;
  late SkinCatalogHttpServer server;
  late HttpClient client;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('skin-catalog-server-');
    boardRoot = await Directory.systemTemp.createTemp(
      'board-skin-catalog-server-',
    );
    releaseRoot = await Directory.systemTemp.createTemp(
      'release-catalog-server-',
    );
    final packages = Directory('${root.path}/packages');
    await packages.create();
    final skins = [
      _skin('alpha', 'Oak', 'Ada', 2, '2026-02-01T00:00:00Z'),
      _skin('beta', 'Amber', 'Zed', 9, '2026-01-01T00:00:00Z'),
      _skin('gamma', 'Cedar', 'Ada', 9, '2026-03-01T00:00:00Z'),
    ];
    await File(
      '${root.path}/catalog.json',
    ).writeAsString(jsonEncode({'schema': 1, 'skins': skins}));
    for (final entry in packageBytes.entries) {
      await File('${packages.path}/${entry.key}.zip').writeAsBytes(entry.value);
    }
    final store = await SkinCatalogStore.load(root);
    final boardPackages = Directory('${boardRoot.path}/board-packages')
      ..createSync();
    await File('${boardRoot.path}/board-catalog.json').writeAsString(
      jsonEncode({
        'schema': 1,
        'skins': [
          _skin('alpha', 'Board Oak', 'Ada', 3, '2026-02-01T00:00:00Z'),
        ],
      }),
    );
    await File(
      '${boardPackages.path}/alpha.zip',
    ).writeAsBytes(packageBytes['alpha']!);
    final boardStore = await SkinCatalogStore.load(
      boardRoot,
      manifestName: 'board-catalog.json',
      packageDirectoryName: 'board-packages',
    );
    await File('${releaseRoot.path}/releases.json').writeAsString(
      jsonEncode({
        'schema': 1,
        'releases': [
          {
            'version': '0.2.0',
            'build': 2,
            'publishedAt': '2026-11-05T00:00:00Z',
            'notes': 'Improved board controls.',
          },
          {
            'version': '0.1.0',
            'build': 1,
            'publishedAt': '2026-10-05T00:00:00Z',
            'notes': 'First release.',
          },
        ],
      }),
    );
    server = await SkinCatalogHttpServer.bind(
      store: store,
      boardStore: boardStore,
      releaseManifest: await ReleaseManifest.load(releaseRoot),
      port: 0,
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
    await root.delete(recursive: true);
    await boardRoot.delete(recursive: true);
    await releaseRoot.delete(recursive: true);
  });

  test(
    'serves operator supplied version and newest-first release notes',
    () async {
      final result = await _getJson(server, client, '/v1/releases/latest');
      expect(result['schema'], 1);
      expect(result['current'], {
        'version': '0.2.0',
        'build': 2,
        'publishedAt': '2026-11-05T00:00:00.000Z',
        'notes': 'Improved board controls.',
      });
      expect((result['history'] as List).length, 2);
      expect((result['history'] as List).first['version'], '0.2.0');
    },
  );

  test('release endpoint is optional and read-only', () async {
    final request = await client.postUrl(
      Uri.parse('${server.baseUrl}/v1/releases/latest'),
    );
    request.write('{}');
    final response = await request.close();
    expect(response.statusCode, HttpStatus.methodNotAllowed);
    await response.drain<void>();

    final disabled = await SkinCatalogHttpServer.bind(
      store: await SkinCatalogStore.load(root),
      port: 0,
    );
    final unavailable = await client.getUrl(
      Uri.parse('${disabled.baseUrl}/v1/releases/latest'),
    );
    final unavailableResponse = await unavailable.close();
    expect(unavailableResponse.statusCode, HttpStatus.notFound);
    await unavailableResponse.drain<void>();
    await disabled.close();
  });

  test(
    'keeps curated order and supports bounded search, sort and paging',
    () async {
      final defaults = await _getJson(server, client, '/v1/catalog');
      expect((defaults['items'] as List).map((item) => item['id']), [
        'alpha',
        'beta',
        'gamma',
      ]);
      expect(defaults['total'], 3);

      final likes = await _getJson(
        server,
        client,
        '/v1/catalog?sort=likes&page=1&pageSize=2',
      );
      expect((likes['items'] as List).map((item) => item['id']), [
        'beta',
        'gamma',
      ]);
      expect(likes['count'], 2);
      expect(likes['total'], 3);

      final names = await _getJson(
        server,
        client,
        '/v1/catalog?q=ced&sort=name&page=1&pageSize=1',
      );
      expect(names['total'], 1);
      expect((names['items'] as List).single['id'], 'gamma');
    },
  );

  test('serves license metadata and hash checked bounded packages', () async {
    final metadata = await _getJson(server, client, '/v1/catalog/alpha');
    expect((metadata['item'] as Map)['license'], 'CC0-1.0');
    expect((metadata['item'] as Map)['attribution'], 'Artist Ada');

    final uri = Uri.parse('${server.baseUrl}/v1/catalog/alpha/package');
    final request = await client.getUrl(uri);
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    expect(response.statusCode, HttpStatus.ok);
    expect(bytes, packageBytes['alpha']);
    final etag = response.headers.value(HttpHeaders.etagHeader);
    expect(etag, '"${sha256.convert(packageBytes['alpha']!)}"');

    final cachedRequest = await client.getUrl(uri);
    cachedRequest.headers.set(HttpHeaders.ifNoneMatchHeader, etag!);
    final cached = await cachedRequest.close();
    expect(cached.statusCode, HttpStatus.notModified);
    await cached.drain<void>();
  });

  test('serves board catalog independently from piece catalog', () async {
    final board = await _getJson(server, client, '/v1/board-catalog');
    expect(board['total'], 1);
    expect((board['items'] as List).single['name'], 'Board Oak');
    expect((await _getJson(server, client, '/v1/catalog'))['total'], 3);

    final request = await client.getUrl(
      Uri.parse('${server.baseUrl}/v1/board-catalog/alpha/package'),
    );
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    expect(response.statusCode, HttpStatus.ok);
    expect(bytes, packageBytes['alpha']);
  });

  test('rejects invalid queries and all mutation methods', () async {
    final bad = await client.getUrl(
      Uri.parse('${server.baseUrl}/v1/catalog?sort=unknown&pageSize=101'),
    );
    final badResponse = await bad.close();
    expect(badResponse.statusCode, HttpStatus.badRequest);
    await badResponse.drain<void>();

    final write = await client.postUrl(
      Uri.parse('${server.baseUrl}/v1/catalog'),
    );
    final writeResponse = await write.close();
    expect(writeResponse.statusCode, HttpStatus.methodNotAllowed);
    expect(
      writeResponse.headers.value(HttpHeaders.allowHeader),
      'GET, HEAD, OPTIONS',
    );
    await writeResponse.drain<void>();
  });

  test('does not serve a package changed after publication', () async {
    await File('${root.path}/packages/alpha.zip').writeAsBytes([99]);
    final request = await client.getUrl(
      Uri.parse('${server.baseUrl}/v1/catalog/alpha/package'),
    );
    request.headers.set(
      HttpHeaders.ifNoneMatchHeader,
      '"${sha256.convert(packageBytes['alpha']!)}"',
    );
    final response = await request.close();
    expect(response.statusCode, HttpStatus.notFound);
    expect(
      jsonDecode(
        await response.transform(utf8.decoder).join(),
      )['error']['code'],
      'package_unavailable',
    );
  });

  test('rejects malformed catalog documents and invalid identifiers', () async {
    final badRoot = await Directory.systemTemp.createTemp(
      'skin-catalog-invalid-',
    );
    addTearDown(() => badRoot.delete(recursive: true));
    await File('${badRoot.path}/catalog.json').writeAsString(
      jsonEncode({
        'schema': 1,
        'skins': [
          _skin('../escape', 'bad', 'author', 0, '2026-01-01T00:00:00Z'),
        ],
      }),
    );
    await expectLater(SkinCatalogStore.load(badRoot), throwsFormatException);
  });
}

Map<String, Object> _skin(
  String id,
  String name,
  String author,
  int likes,
  String publishedAt,
) => {
  'id': id,
  'name': name,
  'author': author,
  'description': 'Original $name appearance.',
  'likes': likes,
  'publishedAt': publishedAt,
  'license': 'CC0-1.0',
  'attribution': 'Artist $author',
  'packageSha256': sha256.convert(packageBytesFor(id)).toString(),
};

List<int> packageBytesFor(String id) => switch (id) {
  'alpha' => [1, 3, 3, 7],
  'beta' => [2, 4, 6, 8],
  'gamma' => [9, 7, 5, 3],
  _ => const [],
};

Future<Map<String, dynamic>> _getJson(
  SkinCatalogHttpServer server,
  HttpClient client,
  String path,
) async {
  final request = await client.getUrl(Uri.parse('${server.baseUrl}$path'));
  final response = await request.close();
  expect(response.statusCode, HttpStatus.ok);
  return jsonDecode(await response.transform(utf8.decoder).join())
      as Map<String, dynamic>;
}
