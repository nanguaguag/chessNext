import 'package:chess_next/app.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../packages/xiangqi_core/test/support/capacity_tree.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  void desktop(WidgetTester t) {
    t.view.physicalSize = const Size(1120, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets(
    '200 percent capacity notice preserves the full game and allows save and reopen',
    (t) async {
      desktop(t);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryGameRepository();
      Widget app() => ChessNextApp(key: UniqueKey(), repository: store);
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      var session = t.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session;
      session.replaceTree(
        capacityTree().annotate('容量评注'),
        metadata: GameMetadata({'Event': '容量自制赛事'}),
      );
      await t.pumpAndSettle();
      final tree = session.tree, move = session.legalMoves.first;
      await tap(t, find.byKey(ValueKey('square-${move.from}')));
      await tap(t, find.byKey(ValueKey('square-${move.to}')));
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      await t.ensureVisible(find.text(BoardSession.capacityNotice));
      await t.pumpAndSettle();
      expect(
        find.text(BoardSession.capacityNotice).hitTestable(),
        findsOneWidget,
      );
      await tap(t, find.text('保存棋谱'));
      await t.enterText(find.byKey(const ValueKey('record-name')), '容量完整棋谱');
      await tap(t, find.widgetWithText(FilledButton, '保存'));
      await pumpUntil(
        t,
        () => find.text('已保存到本地 · 容量完整棋谱').evaluate().isNotEmpty,
      );
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await tap(t, find.text('棋谱库'));
      await pumpUntil(
        t,
        () => find.widgetWithText(ListTile, '容量完整棋谱').evaluate().isNotEmpty,
      );
      await tap(t, find.widgetWithText(ListTile, '容量完整棋谱'));
      await t.pumpAndSettle();
      session = t.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session;
      expect(session.tree.nodeCount, GameTree.maxNodes);
      expect(session.tree.cursorId, tree.cursorId);
      expect(session.tree.current.comment, '容量评注');
      expect(session.metadata.tags['Event'], '容量自制赛事');
      expect(session.dirty, isFalse);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'candidate capacity message is specific and an existing branch remains selectable',
    (t) async {
      desktop(t);
      final fake = FakeEngine();
      await t.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await t.pumpAndSettle();
      final engine = t
          .widget<AnalysisPanel>(find.byType(AnalysisPanel))
          .analysis;
      final full = capacityTree(), root = full.root;
      final missing = root.position.legalMoves.firstWhere(
        (m) => !root.children.any((id) => full.node(id).move == m),
      );
      final current = full.node(root.children.first),
          stored = full.node(root.children[1]);
      engine.session.replaceTree(full.goTo(current.id));
      await t.pumpAndSettle();
      final source = engine.session.tree;
      final job = engine.startCandidates(
        limits: ReviewLimits(depth: 2),
        maximum: 2,
      );
      await pumpUntil(t, () => fake.requests.length == 1);
      fake.emit(fake.requests.last.token, pv: missing.toString());
      await t.pump();
      fake.results.last.complete(missing);
      await pumpUntil(t, () => fake.requests.length == 2);
      fake.emit(fake.requests.last.token, pv: stored.move.toString());
      await t.pump();
      fake.results.last.complete(stored.move);
      await pumpUntil(
        t,
        () => engine.candidates?.phase == ReviewPhase.completed,
      );
      await job;
      await tap(t, find.byKey(ValueKey('trial-$missing')));
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(BoardSession.capacityNotice),
        ),
        findsOneWidget,
      );
      expect(engine.session.tree, same(source));
      expect(engine.candidates!.phase, ReviewPhase.completed);
      await tap(t, find.byKey(ValueKey('trial-${stored.move}')));
      expect(engine.session.tree.cursorId, stored.id);
      expect(engine.session.tree.nodeCount, GameTree.maxNodes);
      expect(engine.session.dirty, isFalse);
      expect(engine.error, isNull);
      expect(t.takeException(), isNull);
    },
  );
}
