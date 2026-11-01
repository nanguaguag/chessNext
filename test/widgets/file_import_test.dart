import 'dart:async';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/transfer/import_file_dialog.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:chess_next/ports/record_file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/memory_record_picker.dart';
import '../support/pump_until.dart';

const fixture = PickedRecordText(
  displayName: '自制.pgn',
  text:
      '[Game "Chinese Chess"]\n[Format "ICCS"]\n[Event "文件赛事"]\n{根评注} 1. H2-E2 {着法评注} *',
);

void main() {
  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> load(WidgetTester tester) async {
    await tap(tester, find.text('导入文件'));
    await tester.tap(find.text('选择文件'));
    await pumpUntil(
      tester,
      () => find.textContaining('PGN · 1着').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'file preview is read-only until explicit import and carries complete PGN',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(
        ChessNextApp(filePicker: MemoryRecordPicker(() async => fixture)),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final before = session.tree;
      await load(tester);
      expect(find.text('自制.pgn'), findsOneWidget);
      expect(session.tree, same(before));
      await tap(tester, find.text('导入'));
      expect(session.tree.nodeCount, 2);
      expect(session.metadata.tags['Event'], '文件赛事');
      expect(session.tree.current.comment, '着法评注');
      expect(session.tree.root.comment, '根评注');
      expect(session.dirty, isTrue);
    },
  );

  testWidgets(
    'dirty cancel preserves metadata and save-before-import retains original record',
    (tester) async {
      desktop(tester);
      final repository = MemoryGameRepository();
      await tester.pumpWidget(
        ChessNextApp(
          repository: repository,
          filePicker: MemoryRecordPicker(() async => fixture),
        ),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.updateMetadata(GameMetadata({'Event': '原棋谱资料'}));
      await load(tester);
      await tap(tester, find.text('导入'));
      await tap(tester, find.text('取消'));
      expect(session.metadata.tags['Event'], '原棋谱资料');
      expect(session.tree.nodeCount, 1);
      await load(tester);
      await tap(tester, find.text('导入'));
      await tap(tester, find.text('先保存'));
      await tester.enterText(find.byType(TextField).last, '文件前原谱');
      await tap(tester, find.text('保存').last);
      await pumpUntil(tester, () => session.metadata.tags['Event'] == '文件赛事');
      final summaries = await repository.list();
      expect(summaries.games.single.title, '文件前原谱');
      expect(
        (await repository.load(
          summaries.games.single.id,
        )).metadata.tags['Event'],
        '原棋谱资料',
      );
    },
  );

  testWidgets(
    'document or position changed during choice cannot be overwritten',
    (tester) async {
      desktop(tester);
      for (final changeDocument in [false, true]) {
        final gate = Completer<PickedRecordText?>();
        await tester.pumpWidget(
          ChessNextApp(
            key: UniqueKey(),
            filePicker: MemoryRecordPicker(() => gate.future),
          ),
        );
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        session.playMove(Move.parse('c3c4'));
        await tap(tester, find.text('导入文件'));
        await tester.tap(find.text('选择文件'));
        await tester.pump();
        if (changeDocument) {
          session.newGame();
        } else {
          session.navigate('n0');
        }
        final changed = session.tree;
        gate.complete(fixture);
        await pumpUntil(
          tester,
          () => find.textContaining('PGN · 1着').evaluate().isNotEmpty,
        );
        await tap(tester, find.text('导入'));
        expect(session.tree, same(changed));
        expect(find.text('导入期间棋谱已变化，请重新导入。'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'native cancel keeps preview; new malformed selection invalidates old preview; retry works',
    (tester) async {
      desktop(tester);
      var attempt = 0;
      final picker = MemoryRecordPicker(
        () async => switch (attempt++) {
          0 => fixture,
          1 => null,
          2 => const PickedRecordText(
            displayName: '坏.pgn',
            text: '[Game "Chinese Chess"]\n[Format "WXF"]\n*',
          ),
          _ => fixture,
        },
      );
      await tester.pumpWidget(ChessNextApp(filePicker: picker));
      await tester.pumpAndSettle();
      await load(tester);
      await tap(tester, find.text('选择文件'));
      expect(find.textContaining('PGN · 1着'), findsOneWidget);
      await tester.tap(find.text('选择文件'));
      await pumpUntil(
        tester,
        () => find.textContaining('暂不支持PGN的WXF').evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '导入'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('选择文件'));
      await pumpUntil(
        tester,
        () => find.textContaining('PGN · 1着').evaluate().isNotEmpty,
      );
      expect(picker.calls, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('typed failure is visible and cannot replace original document', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(
      ChessNextApp(
        filePicker: MemoryRecordPicker(
          () async =>
              throw const RecordFileException(RecordFileFailure.encoding),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final session = tester
        .widget<XiangqiBoard>(find.byType(XiangqiBoard))
        .session;
    final before = session.tree;
    await tap(tester, find.text('导入文件'));
    await tap(tester, find.text('选择文件'));
    expect(find.textContaining('请先转换编码'), findsOneWidget);
    expect(session.tree, same(before));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '导入'))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'cancel or Escape discards late choice and parsing, never closing another route',
    (tester) async {
      desktop(tester);
      for (final cancelDuringParse in [false, true]) {
        final fileGate = Completer<PickedRecordText?>();
        final parseGate = Completer<ImportedRecord>();
        final navigator = GlobalKey<NavigatorState>();
        var parses = 0;
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            navigatorKey: navigator,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<ImportedRecord>(
                    context: context,
                    builder: (_) => ImportFileDialog(
                      picker: MemoryRecordPicker(() => fileGate.future),
                      importer: (_) {
                        parses++;
                        return parseGate.future;
                      },
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        );
        await tap(tester, find.text('打开'));
        await tester.tap(find.text('选择文件'));
        await tester.pump();
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, '选择文件'),
              )
              .onPressed,
          isNull,
        );
        if (cancelDuringParse) {
          fileGate.complete(fixture);
          await tester.pump();
          expect(parses, 1);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          await tester.tap(find.text('取消'));
        }
        unawaited(
          showDialog<void>(
            context: navigator.currentContext!,
            builder: (_) => const AlertDialog(content: Text('另一窗口')),
          ),
        );
        if (cancelDuringParse) {
          parseGate.completeError(const FormatException('迟到错误'));
        } else {
          fileGate.complete(fixture);
        }
        await tester.pumpAndSettle();
        expect(find.text('另一窗口'), findsOneWidget);
        expect(find.text('迟到错误'), findsNothing);
        expect(parses, cancelDuringParse ? 1 : 0);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'file dialog scrolls at 200 percent text and keyboard cancel remains available',
    (tester) async {
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<ImportedRecord>(
                  context: context,
                  builder: (_) => ImportFileDialog(
                    picker: MemoryRecordPicker(() async => null),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      await tap(tester, find.text('选择文件'));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ImportFileDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
