import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

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
          engineFactory: () async => FakeEngine(),
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
      await tester.tap(find.byKey(const ValueKey('display-tone')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('枫木').last);
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
      await tester.enterText(find.byKey(const ValueKey('ai-walk-time')), '2.5');
      await tester.enterText(find.byKey(const ValueKey('ai-walk-time')), '0');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '不限时最大深度'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '不限时最大深度'),
        '42',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('book-service-url')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('book-service-url')),
        'http://localhost:8080',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('opening-book-mode')),
      );
      await tester.tap(find.byKey(const ValueKey('opening-book-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('分差内随机').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(SwitchListTile, '启用残局云库'));
      await tester.tap(find.widgetWithText(SwitchListTile, '启用残局云库'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, '离开开局云库步数'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '离开开局云库步数'),
        '24',
      );
      await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
      await tester.pumpAndSettle();
      expect(repository.value!.theme, ThemePreference.dark);
      expect(repository.value!.displayTone, DisplayTone.maple);
      expect(repository.value!.threads, 2);
      expect(repository.value!.aiWalkTimeMs, 0);
      expect(repository.value!.aiWalkMaxDepth, 42);
      expect(repository.value!.bookServiceBaseUrl, 'http://localhost:8080');
      expect(
        repository.value!.openingBookMode,
        OpeningBookMode.randomWithinGap,
      );
      expect(repository.value!.endgameBookEnabled, isFalse);
      expect(repository.value!.leaveBookMoves, 24);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
        ThemeData(
          colorSchemeSeed: Color(DisplayTone.maple.seedColor),
          brightness: Brightness.light,
        ).colorScheme.primary,
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
      expect(repository.value!.displayTone, DisplayTone.maple);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('automatic hash mode follows thread count and persists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryPreferencesRepository();
    await tester.pumpWidget(
      ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: repository,
        engineFactory: () async => FakeEngine(),
        deviceThreads: 4,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按线程自动分配内存'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '分析线程'), '2');
    await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
    await tester.pumpAndSettle();
    expect(repository.value!.autoHash, isTrue);
    expect(repository.value!.hashMb, 128);
    await tester.ensureVisible(find.text('开始分析'));
    await tester.tap(find.text('开始分析'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('引擎参数'));
    await tester.tap(find.byTooltip('引擎参数'));
    await tester.pumpAndSettle();
    expect(find.text('本地引擎参数'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '计算线程'), '2');
    await tester.enterText(
      find.widgetWithText(TextFormField, '置换表内存（MB）'),
      '96',
    );
    await tester.tap(find.widgetWithText(FilledButton, '应用'));
    await tester.pumpAndSettle();
    expect(repository.value!.autoHash, isFalse);
    expect(repository.value!.hashMb, 96);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
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
