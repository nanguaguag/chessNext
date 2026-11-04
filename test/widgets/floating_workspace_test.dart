import 'package:chess_next/app.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'floating workspace shows board tools and exits to analysis layout',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChessNextApp(preferencesRepository: MemoryPreferencesRepository()),
      );
      await tester.pumpAndSettle();
      expect(find.text('本地棋盘'), findsOneWidget);
      expect(find.byTooltip('显示模式'), findsOneWidget);

      await tester.tap(find.byTooltip('显示模式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('悬浮窗 · 棋盘与状态行'));
      await tester.pumpAndSettle();

      expect(find.text('本地棋盘'), findsNothing);
      expect(find.text('引擎未开启'), findsOneWidget);
      expect(find.byTooltip('应用设置'), findsOneWidget);
      expect(find.byTooltip('更多'), findsOneWidget);
      expect(find.text('退出悬浮窗模式'), findsNothing);

      await tester.tap(find.byTooltip('更多'));
      await tester.pumpAndSettle();
      expect(find.text('退出悬浮窗模式'), findsOneWidget);
      await tester.tap(find.text('退出悬浮窗模式'));
      await tester.pumpAndSettle();

      expect(find.text('本地棋盘'), findsOneWidget);
      expect(find.byTooltip('显示模式'), findsOneWidget);
    },
  );
}
