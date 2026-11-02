import 'package:chess_next/application/analysis_history.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

void main() {
  EngineInfo info({
    int token = 1,
    int depth = 8,
    int score = 10,
    int pv = 1,
    List<Move>? moves,
    String? bound,
    WdlEstimate? wdl,
    int time = 100,
  }) => EngineInfo(
    token: token,
    depth: depth,
    multiPv: pv,
    score: score,
    isMate: false,
    pv: moves ?? [Move.parse('h2e2')],
    bound: bound,
    wdl: wdl,
    timeMs: time,
  );
  void add(AnalysisHistory history, EngineInfo value, {Position? position}) =>
      history.add(
        position: position ?? Position.initial(),
        epoch: 3,
        nodeId: 'n7',
        revision: 4,
        positionRevision: 8,
        info: value,
      );
  test(
    'history freezes engine PV and immutable list snapshots independently',
    () {
      final history = AnalysisHistory(), moves = [Move.parse('h2e2')];
      add(history, info(moves: moves));
      final snapshot = history.entries, entry = snapshot.single;
      moves.clear();
      expect(entry.info.pv, [Move.parse('h2e2')]);
      expect(entry.epoch, 3);
      expect(entry.nodeId, 'n7');
      expect(entry.revision, 4);
      expect(entry.positionRevision, 8);
      expect(() => entry.info.pv.clear(), throwsUnsupportedError);
      expect(() => snapshot.clear(), throwsUnsupportedError);
      history.clear();
      expect(history.entries, isEmpty);
      expect(snapshot.length, 1);
      add(history, info());
      expect(history.entries.single.id, greaterThan(entry.id));
    },
  );
  test(
    'time-only repeats are deduplicated while score, depth, PV, bound, WDL and token changes stay',
    () {
      final history = AnalysisHistory();
      final wdl = WdlEstimate(wins: 10, draws: 980, losses: 10);
      add(history, info(wdl: wdl));
      add(
        history,
        info(time: 500, wdl: WdlEstimate(wins: 10, draws: 980, losses: 10)),
      );
      expect(history.entries.length, 1);
      for (final value in [
        info(score: 11, wdl: wdl),
        info(depth: 9, score: 11, wdl: wdl),
        info(depth: 9, score: 11, bound: 'lower', wdl: wdl),
        info(
          depth: 9,
          score: 11,
          bound: 'lower',
          wdl: WdlEstimate(wins: 20, draws: 970, losses: 10),
        ),
        info(token: 2),
        info(token: 2, moves: [Move.parse('b0c2')]),
      ]) {
        add(history, value);
      }
      expect(history.entries.length, 7);
      expect(history.entries.first.info.pv.single, Move.parse('b0c2'));
    },
  );
  test(
    '64 entries and 128 plies cap memory; bad indices and empty lines are ignored',
    () {
      final history = AnalysisHistory();
      for (final value in [
        info(pv: 0),
        info(pv: 257),
        info(depth: -1),
        info(depth: 256),
        info(moves: []),
      ]) {
        add(history, value);
      }
      expect(history.entries, isEmpty);
      for (var n = 0; n < 100; n++) {
        add(
          history,
          info(score: n, moves: List.filled(300, Move.parse('h2e2'))),
        );
      }
      expect(history.entries.length, 64);
      expect(history.entries.first.info.score, 99);
      expect(history.entries.last.info.score, 36);
      expect(
        history.entries.every(
          (e) =>
              e.info.pv.length == 128 &&
              e.originalPvLength == 300 &&
              e.truncated,
        ),
        isTrue,
      );
    },
  );
  test(
    'scores bounds and model data normalize using the frozen source side',
    () {
      final history = AnalysisHistory();
      add(
        history,
        info(
          bound: 'lower',
          wdl: WdlEstimate(wins: 300, draws: 600, losses: 100),
        ),
        position: Position.initial().play(Move.parse('h2e2')),
      );
      final entry = history.entries.single;
      expect(entry.scoreFor(Side.red), -10);
      expect(entry.boundFor(Side.red), 'upper');
      expect(entry.boundFor(Side.black), 'lower');
      expect(entry.wdlFor(Side.red)!.wins, 100);
      expect(entry.wdlFor(Side.black)!.wins, 300);
    },
  );
  test(
    'controller samples valid tokens, retains stopped history and clears only for position changes',
    () async {
      final session = BoardSession(), fake = FakeEngine();
      final controller = EngineSessionController(
        session,
        () => Future.value(fake),
      );
      Future<void> emit(int token, int score) async {
        fake.emit(token, score: score);
        await Future<void>.delayed(const Duration(milliseconds: 130));
      }

      try {
        await controller.enable();
        final token = fake.requests.last.token;
        await emit(token, 10);
        await emit(token, 10);
        expect(controller.history.length, 1);
        await emit(token, 11);
        expect(controller.history.length, 2);
        final snapshot = controller.history;
        session.flip();
        session.updateMetadata(GameMetadata({'Event': '历史测试'}));
        expect(controller.history, same(snapshot));
        await controller.disable();
        await emit(token, 99);
        expect(controller.history, same(snapshot));
        await controller.enable();
        await emit(fake.requests.last.token, 12);
        expect(controller.history.length, 3);
        final requests = fake.requests.length,
            stops = fake.stops,
            tree = session.tree;
        controller.clearAnalysisHistory();
        expect(controller.history, isEmpty);
        expect(fake.requests.length, requests);
        expect(fake.stops, stops);
        expect(session.tree, same(tree));
        await emit(fake.requests.last.token, 12);
        expect(controller.history.length, 1);
        session.playMove(Move.parse('h2e2'));
        expect(controller.history, isEmpty);
        await emit(token, 100);
        expect(controller.history, isEmpty);
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );
}
