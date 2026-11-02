import 'package:chess_next/application/analysis_history.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/pv_prefix_action.dart';
import 'package:chess_next/application/pv_preview.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

void main() {
  test(
    'document history keeps both source sides while latest info and stale tokens stay isolated',
    () async {
      final session = BoardSession(), fake = FakeEngine();
      final controller = EngineSessionController(
        session,
        () => Future.value(fake),
      );
      Future<void> emit(int token, String pv, {int score = 10}) async {
        fake.emit(
          token,
          pv: pv,
          score: score,
          wdl: WdlEstimate(wins: 300, draws: 600, losses: 100),
        );
        await Future<void>.delayed(const Duration(milliseconds: 130));
      }

      try {
        await controller.enable();
        final redToken = fake.requests.last.token;
        await emit(redToken, 'b2e2 b9c7');
        final red = controller.history.single;
        expect(red.sourcePly, 0);
        expect(red.sourceLabel, '起始局面');
        session.playMove(Move.parse('h2e2'));
        expect(controller.history.single, same(red));
        expect(controller.infos, isEmpty);
        expect(controller.recommended, isNull);
        expect(controller.reply, isNull);
        await emit(redToken, 'h2e2 b9c7', score: 999);
        expect(controller.history.length, 1);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        final blackToken = fake.requests.last.token;
        expect(blackToken, isNot(redToken));
        await emit(blackToken, 'b9c7 b0c2', score: 30);
        final black = controller.history.first;
        expect(controller.history.length, 2);
        expect(black.sourcePly, 1);
        expect(black.sourceMoveLabel, '炮二平五');
        expect(black.position.turn, Side.black);
        expect(black.scoreFor(Side.red), -30);
        expect(black.wdlFor(Side.red)!.wins, 100);
        expect(red.position.turn, Side.red);
        expect(red.scoreFor(Side.red), 10);
        await controller.disable();
        final archive = controller.history;
        session.flip();
        session.updateMetadata(GameMetadata({'Event': '不清历史'}));
        session.first();
        expect(controller.history, same(archive));
        expect(controller.createPvPrefixAction(red).isCurrent, isTrue);
        session.newGame();
        expect(controller.history, isEmpty);
        await emit(blackToken, 'b9c7 b0c2', score: 700);
        expect(controller.history, isEmpty);
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );
  test('all source positions share the same 64-entry and 128-ply budgets', () {
    final history = AnalysisHistory();
    final red = Position.initial(), black = red.play(Move.parse('h2e2'));
    for (var i = 0; i < 80; i++) {
      history.add(
        position: i.isEven ? red : black,
        epoch: 1,
        nodeId: i.isEven ? 'n0' : 'n1',
        revision: 1,
        positionRevision: i,
        sourcePly: i.isEven ? 0 : 1,
        sourceMoveLabel: i.isEven ? null : '炮二平五',
        info: EngineInfo(
          token: i + 1,
          depth: 10,
          multiPv: 1,
          score: i,
          isMate: false,
          pv: List.filled(150, Move.parse(i.isEven ? 'b2e2' : 'b9c7')),
        ),
      );
    }
    expect(history.entries.length, 64);
    expect(history.entries.where((e) => e.sourcePly == 0).length, 32);
    expect(history.entries.where((e) => e.sourcePly == 1).length, 32);
    expect(history.entries.first.scoreFor(Side.red), -79);
    expect(history.entries.last.scoreFor(Side.red), 16);
    expect(history.entries.every((e) => e.info.pv.length == 128), isTrue);
  });
  test(
    'a deleted source is still readable but can never apply to a different node',
    () async {
      final session = BoardSession()..playMove(Move.parse('h2e2'));
      final fake = FakeEngine(),
          controller = EngineSessionController(
            session,
            () => Future.value(fake),
          );
      try {
        await controller.enable();
        fake.emit(fake.requests.last.token, pv: 'b9c7 b0c2');
        await Future<void>.delayed(const Duration(milliseconds: 130));
        await controller.disable();
        final entry = controller.history.single;
        session.first();
        session.deleteBranch(entry.nodeId);
        expect(controller.history.single, same(entry));
        expect(session.tree.hasNode(entry.nodeId), isFalse);
        final preview = await PvPreview.prepareInWorker(entry);
        expect(preview.length, 2);
        expect(preview.positions.first.toFen(), entry.position.toFen());
        final action = controller.createPvPrefixAction(entry);
        expect(action.isCurrent, isFalse);
        final tree = session.tree;
        expect(
          await action.apply(1, PvApplyCancellation()),
          PvApplyResult.stale,
        );
        expect(session.tree, same(tree));
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );
}
