import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/features/review/review_panel.dart';
import 'package:chess_next/features/review/review_options_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

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
  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  Future<void> text(WidgetTester tester, String label, String value) async {
    final target = field(label);
    await tester.ensureVisible(target);
    await tester.enterText(target, value);
    await tester.pumpAndSettle();
  }

  testWidgets('budget validation, queue results and click navigation', (
    tester,
  ) async {
    session.playMove(Move.parse('h2e2'));
    session.first();
    await tester.pumpWidget(shell());
    await tester.tap(find.text('分析整盘棋'));
    await tester.pumpAndSettle();
    await text(tester, '每局面用时（秒）', 'NaN');
    await tester.tap(find.text('开始整谱分析'));
    await tester.pumpAndSettle();
    expect(fake.requests, isEmpty);
    expect(find.text('请输入0或0.001至86400秒'), findsOneWidget);
    await text(tester, '每局面用时（秒）', '0');
    await text(tester, '每局面深度', '0');
    await tester.tap(find.text('开始整谱分析'));
    await tester.pumpAndSettle();
    expect(find.text('至少设置一项有限预算'), findsOneWidget);
    await text(tester, '每局面深度', '2');
    await tester.tap(find.text('开始整谱分析'));
    await tester.pumpAndSettle();
    expect(fake.requests.single.moves.length, 1);
    fake.emit(fake.requests.last.token, score: 30, pv: 'b9c7');
    fake.results.last.complete(Move.parse('b9c7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('1/2 个局面'), findsOneWidget);
    fake.results.last.complete(Move.parse('h2e2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('分析结束，1个局面未取得评分'), findsOneWidget);
    final row = find.byKey(const ValueKey('review-n1'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(session.tree.cursorId, 'n1');
    expect(engine.review!.results['n1']!.redScore, -30);
    session.annotate('后续编辑');
    await tester.pumpAndSettle();
    expect(find.text('棋谱已变化，本次结果已过期'), findsOneWidget);
    expect(tester.widget<ListTile>(row).onTap, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large text configuration cancels and cancels a running job', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(shell());
    await tester.tap(find.text('分析整盘棋'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(fake.requests, isEmpty);
    final job = engine.startReview(limits: ReviewLimits(depth: 3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('取消整谱分析'));
    await tester.tap(find.text('取消整谱分析'));
    await tester.pumpAndSettle();
    await job;
    expect(find.text('已取消，保留已完成的局面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reanalysis switch returns explicit force-recompute intent', (
    tester,
  ) async {
    ReviewConfiguration? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                choice = await showDialog<ReviewConfiguration>(
                  context: context,
                  builder: (_) =>
                      const ReviewOptionsDialog(threads: 1, hashMb: 16),
                );
              },
              child: const Text('配置'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('配置'));
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, '跳过已分析的局面');
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始整谱分析'));
    await tester.pumpAndSettle();
    expect(choice!.skipExisting, isFalse);
  });
}
