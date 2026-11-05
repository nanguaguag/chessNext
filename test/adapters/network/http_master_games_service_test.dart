import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_next/adapters/network/http_master_games_service.dart';
import 'package:chess_next/ports/master_games_service.dart';

void main() {
  late HttpServer server;
  late HttpMasterGamesService service;
  late Map<String, Object?> requestBody;
  var statusCode = HttpStatus.ok;
  Object response = const {};
  const gamePgn = '[Game "Chinese Chess"]\n[Format "ICCS"]\n\n1. a0a1 *';

  setUp(() async {
    statusCode = HttpStatus.ok;
    requestBody = {};
    response = {
      'schema': 1,
      'dataset': {'id': 'sample', 'license': 'CC0', 'attribution': 'operator'},
      'page': 1,
      'pageSize': 24,
      'total': 1,
      'records': [
        {
          'id': 'game-1',
          'category': 'game',
          'red': '红方',
          'black': '黑方',
          'event': '公开赛',
          'year': 2024,
          'result': 'draw',
        },
      ],
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.method == 'GET') {
        requestBody = {'path': request.uri.path};
        request.response.statusCode = statusCode;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'schema': 1,
            'dataset': {
              'id': 'sample',
              'license': 'CC0',
              'attribution': 'operator',
            },
            'record': {
              'id': 'game-1',
              'fen': 'position-fen',
              'history': ['a0a1'],
              'pgn': gamePgn,
            },
          }),
        );
        await request.response.close();
        return;
      }
      requestBody = (jsonDecode(await utf8.decoder.bind(request).join()) as Map)
          .cast<String, Object?>();
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
    service = HttpMasterGamesService();
  });

  tearDown(() async {
    service.close();
    await server.close(force: true);
  });

  MasterGamesQuery query({int page = 1}) => MasterGamesQuery(
    fen: 'position-fen',
    history: const ['a0a1'],
    category: MasterGameCategory.chessbook,
    text: '张三',
    fromYear: 1980,
    toYear: 2024,
    results: const {MasterGameResult.draw},
    page: page,
  );

  test(
    'sends explicit bounded filters and decodes licensed metadata',
    () async {
      final result = await service.query(
        endpoint: Uri.parse('http://localhost:${server.port}'),
        query: query(),
      );
      expect(requestBody, {
        'schema': 1,
        'fen': 'position-fen',
        'history': ['a0a1'],
        'category': 'chessbook',
        'text': '张三',
        'fromYear': 1980,
        'toYear': 2024,
        'results': ['draw'],
        'page': 1,
        'pageSize': 24,
      });
      expect(result.records.single.id, 'game-1');
      expect(result.records.single.result, MasterGameResult.draw);
      expect(result.license, 'CC0');
      expect(result.attribution, 'operator');
    },
  );

  test('rejects malformed response and HTTP errors distinctly', () async {
    response = {'schema': 1};
    await expectLater(
      service.query(
        endpoint: Uri.parse('http://localhost:${server.port}'),
        query: query(),
      ),
      throwsA(isA<MasterGamesInvalidResponse>()),
    );
    statusCode = HttpStatus.serviceUnavailable;
    await expectLater(
      service.query(
        endpoint: Uri.parse('http://localhost:${server.port}'),
        query: query(),
      ),
      throwsA(isA<MasterGamesRejected>()),
    );
  });

  test('reads bounded full record only by explicit ID request', () async {
    final result = await service.readRecord(
      endpoint: Uri.parse('http://localhost:${server.port}'),
      id: 'game-1',
    );
    expect(requestBody['path'], '/v1/master-games/records/game-1');
    expect(result.id, 'game-1');
    expect(result.pgn, gamePgn);
    expect(result.fen, 'position-fen');
    expect(result.history, ['a0a1']);
    expect(result.license, 'CC0');
    expect(result.attribution, 'operator');
    await expectLater(
      service.readRecord(
        endpoint: Uri.parse('http://localhost:${server.port}'),
        id: '../other',
      ),
      throwsA(isA<MasterGamesInvalidResponse>()),
    );
  });

  test(
    'rejects unsafe endpoints and reversed year ranges before network',
    () async {
      await expectLater(
        service.query(
          endpoint: Uri.parse('http://example.com'),
          query: query(),
        ),
        throwsA(isA<MasterGamesInvalidResponse>()),
      );
      expect(
        () => MasterGamesQuery(
          fen: 'fen',
          history: const [],
          fromYear: 2025,
          toYear: 2020,
        ),
        throwsArgumentError,
      );
    },
  );
}
