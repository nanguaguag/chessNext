import 'dart:async';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/transfer/text_transfer_dialog.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/memory_clipboard.dart';
import '../support/pump_until.dart';

const sample =
    '[Game "Chinese Chess"]\n[Format "ICCS"]\n[Event "自制赛"]\n'
    '[Custom "未知保留"]\n[Result "0-1"]\n{根注}\n1. H2-E2 {炮注} B9-C7 0-1 {末注}';

class DelayedPgnSave extends MemoryGameRepository {
  final gate = Completer<void>();
  bool written = false;
  @override
  Future<void> save(SavedGame game) async {
    await gate.future;
    await super.save(game);
    written = true;
  }
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

  Future<void> choose(WidgetTester tester, String format) async {
    await tap(tester, find.byKey(const ValueKey('export-format')));
    await tester.tap(find.text(format).last);
    await tester.pumpAndSettle();
  }

  Future<void> input(WidgetTester tester, String text) async {
    await tap(tester, find.text('导入文字'));
    await tester.enterText(find.byKey(const ValueKey('import-text')), text);
    await tester.pump();
    await tester.tap(find.text('导入'));
  }

  testWidgets(
    'PGN imports complete metadata and comments and export stays at the opened snapshot',
    (tester) async {
      desktop(tester);
      final clipboard = MemoryClipboard();
      await tester.pumpWidget(ChessNextApp(clipboard: clipboard));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      await input(tester, sample);
      await pumpUntil(tester, () => session.tree.nodeCount == 3);
      await tester.pumpAndSettle();
      expect(session.metadata.tags['Event'], '自制赛');
      expect(session.metadata.tags['Custom'], '未知保留');
      expect(session.metadata.result, '0-1');
      expect(session.outcome.isTerminal, isFalse);
      expect(session.tree.root.comment, '根注');
      expect(session.tree.node('n1').comment, '炮注');
      await tap(tester, find.text('导出文字'));
      session.updateMetadata(session.metadata.copyWith({'Event': '后来改动'}));
      session.playMove(Move.parse('c3c4'));
      await tester.pumpAndSettle();
      for (final label in ['PGN（ICCS）', 'PGN（中文）']) {
        await choose(tester, label);
        await tap(tester, find.text('复制'));
        final exported = PgnCodec.parse(clipboard.text!);
        expect(exported.tags['Event'], '自制赛');
        expect(exported.tags['Custom'], '未知保留');
        expect(exported.result, '0-1');
        expect(exported.tree.nodeCount, 3);
        expect(exported.tree.root.comment, '根注');
        expect(exported.tree.node('n1').comment, '炮注');
        expect(exported.tree.current.comment, '末注');
      }
      expect(session.tree.nodeCount, 4);
      expect(session.metadata.tags['Event'], '后来改动');
    },
  );
  testWidgets(
    'unsupported PGN leaves the original document and text available',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.updateMetadata(GameMetadata({'Event': '原棋谱'}));
      final tree = session.tree;
      final revision = session.revision;
      await input(tester, '[Game "Chinese Chess"]\n[Format "WXF"]\n*');
      await pumpUntil(
        tester,
        () => find.textContaining('暂不支持PGN的WXF').evaluate().isNotEmpty,
      );
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.metadata.tags['Event'], '原棋谱');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('import-text')))
            .controller!
            .text,
        contains('WXF'),
      );
      await tap(tester, find.text('取消'));
    },
  );
  testWidgets(
    'cancel and Escape discard late parsing results before disposal without closing another route',
    (tester) async {
      desktop(tester);
      for (final escape in [false, true]) {
        final gate = Completer<ImportedRecord>();
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            navigatorKey: navigator,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<ImportedRecord>(
                    context: context,
                    builder: (_) => ImportTextDialog(
                      clipboard: MemoryClipboard(),
                      importer: (_) => gate.future,
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        );
        await tap(tester, find.text('打开'));
        await tester.enterText(
          find.byKey(const ValueKey('import-text')),
          'startpos',
        );
        await tester.pump();
        await tester.tap(find.text('导入'));
        await tester.pump();
        final old = tester.state(find.byType(ImportTextDialog));
        if (escape) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          await tester.tap(find.text('取消'));
        }
        expect(old.mounted, isTrue);
        unawaited(
          showDialog<void>(
            context: navigator.currentContext!,
            builder: (_) => const AlertDialog(title: Text('新的窗口')),
          ),
        );
        gate.complete(RecordTextExchange.parse('startpos moves h2e2'));
        await tester.pumpAndSettle();
        expect(find.text('新的窗口'), findsOneWidget);
        expect(find.byType(ImportTextDialog), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'late clipboard read cannot overwrite input edited during reading',
    (tester) async {
      desktop(tester);
      final clipboard = MemoryClipboard()..readGate = Completer<String?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<ImportedRecord>(
                  context: context,
                  builder: (_) => ImportTextDialog(clipboard: clipboard),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      await tester.tap(find.text('读取剪贴板'));
      await tester.pump();
      final field = find.byKey(const ValueKey('import-text'));
      expect(tester.widget<TextField>(field).enabled, isTrue);
      await tester.enterText(field, 'startpos moves b2e2');
      clipboard.readGate!.complete('startpos moves h2e2');
      await pumpUntil(
        tester,
        () =>
            tester
                .widget<FilledButton>(find.widgetWithText(FilledButton, '导入'))
                .onPressed !=
            null,
      );
      expect(
        tester.widget<TextField>(field).controller!.text,
        'startpos moves b2e2',
      );
      await tap(tester, find.text('取消'));
    },
  );
  testWidgets(
    'document change during replacement confirmation cannot be overwritten',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.updateMetadata(GameMetadata({'Event': '旧资料'}));
      await input(tester, sample);
      await pumpUntil(
        tester,
        () => find.text('导入前保留当前棋谱？').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      session.newGame();
      session.playMove(Move.parse('b2e2'));
      session.updateMetadata(GameMetadata({'Event': '新资料'}));
      await tap(tester, find.text('替换'));
      expect(session.tree.current.move, Move.parse('b2e2'));
      expect(session.metadata.tags['Event'], '新资料');
      expect(find.text('导入期间棋谱已变化，请重新导入。'), findsOneWidget);
    },
  );
  testWidgets(
    'save-before-import writes its snapshot and refuses to overwrite later content',
    (tester) async {
      desktop(tester);
      final repository = DelayedPgnSave();
      await tester.pumpWidget(ChessNextApp(repository: repository));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.updateMetadata(GameMetadata({'Event': '待保存资料'}));
      await input(tester, sample);
      await pumpUntil(tester, () => find.text('先保存').evaluate().isNotEmpty);
      await tap(tester, find.text('先保存'));
      await tester.enterText(
        find.byKey(const ValueKey('record-name')),
        '导入前副本',
      );
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pump();
      session.newGame();
      session.updateMetadata(GameMetadata({'Event': '保存期间新文档'}));
      repository.gate.complete();
      await pumpUntil(tester, () => repository.written);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(session.metadata.tags['Event'], '保存期间新文档');
      expect(session.tree.nodeCount, 1);
      expect(
        (await repository.list()).games.single.metadata.tags['Event'],
        '待保存资料',
      );
      expect(session.dirty, isTrue);
    },
  );
  testWidgets(
    '200 percent PGN errors disable copying until explicit comment omission',
    (tester) async {
      tester.view.physicalSize = const Size(520, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final clipboard = MemoryClipboard();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ExportTextDialog(
                    tree: GameTree().annotate('含{花括号}'),
                    metadata: GameMetadata({'Event': '测试'}),
                    clipboard: clipboard,
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      await choose(tester, 'PGN（ICCS）');
      expect(find.textContaining('PGN评注包含花括号'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '复制'))
            .onPressed,
        isNull,
      );
      await tap(tester, find.widgetWithText(CheckboxListTile, '包含路径评注'));
      await tap(tester, find.text('复制'));
      final parsed = PgnCodec.parse(clipboard.text!);
      expect(parsed.tree.root.comment, isEmpty);
      expect(parsed.tags['Event'], '测试');
      expect(tester.takeException(), isNull);
    },
  );
}
