import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skin_catalog_server/skin_catalog_server.dart';

void main() {
  late Directory catalogRoot;
  late Directory masterGamesRoot;
  late SkinCatalogHttpServer server;
  late HttpClient client;

  const fen = 'fixture-position';
  const history = ['a0a1'];
  const fixturePgn = '[Game "Chinese Chess"]\n[Format "ICCS"]\n\n1. a0a1 *';

  setUp(() async {
    final root = await Directory.systemTemp.createTemp('master-games-test-');
    catalogRoot = Directory('${root.path}/catalog')..createSync();
    masterGamesRoot = Directory('${root.path}/master-games')..createSync();
    await File(
      '${catalogRoot.path}/catalog.json',
    ).writeAsString(jsonEncode({'schema': 1, 'skins': []}));
    await File('${masterGamesRoot.path}/master-games.json').writeAsString(
      jsonEncode({
        'schema': 1,
        'dataset': {
          'id': 'operator-index',
          'license': 'CC0-1.0',
          'attribution': 'Operator-authored fixture',
        },
        'records': [
          {
            'id': 'game-spring',
            'category': 'game',
            'fen': fen,
            'history': history,
            'red': 'Alpha',
            'black': 'Beta',
            'event': 'Spring Open',
            'year': 2024,
            'result': 'red_win',
            'pgn': fixturePgn,
          },
          {
            'id': 'game-autumn',
            'category': 'game',
            'fen': fen,
            'history': history,
            'red': 'Gamma',
            'black': 'Alpha',
            'event': 'Autumn Cup',
            'year': 2022,
            'result': 'draw',
          },
          {
            'id': 'book-classic',
            'category': 'chessbook',
            'fen': fen,
            'history': history,
            'red': 'Delta',
            'black': 'Epsilon',
            'event': 'Classic Book',
            'year': 2019,
            'result': 'black_win',
          },
          {
            'id': 'other-position',
            'category': 'game',
            'fen': 'another-position',
            'history': history,
            'red': 'Alpha',
            'black': 'Beta',
            'event': 'Spring Open',
            'year': 2024,
            'result': 'red_win',
          },
        ],
      }),
    );
    server = await SkinCatalogHttpServer.bind(
      store: await SkinCatalogStore.load(catalogRoot),
      masterGameDatabase: await MasterGameDatabase.load(masterGamesRoot),
      port: 0,
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
    await catalogRoot.parent.delete(recursive: true);
  });

  test('filters exact-position games and returns dataset provenance', () async {
    final response = await _post(server, client, {
      'schema': 1,
      'fen': fen,
      'history': history,
      'category': 'game',
      'text': 'spring',
      'fromYear': 2024,
      'toYear': 2024,
      'results': ['red_win'],
    });
    final body = jsonDecode(await _read(response)) as Map<String, dynamic>;
    expect(response.statusCode, HttpStatus.ok, reason: body.toString());
    expect(body['dataset'], {
      'id': 'operator-index',
      'license': 'CC0-1.0',
      'attribution': 'Operator-authored fixture',
    });
    expect(body['total'], 1);
    expect((body['records'] as List).single, {
      'id': 'game-spring',
      'category': 'game',
      'red': 'Alpha',
      'black': 'Beta',
      'event': 'Spring Open',
      'year': 2024,
      'result': 'red_win',
      'hasRecord': true,
    });
  });

  test('full records require an explicit bounded detail request', () async {
    final queryResponse = await _post(server, client, {
      'schema': 1,
      'fen': fen,
      'history': history,
      'category': 'game',
      'text': 'spring',
    });
    final queryBody =
        jsonDecode(await _read(queryResponse)) as Map<String, dynamic>;
    expect(queryBody['records'].single, isNot(contains('pgn')));
    expect(queryBody['records'].single['hasRecord'], isTrue);

    final details = await client.getUrl(
      Uri.parse('${server.baseUrl}/v1/master-games/records/game-spring'),
    );
    final response = await details.close();
    final body = jsonDecode(await _read(response)) as Map<String, dynamic>;
    expect(response.statusCode, HttpStatus.ok);
    expect(body['dataset']['license'], 'CC0-1.0');
    expect(body['dataset']['attribution'], 'Operator-authored fixture');
    expect(body['record'], {
      'id': 'game-spring',
      'fen': fen,
      'history': history,
      'pgn': fixturePgn,
    });
  });

  test('detail endpoint does not expose absent or unknown records', () async {
    for (final id in ['game-autumn', 'not-present']) {
      final request = await client.getUrl(
        Uri.parse('${server.baseUrl}/v1/master-games/records/$id'),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.notFound);
      expect(
        jsonDecode(await _read(response))['error']['code'],
        'record_unavailable',
      );
    }
  });

  test('all category and result filters page in manifest order', () async {
    final first = await _post(server, client, {
      'schema': 1,
      'fen': fen,
      'history': history,
      'pageSize': 1,
    });
    final firstBody = jsonDecode(await _read(first)) as Map<String, dynamic>;
    expect(firstBody['total'], 3);
    expect((firstBody['records'] as List).single['id'], 'game-spring');

    final next = await _post(server, client, {
      'schema': 1,
      'fen': fen,
      'history': history,
      'results': ['draw', 'black_win'],
    });
    final nextBody = jsonDecode(await _read(next)) as Map<String, dynamic>;
    expect(nextBody['total'], 2);
    expect((nextBody['records'] as List).map((record) => record['id']), [
      'game-autumn',
      'book-classic',
    ]);
  });

  test(
    'rejects invalid range, duplicate results and unknown query fields',
    () async {
      for (final invalid in [
        {
          'schema': 1,
          'fen': fen,
          'history': history,
          'fromYear': 2025,
          'toYear': 2024,
        },
        {
          'schema': 1,
          'fen': fen,
          'history': history,
          'results': ['draw', 'draw'],
        },
        {
          'schema': 1,
          'fen': fen,
          'history': history,
          'queryToken': 'must-not-be-accepted',
        },
      ]) {
        final response = await _post(server, client, invalid);
        expect(response.statusCode, HttpStatus.badRequest);
        await response.drain<void>();
      }
    },
  );
}

Future<HttpClientResponse> _post(
  SkinCatalogHttpServer server,
  HttpClient client,
  Map<String, Object?> body,
) async {
  final request = await client.postUrl(
    Uri.parse('${server.baseUrl}/v1/master-games/query'),
  );
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  return request.close();
}

Future<String> _read(HttpClientResponse response) =>
    response.transform(utf8.decoder).join();
