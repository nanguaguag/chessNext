import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/features/review/review_panel.dart';
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
        child: SizedBox(width: 326, child: ReviewPanel(engine: engine)),
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
    'multi mode validates count, exposes partial data and complete details',
    (tester) async {
      await tester.pumpWidget(shell());
      await tester.tap(find.text('分析整盘棋'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('最佳着法'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('多候选').last);
      await tester.pumpAndSettle();
      await text(tester, '每局面最多候选数', '1');
      await tester.tap(find.text('开始整谱分析'));
      await tester.pumpAndSettle();
      expect(find.text('请输入2至256的整数'), findsOneWidget);
      expect(fake.requests, isEmpty);
      await text(tester, '每局面最多候选数', '2');
      await text(tester, '每个候选用时（秒）', '0');
      await text(tester, '每个候选深度', '3');
      await tester.tap(find.text('开始整谱分析'));
      await tester.pumpAndSettle();
      fake.emit(fake.requests.last.token, pv: 'h2e2', score: 20);
      fake.results.last.complete(Move.parse('h2e2'));
      await pumpUntil(tester, () => fake.requests.length == 2);
      expect(find.text('0/1 个局面'), findsOneWidget);
      await tester.ensureVisible(find.text('查看当前局面的部分候选'));
      await tester.tap(find.text('查看当前局面的部分候选'));
      await tester.pumpAndSettle();
      expect(find.text('部分候选（局面未完成）'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-detail-h2e2')), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      fake.emit(fake.requests.last.token, pv: 'b2e2', score: 999);
      fake.results.last.complete(Move.parse('b2e2'));
      await pumpUntil(
        tester,
        () => engine.review!.phase == ReviewPhase.completed,
      );
      expect(engine.review!.results['n0']!.redScore, 20);
      final details = find.byKey(const ValueKey('review-candidates-n0'));
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text('局面候选详情'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-detail-b2e2')), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancelled partial candidates remain readable at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(shell());
      var done = false;
      final job = engine
          .startReview(
            mode: ReviewMode.candidates,
            maximum: 2,
            limits: ReviewLimits(depth: 3),
          )
          .whenComplete(() => done = true);
      await pumpUntil(tester, () => fake.requests.length == 1);
      fake.emit(fake.requests.last.token, pv: 'h2e2');
      fake.results.last.complete(Move.parse('h2e2'));
      await pumpUntil(tester, () => fake.requests.length == 2);
      await engine.cancelReview();
      await pumpUntil(tester, () => done);
      await job;
      await tester.ensureVisible(find.text('查看当前局面的部分候选'));
      await tester.tap(find.text('查看当前局面的部分候选'));
      await tester.pumpAndSettle();
      expect(find.text('部分候选（局面未完成）'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
