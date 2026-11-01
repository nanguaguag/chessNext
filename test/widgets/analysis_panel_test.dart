import 'package:chess_next/app.dart';
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
}
