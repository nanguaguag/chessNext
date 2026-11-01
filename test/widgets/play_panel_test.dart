import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:flutter/foundation.dart' as foundation;
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
  testWidgets(
    'mobile inactive state cancels AI without applying a late result',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final engine = FakeEngine();
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => engine));
      await tester.ensureVisible(find.text('引擎执黑'));
      await tester.tap(find.text('引擎执黑'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('square-h2')));
      await tester.tap(find.byKey(const ValueKey('square-e2')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(engine.requests, isNotEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('分析已停止'), findsOneWidget);
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      expect(session.moves.length, 1);
      expect(session.inputLocked, isFalse);
    },
  );
  testWidgets(
    'desktop focus loss keeps analysis running, while hiding cancels it',
    (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = FakeEngine();
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => engine));
      await tester.ensureVisible(find.text('开始分析'));
      await tester.tap(find.text('开始分析'));
      await tester.pumpAndSettle();
      final requests = engine.requests.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('停止分析'), findsOneWidget);
      expect(engine.requests.length, requests);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      expect(
        tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis
            .enabled,
        isFalse,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('分析已停止'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant({foundation.TargetPlatform.macOS}),
  );
}
