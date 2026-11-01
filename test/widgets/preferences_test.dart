import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Material settings persist across instances without enabling automatic play',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryPreferencesRepository();
      await tester.pumpWidget(
        ChessNextApp(
          key: UniqueKey(),
          preferencesRepository: repository,
          deviceThreads: 4,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('应用设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<ThemePreference>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('深色').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '分析线程'), '2');
      await tester.enterText(
        find.widgetWithText(TextFormField, '分析内存（MB）'),
        '64',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '多路变化数'), '3');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'AI每步用时（秒）'),
        '3',
      );
      await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
      await tester.pumpAndSettle();
      expect(repository.value!.theme, ThemePreference.dark);
      expect(repository.value!.threads, 2);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(
          key: UniqueKey(),
          preferencesRepository: repository,
          deviceThreads: 4,
        ),
      );
      await tester.pumpAndSettle();
      final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
      expect(engine.settings.hashMb, 64);
      expect(engine.settings.multiPv, 3);
      expect(engine.thinkTimeMs, 3000);
      expect(engine.aiSides, isEmpty);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'settings remain scrollable and valid at 200 percent text on a narrow window',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('应用设置'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'AI每步用时（秒）'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'AI每步用时（秒）'),
        'NaN',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, '应用设置'));
      await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
      await tester.pumpAndSettle();
      expect(find.text('请输入0.05至600之间的秒数'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    },
  );
}
