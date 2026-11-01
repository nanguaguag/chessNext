import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/application/review_report.dart';
import 'package:chess_next/features/review/review_panel.dart';
import 'package:chess_next/features/review/review_report_dialog.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  late BoardSession session;
  late FakeEngine fake;
  late EngineSessionController engine;
  setUp(() {
    session = BoardSession()
      ..playMove(Move.parse('h2e2'))
      ..playMove(Move.parse('b9c7'));
    fake = FakeEngine();
    engine = EngineSessionController(session, () async => fake);
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Future<void> completeReview(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ReviewPanel(engine: engine)),
        ),
      ),
    );
    final job = engine.startReview(
      limits: ReviewLimits(depth: 4, moveTimeMs: null),
    );
    await pumpUntil(tester, () => fake.requests.length == 1);
    final values = [
      (900, 100, 0, 'b0c2'),
      (300, 400, 300, 'h9g7'),
      (800, 200, 0, 'b2e2'),
    ];
    for (var i = 0; i < values.length; i++) {
      final (w, d, l, pv) = values[i];
      fake.emit(
        fake.requests.last.token,
        pv: pv,
        wdl: WdlEstimate(wins: w, draws: d, losses: l),
      );
      fake.results.last.complete(Move.parse(pv));
      await pumpUntil(
        tester,
        () => i == 2
            ? engine.review!.phase == ReviewPhase.completed
            : fake.requests.length > i + 1,
      );
    }
    await job;
    final entry = find.text('查看着法评级');
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  testWidgets('report filters and stable-node navigation do not edit tree', (
    tester,
  ) async {
    await completeReview(tester);
    final revision = session.revision;
    expect(find.text('模型着法评级'), findsOneWidget);
    expect(find.byKey(const ValueKey('assessment-n1')), findsOneWidget);
    expect(find.byKey(const ValueKey('assessment-n2')), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '红方'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assessment-n2')), findsNothing);
    final row = find.byKey(const ValueKey('assessment-n1'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('模型着法评级'), findsNothing);
    expect(session.tree.cursorId, 'n1');
    expect(session.revision, revision);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'new document reusing node ID cannot receive stale report navigation',
    (tester) async {
      await completeReview(tester);
      session.newGame();
      session.playMove(Move.parse('b2e2'));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('assessment-n1'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('棋谱已变化，本次未跳转。'), findsOneWidget);
      expect(session.tree.current.move, Move.parse('b2e2'));
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(OutlinedButton, '查看着法评级');
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    },
  );
  testWidgets(
    'partial missing report at 200 percent has no fake perfect value',
    (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final report = ReviewReport.fromRun(
        ReviewRun(
          epoch: 0,
          revision: 0,
          tree: session.tree,
          scope: ReviewScope.line,
          limits: ReviewLimits(depth: 4),
          nodeIds: ['n2', 'n1', 'n0'],
          phase: ReviewPhase.cancelled,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ReviewReportDialog(
                    report: report,
                    onNavigate: (_) async => false,
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.textContaining('平均预期损失 暂无数据'), findsNWidgets(2));
      final toggle = find.widgetWithText(SwitchListTile, '只看问题着法');
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('assessment-n1')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
    },
  );
}
