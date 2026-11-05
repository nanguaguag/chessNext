import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/master_games_lookup_controller.dart';
import 'package:chess_next/ports/master_games_service.dart';

void main() {
  late BoardSession session;
  late _FakeService service;
  late MasterGamesLookupController controller;

  setUp(() {
    session = BoardSession();
    service = _FakeService();
    controller = MasterGamesLookupController(session, service);
  });

  tearDown(() {
    controller.dispose();
    session.dispose();
  });

  test('only explicit query sends captured position and filters', () async {
    controller.setFilters(
      category: MasterGameCategory.game,
      text: '棋手',
      fromYear: 2000,
      results: const {MasterGameResult.redWin},
    );
    expect(service.calls, 0);
    await controller.query('http://localhost:8080');
    expect(service.calls, 1);
    expect(service.lastEndpoint!.host, 'localhost');
    expect(service.lastQuery!.fen, session.position.toFen());
    expect(service.lastQuery!.category, MasterGameCategory.game);
    expect(service.lastQuery!.text, '棋手');
    expect(service.lastQuery!.fromYear, 2000);
    expect(service.lastQuery!.results, {MasterGameResult.redWin});
    expect(controller.status, MasterGamesStatus.hit);
    expect(controller.records.single.id, 'game');
    expect(controller.license, 'CC0');
    expect(session.tree.path, hasLength(1));
  });

  test(
    'empty endpoint stays offline and navigation drops in-flight results',
    () async {
      await controller.query('');
      expect(service.calls, 0);
      expect(controller.status, MasterGamesStatus.unavailable);

      final pending = Completer<MasterGamesPage>();
      service.pending = pending;
      final request = controller.query('http://localhost:8080');
      expect(controller.status, MasterGamesStatus.loading);
      session.playMove(session.legalMoves.first);
      pending.complete(_page());
      await request;
      expect(controller.status, MasterGamesStatus.stale);
      expect(controller.records, isEmpty);
    },
  );

  test(
    'invalid filters cannot be queried and result metadata stays separate',
    () async {
      controller.setFilters(toYear: 2020);
      controller.setFilters(fromYear: 2025);
      await controller.query('http://localhost:8080');
      expect(service.calls, 0);
      expect(controller.status, MasterGamesStatus.invalid);
      controller.setFilters(toYear: 2025);
      await controller.query('http://localhost:8080');
      expect(service.calls, 1);
      expect(service.lastQuery!.fromYear, 2025);
      expect(service.lastQuery!.toYear, 2025);
    },
  );

  test('reads licensed PGN without changing the active game', () async {
    await controller.query('http://localhost:8080');
    final game = GameTree().play(Move.parse('h2e2'));
    service.detail = MasterGameDetail(
      id: 'game',
      pgn: PgnCodec.path(
        PgnRecord(
          tree: game,
          tags: {'Red': '红方', 'Black': '黑方', 'Event': '公开赛'},
        ),
      ),
      fen: Position.initialFen,
      history: const [],
      datasetId: 'operator-index',
      license: 'CC0',
      attribution: 'operator',
    );
    final parsed = await controller.readRecord(
      controller.records.single,
      'http://localhost:8080',
    );
    expect(parsed, isNotNull);
    expect(parsed!.tree.currentLine, hasLength(2));
    expect(session.tree.path, hasLength(1));
    expect(session.position.toFen(), Position.initialFen);
  });

  test('drops detail response after active position changes', () async {
    await controller.query('http://localhost:8080');
    final game = GameTree().play(Move.parse('h2e2'));
    final pending = Completer<MasterGameDetail>();
    service.detailPending = pending;
    final read = controller.readRecord(
      controller.records.single,
      'http://localhost:8080',
    );
    session.playMove(session.legalMoves.first);
    pending.complete(
      MasterGameDetail(
        id: 'game',
        pgn: PgnCodec.path(PgnRecord(tree: game)),
        fen: Position.initialFen,
        history: const [],
        datasetId: 'operator-index',
        license: 'CC0',
        attribution: 'operator',
      ),
    );
    expect(await read, isNull);
  });
}

MasterGamesPage _page() => const MasterGamesPage(
  datasetId: 'operator-index',
  license: 'CC0',
  attribution: 'operator',
  page: 1,
  pageSize: 24,
  total: 1,
  records: [
    MasterGameRecord(
      id: 'game',
      category: MasterGameCategory.game,
      red: '红方',
      black: '黑方',
      event: '公开赛',
      year: 2024,
      result: MasterGameResult.redWin,
      hasRecord: true,
    ),
  ],
);

final class _FakeService implements MasterGamesService {
  int calls = 0;
  Uri? lastEndpoint;
  MasterGamesQuery? lastQuery;
  Completer<MasterGamesPage>? pending;
  MasterGameDetail? detail;
  Completer<MasterGameDetail>? detailPending;

  @override
  Future<MasterGameDetail> readRecord({
    required Uri endpoint,
    required String id,
  }) => detailPending?.future ?? Future.value(detail!);

  @override
  Future<MasterGamesPage> query({
    required Uri endpoint,
    required MasterGamesQuery query,
  }) {
    calls++;
    lastEndpoint = endpoint;
    lastQuery = query;
    return pending?.future ?? Future.value(_page());
  }
}
