import 'dart:io';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test(
    'actual worker transfers legal tree and every normalized metadata tag',
    () async {
      final text = await File(
        'docs/research/samples/E20-self-created-iccs.pgn',
      ).readAsString();
      final imported = await RecordTextExchange.parseInWorker(text);
      expect(imported.source, TextSourceFormat.pgn);
      expect(imported.tree.nodeCount, 4);
      expect(imported.metadata.tags, PgnCodec.parse(text).tags);
      expect(imported.tree.current.move, Move.parse('h2h4'));
    },
  );
  test(
    'worker preserves unicode metadata and comments and returns typed format errors',
    () async {
      const text =
          '[Game "Chinese Chess"]\n[Event "自制😀"]\n[Custom "保留\uFEFF标记"]\n1. 炮二平五 {保留评注} *';
      final imported = await RecordTextExchange.parseInWorker(text);
      expect(imported.metadata.tags['Event'], '自制😀');
      expect(imported.metadata.tags['Custom'], '保留\uFEFF标记');
      expect(imported.tree.current.comment, '保留评注');
      await expectLater(
        RecordTextExchange.parseInWorker('[Game "Chinese Chess"]\n1. 不支持 *'),
        throwsFormatException,
      );
      await expectLater(
        RecordTextExchange.parseInWorker('x' * 64001),
        throwsFormatException,
      );
    },
  );
  test(
    'plain formats remain compatible with empty metadata in both sync and worker paths',
    () async {
      for (final text in ['startpos moves h2e2 b9c7', '1. 炮二平五 马２进３']) {
        final imported = await RecordTextExchange.parseInWorker(text);
        expect(imported.source, TextSourceFormat.plain);
        expect(imported.metadata.isEmpty, isTrue);
        expect(
          imported.tree.current.position.toFen(),
          TextRecord.parse(text).current.position.toFen(),
        );
      }
    },
  );
  test(
    'export regenerates derived fields and preserves document result and opaque metadata',
    () {
      final tree = GameTree().play(Move.parse('h2e2')).annotate('中文注释');
      final metadata = GameMetadata({
        'Game': 'Chinese Chess',
        'FEN': '原始标签',
        'Format': '旧格式',
        'Event': '事件',
        'Custom': '保留',
        'Result': '1-0',
      });
      for (final format in [
        TextExportFormat.pgnIccs,
        TextExportFormat.pgnChinese,
      ]) {
        final text = RecordTextExchange.exportText(tree, metadata, format);
        final parsed = PgnCodec.parse(text);
        expect(parsed.result, '1-0');
        expect(parsed.tags['Event'], '事件');
        expect(parsed.tags['Custom'], '保留');
        expect(parsed.tags['FEN'], tree.root.position.toFen());
        expect(parsed.tree.current.comment, '中文注释');
        expect(
          parsed.tags['Format'],
          format == TextExportFormat.pgnIccs ? 'ICCS' : 'Chinese',
        );
      }
      expect(metadata.tags['FEN'], '原始标签');
    },
  );
  test(
    'path scope and explicit comment omission stay consistent across UI formats',
    () {
      var tree = GameTree().play(Move.parse('h2e2')).play(Move.parse('b9c7'));
      tree = tree.goTo('n0').play(Move.parse('b2e2')).annotate('含{花括号}');
      final text = RecordTextExchange.exportText(
        tree,
        GameMetadata.empty,
        TextExportFormat.uci,
      );
      expect(TextRecord.parse(text).nodeCount, 2);
      expect(
        () => RecordTextExchange.exportText(
          tree,
          GameMetadata.empty,
          TextExportFormat.pgnIccs,
        ),
        throwsFormatException,
      );
      final pgn = RecordTextExchange.exportText(
        tree,
        GameMetadata.empty,
        TextExportFormat.pgnIccs,
        includeComments: false,
      );
      expect(PgnCodec.parse(pgn).tree.current.comment, isEmpty);
      expect(PgnCodec.parse(pgn).tree.nodeCount, 2);
    },
  );
}
