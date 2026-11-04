import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_next/adapters/network/http_piece_skin_catalog.dart';
import 'package:chess_next/adapters/storage/file_piece_skin_catalog_cache.dart';
import 'package:chess_next/ports/piece_skin_catalog.dart';

void main() {
  late HttpServer server;
  late HttpPieceSkinCatalog catalog;
  late Directory cacheDirectory;
  late List<Uri> requests;
  final packageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

  setUp(() async {
    requests = [];
    cacheDirectory = await Directory.systemTemp.createTemp(
      'skin-catalog-http-cache-',
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri);
      if (request.uri.path.endsWith('/package')) {
        request.response.headers.contentType = ContentType(
          'application',
          'zip',
        );
        request.response.add(packageBytes);
        await request.response.close();
        return;
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'schema': 1,
          'page': int.parse(request.uri.queryParameters['page']!),
          'pageSize': int.parse(request.uri.queryParameters['pageSize']!),
          'count': 1,
          'total': 1,
          'items': [
            {
              'id': 'original-red',
              'name': '原创红章',
              'author': '本地作者',
              'description': '经许可发布',
              'likes': 4,
              'publishedAt': '2026-10-20T00:00:00Z',
              'license': 'CC-BY-4.0',
              'attribution': 'ChessNext社区作者',
              'packageSha256': List.filled(64, 'a').join(),
            },
          ],
        }),
      );
      await request.response.close();
    });
    catalog = HttpPieceSkinCatalog(
      timeout: const Duration(seconds: 2),
      cache: FilePieceSkinCatalogCache(() async => cacheDirectory),
    );
  });

  tearDown(() async {
    catalog.close();
    await server.close(force: true);
    await cacheDirectory.delete(recursive: true);
  });

  test('encodes query and sort and decodes license metadata', () async {
    final result = await catalog.search(
      endpoint: Uri.parse('http://127.0.0.1:${server.port}/'),
      query: '红 章',
      sort: PublicPieceSkinSort.likes,
      page: 2,
      pageSize: 12,
    );
    expect(result.total, 1);
    expect(result.items.single.license, 'CC-BY-4.0');
    expect(result.items.single.attribution, 'ChessNext社区作者');
    expect(requests.single.queryParameters, {
      'q': '红 章',
      'sort': 'likes',
      'page': '2',
      'pageSize': '12',
    });
  });

  test(
    'rejects cleartext remote endpoints and invalid bounds before request',
    () async {
      await expectLater(
        catalog.search(
          endpoint: Uri.parse('http://example.com'),
          query: '',
          sort: PublicPieceSkinSort.defaultOrder,
        ),
        throwsA(isA<PieceSkinCatalogInvalidResponse>()),
      );
      expect(requests, isEmpty);
    },
  );

  test('maps connection failure to unavailable', () async {
    final closedPort = server.port;
    await server.close(force: true);
    await expectLater(
      catalog.search(
        endpoint: Uri.parse('http://127.0.0.1:$closedPort'),
        query: '',
        sort: PublicPieceSkinSort.defaultOrder,
      ),
      throwsA(isA<PieceSkinCatalogUnavailable>()),
    );
  });

  test(
    'uses persisted last successful page when the server is unavailable',
    () async {
      final endpoint = Uri.parse('http://127.0.0.1:${server.port}');
      final online = await catalog.search(
        endpoint: endpoint,
        query: '红章',
        sort: PublicPieceSkinSort.likes,
      );
      expect(online.isStale, isFalse);
      final savedPort = server.port;
      await server.close(force: true);

      final reopenedCatalog = HttpPieceSkinCatalog(
        timeout: const Duration(milliseconds: 100),
        cache: FilePieceSkinCatalogCache(() async => cacheDirectory),
      );
      addTearDown(reopenedCatalog.close);
      final cached = await reopenedCatalog.search(
        endpoint: Uri.parse('http://127.0.0.1:$savedPort'),
        query: '红章',
        sort: PublicPieceSkinSort.likes,
      );
      expect(cached.isStale, isTrue);
      expect(cached.cachedAt, isNotNull);
      expect(cached.items.single.id, 'original-red');
    },
  );

  test('downloads only the expected bounded package digest', () async {
    final bytes = await catalog.downloadPackage(
      endpoint: Uri.parse('http://127.0.0.1:${server.port}'),
      id: 'original-red',
      expectedSha256: sha256.convert(packageBytes).toString(),
    );
    expect(bytes, packageBytes);
    await expectLater(
      catalog.downloadPackage(
        endpoint: Uri.parse('http://127.0.0.1:${server.port}'),
        id: 'original-red',
        expectedSha256: List.filled(64, 'b').join(),
      ),
      throwsA(isA<PieceSkinCatalogInvalidResponse>()),
    );
  });
}
