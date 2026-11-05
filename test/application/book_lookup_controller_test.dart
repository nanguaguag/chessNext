import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:chess_next/application/book_lookup_controller.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/ports/book_service.dart';

void main() {
  late BoardSession session;
  late _FakeBookService service;
  late BookLookupController controller;

  setUp(() {
    session = BoardSession();
    service = _FakeBookService();
    controller = BookLookupController(session, service);
  });

  tearDown(() {
    controller.dispose();
    session.dispose();
  });

  test(
    'queries only on explicit request and keeps legal candidates read-only',
    () async {
      expect(service.calls, 0);
      final move = session.legalMoves.first;
      service.response = BookLookup(
        hit: true,
        candidates: [
          BookMoveCandidate(uci: move.toString(), scoreCp: 12, weight: 4),
          const BookMoveCandidate(uci: 'a0a9', scoreCp: 999, weight: 1),
        ],
        datasetId: 'sample',
        license: 'CC0',
        attribution: 'operator',
      );

      await controller.query('http://127.0.0.1:8080');

      expect(service.calls, 1);
      expect(service.lastEndpoint.toString(), 'http://127.0.0.1:8080');
      expect(service.lastPosition!.kind, BookKind.opening);
      expect(controller.status, BookLookupStatus.hit);
      expect(controller.candidates.map((candidate) => candidate.uci), [
        move.toString(),
      ]);
      expect(
        controller.candidates.single.notation,
        ChineseNotation.format(session.position, move),
      );
      expect(controller.datasetId, 'sample');
      expect(controller.license, 'CC0');
      expect(controller.attribution, 'operator');
      expect(session.tree.path, hasLength(1));
    },
  );

  test(
    'does not send a query without an explicitly configured endpoint',
    () async {
      await controller.query(' ');

      expect(service.calls, 0);
      expect(controller.status, BookLookupStatus.unavailable);
      expect(controller.message, contains('配置'));
    },
  );

  test('navigation clears candidates and ignores an old response', () async {
    final pending = Completer<BookLookup>();
    service.pending = pending;
    final request = controller.query('http://localhost:8080');
    expect(controller.status, BookLookupStatus.loading);

    session.playMove(session.legalMoves.first);
    pending.complete(
      BookLookup(
        hit: true,
        candidates: const [
          BookMoveCandidate(uci: 'a0a1', scoreCp: 0, weight: 1),
        ],
        datasetId: 'stale',
        license: 'CC0',
        attribution: 'operator',
      ),
    );
    await request;

    expect(controller.status, BookLookupStatus.stale);
    expect(controller.candidates, isEmpty);
    expect(controller.message, contains('局面已变化'));
  });

  test(
    'changing the book kind invalidates a request for the previous kind',
    () async {
      final pending = Completer<BookLookup>();
      service.pending = pending;
      final request = controller.query('http://localhost:8080');
      controller.setKind(BookKind.endgame);
      pending.complete(
        const BookLookup(
          hit: true,
          candidates: [BookMoveCandidate(uci: 'a0a1', scoreCp: 0, weight: 1)],
          datasetId: 'opening-only',
          license: 'CC0',
          attribution: 'operator',
        ),
      );
      await request;

      expect(controller.kind, BookKind.endgame);
      expect(controller.status, BookLookupStatus.idle);
      expect(controller.candidates, isEmpty);
    },
  );

  test(
    'hides a hit whose every candidate is illegal at the current position',
    () async {
      service.response = const BookLookup(
        hit: true,
        candidates: [BookMoveCandidate(uci: 'a0a9', scoreCp: 0, weight: 1)],
        datasetId: 'invalid',
        license: 'CC0',
        attribution: 'operator',
      );

      await controller.query('http://localhost:8080');

      expect(controller.status, BookLookupStatus.invalid);
      expect(controller.candidates, isEmpty);
      expect(controller.datasetId, isNull);
    },
  );

  test('separates offline failures from a valid miss', () async {
    service.error = const BookServiceUnavailable();
    await controller.query('http://localhost:8080');
    expect(controller.status, BookLookupStatus.unavailable);

    service.error = null;
    service.response = const BookLookup(
      hit: false,
      candidates: [],
      datasetId: 'empty-set',
      license: 'CC0',
      attribution: 'operator',
    );
    await controller.query('http://localhost:8080');
    expect(controller.status, BookLookupStatus.miss);
    expect(controller.message, contains('未收录'));
  });
}

final class _FakeBookService implements BookService {
  BookLookup response = const BookLookup(
    hit: false,
    candidates: [],
    datasetId: null,
    license: null,
    attribution: null,
  );
  Completer<BookLookup>? pending;
  Object? error;
  Uri? lastEndpoint;
  BookPositionKey? lastPosition;
  int calls = 0;

  @override
  Future<BookLookup> query({
    required Uri endpoint,
    required BookPositionKey position,
  }) async {
    calls++;
    lastEndpoint = endpoint;
    lastPosition = position;
    if (error case final failure?) throw failure;
    if (pending case final completer?) return completer.future;
    return response;
  }
}
