import 'package:chess_next/app.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

void main() {
  testWidgets('analysis panel starts, normalizes the score on flip and stops', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = FakeEngine();
    await tester.pumpWidget(ChessNextApp(engineFactory: () async => engine));
    await tester.ensureVisible(find.text('开始分析'));
    await tester.tap(find.text('开始分析'));
    await tester.pump();
    engine.emit(engine.requests.last.token);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.textContaining('红分 +10'), findsOneWidget);
    expect(
      tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .recommendation
          .toString(),
      'h2e2',
    );
    await tester.ensureVisible(find.text('翻转'));
    await tester.tap(find.text('翻转'));
    await tester.pump();
    expect(find.textContaining('黑分 -10'), findsOneWidget);
    await tester.ensureVisible(find.text('停止分析'));
    await tester.tap(find.text('停止分析'));
    await tester.pump();
    expect(find.text('分析已停止'), findsOneWidget);
    expect(engine.stops, greaterThan(0));
  });
  testWidgets(
    'native forecast distinguishes wins, draws and expected score on flip',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = FakeEngine();
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => engine));
      await tester.ensureVisible(find.text('开始分析'));
      await tester.tap(find.text('开始分析'));
      await tester.pump();
      expect(engine.requests.last.preferWdl, isTrue);
      final estimate = WdlEstimate(wins: 274, draws: 724, losses: 2);
      engine.emit(engine.requests.last.token, score: 72, wdl: estimate);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.textContaining('红方模型估计：胜 27.4%'), findsOneWidget);
      expect(find.textContaining('预期得分 63.6%'), findsOneWidget);
      await tester.ensureVisible(find.text('翻转'));
      await tester.tap(find.text('翻转'));
      await tester.pumpAndSettle();
      expect(find.textContaining('黑方模型估计：胜 0.2%'), findsOneWidget);
      expect(find.textContaining('预期得分 36.4%'), findsOneWidget);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      engine.emit(engine.requests.last.token, bound: 'lower', wdl: estimate);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.textContaining('模型估计：'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
