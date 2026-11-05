import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/settings/app_text_scaling.dart';
import 'package:chess_next/features/settings/text_size_dialog.dart';
import 'package:chess_next/l10n/app_localizations.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingSizeStore extends MemoryPreferencesRepository {
  bool fail = true;
  @override
  Future<void> save(AppPreferences next) async {
    if (fail) throw StateError('disk full');
    await super.save(next);
  }
}

class NonlinearScaler extends TextScaler {
  const NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize * (fontSize < 20 ? 1.8 : 1.2);
  @override
  double get textScaleFactor => 1.8;
}

void main() {
  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('界面字号'));
  }

  double font(WidgetTester tester) => MediaQuery.textScalerOf(
    tester.element(find.byType(XiangqiBoard)),
  ).scale(20);

  testWidgets(
    'text size dialog uses the selected localization for labels and semantics',
    (tester) async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      await preferences.initialize();
      addTearDown(preferences.dispose);
      addTearDown(engine.dispose);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => TextSizeDialog(preferences: preferences),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Interface text size'), findsOneWidget);
      expect(find.text('Follow system text size'), findsOneWidget);
      expect(find.text('Standard 100%'), findsOneWidget);
      expect(
        find.text('Red to move · Local records and analysis'),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('text-size-slider')),
      );
      expect(slider.semanticFormatterCallback!(1), 'Large 115%');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'live slider exits system, keyboard selects extra large, system toggle resets manual',
    (tester) async {
      desktop(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryPreferencesRepository();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree;
      expect(font(tester), 40);
      await open(tester);
      final slider = find.byKey(const ValueKey('text-size-slider'));
      await tap(tester, slider);
      expect(store.value!.textSize, TextSizePreference.large);
      expect(font(tester), closeTo(23, .001));
      expect(
        tester
            .widget<SwitchListTile>(
              find.descendant(
                of: find.byType(TextSizeDialog),
                matching: find.byType(SwitchListTile),
              ),
            )
            .value,
        isFalse,
      );
      // Touch taps need not acquire keyboard focus. Reach the slider through
      // the same bounded Tab traversal used by a keyboard-only user.
      bool sliderFocused() =>
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<Slider>()
              ?.key ==
          const ValueKey('text-size-slider');
      for (var i = 0; i < 10 && !sliderFocused(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(sliderFocused(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(store.value!.textSize, TextSizePreference.extraLarge);
      expect(font(tester), 26);
      await tap(tester, find.text('跟随系统字号'));
      expect(font(tester), 40);
      expect(store.value!.textSize, TextSizePreference.system);
      await tap(tester, find.text('跟随系统字号'));
      expect(font(tester), 20);
      expect(store.value!.textSize, TextSizePreference.standard);
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual selection survives other settings apply and a new App instance',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(guideVersion: 99);
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      await open(tester);
      await tap(tester, find.byKey(const ValueKey('text-size-slider')));
      expect(font(tester), closeTo(23, .001));
      await tap(tester, find.text('关闭'));
      await tap(tester, find.widgetWithText(FilledButton, '应用设置'));
      expect(store.value!.textSize, TextSizePreference.large);
      expect(store.value!.guideVersion, 99);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      expect(font(tester), closeTo(23, .001));
      await open(tester);
      expect(find.text('当前字号：大115%'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TextSizeDialog), findsNothing);
      expect(find.text('应用设置'), findsWidgets);
    },
  );

  testWidgets('OS changes update system scaler while manual mode stays fixed', (
    tester,
  ) async {
    desktop(tester);
    final store = MemoryPreferencesRepository()
      ..value = AppPreferences(textSize: TextSizePreference.extraLarge);
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    expect(font(tester), 26);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(font(tester), 26);
    await open(tester);
    expect(find.text('系统字号预览：180%'), findsOneWidget);
    await tap(tester, find.text('跟随系统字号'));
    expect(font(tester), 36);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(font(tester), 40);
  });

  testWidgets(
    'failed persistence keeps active size and retry persists the same choice',
    (tester) async {
      desktop(tester);
      final store = FailingSizeStore();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await open(tester);
      await tap(tester, find.byKey(const ValueKey('text-size-slider')));
      expect(font(tester), closeTo(23, .001));
      expect(find.text('设置保存失败，当前设置仍生效，请重试').last, findsOneWidget);
      expect(store.value, isNull);
      store.fail = false;
      await tap(tester, find.text('重试'));
      expect(store.value!.textSize, TextSizePreference.large);
      expect(find.text('设置保存失败，当前设置仍生效，请重试'), findsNothing);
    },
  );

  testWidgets(
    'system nonlinear scaler is preserved by identity and manual factors do not multiply it',
    (tester) async {
      const os = NonlinearScaler();
      for (final mode in TextSizePreference.values) {
        late TextScaler actual, source;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: os),
            child: AppTextScaling(
              preference: mode,
              child: Builder(
                builder: (context) {
                  actual = MediaQuery.textScalerOf(context);
                  source = AppTextScaling.systemOf(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        expect(source, same(os));
        if (mode == TextSizePreference.system) {
          expect(actual, same(os));
          expect(actual.scale(12), closeTo(21.6, .001));
          expect(actual.scale(24), closeTo(28.8, .001));
        } else {
          expect(actual.scale(12), closeTo(12 * mode.manualScale!, .001));
          expect(actual.scale(24), closeTo(24 * mode.manualScale!, .001));
        }
      }
    },
  );

  testWidgets(
    'narrow system 200 percent dialog scrolls and exposes slider semantics',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const ChessNextApp());
        await tester.pumpAndSettle();
        await open(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('text-size-slider')),
        );
        expect(find.bySemanticsLabel(RegExp('界面字号')), findsWidgets);
        await tap(tester, find.byKey(const ValueKey('text-size-slider')));
        await tap(tester, find.text('跟随系统字号'));
        expect(font(tester), 40);
        await tap(tester, find.text('关闭'));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
