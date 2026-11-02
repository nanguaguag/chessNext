import 'package:chess_next/app.dart';
import 'package:chess_next/application/analysis_history.dart';
import 'package:chess_next/application/pv_prefix_action.dart';
import 'package:chess_next/application/pv_preview.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/analysis/pv_history_dialog.dart';
import 'package:chess_next/features/analysis/pv_preview_dialog.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'old source previews stay independent and only apply after returning and reopening the source',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeEngine();
      await tester.pumpWidget(
        ChessNextApp(engineFactory: () => Future.value(fake)),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      fake.emit(fake.requests.last.token, pv: 'b2e2 b9c7');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      final engine = tester
              .widget<AnalysisPanel>(find.byType(AnalysisPanel))
              .analysis,
          session = tester
              .widget<XiangqiBoard>(find.byType(XiangqiBoard))
              .session;
      final old = engine.history.single, oldToken = fake.requests.last.token;
      session.playMove(Move.parse('h2e2'));
      await tester.pump(const Duration(milliseconds: 180));
      await pumpUntil(tester, () => fake.requests.last.token != oldToken);
      expect(engine.infos, isEmpty);
      fake.emit(fake.requests.last.token, pv: 'b9c7 b0c2', score: 30);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await tap(tester, find.text('停止分析'));
      Future<void> previewOld() async {
        await tap(tester, find.byKey(const ValueKey('pv-history-open')));
        await tester.tap(find.byKey(ValueKey('pv-history-preview-${old.id}')));
        await tester.pump();
        await pumpUntil(
          tester,
          () => find
              .byKey(const ValueKey('pv-preview-progress'))
              .evaluate()
              .isNotEmpty,
        );
      }

      await tap(tester, find.byKey(const ValueKey('pv-history-open')));
      expect(find.text('起始局面 · 红方行棋'), findsOneWidget);
      expect(find.text('第1步后：炮二平五 · 黑方行棋'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PvHistoryDialog),
          matching: find.textContaining('红分 -30'),
        ),
        findsOneWidget,
      );
      await tap(tester, find.text('关闭'));
      final tree = session.tree;
      await previewOld();
      final board = tester.widget<BoardSurface>(
        find.descendant(
          of: find.byType(PvPreviewDialog),
          matching: find.byType(BoardSurface),
        ),
      );
      expect(board.at(Square.parse('b2')), isNull);
      expect(session.position.at(Square.parse('b2'))?.type, PieceType.cannon);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('pv-apply-prefix')))
            .onPressed,
        isNull,
      );
      expect(session.tree, same(tree));
      await tap(tester, find.text('关闭预览'));
      await tap(tester, find.text('关闭'));
      session.first();
      await tester.pumpAndSettle();
      await previewOld();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('pv-apply-prefix')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('pv-apply-prefix')));
      await tester.pump();
      await pumpUntil(
        tester,
        () => find.byType(PvPreviewDialog).evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.byType(PvHistoryDialog), findsNothing);
      expect(session.moves, [Move.parse('b2e2')]);
      expect(session.tree.node('n1').move, Move.parse('h2e2'));
      expect(engine.history.length, 2);
    },
  );
  testWidgets(
    '200 percent archived source explanation keeps a readable mini board',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final history = AnalysisHistory();
      history.add(
        position: Position.initial().play(Move.parse('h2e2')),
        epoch: 1,
        nodeId: 'n1',
        revision: 1,
        positionRevision: 1,
        sourcePly: 1,
        sourceMoveLabel: '炮二平五',
        info: EngineInfo(
          token: 1,
          depth: 20,
          multiPv: 1,
          score: 30,
          isMate: false,
          pv: [Move.parse('b9c7'), Move.parse('b0c2')],
        ),
      );
      final entry = history.entries.single;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<PvPreviewExit>(
                context: context,
                builder: (_) => PvPreviewDialog(
                  entry: entry,
                  action: PvPrefixAction(
                    isCurrent: () => false,
                    perform: (_, _) async => PvApplyResult.stale,
                  ),
                  loader: (e) => Future.value(PvPreview.prepare(e)),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      expect(find.text('来源：第1步后：炮二平五'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('pv-apply-prefix')))
            .onPressed,
        isNull,
      );
      expect(
        tester.getSize(find.byType(BoardSurface)).height,
        greaterThanOrEqualTo(240),
      );
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('关闭预览'));
    },
  );
}
