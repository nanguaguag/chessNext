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
}
