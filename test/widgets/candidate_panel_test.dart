import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/features/review/candidate_panel.dart';
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
    session = BoardSession();
    session.playMove(Move.parse('h2e2'));
    session.playMove(Move.parse('b9c7'));
    fake = FakeEngine();
    engine = EngineSessionController(session, () async => fake);
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Widget shell() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(width: 326, child: CandidatePanel(engine: engine)),
      ),
    ),
  );
  Future<void> text(WidgetTester tester, String label, String value) async {
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'validates candidate budgets and trials a black sibling from its parent',
    (tester) async {
      await tester.pumpWidget(shell());
      await tester.tap(find.text('分析替代候选'));
      await tester.pumpAndSettle();
      await text(tester, '每个候选用时（秒）', 'NaN');
      await text(tester, '最多候选数（含首选）', '1');
      await tester.tap(find.text('开始候选分析'));
      await tester.pumpAndSettle();
      expect(fake.requests, isEmpty);
      expect(find.text('请输入2至256的整数'), findsOneWidget);
      await text(tester, '每个候选用时（秒）', '0');
      await text(tester, '每个候选深度', '0');
      await text(tester, '最多候选数（含首选）', '2');
      await tester.tap(find.text('开始候选分析'));
      await tester.pumpAndSettle();
      expect(find.text('至少设置一项有限预算'), findsOneWidget);
      await text(tester, '每个候选深度', '3');
      await tester.tap(find.text('开始候选分析'));
      await tester.pumpAndSettle();
      fake.emit(fake.requests.last.token, pv: 'b9c7');
      fake.results.last.complete(Move.parse('b9c7'));
      await pumpUntil(tester, () => fake.requests.length == 2);
      fake.emit(fake.requests.last.token, pv: 'h9g7');
      fake.results.last.complete(Move.parse('h9g7'));
      await pumpUntil(
        tester,
        () => engine.candidates!.phase == ReviewPhase.completed,
      );
      expect(engine.candidates!.phase, ReviewPhase.completed);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('trial-b9c7')))
            .onPressed,
        isNull,
      );
      final trial = find.byKey(const ValueKey('trial-h9g7'));
      await tester.ensureVisible(trial);
      await tester.tap(trial);
      await tester.pumpAndSettle();
      expect(session.tree.current.move, Move.parse('h9g7'));
      expect(session.tree.node('n1').children, ['n2', 'n3']);
      expect(find.text('局面已变化，候选结果已过期'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('large text options cancel and a running job can be stopped', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(shell());
    await tester.tap(find.text('分析替代候选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    var completed = false;
    final job = engine
        .startCandidates(limits: ReviewLimits(depth: 3), maximum: 2)
        .whenComplete(() => completed = true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('停止候选分析'));
    await tester.tap(find.text('停止候选分析'));
    await tester.pumpAndSettle();
    await pumpUntil(tester, () => completed);
    await job;
    expect(find.text('已取消，保留已完成候选'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'navigating behind the options dialog cannot start on the new position',
    (tester) async {
      await tester.pumpWidget(shell());
      await tester.tap(find.text('分析替代候选'));
      await tester.pumpAndSettle();
      session.undo();
      await tester.tap(find.text('开始候选分析'));
      await tester.pumpAndSettle();
      expect(fake.requests, isEmpty);
      expect(find.text('局面已变化，请重新选择候选分析。'), findsOneWidget);
    },
  );
}
