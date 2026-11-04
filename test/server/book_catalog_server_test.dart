import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skin_catalog_server/skin_catalog_server.dart';

void main() {
  late Directory skinRoot;
  late Directory bookRoot;
  late SkinCatalogHttpServer server;
  late HttpClient client;

  setUp(() async {
    skinRoot = await Directory.systemTemp.createTemp('book-skin-root-');
    bookRoot = await Directory.systemTemp.createTemp('book-data-root-');
    await File(
      '${skinRoot.path}/catalog.json',
    ).writeAsString(jsonEncode({'schema': 1, 'skins': []}));
    await File('${bookRoot.path}/book.json').writeAsString(
      jsonEncode({
        'schema': 1,
        'dataset': {
          'id': 'operator-fixture',
          'license': 'CC0-1.0',
          'attribution': 'Self-authored test fixture',
        },
        'entries': [
          {
            'kind': 'opening',
            'fen': 'fixture-position',
            'history': ['a0a1'],
            'moves': [
              {'move': 'b0b1', 'scoreCp': 12, 'weight': 8},
              {'move': 'c0c1', 'scoreCp': 3, 'weight': 2},
            ],
          },
        ],
      }),
    );
    server = await SkinCatalogHttpServer.bind(
      store: await SkinCatalogStore.load(skinRoot),
      bookDatabase: await BookDatabase.load(bookRoot),
      port: 0,
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
    await skinRoot.delete(recursive: true);
    await bookRoot.delete(recursive: true);
  });

  test('exact book lookup returns candidates and dataset provenance', () async {
    final response = await _post(server, client, {
      'schema': 1,
      'kind': 'opening',
      'fen': 'fixture-position',
      'history': ['a0a1'],
    });
    final responseBody = await _responseBody(response);
    expect(response.statusCode, HttpStatus.ok, reason: responseBody);
    final body = jsonDecode(responseBody) as Map<String, dynamic>;
    expect(body['status'], 'hit');
    expect(body['dataset'], {
      'id': 'operator-fixture',
      'license': 'CC0-1.0',
      'attribution': 'Self-authored test fixture',
    });
    expect((body['moves'] as List).first['move'], 'b0b1');
  });

  test(
    'misses are explicit and history/kind are part of the lookup key',
    () async {
      for (final request in [
        {
          'schema': 1,
          'kind': 'opening',
          'fen': 'fixture-position',
          'history': [],
        },
        {
          'schema': 1,
          'kind': 'endgame',
          'fen': 'fixture-position',
          'history': ['a0a1'],
        },
      ]) {
        final response = await _post(server, client, request);
        final body =
            jsonDecode(await _responseBody(response)) as Map<String, dynamic>;
        expect(body['status'], 'miss');
        expect(body['moves'], isEmpty);
      }
    },
  );

  test(
    'rejects malformed moves, unknown fields and wrong content type',
    () async {
      final badMove = await _post(server, client, {
        'schema': 1,
        'kind': 'opening',
        'fen': 'fixture-position',
        'history': ['../escape'],
      });
      expect(badMove.statusCode, HttpStatus.badRequest);
      await badMove.drain<void>();

      final unknown = await _post(server, client, {
        'schema': 1,
        'kind': 'opening',
        'fen': 'fixture-position',
        'history': [],
        'accountToken': 'must-not-be-accepted',
      });
      expect(unknown.statusCode, HttpStatus.badRequest);
      await unknown.drain<void>();

      final uri = Uri.parse('${server.baseUrl}/v1/book/query');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.text;
      request.write('{}');
      final response = await request.close();
      expect(response.statusCode, HttpStatus.badRequest);
      await response.drain<void>();
    },
  );

  test('book query is opt-in and preflight declares JSON POST', () async {
    final options = await client.openUrl(
      'OPTIONS',
      Uri.parse('${server.baseUrl}/v1/book/query'),
    );
    final preflight = await options.close();
    expect(preflight.statusCode, HttpStatus.noContent);
    expect(
      preflight.headers.value(HttpHeaders.accessControlAllowMethodsHeader),
      contains('POST'),
    );
    expect(
      preflight.headers.value(HttpHeaders.accessControlAllowHeadersHeader),
      contains('Content-Type'),
    );
    await preflight.drain<void>();
  });

  test('rejects unlicensed and ambiguous operator manifests', () async {
    final file = File('${bookRoot.path}/book.json');
    final original = await file.readAsString();
    final unlicensed = jsonDecode(original) as Map<String, dynamic>;
    (unlicensed['dataset'] as Map<String, dynamic>).remove('license');
    await file.writeAsString(jsonEncode(unlicensed));
    await expectLater(BookDatabase.load(bookRoot), throwsFormatException);

    final duplicate = jsonDecode(original) as Map<String, dynamic>;
    final first = (duplicate['entries'] as List).single;
    duplicate['entries'] = [first, first];
    await file.writeAsString(jsonEncode(duplicate));
    await expectLater(BookDatabase.load(bookRoot), throwsFormatException);
  });

  test('rejects chunked requests after the 32 KiB streaming limit', () async {
    final request = await client.postUrl(
      Uri.parse('${server.baseUrl}/v1/book/query'),
    );
    request.headers.contentType = ContentType.json;
    request.headers.chunkedTransferEncoding = true;
    request.write('{"padding":"${'x' * 40000}"}');
    final response = await request.close();
    expect(response.statusCode, 413);
    await response.drain<void>();
  });
}

Future<HttpClientResponse> _post(
  SkinCatalogHttpServer server,
  HttpClient client,
  Map<String, Object> body,
) async {
  final request = await client.postUrl(
    Uri.parse('${server.baseUrl}/v1/book/query'),
  );
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  return request.close();
}

Future<String> _responseBody(HttpClientResponse response) async => utf8.decode(
  await response.fold<List<int>>(<int>[], (all, bytes) => all..addAll(bytes)),
);
