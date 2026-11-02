import 'package:chess_next/app.dart';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/record_file_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/branched_record.dart';
import '../support/memory_clipboard.dart';

class LineExporter implements RecordFileExporter {
  final texts = <String>[];
  @override
  Future<RecordFileExportResult> saveText({
    required String text,
    required String extension,
    required FileExportCancellation cancellation,
  }) async {
    texts.add(text);
    return RecordFileExportResult.saved;
  }
}

void main() {
  void desktop(WidgetTester t) {
    t.view.physicalSize = const Size(1120, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> choose(WidgetTester t, String label) async {
    await tap(t, find.byKey(const ValueKey('export-format')));
    await tap(t, find.text(label).last);
  }

  testWidgets(
    '200 percent range option keeps copy and file identical and freezes future and metadata at opening',
    (t) async {
      desktop(t);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final clipboard = MemoryClipboard(), writer = LineExporter();
      await t.pumpWidget(
        ChessNextApp(clipboard: clipboard, fileExporter: writer),
      );
      await t.pumpAndSettle();
      final session = t.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session;
      session.replaceTree(
        branchedRecord().annotate('开窗未来').goTo('n1'),
        metadata: GameMetadata({'Event': '开窗赛事'}),
      );
      await t.pumpAndSettle();
      final snapshot = session.tree, metadata = session.metadata;
      await tap(t, find.text('导出文字'));
      session.navigate('n4');
      session.annotate('之后变化');
      session.updateMetadata(GameMetadata({'Event': '之后赛事'}));
      final source = session.tree, revision = session.revision;
      await choose(t, 'PGN（ICCS）');
      expect(
        t
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('pgn-include-future')),
            )
            .value,
        isTrue,
      );
      Future<void> check(
        int nodes,
        TextExportFormat format, {
        bool future = true,
      }) async {
        await tap(t, find.widgetWithText(FilledButton, '复制'));
        await tap(t, find.text('保存文件'));
        expect(clipboard.text, writer.texts.last);
        expect(
          writer.texts.last,
          RecordTextExchange.exportText(
            snapshot,
            metadata,
            format,
            includeFuture: future,
          ),
        );
        final parsed = PgnCodec.parse(writer.texts.last);
        expect(parsed.tree.nodeCount, nodes);
        expect(parsed.tags['Event'], '开窗赛事');
      }

      await check(4, TextExportFormat.pgnIccs);
      await tap(t, find.byKey(const ValueKey('pgn-include-future')));
      await check(2, TextExportFormat.pgnIccs, future: false);
      await choose(t, 'PGN（中文）');
      await check(2, TextExportFormat.pgnChinese, future: false);
      await tap(t, find.byKey(const ValueKey('pgn-include-future')));
      await check(4, TextExportFormat.pgnChinese);
      await tap(t, find.text('关闭'));
      expect(session.tree, same(source));
      expect(session.revision, revision);
      expect(session.dirty, isTrue);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'an unrepresentable future comment is never silently dropped; explicit range or comments can recover',
    (t) async {
      desktop(t);
      final clipboard = MemoryClipboard(), writer = LineExporter();
      await t.pumpWidget(
        ChessNextApp(clipboard: clipboard, fileExporter: writer),
      );
      await t.pumpAndSettle();
      final session = t.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session;
      session.replaceTree(branchedRecord().annotate('未来{不能无损}').goTo('n1'));
      await t.pumpAndSettle();
      final source = session.tree;
      await tap(t, find.text('导出文字'));
      await choose(t, 'PGN（ICCS）');
      expect(find.byKey(const ValueKey('export-text')), findsNothing);
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, '复制'))
            .onPressed,
        isNull,
      );
      await tap(t, find.byKey(const ValueKey('pgn-include-future')));
      await tap(t, find.text('保存文件'));
      expect(PgnCodec.parse(writer.texts.last).tree.nodeCount, 2);
      await tap(t, find.byKey(const ValueKey('pgn-include-future')));
      expect(find.byKey(const ValueKey('export-text')), findsNothing);
      await tap(t, find.text('包含路径评注'));
      await tap(t, find.widgetWithText(FilledButton, '复制'));
      await tap(t, find.text('保存文件'));
      expect(clipboard.text, writer.texts.last);
      final full = PgnCodec.parse(writer.texts.last);
      expect(full.tree.nodeCount, 4);
      expect(full.tree.current.comment, isEmpty);
      expect(session.tree, same(source));
      expect(source.node('n5').comment, '未来{不能无损}');
      expect(t.takeException(), isNull);
    },
  );
}
