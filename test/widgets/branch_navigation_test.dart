import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/branch_tree.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  Future<void> tap(
    WidgetTester tester,
    String tooltip, {
    bool thinking = false,
  }) async {
    final target = find.byTooltip(tooltip);
    await tester.ensureVisible(target);
    if (thinking) {
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
    await tester.tap(target);
    if (thinking) {
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'strict branch jumps preserve selection and absolute endpoints at large text',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(nestedBranches().goTo('n8'));
      final revision = session.revision;
      await tester.pumpAndSettle();
      for (final expected in ['n4', 'n2', 'n0']) {
        await tap(tester, '上一分支点或开始');
        expect(session.tree.cursorId, expected);
      }
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.keyboard_double_arrow_left),
            )
            .onPressed,
        isNull,
      );
      for (final expected in ['n2', 'n4', 'n8']) {
        await tap(tester, '下一分支点或末尾');
        expect(session.tree.cursorId, expected);
      }
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(
                IconButton,
                Icons.keyboard_double_arrow_right,
              ),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, '回到开始');
      expect(session.tree.cursorId, 'n0');
      await tap(tester, '当前线路末尾');
      expect(session.tree.cursorId, 'n8');
      expect(session.revision, revision);
      expect(session.dirty, isFalse);
      expect(session.tree.nodeCount, 11);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'branch jump pauses thinking AI and discards the bestmove returned by stop',
    (tester) async {
      final fake = FakeEngine()..stopMove = Move.parse('g3g4');
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await tester.pumpAndSettle();
      final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
      final session = engine.session;
      session.replaceTree(nestedBranches().goTo('n4'));
      await tester.pumpAndSettle();
      final revision = session.revision;
      await engine.setAiSide(Side.red, true);
      await tester.pump(const Duration(milliseconds: 100));
      final oldToken = fake.requests.single.token;
      await tap(tester, '上一分支点或开始', thinking: true);
      await pumpUntil(tester, () => session.tree.cursorId == 'n2');
      fake.emit(oldToken, pv: 'g3g4');
      await tester.pumpAndSettle();
      expect(engine.playing, isFalse);
      expect(session.inputLocked, isFalse);
      expect(session.tree.cursorId, 'n2');
      expect(session.revision, revision);
      expect(session.tree.nodeCount, 11);
      expect(session.dirty, isFalse);
    },
  );
  testWidgets(
    'a stale branch action cannot navigate a new document with reused IDs',
    (tester) async {
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(nestedBranches().goTo('n4'));
      await tester.pumpAndSettle();
      final callback = tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.keyboard_double_arrow_left),
          )
          .onPressed!;
      session.newGame();
      for (final step in ['b2e2', 'h9g7', 'h0g2']) {
        session.playMove(Move.parse(step));
      }
      callback();
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n3');
      expect(session.tree.current.move, Move.parse('h0g2'));
    },
  );
}
