import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_next/adapters/network/http_book_service.dart';
import 'package:chess_next/ports/book_service.dart';

void main() {
  late HttpServer server;
  late HttpBookService service;
  late List<int> requestBody;

  setUp(() async {
    requestBody = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestBody = await request.fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk));
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'schema': 1,
        'status': 'hit',
        'kind': 'opening',
        'fen': 'full-fen',
        'history': [],
        'dataset': {'id': 'licensed-book', 'license': 'CC0', 'attribution': 'Curator'},
        'moves': [
          {'move': 'a0a1', 'scoreCp': 24, 'weight': 3},
        ],
      }));
      await request.response.close();
    });
    service = HttpBookService();
  });

  tearDown(() async {
    service.close();
    await server.close(force: true);
  });

  test('sends exact key and returns candidates with provenance', () async {
    final result = await service.query(
      endpoint: Uri.parse('http://localhost:${server.port}'),
      position: BookPositionKey(
        kind: BookKind.opening,
        fen: 'full-fen',
        history: const [],
      ),
    );

    expect(jsonDecode(utf8.decode(requestBody)), {
      'kind': 'opening',
      'fen': 'full-fen',
      'history': [],
    });
    expect(result.hit, isTrue);
    expect(result.candidates.single.uci, 'a0a1');
    expect(result.datasetId, 'licensed-book');
    expect(result.license, 'CC0');
  });

  test('rejects non-HTTPS public endpoints before sending a request', () async {
    await expectLater(
      service.query(
        endpoint: Uri.parse('http://example.org'),
        position: BookPositionKey(
          kind: BookKind.opening,
          fen: 'full-fen',
          history: const [],
        ),
      ),
      throwsA(isA<BookServiceInvalidResponse>()),
    );
    expect(requestBody, isEmpty);
  });

  test('rejects an invalid candidate returned by the service', () async {
    await server.close(force: true);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'schema': 1,
        'status': 'hit',
        'kind': 'opening',
        'fen': 'full-fen',
        'history': [],
        'dataset': {'id': 'licensed-book', 'license': 'CC0', 'attribution': ''},
        'moves': [
          {'move': 'bad!', 'scoreCp': 0, 'weight': 1},
        ],
      }));
      await request.response.close();
    });
    await expectLater(
      service.query(
        endpoint: Uri.parse('http://localhost:${server.port}'),
        position: BookPositionKey(
          kind: BookKind.opening,
          fen: 'full-fen',
          history: const [],
        ),
      ),
      throwsA(isA<BookServiceInvalidResponse>()),
    );
  });

  test('rejects oversized history before sending', () async {
    await expectLater(
      service.query(
        endpoint: Uri.parse('http://localhost:${server.port}'),
        position: BookPositionKey(
          kind: BookKind.opening,
          fen: 'full-fen',
          history: List.filled(513, 'a0a1'),
        ),
      ),
      throwsA(isA<BookServiceInvalidResponse>()),
    );
    expect(requestBody, isEmpty);
  });
}
