import 'package:chess_next/app.dart';
import 'package:chess_next/application/analysis_history.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/analysis/pv_history_dialog.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'history snapshots stay readable as search continues and clearing does not restart it',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine();
      await tester.pumpWidget(
        ChessNextApp(engineFactory: () => Future.value(fake)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'PV历史（0）'))
            .onPressed,
        isNull,
      );
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      final token = fake.requests.last.token;
      fake.emit(token, score: 10);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      fake.emit(token, score: 20);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await tap(tester, find.text('PV历史（2）'));
      final dialog = tester.widget<PvHistoryDialog>(
        find.byType(PvHistoryDialog),
      );
      expect(dialog.entries.map((e) => e.info.score), [20, 10]);
      fake.emit(token, score: 30);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PvHistoryDialog>(find.byType(PvHistoryDialog)).entries,
        same(dialog.entries),
      );
      expect(
        find.descendant(
          of: find.byType(PvHistoryDialog),
          matching: find.textContaining('红分 +30'),
        ),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PvHistoryDialog), findsNothing);
      final engine = tester
              .widget<AnalysisPanel>(find.byType(AnalysisPanel))
              .analysis,
          session = tester
              .widget<XiangqiBoard>(find.byType(XiangqiBoard))
              .session;
      final tree = session.tree,
          requests = fake.requests.length,
          stops = fake.stops;
      await tap(tester, find.byTooltip('清空本局面PV历史'));
      expect(engine.history, isEmpty);
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      fake.emit(token, score: 40);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await tap(tester, find.text('停止分析'));
      expect(find.text('PV历史（1）'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      await tap(tester, find.byKey(const ValueKey('square-e2')));
      expect(find.text('PV历史（0）'), findsOneWidget);
    },
  );
  testWidgets(
    'frozen source black scores and bounds stay consistent even when current board flips',
    (tester) async {
      desktop(tester);
      final history = AnalysisHistory();
      history.add(
        position: Position.initial().play(Move.parse('h2e2')),
        epoch: 1,
        nodeId: 'n1',
        revision: 1,
        positionRevision: 1,
        info: EngineInfo(
          token: 1,
          depth: 12,
          multiPv: 2,
          score: 56,
          isMate: false,
          bound: 'lower',
          pv: [Move.parse('b9c7')],
          wdl: WdlEstimate(wins: 300, draws: 600, losses: 100),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    PvHistoryDialog(entries: history.entries, side: Side.red),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      expect(find.text('变化 2 · 深度 12 · 红分 ≤ -56'), findsOneWidget);
      expect(find.textContaining('本机WDL'), findsNothing);
      expect(find.text('b9c7'), findsOneWidget);
    },
  );
  testWidgets(
    'long history is virtualized and scrollable at narrow 200 percent text scale',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final history = AnalysisHistory();
      for (var i = 0; i < 80; i++) {
        history.add(
          position: Position.initial(),
          epoch: 1,
          nodeId: 'n0',
          revision: 0,
          positionRevision: 0,
          info: EngineInfo(
            token: 1,
            depth: 8,
            multiPv: 1,
            score: i,
            isMate: false,
            pv: List.filled(140, Move.parse('h2e2')),
          ),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    PvHistoryDialog(entries: history.entries, side: Side.red),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      expect(
        find.byKey(ValueKey('pv-history-${history.entries.last.id}')),
        findsNothing,
      );
      expect(find.textContaining('原PV为140步'), findsWidgets);
      final scrollable = find
          .descendant(
            of: find.byType(PvHistoryDialog),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('pv-history-${history.entries.last.id}')),
        1500,
        scrollable: scrollable,
        maxScrolls: 160,
      );
      expect(find.text('变化 1 · 深度 8 · 红分 +16'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PvHistoryDialog), findsNothing);
    },
  );
}
