import 'package:chess_next/application/review_report.dart';
import 'package:chess_next/features/board/move_grade_badge.dart';
import 'package:chess_next/features/settings/analysis_markers_dialog.dart';
import 'package:chess_next/application/pv_prefix_action.dart';
import 'package:chess_next/features/analysis/pv_preview_dialog.dart';
import 'package:chess_next/features/analysis/pv_history_dialog.dart';
import 'package:chess_next/features/board/last_move_markers.dart';
import 'package:chess_next/application/board_evaluation.dart';
import 'package:chess_next/features/analysis/evaluation_board.dart';
import '../test/support/branched_record.dart';
import 'package:chess_next/features/board/variation_arrows_painter.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:chess_next/features/board/board_file_coordinates.dart';
import 'dart:convert';
import 'package:chess_next/adapters/platform/macos_record_file_exporter.dart';
import 'package:chess_next/ports/record_file_exporter.dart';
import 'package:chess_next/adapters/platform/file_selector_record_picker.dart';
import 'package:file_selector/file_selector.dart';
import '../test/support/memory_clipboard.dart';
import 'package:chess_next/features/help/onboarding_dialog.dart';
import 'package:chess_next/adapters/storage/file_recent_reading_repository.dart';
import 'package:chess_next/features/library/recent_reading_dialog.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'dart:io';
import 'package:chess_next/features/review/candidate_panel.dart';
import 'package:chess_next/adapters/storage/file_review_cache_repository.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/ports/engine_gateway.dart';
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
    final beforeHelp = tester
        .widget<XiangqiBoard>(find.byType(XiangqiBoard))
        .session
        .tree;
    await tester.tap(find.byTooltip('帮助与按钮说明'));
    await tester.pumpAndSettle();
    await enterNativeText(
      tester,
      find.byKey(const ValueKey('help-search')),
      '最近阅读',
    );
    expect(find.text('保存、草稿与最近阅读'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session.tree,
      same(beforeHelp),
    );

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
    expect(find.text('1. 炮二平五'), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(const ValueKey('move-n0'))).selected,
      isTrue,
    );
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
    for (
      var i = 0;
      i < 100 && find.textContaining('模型估计：').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(analysis.infos.every((i) => i.wdl != null), isTrue);
    expect(find.textContaining('模型估计：'), findsWidgets);
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
      await tester.tap(find.byKey(const ValueKey('export-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FEN + 着法').last);
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
  testWidgets('bundled NNUE stops a combined search at the node budget', (
    _,
  ) async {
    final engine = await openBundledEngine();
    final identity = engine.identity!;
    expect(identity.release, 'Pikafish-2026-09-06');
    expect(identity.commit, '4c17cee11f888ae1d48a9494f2e2239f019f0a1f');
    expect(
      identity.sourceBinarySha256,
      '3a11f9034ef723bb4068e4cf88a79a12d99507474ba118fa916ec2cecd4f4abe',
    );
    expect(
      identity.networkSha256,
      '7d13d73569a9b571ba0eb20cf1596247bc2a42738967e61afef6482b231e900e',
    );
    expect(identity.target, contains('macos'));
    final infos = <EngineInfo>[];
    final subscription = engine.info.listen(infos.add);
    try {
      await engine.initialize();
      expect(engine.name, contains('Pikafish'));
      final root = Position.initial();
      final search = await engine.start(
        EngineRequest(
          token: 901,
          root: root,
          depth: 100,
          moveTimeMs: 10000,
          nodeLimit: 2000,
        ),
      );
      final move = await search.bestMove.timeout(const Duration(seconds: 10));
      expect(root.legalMoves, contains(move));
      await Future<void>.delayed(Duration.zero);
      expect(infos, isNotEmpty);
      expect(infos.last.depth, lessThan(100));
      expect(infos.last.nodes, lessThan(50000));
    } finally {
      await subscription.cancel();
      await engine.dispose();
    }
  });
  testWidgets(
    'native reading list navigates future moves and keeps the chosen branch',
    (tester) async {
      await tester.pumpWidget(ChessNextApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      Future<void> move(String from, String to) async {
        await tester.tap(find.byKey(ValueKey('square-$from')));
        await tester.tap(find.byKey(ValueKey('square-$to')));
        await tester.pumpAndSettle();
      }

      Future<void> read(String id) async {
        final row = find.byKey(ValueKey('move-$id'));
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pumpAndSettle();
      }

      await move('h2', 'e2');
      await move('b9', 'c7');
      await read('n0');
      expect(session.moves, isEmpty);
      expect(find.byKey(const ValueKey('move-n2')), findsOneWidget);
      await read('n2');
      expect(session.moves.length, 2);
      await read('n0');
      await move('b2', 'e2');
      await move('h9', 'g7');
      await read('n0');
      expect(find.byKey(const ValueKey('move-n3')), findsOneWidget);
      expect(find.byKey(const ValueKey('move-n1')), findsNothing);
      await tester.ensureVisible(find.byTooltip('下一着'));
      await tester.tap(find.byTooltip('下一着'));
      await tester.pumpAndSettle();
      expect(session.moves.single.toString(), 'b2e2');
      expect(
        tester.widget<ListTile>(find.byKey(const ValueKey('move-n3'))).selected,
        isTrue,
      );
      session.playMove(
        Move.parse('b9c7'),
      ); // n5, sibling of n4 after selected n3.
      final revision = session.revision;
      session.markSaved(revision);
      await tester.pumpAndSettle();
      Future<void> branch(String tooltip, String expected) async {
        final target = find.byTooltip(tooltip);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(session.tree.cursorId, expected);
      }

      await branch('上一分支点或开始', 'n3');
      await branch('上一分支点或开始', 'n0');
      await branch('下一分支点或末尾', 'n3');
      await branch('下一分支点或末尾', 'n5');
      expect(session.tree.currentLine.last.id, 'n5');
      expect(session.tree.nodeCount, 6);
      expect(session.revision, revision);
      expect(session.dirty, isFalse);
    },
  );
  testWidgets(
    'native current-move variants switch, promote and confirm deletion',
    (tester) async {
      await tester.pumpWidget(ChessNextApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      session.first();
      session.playMove(Move.parse('b2e2'));
      await tester.pumpAndSettle();
      Future<void> tapVisible(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapVisible(find.byKey(const ValueKey('sibling-n1')));
      expect(session.tree.cursorId, 'n1');
      expect(session.tree.currentLine.last.id, 'n2');
      await tapVisible(find.byKey(const ValueKey('sibling-actions-n3')));
      await tapVisible(find.text('提升为主线'));
      expect(session.tree.root.children.first, 'n3');
      expect(session.tree.cursorId, 'n1');
      await tapVisible(find.byKey(const ValueKey('sibling-actions-n1')));
      await tapVisible(find.text('删除变着'));
      await tapVisible(find.text('取消'));
      expect(session.tree.hasNode('n2'), isTrue);
      await tapVisible(find.byKey(const ValueKey('sibling-actions-n1')));
      await tapVisible(find.text('删除变着'));
      await tapVisible(find.text('删除'));
      expect(session.tree.hasNode('n1'), isFalse);
      expect(session.tree.hasNode('n2'), isFalse);
      expect(session.tree.cursorId, 'n0');
      expect(session.dirty, isTrue);
    },
  );
  testWidgets(
    'native bundled engine reviews branches and supports cancellation',
    (tester) async {
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), engineFactory: openBundledEngine),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      session.first();
      session.playMove(Move.parse('b2e2'));
      session.first();
      await tester.pumpAndSettle();
      final revision = session.revision;
      Future<void> tapVisible(Finder finder) async {
        await tester.ensureVisible(finder);
        if (engine.batching) {
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
        await tester.tap(finder);
        if (engine.batching) {
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
      }

      await tapVisible(find.text('分析整盘棋'));
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await enterNativeText(tester, field('每局面用时（秒）'), '0');
      await enterNativeText(tester, field('每局面深度'), '4');
      await tapVisible(find.text('包括所有变着'));
      await tapVisible(find.text('开始整谱分析'));
      for (
        var i = 0;
        i < 150 && engine.review?.phase != ReviewPhase.completed;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(engine.review!.phase, ReviewPhase.completed);
      expect(engine.review!.results.length, 4);
      expect(
        engine.review!.results.values.every((r) => r.info != null),
        isTrue,
      );
      expect(session.tree.cursorId, 'n0');
      expect(session.revision, revision);
      final cachedJob = engine.startReview(
        scope: ReviewScope.tree,
        limits: ReviewLimits(depth: 4, moveTimeMs: null),
      );
      for (
        var i = 0;
        i < 100 && engine.review?.phase != ReviewPhase.completed;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await cachedJob;
      await tester.pumpAndSettle();
      expect(engine.review!.cachedCount, 4);
      expect(
        engine.review!.results.values.every((r) => r.info!.token == 0),
        isTrue,
      );
      expect(find.text('复用 4 个局面'), findsOneWidget);
      await tapVisible(find.byKey(const ValueKey('review-n1')));
      expect(session.tree.cursorId, 'n1');
      await tapVisible(find.byKey(const ValueKey('review-chart')));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n2');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n1');
      final job = engine.startReview(
        limits: ReviewLimits(depth: 255, moveTimeMs: 100000),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tapVisible(find.text('取消整谱分析'));
      await job;
      expect(engine.review!.phase, ReviewPhase.cancelled);
      expect(engine.enabled, isFalse);
      expect(engine.aiSides, isEmpty);
      expect(session.tree.cursorId, 'n1');
    },
  );
  testWidgets(
    'native analysis cache survives new app, repository and engine instances',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final temp = await support.createTemp('.chessnext-analysis-integration-');
      try {
        Future<EngineSessionController> open(GameTree? tree) async {
          await tester.pumpWidget(
            ChessNextApp(
              key: UniqueKey(),
              engineFactory: openBundledEngine,
              reviewCache: FileReviewCacheRepository(() async => temp),
            ),
          );
          await tester.pumpAndSettle();
          final session = tester
              .widget<XiangqiBoard>(find.byType(XiangqiBoard))
              .session;
          if (tree != null) session.replaceTree(tree);
          return tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
        }

        var engine = await open(null);
        engine.session.playMove(Move.parse('h2e2'));
        engine.session.playMove(Move.parse('b9c7'));
        final tree = engine.session.tree;
        await engine.startReview(
          limits: ReviewLimits(depth: 4, moveTimeMs: null),
        );
        await tester.pumpAndSettle();
        expect(engine.review!.cachedCount, 0);
        expect(
          engine.review!.results.values.every((r) => r.info != null),
          isTrue,
        );
        final fingerprint = engine.engineIdentity!.cacheIdentity;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        engine = await open(tree);
        await engine.startReview(
          limits: ReviewLimits(depth: 4, moveTimeMs: null),
        );
        await tester.pumpAndSettle();
        expect(engine.engineIdentity!.cacheIdentity, fingerprint);
        expect(engine.review!.phase, ReviewPhase.completed);
        expect(engine.review!.cachedCount, 3);
        expect(
          engine.review!.results.values.every((r) => r.info!.token == 0),
          isTrue,
        );
        final files = await Directory(
          '${temp.path}/chessnext-analysis-cache',
        ).list().toList();
        final damaged = files.whereType<File>().first;
        await damaged.writeAsString('broken-cache');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        engine = await open(tree);
        await engine.startReview(
          limits: ReviewLimits(depth: 4, moveTimeMs: null),
        );
        await tester.pumpAndSettle();
        expect(engine.review!.phase, ReviewPhase.completed);
        expect(engine.review!.cacheNotice, '缓存读取失败，本次重新计算');
        expect(
          engine.review!.results.values.every((r) => r.info != null),
          isTrue,
        );
        expect(engine.session.tree.nodeCount, 3);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await temp.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native candidates analyze the parent and trial a sibling without losing the game',
    (tester) async {
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), engineFactory: openBundledEngine),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      await tester.pumpAndSettle();
      final engine = tester
          .widget<CandidatePanel>(find.byType(CandidatePanel))
          .engine;
      Future<void> tapVisible(Finder target) async {
        await tester.ensureVisible(target);
        if (engine.batching) {
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
        await tester.tap(target);
        if (engine.batching) {
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
      }

      await tapVisible(find.text('分析替代候选'));
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      for (final input in {
        '每个候选用时（秒）': '0',
        '每个候选深度': '4',
        '最多候选数（含首选）': '2',
      }.entries) {
        await tester.ensureVisible(field(input.key));
        await enterNativeText(tester, field(input.key), input.value);
      }
      await tapVisible(find.text('开始候选分析'));
      for (
        var i = 0;
        i < 150 && engine.candidates?.phase != ReviewPhase.completed;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final run = engine.candidates!;
      expect(run.phase, ReviewPhase.completed);
      expect(run.results.length, 2);
      expect(run.parentId, 'n1');
      expect(run.position.turn, Side.black);
      final alternative = run.results.firstWhere(
        (r) => r.move != session.tree.current.move,
      );
      await tapVisible(find.byKey(ValueKey('trial-${alternative.move}')));
      expect(session.tree.current.move, alternative.move);
      expect(session.position.turn, Side.red);
      expect(session.tree.node('n1').children.length, 2);
      expect(session.tree.hasNode('n2'), isTrue);
      await engine.startCandidates(
        limits: ReviewLimits(depth: 4, moveTimeMs: null),
        maximum: 2,
      );
      await tester.pumpAndSettle();
      expect(engine.candidates!.cachedCount, 2);
      expect(engine.candidates!.phase, ReviewPhase.completed);
    },
  );
  testWidgets(
    'native multi-candidate review configures branches, details and cache counts',
    (tester) async {
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), engineFactory: openBundledEngine),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      session.first();
      session.playMove(Move.parse('b2e2'));
      session.first();
      await tester.pumpAndSettle();
      Future<void> tapVisible(Finder target) async {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.ensureVisible(target);
        if (engine.batching) {
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
        await tester.tap(target);
        if (engine.batching) {
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
      }

      await tapVisible(find.text('分析整盘棋'));
      await tapVisible(find.text('最佳着法'));
      await tapVisible(find.text('多候选').last);
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      for (final item in {
        '每局面最多候选数': '2',
        '每个候选用时（秒）': '0',
        '每个候选深度': '4',
      }.entries) {
        await tester.ensureVisible(field(item.key));
        await enterNativeText(tester, field(item.key), item.value);
      }
      await tapVisible(find.text('包括所有变着'));
      await tapVisible(find.text('开始整谱分析'));
      for (
        var i = 0;
        i < 200 && engine.review?.phase != ReviewPhase.completed;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final run = engine.review!;
      expect(run.phase, ReviewPhase.completed);
      expect(run.mode, ReviewMode.candidates);
      expect(run.results.length, 4);
      expect(
        run.candidateResults.values.every(
          (c) => c.entries.length == 2 && c.complete,
        ),
        isTrue,
      );
      expect(session.tree.cursorId, 'n0');
      await tapVisible(find.byKey(const ValueKey('review-candidates-n1')));
      expect(find.text('局面候选详情'), findsOneWidget);
      for (final candidate in run.candidateResults['n1']!.entries) {
        expect(
          find.byKey(ValueKey('review-detail-${candidate.move}')),
          findsOneWidget,
        );
      }
      await tapVisible(find.text('关闭'));
      await engine.startReview(
        scope: ReviewScope.tree,
        mode: ReviewMode.candidates,
        maximum: 2,
        limits: ReviewLimits(depth: 4, moveTimeMs: null),
      );
      await tester.pumpAndSettle();
      expect(engine.review!.cachedCount, 4);
      expect(engine.review!.cachedSearchCount, 8);
      expect(find.text('复用 8 次候选搜索'), findsOneWidget);
      final revision = session.revision;
      await tapVisible(find.text('查看着法评级'));
      expect(find.text('模型着法评级'), findsOneWidget);
      await tapVisible(find.widgetWithText(SwitchListTile, '只看问题着法'));
      final assessment = find.byKey(const ValueKey('assessment-n1'));
      await tapVisible(assessment);
      expect(session.tree.cursorId, 'n1');
      expect(session.revision, revision);
      expect(find.text('模型着法评级'), findsNothing);
    },
  );
  testWidgets(
    'native recent reading reopens a fresh app at an independent saved cursor',
    (tester) async {
      final directory = await (await getApplicationDocumentsDirectory())
          .createTemp('.chessnext-recent-');
      try {
        final games = FileGameRepository(() async => directory);
        await games.save(
          SavedGame(
            id: 'native_recent',
            title: '原生阅读位置',
            tree: GameTree().play(Move.parse('h2e2')).play(Move.parse('b9c7')),
            modifiedAt: DateTime.utc(2026),
          ),
        );
        Widget app() => ChessNextApp(
          key: UniqueKey(),
          repository: FileGameRepository(() async => directory),
          recentReadingRepository: FileRecentReadingRepository(
            () async => directory,
          ),
        );
        Future<void> tap(Finder target) async {
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.text('棋谱库'));
        for (var i = 0; i < 50 && find.text('原生阅读位置').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tap(find.text('原生阅读位置'));
        final session = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis
            .session;
        expect(session.tree.cursorId, 'n2');
        await tap(find.byTooltip('回到开始'));
        expect(session.tree.cursorId, 'n0');
        expect(session.dirty, isFalse);
        await tap(find.widgetWithText(OutlinedButton, '最近阅读'));
        final readings = tester
            .widget<RecentReadingDialog>(find.byType(RecentReadingDialog))
            .readings;
        await readings.flush();
        expect(readings.entries.single.path, isEmpty);
        expect((await games.load('native_recent')).tree.cursorId, 'n2');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.widgetWithText(OutlinedButton, '最近阅读'));
        for (var i = 0; i < 50 && find.text('原生阅读位置').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tap(find.text('原生阅读位置'));
        final restored = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis
            .session;
        expect(restored.tree.cursorId, 'n0');
        expect(restored.tree.nodeCount, 3);
        expect(restored.dirty, isFalse);
        expect((await games.load('native_recent')).tree.cursorId, 'n2');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native first-run guide persists acknowledgment and replays without altering the game',
    (tester) async {
      final directory = await (await getApplicationDocumentsDirectory())
          .createTemp('.chessnext-guide-');
      final repository = FilePreferencesRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        showFirstRunGuide: true,
        preferencesRepository: FilePreferencesRepository(() async => directory),
      );
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 && find.byType(OnboardingDialog).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('1 / 4'), findsOneWidget);
        expect(await repository.load(), isNull);
        await tester.tap(find.text('跳过引导'));
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 && (await repository.load())?.value.guideVersion != 1;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await repository.load())!.value.guideVersion, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingDialog), findsNothing);
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final tree = session.tree;
        await tester.tap(find.byTooltip('帮助与按钮说明'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('新手引导'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 4'), findsOneWidget);
        await tester.tap(find.text('跳过引导'));
        await tester.pumpAndSettle();
        expect(session.tree, same(tree));
        expect(session.dirty, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native record metadata survives saves and independent draft recovery',
    (tester) async {
      final directory = await (await getApplicationDocumentsDirectory())
          .createTemp('.chessnext-metadata-');
      final games = FileGameRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        repository: FileGameRepository(() async => directory),
        draftRepository: FileDraftRepository(() async => directory),
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final drafts = tester
            .widget<DraftStatusBar>(find.byType(DraftStatusBar))
            .drafts;
        for (var i = 0; i < 50 && drafts.loading; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(drafts.canSave, isTrue);
        session.updateMetadata(GameMetadata({'Custom': '本机原始标签'}));
        await tester.pumpAndSettle();
        await tap(find.widgetWithText(OutlinedButton, '棋谱资料'));
        for (final entry in {'Event': '原生自制比赛', 'Red': '保存的棋手'}.entries) {
          final field = find.byKey(ValueKey('metadata-${entry.key}'));
          await tester.ensureVisible(field);
          await enterNativeText(tester, field, entry.value);
        }
        await tap(find.text('应用资料'));
        expect(session.metadata.tags['Custom'], '本机原始标签');
        expect(session.dirty, isTrue);
        await tap(find.text('保存棋谱'));
        await enterNativeText(
          tester,
          find.byKey(const ValueKey('record-name')),
          '原生资料棋谱',
        );
        await tap(find.widgetWithText(FilledButton, '保存'));
        for (var i = 0; i < 50 && session.dirty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(session.dirty, isFalse);
        final stored = (await games.list()).games.single;
        expect(stored.metadata.tags['Red'], '保存的棋手');
        session.updateMetadata(session.metadata.copyWith({'Red': '草稿棋手'}));
        await drafts.flush();
        expect(
          (await FileDraftRepository(
            () async => directory,
          ).load())!.metadata.tags['Red'],
          '草稿棋手',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        for (var i = 0; i < 50 && find.text('恢复草稿').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final restored = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        await tap(find.text('棋谱库'));
        final savedRow = find.widgetWithText(ListTile, '原生资料棋谱');
        for (var i = 0; i < 50 && savedRow.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tap(savedRow);
        expect(restored.metadata.tags['Red'], '保存的棋手');
        await tap(find.text('恢复草稿'));
        expect(restored.metadata.tags['Red'], '草稿棋手');
        expect(restored.metadata.tags['Custom'], '本机原始标签');
        expect(restored.dirty, isTrue);
        expect((await games.load(stored.id)).metadata.tags['Red'], '保存的棋手');
        await tester
            .widget<DraftStatusBar>(find.byType(DraftStatusBar))
            .drafts
            .flush();
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets('native PGN text preserves metadata, comments and saved branches', (
    tester,
  ) async {
    final directory = await (await getApplicationDocumentsDirectory())
        .createTemp('.chessnext-pgn-');
    final games = FileGameRepository(() async => directory);
    const pgn =
        '[Game "Chinese Chess"]\n[Format "ICCS"]\n[Event "原生PGN自制"]\n'
        '[Custom "未知标签"]\n[Result "1/2-1/2"]\n{根评}\n1. B2-E2 {炮评} B9-C7 2. H2-H4 {后续评注} 1/2-1/2';
    final clipboard = MemoryClipboard()..text = pgn;
    Widget app() => ChessNextApp(
      key: UniqueKey(),
      repository: FileGameRepository(() async => directory),
      clipboard: clipboard,
    );
    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    try {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      await tap(find.text('导入文字'));
      await tap(find.text('读取剪贴板'));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('import-text')))
            .controller!
            .text,
        pgn,
      );
      await tap(find.text('导入'));
      expect(session.tree.nodeCount, 4);
      expect(session.metadata.tags['Custom'], '未知标签');
      expect(session.metadata.result, '1/2-1/2');
      expect(session.outcome.isTerminal, isFalse);
      session.first();
      session.playMove(Move.parse('h2e2'));
      session.navigate('n2');
      await tester.pumpAndSettle();
      expect(session.tree.nodeCount, 5);
      await tap(find.text('导出文字'));
      await tap(find.byKey(const ValueKey('export-format')));
      await tap(find.text('PGN（中文）').last);
      await tap(find.text('复制'));
      final copied = PgnCodec.parse(clipboard.text!);
      expect(copied.tree.nodeCount, 3);
      expect(copied.tree.current.move, Move.parse('b9c7'));
      expect(copied.tree.root.comment, '根评');
      expect(copied.tree.node('n1').comment, '炮评');
      expect(copied.tags['Custom'], '未知标签');
      expect(copied.tags['Format'], 'Chinese');
      expect(session.metadata.tags['Format'], 'ICCS');
      await tap(find.text('关闭'));
      await tap(find.text('保存棋谱'));
      await enterNativeText(
        tester,
        find.byKey(const ValueKey('record-name')),
        '原生PGN验证',
      );
      await tap(find.widgetWithText(FilledButton, '保存'));
      for (var i = 0; i < 50 && session.dirty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(session.dirty, isFalse);
      final saved = (await games.list()).games.single;
      expect(saved.tree.nodeCount, 5);
      expect(saved.metadata.tags['Custom'], '未知标签');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap(find.text('棋谱库'));
      final row = find.widgetWithText(ListTile, '原生PGN验证');
      for (var i = 0; i < 50 && row.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tap(row);
      final restored = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      expect(restored.tree.nodeCount, 5);
      expect(restored.tree.cursorId, 'n2');
      expect(restored.tree.node('n3').comment, '后续评注');
      expect(restored.metadata.tags['Custom'], '未知标签');
      expect(restored.metadata.result, '1/2-1/2');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await directory.delete(recursive: true);
    }
  });
  testWidgets(
    'native file import reads UTF8 and preserves source plus saved metadata',
    (tester) async {
      final directory = await (await getApplicationDocumentsDirectory())
          .createTemp('.chessnext-file-import-');
      final source = File('${directory.path}/自制.pgn');
      const text =
          '[Game "Chinese Chess"]\n[Format "ICCS"]\n[Event "原生文件赛事"]\n[Custom "保留"]\n{根注} 1. H2-E2 {炮注} *';
      await source.writeAsString(text);
      final bytes = await source.readAsBytes();
      var choices = 0;
      final picker = FileSelectorRecordPicker(
        chooser: (types) async {
          choices++;
          expect(types.single.extensions, ['pgn', 'fen', 'txt']);
          return XFile(source.path);
        },
      );
      final games = FileGameRepository(() async => directory);
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(
          ChessNextApp(key: UniqueKey(), repository: games, filePicker: picker),
        );
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final before = session.tree;
        await tap(find.text('导入文件'));
        await tester.tap(find.text('选择文件'));
        for (
          var i = 0;
          i < 100 && find.textContaining('PGN · 1着').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.textContaining('PGN · 1着'), findsOneWidget);
        expect(session.tree, same(before));
        await tap(find.text('导入'));
        expect(choices, 1);
        expect(session.tree.nodeCount, 2);
        expect(session.metadata.tags['Event'], '原生文件赛事');
        expect(session.tree.root.comment, '根注');
        expect(session.tree.current.comment, '炮注');
        await tap(find.text('保存棋谱'));
        await enterNativeText(tester, find.byType(TextField).last, '原生文件导入验证');
        await tap(find.widgetWithText(FilledButton, '保存'));
        for (var i = 0; i < 50 && session.dirty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(session.dirty, isFalse);
        final saved = (await games.list()).games.single;
        expect(saved.metadata.tags['Custom'], '保留');
        expect(saved.tree.current.comment, '炮注');
        expect(await source.readAsBytes(), bytes);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native file export atomically saves snapshot and protects existing files on failure',
    (tester) async {
      final directory = await (await getApplicationDocumentsDirectory())
          .createTemp('.chessnext-file-export-');
      final target = File('${directory.path}/自制.pgn');
      await target.writeAsString('原文件内容');
      var choices = 0;
      final exporter = MacOsRecordFileExporter(
        chooser: (extension) async {
          choices++;
          expect(extension, 'pgn');
          return target.path;
        },
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(
          ChessNextApp(key: UniqueKey(), fileExporter: exporter),
        );
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        session.playMove(Move.parse('h2e2'));
        session.annotate('导出炮注');
        session.updateMetadata(GameMetadata({'Event': '导出时资料'}));
        await tap(find.text('导出文字'));
        session.playMove(Move.parse('b9c7'));
        final revision = session.revision;
        await tap(find.byKey(const ValueKey('export-format')));
        await tap(find.text('PGN（ICCS）').last);
        await tap(find.text('保存文件'));
        for (var i = 0; i < 100 && find.text('文件已保存').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('文件已保存'), findsOneWidget);
        expect(choices, 1);
        final record = PgnCodec.parse(await target.readAsString());
        expect(record.tree.nodeCount, 2);
        expect(record.tree.current.comment, '导出炮注');
        expect(record.tags['Event'], '导出时资料');
        expect(session.tree.nodeCount, 3);
        expect(session.revision, revision);
        expect(session.dirty, isTrue);
        final goodBytes = await target.readAsBytes();
        await expectLater(
          MacOsRecordFileExporter(
            chooser: (_) async => '${target.path}/invalid.pgn',
          ).saveText(
            text: '不能替换旧文件',
            extension: 'pgn',
            cancellation: FileExportCancellation(),
          ),
          throwsA(
            isA<RecordExportException>().having(
              (e) => e.failure,
              'failure',
              RecordExportFailure.write,
            ),
          ),
        );
        await expectLater(
          MacOsRecordFileExporter(
            chooser: (_) async => directory.path,
          ).saveText(
            text: '目录不应被替换',
            extension: 'pgn',
            cancellation: FileExportCancellation(),
          ),
          throwsA(isA<RecordExportException>()),
        );
        final link = Link('${directory.path}/link.pgn');
        await link.create(target.path);
        await expectLater(
          MacOsRecordFileExporter(chooser: (_) async => link.path).saveText(
            text: '不跟随符号链接写文件',
            extension: 'pgn',
            cancellation: FileExportCancellation(),
          ),
          throwsA(isA<RecordExportException>()),
        );
        expect(await link.target(), target.path);
        await expectLater(
          MacOsRecordFileExporter.channel.invokeMethod<void>('writeAtomic', {
            'path': target.path,
            'bytes': Uint8List(256001),
          }),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'invalid_export',
            ),
          ),
        );
        expect(await target.readAsBytes(), goodBytes);
        final newlyCreated = File('${directory.path}/new.fen');
        expect(
          await MacOsRecordFileExporter(
            chooser: (_) async => newlyCreated.path,
          ).saveText(
            text: session.position.toFen(),
            extension: 'fen',
            cancellation: FileExportCancellation(),
          ),
          RecordFileExportResult.saved,
        );
        expect(
          utf8.decode(await newlyCreated.readAsBytes()),
          session.position.toFen(),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native text size persists across app instances without changing records',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-text-size-');
      final repository = FilePreferencesRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: FilePreferencesRepository(() async => directory),
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        session.playMove(Move.parse('h2e2'));
        final tree = session.tree;
        final revision = session.revision;
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('界面字号'));
        await tap(find.byKey(const ValueKey('text-size-slider')));
        for (
          var i = 0;
          i < 50 &&
              (await repository.load())?.value.textSize !=
                  TextSizePreference.large;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          (await repository.load())!.value.textSize,
          TextSizePreference.large,
        );
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(XiangqiBoard)),
          ).scale(20),
          closeTo(23, .001),
        );
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.dirty, isTrue);
        await tap(find.text('关闭'));
        await tap(find.widgetWithText(FilledButton, '应用设置'));
        expect(
          (await repository.load())!.value.textSize,
          TextSizePreference.large,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 &&
              MediaQuery.textScalerOf(
                    tester.element(find.byType(XiangqiBoard)),
                  ).scale(20) !=
                  23;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(XiangqiBoard)),
          ).scale(20),
          closeTo(23, .001),
        );
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('界面字号'));
        expect(find.text('当前字号：大115%'), findsOneWidget);
        await tap(find.text('跟随系统字号'));
        for (
          var i = 0;
          i < 50 &&
              (await repository.load())?.value.textSize !=
                  TextSizePreference.system;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          (await repository.load())!.value.textSize,
          TextSizePreference.system,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native board coordinate preference restores and keeps flipped editor targets',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-coordinates-');
      final repository = FilePreferencesRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: FilePreferencesRepository(() async => directory),
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> display() async {
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('棋盘显示'));
      }

      String rail(String edge) => [
        for (var i = 0; i < 9; i++)
          tester
              .widget<Text>(find.byKey(ValueKey('coordinate-$edge-$i')))
              .data!,
      ].join();
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(rail('top'), '123456789');
        await tap(find.byKey(const ValueKey('square-h2')));
        await tap(find.byKey(const ValueKey('square-e2')));
        final tree = session.tree;
        final revision = session.revision;
        await display();
        await tap(find.text('显示坐标'));
        for (
          var i = 0;
          i < 50 && (await repository.load())?.value.showCoordinates != false;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await repository.load())!.value.showCoordinates, isFalse);
        expect(find.byType(BoardFileCoordinates), findsNothing);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        await tap(find.text('关闭'));
        await tap(find.widgetWithText(FilledButton, '应用设置'));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 && find.byType(BoardFileCoordinates).evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(BoardFileCoordinates), findsNothing);
        await display();
        await tap(find.text('显示坐标'));
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await tap(find.text('翻转'));
        expect(rail('top'), '一二三四五六七八九');
        await tap(find.byKey(const ValueKey('square-h2')));
        await tap(find.byKey(const ValueKey('square-e2')));
        final restored = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(restored.tree.current.move, Move.parse('h2e2'));
        await tap(find.text('编辑局面'));
        await tap(find.text('继续编辑'));
        await tap(find.text('旋转棋盘'));
        await tap(find.text('左右翻转'));
        expect(rail('top'), '九八七六五四三二一');
        await tap(find.text('清空'));
        final from = tester.getCenter(
          find.byKey(const ValueKey('palette-red-pawn')),
        );
        final to = tester.getCenter(find.byKey(const ValueKey('square-a3')));
        await tester.dragFrom(from, to - from);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BoardSurface>(find.byType(BoardSurface))
              .at(Square.parse('a3'))
              ?.type,
          PieceType.pawn,
        );
        await tap(find.byTooltip('取消编辑'));
        expect(restored.tree.current.move, Move.parse('h2e2'));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native piece size saves, restores and keeps overlapping piece hit targets',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-piece-size-');
      final repository = FilePreferencesRepository(() async => directory);
      await repository.save(
        AppPreferences(
          showCoordinates: false,
          textSize: TextSizePreference.large,
          guideVersion: 44,
        ),
      );
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: FilePreferencesRepository(() async => directory),
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> display() async {
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('棋盘显示'));
      }

      double scale(String square) => tester
          .widget<Transform>(
            find.descendant(
              of: find.byKey(ValueKey('square-$square')),
              matching: find.byKey(const ValueKey('piece-size')),
            ),
          )
          .transform
          .storage[0];
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        final initialCell = tester.getRect(
          find.byKey(const ValueKey('square-h2')),
        );
        await display();
        final slider = find.byKey(const ValueKey('piece-size-slider'));
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        final rect = tester.getRect(slider);
        await tester.tapAt(Offset(rect.right - 5, rect.center.dy));
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 && (await repository.load())!.value.pieceSizePercent != 200;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await repository.load())!.value.pieceSizePercent, 200);
        expect(scale('h2'), 2);
        expect(
          tester.getRect(find.byKey(const ValueKey('square-h2'))),
          initialCell,
        );
        await tap(find.text('关闭'));
        await tap(find.widgetWithText(FilledButton, '应用设置'));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        for (var i = 0; i < 50 && scale('h2') != 2; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(scale('h2'), 2);
        await tap(find.byKey(const ValueKey('square-h2')));
        await tap(find.byKey(const ValueKey('square-e2')));
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(session.tree.current.move, Move.parse('h2e2'));
        final tree = session.tree;
        await display();
        await tap(find.text('恢复默认大小'));
        for (
          var i = 0;
          i < 50 && (await repository.load())!.value.pieceSizePercent != 100;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final saved = (await repository.load())!.value;
        expect(saved.pieceSizePercent, 100);
        expect(saved.showCoordinates, isFalse);
        expect(saved.textSize, TextSizePreference.large);
        expect(saved.guideVersion, 44);
        expect(scale('e2'), 1);
        expect(session.tree, same(tree));
        expect(session.dirty, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native analysis markers preserve live NNUE search and reopen persisted style',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-markers-');
      final repository = FilePreferencesRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: FilePreferencesRepository(() async => directory),
        engineFactory: openBundledEngine,
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Finder arrows() => find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is BoardArrowsPainter,
      );
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        for (var i = 0; i < 100 && engine.reply == null; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.recommended, isNotNull);
        expect(engine.reply, isNotNull);
        final token = engine.infos.first.token;
        final identity = engine.engineIdentity;
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final tree = session.tree;
        expect(arrows(), findsOneWidget);
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('分析标记'));
        await tap(find.text('推荐箭头'));
        expect(arrows(), findsNothing);
        expect(engine.enabled, isTrue);
        await tap(find.byType(DropdownButtonFormField<ArrowHeadStyle>));
        await tap(find.text('宽').last);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.infos.every((info) => info.token == token), isTrue);
        expect(engine.infos, isNotEmpty);
        expect(engine.engineIdentity, identity);
        await tap(find.text('推荐箭头'));
        final paint =
            tester.widget<CustomPaint>(arrows()).painter! as BoardArrowsPainter;
        expect(paint.headStyle, ArrowHeadStyle.wide);
        expect(paint.recommendation, engine.recommended);
        expect(paint.reply, engine.reply);
        await tap(find.text('推荐箭头'));
        for (
          var i = 0;
          i < 50 &&
              (await repository.load())?.value.arrowHead != ArrowHeadStyle.wide;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await repository.load())!.value.arrowHead, ArrowHeadStyle.wide);
        expect((await repository.load())!.value.showAnalysisArrows, isFalse);
        expect(session.tree, same(tree));
        expect(session.dirty, isFalse);
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await engine.disable();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('分析标记'));
        expect(
          tester
              .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, '推荐箭头'),
              )
              .value,
          isFalse,
        );
        expect(
          tester
              .widget<DropdownButtonFormField<ArrowHeadStyle>>(
                find.byType(DropdownButtonFormField<ArrowHeadStyle>),
              )
              .initialValue,
          ArrowHeadStyle.wide,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native numbered variation arrows share a global gate but never change the saved tree',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-variation-arrows-');
      final games = FileGameRepository(() async => directory);
      final preferences = FilePreferencesRepository(() async => directory);
      await games.save(
        SavedGame(
          id: 'numbered-variation',
          title: '编号变着验证',
          tree: branchedRecord(),
          modifiedAt: DateTime.now(),
        ),
      );
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        repository: FileGameRepository(() async => directory),
        preferencesRepository: FilePreferencesRepository(() async => directory),
        engineFactory: openBundledEngine,
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Finder arrows() => find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is VariationArrowsPainter,
      );
      final toggle = find.byKey(const ValueKey('current-variation-arrows'));
      Future<void> openRecord() async {
        await tap(find.text('棋谱库'));
        final row = find.widgetWithText(ListTile, '编号变着验证');
        for (var i = 0; i < 50 && row.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tap(row);
      }

      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await openRecord();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final tree = session.tree,
            revision = session.revision,
            positionRevision = session.positionRevision;
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        for (var i = 0; i < 100 && engine.infos.isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.infos, isNotEmpty);
        final token = engine.infos.first.token;
        await tap(toggle);
        final paint =
            tester.widget<CustomPaint>(arrows()).painter!
                as VariationArrowsPainter;
        expect(paint.arrows.map((a) => a.move.toString()), ['b0c2', 'h2h4']);
        expect(paint.arrows.map((a) => a.number), [1, 2]);
        await tap(find.byTooltip('应用设置'));
        expect(session.showCurrentVariationArrows, isFalse);
        await tap(find.text('分析标记'));
        await tap(find.text('变着箭头'));
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await tap(toggle);
        expect(session.showCurrentVariationArrows, isTrue);
        expect(arrows(), findsNothing);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.infos, isNotEmpty);
        expect(engine.infos.every((info) => info.token == token), isTrue);
        expect((await preferences.load())!.value.showVariationArrows, isFalse);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.positionRevision, positionRevision);
        expect(session.dirty, isFalse);
        expect(
          (await games.load('numbered-variation')).tree.toJson(),
          tree.toJson(),
        );
        await engine.disable();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await openRecord();
        final restored = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(restored.showCurrentVariationArrows, isFalse);
        expect(restored.tree.nodeCount, 6);
        await tap(toggle);
        expect(arrows(), findsNothing);
        expect(find.text('变着箭头已在分析标记设置中关闭。'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native WDL evaluation bar preserves search, frozen view and persisted visibility',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-evaluation-');
      final repository = FilePreferencesRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: FilePreferencesRepository(() async => directory),
        engineFactory: openBundledEngine,
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> markers() async {
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('分析标记'));
      }

      BoardEvaluation evaluation() => tester
          .widget<EvaluationBoard>(find.byType(EvaluationBoard))
          .evaluation;
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(evaluation().redRatio, isNull);
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final tree = session.tree, revision = session.revision;
        await tap(find.text('开始分析'));
        for (
          var i = 0;
          i < 100 && evaluation().kind != EvaluationKind.model;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(evaluation().kind, EvaluationKind.model);
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        final token = engine.infos.first.token;
        final width = tester.getSize(find.byType(XiangqiBoard)).width;
        await markers();
        await tap(find.text('局势条'));
        expect(find.byKey(const ValueKey('evaluation-strip')), findsNothing);
        expect(
          tester.getSize(find.byType(XiangqiBoard)).width,
          closeTo(width + 28, .01),
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.enabled, isTrue);
        expect(engine.infos, isNotEmpty);
        expect(engine.infos.every((value) => value.token == token), isTrue);
        await tap(find.text('局势条'));
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await tap(find.text('停止分析'));
        final frozen = evaluation().redUnits;
        expect(frozen, isNotNull);
        expect(evaluation().description, contains('保留的当前局面结果'));
        await tap(find.text('翻转'));
        final paint =
            tester
                    .widget<CustomPaint>(
                      find.byKey(const ValueKey('evaluation-fill')),
                    )
                    .painter!
                as EvaluationStripPainter;
        expect(paint.flipped, isTrue);
        expect(evaluation().redUnits, frozen);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.dirty, isFalse);
        await markers();
        await tap(find.text('局势条'));
        for (
          var i = 0;
          i < 50 && (await repository.load())?.value.showEvaluationBar != false;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await repository.load())!.value.showEvaluationBar, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 &&
              find
                  .byKey(const ValueKey('evaluation-strip'))
                  .evaluate()
                  .isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byKey(const ValueKey('evaluation-strip')), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native last move markers persist styles and preserve NNUE plus saved game',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-last-move-');
      final repository = FilePreferencesRepository(() async => directory);
      final games = FileGameRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        repository: FileGameRepository(() async => directory),
        preferencesRepository: FilePreferencesRepository(() async => directory),
        engineFactory: openBundledEngine,
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      LastMoveMarkersPainter marker() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('last-move-markers')),
                  )
                  .painter!
              as LastMoveMarkersPainter;
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.byType(LastMoveMarkers), findsNothing);
        await tap(find.byKey(const ValueKey('square-h2')));
        await tap(find.byKey(const ValueKey('square-e2')));
        expect(marker().move, Move.parse('h2e2'));
        expect(marker().phase, 1);
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final tree = session.tree,
            revision = session.revision,
            positionRevision = session.positionRevision;
        final targetRect = tester.getRect(
          find.byKey(const ValueKey('square-e2')),
        );
        await games.save(
          SavedGame(
            id: 'marker-game',
            title: '落子标记验证',
            tree: tree,
            modifiedAt: DateTime.now(),
          ),
        );
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        for (var i = 0; i < 100 && engine.infos.isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.infos, isNotEmpty);
        final token = engine.infos.first.token;
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('棋盘显示'));
        await tap(find.byType(DropdownButtonFormField<LastMoveMarkerStyle>));
        await tap(find.text('方框').last);
        for (
          var i = 0;
          i < 50 &&
              (await repository.load())?.value.lastMoveMarker !=
                  LastMoveMarkerStyle.box;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          (await repository.load())!.value.lastMoveMarker,
          LastMoveMarkerStyle.box,
        );
        expect(marker().style, LastMoveMarkerStyle.box);
        expect(engine.infos.every((info) => info.token == token), isTrue);
        expect(engine.enabled, isTrue);
        expect(
          tester.getRect(find.byKey(const ValueKey('square-e2'))),
          targetRect,
        );
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.positionRevision, positionRevision);
        expect((await games.load('marker-game')).tree.toJson(), tree.toJson());
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await engine.disable();
        await tap(find.text('翻转'));
        expect(marker().flipped, isTrue);
        expect(marker().move, Move.parse('h2e2'));
        session.first();
        await tester.pumpAndSettle();
        expect(find.byType(LastMoveMarkers), findsNothing);
        session.forward();
        await tester.pumpAndSettle();
        expect(marker().move, Move.parse('h2e2'));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.text('棋谱库'));
        final row = find.widgetWithText(ListTile, '落子标记验证');
        for (var i = 0; i < 50 && row.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tap(row);
        expect(marker().style, LastMoveMarkerStyle.box);
        expect(marker().move, Move.parse('h2e2'));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native selection style restores preferences and editor hit targets without changing saved game',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-selection-');
      final preferences = FilePreferencesRepository(() async => directory);
      final games = FileGameRepository(() async => directory);
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: FilePreferencesRepository(() async => directory),
        engineFactory: openBundledEngine,
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      final frame = find.byKey(const ValueKey('selected-piece-frame'));
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('square-h2')));
        expect(
          find.byKey(const ValueKey('selected-piece-lift')),
          findsOneWidget,
        );
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        final tree = session.tree,
            revision = session.revision,
            positionRevision = session.positionRevision;
        final cell = tester.getRect(find.byKey(const ValueKey('square-h2')));
        await games.save(
          SavedGame(
            id: 'selection-game',
            title: '选子验证',
            tree: tree,
            modifiedAt: DateTime.now(),
          ),
        );
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        for (var i = 0; i < 100 && engine.infos.isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.infos, isNotEmpty);
        final token = engine.infos.first.token;
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('棋盘显示'));
        await tap(find.byType(DropdownButtonFormField<SelectionStyle>));
        await tap(find.text('选择框').last);
        for (
          var i = 0;
          i < 50 &&
              (await preferences.load())?.value.selectionStyle !=
                  SelectionStyle.frame;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          (await preferences.load())!.value.selectionStyle,
          SelectionStyle.frame,
        );
        expect(frame, findsOneWidget);
        expect(session.selected, Square.parse('h2'));
        expect(tester.getRect(find.byKey(const ValueKey('square-h2'))), cell);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.positionRevision, positionRevision);
        expect(session.dirty, isFalse);
        expect(engine.infos.every((info) => info.token == token), isTrue);
        expect(engine.enabled, isTrue);
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await engine.disable();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('square-h2')));
        expect(frame, findsOneWidget);
        await tap(find.text('编辑局面'));
        await tap(find.text('旋转棋盘'));
        await tap(find.text('左右翻转'));
        await tap(find.byKey(const ValueKey('square-h2')));
        expect(frame, findsOneWidget);
        final from = tester.getCenter(find.byKey(const ValueKey('square-h2'))),
            to = tester.getCenter(find.byKey(const ValueKey('square-h3')));
        await tester.dragFrom(from, to - from);
        await tester.pumpAndSettle();
        expect(frame, findsNothing);
        expect(
          tester
              .widget<BoardSurface>(find.byType(BoardSurface))
              .at(Square.parse('h3'))
              ?.type,
          PieceType.cannon,
        );
        await tap(find.byTooltip('取消编辑'));
        expect(
          tester
              .widget<XiangqiBoard>(find.byType(XiangqiBoard))
              .session
              .tree
              .toJson(),
          tree.toJson(),
        );
        expect(
          (await games.load('selection-game')).tree.toJson(),
          tree.toJson(),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native NNUE PV history is frozen, retained across positions and cleared by new document',
    (tester) async {
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(ChessNextApp(engineFactory: openBundledEngine));
        await tester.pumpAndSettle();
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        for (var i = 0; i < 100 && engine.history.length < 2; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.history.length, greaterThanOrEqualTo(2));
        final token = engine.infos.first.token,
            tree = session.tree,
            revision = session.revision;
        await tap(find.byKey(const ValueKey('pv-history-open')));
        final snapshot = tester
            .widget<PvHistoryDialog>(find.byType(PvHistoryDialog))
            .entries;
        expect(snapshot, isNotEmpty);
        expect(snapshot.length, lessThanOrEqualTo(64));
        expect(
          snapshot.every((e) => e.info.token == token && e.info.pv.isNotEmpty),
          isTrue,
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          tester.widget<PvHistoryDialog>(find.byType(PvHistoryDialog)).entries,
          same(snapshot),
        );
        expect(engine.infos.every((info) => info.token == token), isTrue);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.dirty, isFalse);
        await tap(find.text('关闭'));
        await tap(find.text('停止分析'));
        final retained = engine.history;
        expect(retained, isNotEmpty);
        session.flip();
        session.updateMetadata(GameMetadata({'Event': '历史验证'}));
        await tester.pumpAndSettle();
        expect(engine.history, same(retained));
        await tap(find.byKey(const ValueKey('pv-history-open')));
        expect(find.byType(PvHistoryDialog), findsOneWidget);
        await tap(find.text('关闭'));
        await tap(find.byTooltip('清空本谱PV历史'));
        expect(engine.history, isEmpty);
        expect(session.tree, same(tree));
        await tap(find.text('开始分析'));
        for (var i = 0; i < 100 && engine.history.isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.history, isNotEmpty);
        await tap(find.text('停止分析'));
        final archive = engine.history;
        session.playMove(Move.parse('h2e2'));
        await tester.pumpAndSettle();
        expect(engine.history, same(archive));
        expect(engine.infos, isEmpty);
        session.newGame();
        await tester.pumpAndSettle();
        expect(engine.history, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'native PV preview uses a real worker and never changes the NNUE search or game',
    (tester) async {
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(ChessNextApp(engineFactory: openBundledEngine));
        await tester.pumpAndSettle();
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        for (
          var i = 0;
          i < 100 && !engine.history.any((e) => e.info.pv.length >= 3);
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(engine.history.any((e) => e.info.pv.length >= 3), isTrue);
        final tree = session.tree,
            revision = session.revision,
            positionRevision = session.positionRevision,
            token = engine.infos.first.token;
        await tap(find.byKey(const ValueKey('pv-history-open')));
        final history = tester.widget<PvHistoryDialog>(
          find.byType(PvHistoryDialog),
        );
        final entry = history.entries.firstWhere((e) => e.info.pv.length >= 3);
        final button = find.byKey(ValueKey('pv-history-preview-${entry.id}'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        final progress = find.byKey(const ValueKey('pv-preview-progress'));
        for (var i = 0; i < 100 && progress.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(progress, findsOneWidget);
        expect(
          tester.widget<Text>(progress).data,
          '1 / ${entry.info.pv.length}',
        );
        final board = tester.widget<BoardSurface>(
          find.descendant(
            of: find.byType(PvPreviewDialog),
            matching: find.byType(BoardSurface),
          ),
        );
        expect(board.enabled, isFalse);
        expect(
          board.at(entry.info.pv.first.to)?.fen,
          entry.position
              .play(entry.info.pv.first)
              .at(entry.info.pv.first.to)
              ?.fen,
        );
        await tap(find.byTooltip('回到原局面'));
        expect(
          tester.widget<Text>(progress).data,
          '0 / ${entry.info.pv.length}',
        );
        await tester.tap(find.byTooltip('播放'));
        await tester.pump(const Duration(milliseconds: 900));
        expect(
          tester.widget<Text>(progress).data,
          isNot('0 / ${entry.info.pv.length}'),
        );
        await tester.tap(find.byTooltip('暂停'));
        await tester.pumpAndSettle();
        final paused = tester.widget<Text>(progress).data;
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.widget<Text>(progress).data, paused);
        await tap(find.byTooltip('下一步'));
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.positionRevision, positionRevision);
        expect(session.dirty, isFalse);
        expect(engine.enabled, isTrue);
        expect(engine.infos.every((info) => info.token == token), isTrue);
        await tap(find.text('关闭预览'));
        expect(find.byType(PvPreviewDialog), findsNothing);
        expect(find.byType(PvHistoryDialog), findsOneWidget);
        await tap(find.text('关闭'));
        await tap(find.text('停止分析'));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'native PV prefix applies atomically, preserves saved branches and reuses existing nodes',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-pv-prefix-');
      final games = FileGameRepository(() async => directory);
      final oldMove = Move.parse('a6a5');
      var original = branchedRecord()
          .play(oldMove)
          .play(Move.parse('a3a4'))
          .annotate('保留原后续');
      final oldLeaf = original.cursorId;
      original = original.goTo('n5');
      await games.save(
        SavedGame(
          id: 'pv-source',
          title: 'PV应用验证',
          tree: original,
          metadata: GameMetadata({'Event': '原资料'}),
          modifiedAt: DateTime.now(),
        ),
      );
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        repository: FileGameRepository(() async => directory),
        engineFactory: openBundledEngine,
      );
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> openRecord() async {
        await tap(find.text('棋谱库'));
        final row = find.widgetWithText(ListTile, 'PV应用验证');
        for (var i = 0; i < 50 && row.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tap(row);
      }

      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await openRecord();
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        bool suitable() => engine.history.any(
          (e) => e.info.pv.length >= 3 && e.info.pv.first != oldMove,
        );
        for (var i = 0; i < 100 && !suitable(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(suitable(), isTrue);
        final source = session.tree,
            revision = session.revision,
            positionRevision = session.positionRevision,
            epoch = session.epoch;
        await tap(find.byKey(const ValueKey('pv-history-open')));
        final entry = tester
            .widget<PvHistoryDialog>(find.byType(PvHistoryDialog))
            .entries
            .firstWhere(
              (e) => e.info.pv.length >= 3 && e.info.pv.first != oldMove,
            );
        final button = find.byKey(ValueKey('pv-history-preview-${entry.id}'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        final progress = find.byKey(const ValueKey('pv-preview-progress'));
        for (var i = 0; i < 100 && progress.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(progress, findsOneWidget);
        await tap(find.byTooltip('下一步'));
        expect(
          tester.widget<Text>(progress).data,
          '2 / ${entry.info.pv.length}',
        );
        await tester.tap(find.byKey(const ValueKey('pv-apply-prefix')));
        await tester.pump();
        for (
          var i = 0;
          i < 100 && find.byType(PvPreviewDialog).evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(find.byType(PvPreviewDialog), findsNothing);
        expect(find.byType(PvHistoryDialog), findsNothing);
        expect(engine.enabled, isFalse);
        expect(engine.playing, isFalse);
        expect(session.tree.nodeCount, source.nodeCount + 2);
        expect(session.moves.skip(3), entry.info.pv.take(2));
        expect(session.tree.node(oldLeaf).comment, '保留原后续');
        expect(
          session.tree.node('n5').children.first,
          source.node('n5').children.first,
        );
        expect(session.metadata.tags['Event'], '原资料');
        expect(session.revision, revision + 1);
        expect(session.positionRevision, positionRevision + 1);
        expect(session.epoch, epoch);
        expect(session.dirty, isTrue);
        await tap(find.text('保存棋谱'));
        await tap(find.widgetWithText(FilledButton, '保存'));
        for (var i = 0; i < 50 && session.dirty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(session.dirty, isFalse);
        final saved = await games.load('pv-source'),
            savedRevision = session.revision,
            target = session.tree.cursorId;
        session.navigate(entry.nodeId);
        await tester.pumpAndSettle();
        expect(
          await engine
              .createPvPrefixAction(entry)
              .apply(2, PvApplyCancellation()),
          PvApplyResult.applied,
        );
        await tester.pumpAndSettle();
        expect(session.revision, savedRevision);
        expect(session.dirty, isFalse);
        expect(session.tree.cursorId, target);
        expect(session.tree.nodeCount, saved.tree.nodeCount);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await openRecord();
        final restored = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(restored.tree.toJson(), saved.tree.toJson());
        expect(restored.metadata.tags['Event'], '原资料');
        expect(restored.tree.node(oldLeaf).comment, '保留原后续');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'native cross-position PV archive preserves source previews and rejects a different current node',
    (tester) async {
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(ChessNextApp(engineFactory: openBundledEngine));
        await tester.pumpAndSettle();
        await tap(find.text('开始分析'));
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        for (
          var i = 0;
          i < 100 && !engine.history.any((e) => e.info.pv.length >= 2);
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final original = engine.history.firstWhere(
          (e) => e.info.pv.length >= 2,
        );
        expect(original.sourcePly, 0);
        session.playMove(Move.parse('h2e2'));
        expect(engine.infos, isEmpty);
        expect(engine.recommended, isNull);
        for (
          var i = 0;
          i < 100 && !engine.history.any((e) => e.sourcePly == 1);
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          engine.history.any(
            (e) => e.sourcePly == 1 && e.sourceMoveLabel == '炮二平五',
          ),
          isTrue,
        );
        await engine.disable();
        await tester.pumpAndSettle();
        expect(engine.history.any((e) => e.id == original.id), isTrue);
        final tree = session.tree, revision = session.revision;
        Future<void> oldPreview() async {
          await tap(find.byKey(const ValueKey('pv-history-open')));
          final row = find.byKey(ValueKey('pv-history-preview-${original.id}'));
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          expect(row.hitTestable(), findsOneWidget);
          await tester.tap(row);
          await tester.pump();
          final progress = find.byKey(const ValueKey('pv-preview-progress'));
          for (var i = 0; i < 100 && progress.evaluate().isEmpty; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(progress, findsOneWidget);
        }

        await oldPreview();
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('pv-apply-prefix')),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('来源：起始局面'), findsOneWidget);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        final board = tester.widget<BoardSurface>(
          find.descendant(
            of: find.byType(PvPreviewDialog),
            matching: find.byType(BoardSurface),
          ),
        );
        expect(board.lastMove, original.info.pv.first);
        expect(board.enabled, isFalse);
        await tap(find.text('关闭预览'));
        await tap(find.text('关闭'));
        session.first();
        await tester.pumpAndSettle();
        await oldPreview();
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('pv-apply-prefix')),
              )
              .onPressed,
          isNotNull,
        );
        await tap(find.text('关闭预览'));
        await tap(find.text('关闭'));
        session.newGame();
        await tester.pumpAndSettle();
        expect(engine.history, isEmpty);
        expect(find.text('PV历史（0）'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'native move grade badge uses NNUE review and shared persisted toggle',
    (tester) async {
      final directory = await (await getApplicationSupportDirectory())
          .createTemp('.chessnext-grade-');
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        engineFactory: openBundledEngine,
        preferencesRepository: FilePreferencesRepository(() async => directory),
      );
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        expect(f.hitTestable(), findsOneWidget);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        final engine = tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis;
        final session = engine.session;
        session.playMove(Move.parse('h2e2'));
        session.playMove(Move.parse('b9c7'));
        await tester.pumpAndSettle();
        final tree = session.tree, revision = session.revision;
        var done = false;
        final job = engine
            .startReview(limits: ReviewLimits(depth: 4, moveTimeMs: null))
            .whenComplete(() => done = true);
        for (var i = 0; i < 150 && !done; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(done, isTrue);
        await job;
        await tester.pumpAndSettle();
        expect(engine.review!.phase, ReviewPhase.completed);
        expect(
          engine.review!.results.values.every((r) => r.info?.wdl != null),
          isTrue,
        );
        final row = engine.currentMoveAssessment!;
        expect(row.rated, isTrue);
        expect(find.byType(MoveGradeBadge), findsOneWidget);
        await tap(find.byKey(const ValueKey('show-move-grades')));
        expect(find.byType(MoveGradeBadge), findsNothing);
        expect(
          find.textContaining('本机模型评级：${row.grade.label}'),
          findsOneWidget,
        );
        await tap(find.byTooltip('应用设置'));
        await tap(find.text('分析标记'));
        final flag = find.descendant(
          of: find.byType(AnalysisMarkersDialog),
          matching: find.byKey(const ValueKey('show-move-grades')),
        );
        expect(tester.widget<SwitchListTile>(flag).value, isFalse);
        await tap(flag);
        expect(find.byType(MoveGradeBadge), findsOneWidget);
        await tap(find.text('关闭'));
        await tap(find.text('取消'));
        await tap(find.text('翻转'));
        expect(
          tester.widget<MoveGradeBadge>(find.byType(MoveGradeBadge)).flipped,
          isTrue,
        );
        expect(engine.currentMoveAssessment, same(row));
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        await tap(find.byKey(const ValueKey('show-move-grades')));
        final store = FilePreferencesRepository(() async => directory);
        for (
          var i = 0;
          i < 50 && (await store.load())?.value.showMoveGrades != false;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect((await store.load())!.value.showMoveGrades, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const ValueKey('show-move-grades')),
              )
              .value,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await directory.delete(recursive: true);
      }
    },
  );
}
