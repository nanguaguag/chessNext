import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_next/adapters/network/http_piece_skin_catalog.dart';
import 'package:chess_next/ports/piece_skin_catalog.dart';

void main() {
  late HttpServer server;
  late HttpPieceSkinCatalog catalog;
  late List<Uri> requests;

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri);
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
    catalog = HttpPieceSkinCatalog(timeout: const Duration(seconds: 2));
  });

  tearDown(() async {
    catalog.close();
    await server.close(force: true);
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
}
