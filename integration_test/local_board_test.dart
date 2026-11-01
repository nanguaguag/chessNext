import 'package:flutter/services.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/adapters/storage/file_preferences_repository.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/adapters/storage/file_draft_repository.dart';
import 'package:chess_next/features/drafts/draft_status_bar.dart';
import 'package:chess_next/features/editor/editor_page.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/adapters/engine/bundled_engine.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chess_next/adapters/storage/file_game_repository.dart';
import 'package:chess_next/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class LifecycleTrace extends WidgetsBindingObserver {
  final states = <AppLifecycleState>[];
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => states.add(state);
}

Future<void> enterNativeText(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
  final editable = finder.evaluate().single.widget is EditableText
      ? finder
      : find.descendant(of: finder, matching: find.byType(EditableText));
  expect(tester.widget<EditableText>(editable).controller.text, value);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // This native fixture controls framework visibility. Physical window focus
  // and minimization remain platform QA tasks; production has no override.
  final nativeStates = <String>[];
  void resumeFixture() {
    if (binding.lifecycleState == AppLifecycleState.paused) {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }
    if (binding.lifecycleState == AppLifecycleState.hidden) {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    }
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  SystemChannels.lifecycle.setMessageHandler((message) async {
    nativeStates.add(message ?? '<null>');
    resumeFixture();
    return null;
  });
  resumeFixture();
  tearDownAll(() {
    SystemChannels.lifecycle.setMessageHandler(null);
    debugPrint('Native lifecycle fixture observed: $nativeStates');
  });
  testWidgets('macOS local board supports a full interactive move cycle', (
    tester,
  ) async {
    await tester.pumpWidget(ChessNextApp(key: UniqueKey()));
    await tester.pumpAndSettle();
    expect(find.text('红方行棋'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    expect(find.text('黑方行棋'), findsOneWidget);
    expect(find.text('1. 炮二平五'), findsOneWidget);
    await tester.tap(find.text('翻转'));
    await tester.pumpAndSettle();
    expect(find.text('黑方行棋'), findsOneWidget);
    await tester.tap(find.text('悔棋'));
    await tester.pumpAndSettle();
    expect(find.text('红方行棋'), findsOneWidget);
    expect(find.text('1. 炮二平五'), findsNothing);
    // After flip h2/e2 are still addressed by board coordinates, not pixels.
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('1. 炮二平五'), findsOneWidget);
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '开始新局'));
    await tester.pumpAndSettle();
    expect(find.text('红方行棋'), findsOneWidget);
    expect(find.text('1. 炮二平五'), findsNothing);
    await tester.tap(find.byTooltip('切换明暗主题'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'macOS sandbox saves records and a fresh app instance reopens them',
    (tester) async {
      final documents = await getApplicationDocumentsDirectory();
      final temp = await documents.createTemp('.chessnext-integration-');
      try {
        await tester.pumpWidget(
          ChessNextApp(
            key: UniqueKey(),
            repository: FileGameRepository(() async => temp),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('square-h2')));
        await tester.tap(find.byKey(const ValueKey('square-e2')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('保存棋谱'));
        await tester.pumpAndSettle();
        await enterNativeText(
          tester,
          find.byKey(const ValueKey('record-name')),
          '原生磁盘恢复测试',
        );
        await tester.tap(find.widgetWithText(FilledButton, '保存'));
        for (
          var i = 0;
          i < 50 && find.text('已保存到本地 · 原生磁盘恢复测试').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('已保存到本地 · 原生磁盘恢复测试'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          ChessNextApp(
            key: UniqueKey(),
            repository: FileGameRepository(() async => temp),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('棋谱库'));
        for (
          var i = 0;
          i < 50 && find.text('原生磁盘恢复测试').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.text('原生磁盘恢复测试'));
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 && find.text('1. 炮二平五').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('1. 炮二平五'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await temp.delete(recursive: true);
      }
    },
  );
  testWidgets('bundled Pikafish analyzes offline, switches MultiPV and stops', (
    tester,
  ) async {
    final lifecycle = LifecycleTrace();
    WidgetsBinding.instance.addObserver(lifecycle);
    addTearDown(() => WidgetsBinding.instance.removeObserver(lifecycle));
    await tester.pumpWidget(
      ChessNextApp(key: UniqueKey(), engineFactory: openBundledEngine),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('开始分析'));
    await tester.tap(find.text('开始分析'));
    for (
      var i = 0;
      i < 100 && find.textContaining('红分').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('红分'), findsWidgets);
    expect(
      tester.widget<XiangqiBoard>(find.byType(XiangqiBoard)).recommendation,
      isNotNull,
    );
    await tester.ensureVisible(find.byTooltip('引擎参数'));
    await tester.tap(find.byTooltip('引擎参数'));
    await tester.pumpAndSettle();
    await enterNativeText(
      tester,
      find.widgetWithText(TextFormField, '同时分析变化数'),
      '2',
    );
    await tester.tap(find.widgetWithText(FilledButton, '应用'));
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 100 && find.byKey(const ValueKey('pv-2')).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final analysis = tester
        .widget<AnalysisPanel>(find.byType(AnalysisPanel))
        .analysis;
    expect(
      find.byKey(const ValueKey('pv-2')),
      findsOneWidget,
      reason:
          '${analysis.status}; ${analysis.error}; enabled=${analysis.enabled}; pv=${analysis.settings.multiPv}; lifecycle=${lifecycle.states}',
    );
    await tester.ensureVisible(find.text('停止分析'));
    await tester.tap(find.text('停止分析'));
    await tester.pumpAndSettle();
    expect(find.text('分析已停止'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets('bundled AI replies, changes its move and undoes both plies', (
    tester,
  ) async {
    final lifecycle = LifecycleTrace();
    WidgetsBinding.instance.addObserver(lifecycle);
    addTearDown(() => WidgetsBinding.instance.removeObserver(lifecycle));
    await tester.pumpWidget(
      ChessNextApp(key: UniqueKey(), engineFactory: openBundledEngine),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('引擎执黑'));
    await tester.tap(find.text('引擎执黑'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    final session = tester
        .widget<XiangqiBoard>(find.byType(XiangqiBoard))
        .session;
    for (var i = 0; i < 100 && session.moves.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(session.moves.length, 2);
    final old = session.moves.last;
    await tester.ensureVisible(find.text('变招'));
    await tester.tap(find.text('变招'));
    for (
      var i = 0;
      i < 100 && (session.moves.length < 2 || session.moves.last == old);
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final playState = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
    expect(
      session.moves.length,
      2,
      reason:
          '${playState.status}; ${playState.error}; playing=${playState.playing}; thinking=${playState.thinking}; lifecycle=${lifecycle.states}',
    );
    expect(session.moves.last, isNot(old));
    expect(session.tree.node('n1').children.length, 2);
    await tester.ensureVisible(find.text('悔棋'));
    await tester.tap(find.text('悔棋'));
    await tester.pumpAndSettle();
    expect(session.moves, isEmpty);
    await tester.ensureVisible(find.text('引擎执红'));
    await tester.tap(find.text('引擎执红'));
    await tester.pump();
    await tester.ensureVisible(find.text('停止对弈'));
    await tester.tap(find.text('停止对弈'));
    await tester.pumpAndSettle();
    final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
    expect(engine.aiSides, isEmpty);
    expect(session.inputLocked, isFalse);
  });
  testWidgets(
    'native editor rejects facing generals and applies a valid chosen turn',
    (tester) async {
      await tester.pumpWidget(ChessNextApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final before = session.tree.toJson();
      await tester.ensureVisible(find.text('编辑局面'));
      await tester.tap(find.text('编辑局面'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清空'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('square-d9')));
      await tester.tap(find.byKey(const ValueKey('square-e9')));
      await tester.pump();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsOneWidget);
      expect(session.tree.toJson(), before);
      await tester.tap(find.text('清空'));
      await tester.tap(find.text('黑先'));
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsNothing);
      expect(session.position.turn, Side.black);
      expect(session.position.validateForPlay().isValid, isTrue);
      expect(session.dirty, isTrue);
    },
  );
  testWidgets(
    'native text transfer rejects illegal moves and roundtrips a path',
    (tester) async {
      await tester.pumpWidget(ChessNextApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      await tester.ensureVisible(find.text('导入文字'));
      await tester.tap(find.text('导入文字'));
      await tester.pumpAndSettle();
      await enterNativeText(
        tester,
        find.byKey(const ValueKey('import-text')),
        'startpos moves a0a9',
      );
      await tester.pump();
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(find.textContaining('第1步不合法'), findsOneWidget);
      expect(session.hasMoves, isFalse);
      await tester.tap(find.byKey(const ValueKey('import-text')));
      await tester.pumpAndSettle();
      await enterNativeText(
        tester,
        find.byKey(const ValueKey('import-text')),
        '1. 炮二平五 馬２進３',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('import-text')))
            .controller!
            .text,
        '1. 炮二平五 馬２進３',
      );
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('import-text')), findsNothing);
      expect(session.moves.length, 2);
      await tester.ensureVisible(find.text('导出文字'));
      await tester.tap(find.text('导出文字'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FEN + 着法'));
      await tester.pump();
      final exported = tester
          .widget<SelectableText>(find.byKey(const ValueKey('export-text')))
          .data!;
      expect(
        TextRecord.parse(exported).current.position.toFen(),
        session.position.toFen(),
      );
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'native autosave restores a fresh working copy without modifying the saved library',
    (tester) async {
      final documents = await getApplicationDocumentsDirectory();
      final temp = await documents.createTemp('.chessnext-draft-integration-');
      try {
        final repository = FileDraftRepository(() async => temp);
        await tester.pumpWidget(
          ChessNextApp(
            key: UniqueKey(),
            draftRepository: repository,
            repository: FileGameRepository(() async => temp),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('square-h2')));
        await tester.tap(find.byKey(const ValueKey('square-e2')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(TextFormField, '当前局面注释'),
        );
        await enterNativeText(
          tester,
          find.widgetWithText(TextFormField, '当前局面注释'),
          '自动恢复验证',
        );
        await tester.pump(const Duration(milliseconds: 350));
        final controller = tester
            .widget<DraftStatusBar>(find.byType(DraftStatusBar))
            .drafts;
        await controller.flush();
        expect(controller.error, isNull);
        expect((await repository.load())!.tree.current.comment, '自动恢复验证');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          ChessNextApp(
            key: UniqueKey(),
            draftRepository: FileDraftRepository(() async => temp),
            repository: FileGameRepository(() async => temp),
          ),
        );
        for (var i = 0; i < 50 && find.text('恢复草稿').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.ensureVisible(find.text('恢复草稿'));
        await tester.tap(find.text('恢复草稿'));
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(session.moves.single.toString(), 'h2e2');
        expect(session.tree.current.comment, '自动恢复验证');
        expect(session.dirty, isTrue);
        expect(
          (await FileGameRepository(() async => temp).list()).games,
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await temp.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native settings survive a new app instance and restore resources without AI roles',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final temp = await support.createTemp('.chessnext-settings-integration-');
      try {
        final repository = FilePreferencesRepository(() async => temp);
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
        await enterNativeText(
          tester,
          find.widgetWithText(TextFormField, '分析线程'),
          '2',
        );
        await enterNativeText(
          tester,
          find.widgetWithText(TextFormField, '分析内存（MB）'),
          '64',
        );
        await enterNativeText(
          tester,
          find.widgetWithText(TextFormField, '多路变化数'),
          '3',
        );
        await enterNativeText(
          tester,
          find.widgetWithText(TextFormField, 'AI每步用时（秒）'),
          '3',
        );
        await tester.ensureVisible(find.widgetWithText(FilledButton, '应用设置'));
        await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
        for (
          var i = 0;
          i < 50 &&
              find.widgetWithText(FilledButton, '应用设置').evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await repository.load())!.value.theme, ThemePreference.dark);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          ChessNextApp(
            key: UniqueKey(),
            preferencesRepository: FilePreferencesRepository(() async => temp),
            deviceThreads: 4,
          ),
        );
        for (
          var i = 0;
          i < 50 &&
              tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode !=
                  ThemeMode.dark;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.dark,
        );
        final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
        expect(engine.settings.threads, 2);
        expect(engine.settings.hashMb, 64);
        expect(engine.settings.multiPv, 3);
        expect(engine.thinkTimeMs, 3000);
        expect(engine.aiSides, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await temp.delete(recursive: true);
      }
    },
  );
}
