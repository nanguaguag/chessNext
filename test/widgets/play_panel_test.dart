import 'package:chess_next/app.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/chess_next.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

void main() {
  testWidgets(
    'AI side toggle responds and the play undo button returns two plies',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeEngine();
      await tester.pumpWidget(
        ChessNextApp(engineFactory: () => Future.value(fake)),
      );
      await tester.ensureVisible(find.text('引擎执黑'));
      await tester.tap(find.text('引擎执黑'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('square-h2')));
      await tester.tap(find.byKey(const ValueKey('square-e2')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(fake.requests, isNotEmpty);
      fake.results.last.complete(Move.parse('b9c7'));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      expect(session.moves.length, 2);
      await tester.ensureVisible(find.text('悔棋'));
      await tester.tap(find.text('悔棋'));
      await tester.pumpAndSettle();
      expect(session.moves, isEmpty);
    },
  );
}
