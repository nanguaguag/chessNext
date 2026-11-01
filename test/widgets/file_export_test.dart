import 'dart:async';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/transfer/text_transfer_dialog.dart';
import 'package:chess_next/ports/record_file_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/memory_clipboard.dart';

class RecordingExporter implements RecordFileExporter {
  final calls =
      <({String text, String extension, FileExportCancellation token})>[];
  Future<RecordFileExportResult> Function(FileExportCancellation)? handler;
  @override
  Future<RecordFileExportResult> saveText({
    required String text,
    required String extension,
    required FileExportCancellation cancellation,
  }) async {
    calls.add((text: text, extension: extension, token: cancellation));
    return handler == null
        ? RecordFileExportResult.saved
        : handler!(cancellation);
  }
}

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

  Future<void> choose(WidgetTester tester, String label) async {
    await tap(tester, find.byKey(const ValueKey('export-format')));
    await tap(tester, find.text(label).last);
  }

  testWidgets(
    'all five formats save the opened snapshot and leave dirty document untouched',
    (tester) async {
      desktop(tester);
      final exporter = RecordingExporter();
      await tester.pumpWidget(ChessNextApp(fileExporter: exporter));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.playMove(Move.parse('h2e2'));
      session.annotate('炮评');
      session.updateMetadata(GameMetadata({'Event': '开窗时资料'}));
      final snapshot = session.tree, metadata = session.metadata;
      await tap(tester, find.text('导出文字'));
      session.playMove(Move.parse('b9c7'));
      session.updateMetadata(session.metadata.copyWith({'Event': '后来资料'}));
      final revision = session.revision;
      final options = [
        ('当前局面FEN', TextExportFormat.fen, 'fen'),
        ('FEN + 着法', TextExportFormat.uci, 'txt'),
        ('中文棋谱', TextExportFormat.chinese, 'txt'),
        ('PGN（ICCS）', TextExportFormat.pgnIccs, 'pgn'),
        ('PGN（中文）', TextExportFormat.pgnChinese, 'pgn'),
      ];
      for (final (label, format, extension) in options) {
        await choose(tester, label);
        await tap(tester, find.text('保存文件'));
        final call = exporter.calls.last;
        expect(call.extension, extension);
        expect(
          call.text,
          RecordTextExchange.exportText(snapshot, metadata, format),
        );
        expect(find.text('文件已保存'), findsOneWidget);
      }
      expect(session.revision, revision);
      expect(session.dirty, isTrue);
      expect(session.tree.nodeCount, 3);
      expect(session.metadata.tags['Event'], '后来资料');
    },
  );
  testWidgets(
    'unrepresentable PGN blocks saving until comments are explicitly omitted',
    (tester) async {
      desktop(tester);
      final exporter = RecordingExporter();
      await tester.pumpWidget(ChessNextApp(fileExporter: exporter));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.annotate('不能无损{原文}');
      await tap(tester, find.text('导出文字'));
      await choose(tester, 'PGN（ICCS）');
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '保存文件'))
            .onPressed,
        isNull,
      );
      expect(exporter.calls, isEmpty);
      await tap(tester, find.text('包含路径评注'));
      await tap(tester, find.text('保存文件'));
      expect(
        PgnCodec.parse(exporter.calls.single.text).tree.root.comment,
        isEmpty,
      );
      expect(session.tree.root.comment, '不能无损{原文}');
    },
  );
  testWidgets(
    'cancel and failed write are distinct, retry works with no document changes',
    (tester) async {
      desktop(tester);
      final exporter = RecordingExporter();
      var count = 0;
      exporter.handler = (_) async {
        if (count++ == 0) return RecordFileExportResult.cancelled;
        if (count == 2) {
          throw const RecordExportException(RecordExportFailure.write);
        }
        return RecordFileExportResult.saved;
      };
      await tester.pumpWidget(ChessNextApp(fileExporter: exporter));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final before = session.tree;
      await tap(tester, find.text('导出文字'));
      for (final expected in [
        '已取消文件保存',
        const RecordExportException(RecordExportFailure.write).message,
        '文件已保存',
      ]) {
        await tap(tester, find.text('保存文件'));
        expect(find.text(expected), findsOneWidget);
      }
      expect(session.tree, same(before));
      expect(session.dirty, isFalse);
    },
  );
  testWidgets(
    'busy export freezes format and copy; closing cancels a late destination',
    (tester) async {
      desktop(tester);
      final exporter = RecordingExporter();
      final gate = Completer<RecordFileExportResult>();
      exporter.handler = (_) => gate.future;
      await tester.pumpWidget(ChessNextApp(fileExporter: exporter));
      await tester.pumpAndSettle();
      await tap(tester, find.text('导出文字'));
      await tester.tap(find.text('保存文件'));
      await tester.pump();
      expect(
        tester
            .widget<DropdownButtonFormField<TextExportFormat>>(
              find.byKey(const ValueKey('export-format')),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '复制'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '保存文件'))
            .onPressed,
        isNull,
      );
      expect(exporter.calls.single.token.isCancelled, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(exporter.calls.single.token.isCancelled, isTrue);
      // A second route is allowed during the first route's fade-out.
      final context = tester.element(find.byType(XiangqiBoard));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('另一个窗口')),
        ),
      );
      gate.completeError(
        const RecordExportException(RecordExportFailure.write),
      );
      await tester.pumpAndSettle();
      expect(find.text('另一个窗口'), findsOneWidget);
      expect(
        find.text(
          const RecordExportException(RecordExportFailure.write).message,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('save and copy remain reachable with 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final exporter = RecordingExporter();
    final clipboard = MemoryClipboard();
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
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ExportTextDialog(
                  tree: GameTree(),
                  clipboard: clipboard,
                  fileExporter: exporter,
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tap(tester, find.text('打开'));
    await tap(tester, find.text('保存文件'));
    await tap(tester, find.text('复制'));
    expect(exporter.calls.single.text, clipboard.text);
    expect(tester.takeException(), isNull);
  });
}
