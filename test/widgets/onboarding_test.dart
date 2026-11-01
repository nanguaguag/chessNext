import 'dart:async';
import 'package:chess_next/features/help/offline_help_dialog.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/help/onboarding_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

class FailingGuideRepository extends MemoryPreferencesRepository {
  bool failRead = false, failWrite = false;
  Completer<void>? readGate;
  int writes = 0;
  @override
  Future<LoadedPreferences?> load() async {
    await readGate?.future;
    if (failRead) throw StateError('broken');
    return super.load();
  }

  @override
  Future<void> save(AppPreferences next) async {
    writes++;
    if (failWrite) throw StateError('full');
    await super.save(next);
  }
}

void main() {
  Future<void> manual(WidgetTester tester) async {
    await tester.tap(find.byTooltip('帮助与按钮说明'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新手引导'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'automatic first guide navigates all steps, persists completion and manual replay stays read-only',
    (tester) async {
      final repository = MemoryPreferencesRepository();
      var factories = 0;
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        showFirstRunGuide: true,
        preferencesRepository: repository,
        engineFactory: () async {
          factories++;
          return FakeEngine();
        },
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingDialog), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(repository.value, isNull);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '上一步'))
            .onPressed,
        isNull,
      );
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree;
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);
      await tester.tap(find.text('上一步'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 4'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('下一步'));
        await tester.pumpAndSettle();
      }
      expect(find.text('4 / 4'), findsOneWidget);
      await tester.tap(find.text('开始使用'));
      await tester.pumpAndSettle();
      expect(repository.value!.guideVersion, 1);
      expect(session.tree, same(tree));
      expect(factories, 0);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingDialog), findsNothing);
      final fresh = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      fresh.playMove(Move.parse('h2e2'));
      final edited = fresh.tree;
      await tester.pumpAndSettle();
      await manual(tester);
      expect(find.text('1 / 4'), findsOneWidget);
      await tester.tap(find.text('跳过引导'));
      await tester.pumpAndSettle();
      expect(fresh.tree, same(edited));
      expect(fresh.dirty, isTrue);
      expect(factories, 0);
      await tester.tap(find.byTooltip('应用设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
      await tester.pumpAndSettle();
      expect(
        repository.value!.guideVersion,
        1,
      ); // Saving ordinary settings must preserve acknowledgment.
    },
  );
  testWidgets(
    'Escape interruption is not persisted while skip is; 200 percent is scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repository = MemoryPreferencesRepository();
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        showFirstRunGuide: true,
        preferencesRepository: repository,
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(repository.value, isNull);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('跳过引导'));
      await tester.pumpAndSettle();
      expect(repository.value!.guideVersion, 1);
    },
  );
  testWidgets(
    'write failure offers retry and read failure suppresses automatic overwrite',
    (tester) async {
      final repository = FailingGuideRepository()..failWrite = true;
      await tester.pumpWidget(
        ChessNextApp(
          key: UniqueKey(),
          showFirstRunGuide: true,
          preferencesRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('跳过引导'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('设置保存失败'),
        ),
        findsOneWidget,
      );
      repository.failWrite = false;
      await tester.tap(find.widgetWithText(TextButton, '重试'));
      await pumpUntil(tester, () => repository.value?.guideVersion == 1);
      final damaged = FailingGuideRepository()..failRead = true;
      await tester.pumpWidget(
        ChessNextApp(
          key: UniqueKey(),
          showFirstRunGuide: true,
          preferencesRepository: damaged,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingDialog), findsNothing);
      await manual(tester);
      await tester.tap(find.text('跳过引导'));
      await tester.pumpAndSettle();
      expect(damaged.writes, 0);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('原文件已保留'),
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('late preferences cannot cover an already open user dialog', (
    tester,
  ) async {
    final repository = FailingGuideRepository()..readGate = Completer<void>();
    await tester.pumpWidget(
      ChessNextApp(showFirstRunGuide: true, preferencesRepository: repository),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('帮助与按钮说明'));
    await tester.pump(const Duration(milliseconds: 400));
    repository.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(OfflineHelpDialog), findsOneWidget);
    expect(find.byType(OnboardingDialog), findsNothing);
    await tester.tap(find.text('新手引导'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDialog), findsOneWidget);
    await tester.tap(find.text('跳过引导'));
    await tester.pumpAndSettle();
    expect(repository.value!.guideVersion, 1);
  });
}
