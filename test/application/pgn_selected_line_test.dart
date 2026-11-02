import 'dart:io';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/branched_record.dart';

void main() {
  test(
    'PGN includes selected future, preserves metadata and comments, and can explicitly stop at cursor',
    () {
      var tree = branchedRecord().annotate('选定终点');
      tree = tree.goTo('n1').annotate('当前评注');
      final original = tree.toJson(), anchor = tree.lineAnchorId;
      final metadata = GameMetadata({
        'Event': '完整线路自制',
        'Custom': '保留',
        'Result': '0-1',
      });
      for (final format in [
        TextExportFormat.pgnIccs,
        TextExportFormat.pgnChinese,
      ]) {
        PgnRecord render(GameTree source, {bool future = true}) =>
            PgnCodec.parse(
              RecordTextExchange.exportText(
                source,
                metadata,
                format,
                includeFuture: future,
              ),
            );
        final full = render(tree);
        expect(full.tree.path.skip(1).map((n) => n.move.toString()), [
          'b2e2',
          'b9c7',
          'h2h4',
        ]);
        expect(full.tree.current.comment, '选定终点');
        expect(full.tree.node('n1').comment, '当前评注');
        expect(full.tags['Event'], '完整线路自制');
        expect(full.tags['Custom'], '保留');
        expect(full.result, '0-1');
        expect(render(tree, future: false).tree.nodeCount, 2);
        expect(render(tree.goTo('n0')).tree.nodeCount, 4);
        expect(render(tree.goTo('n5')).tree.nodeCount, 4);
        final other = render(tree.goTo('n3'));
        expect(other.tree.path.skip(1).map((n) => n.move.toString()), [
          'b2e2',
          'b9c7',
          'b0c2',
          'h9g7',
        ]);
        expect(other.tree.path.any((n) => n.comment == '选定终点'), isFalse);
        final noComments = PgnCodec.parse(
          RecordTextExchange.exportText(
            tree,
            metadata,
            format,
            includeComments: false,
          ),
        );
        expect(noComments.tree.path.every((n) => n.comment.isEmpty), isTrue);
        expect(noComments.tree.nodeCount, 4);
      }
      expect(tree.toJson(), original);
      expect(tree.lineAnchorId, anchor);
      expect(tree.cursorId, 'n1');
    },
  );
  test(
    'E33 future-line export matches observed moves and plain formats remain current-path scoped',
    () async {
      final reference = PgnCodec.parse(
        await File('docs/research/samples/E33-before.pgn').readAsString(),
      );
      final tree = reference.tree.goTo('n3');
      final full = PgnCodec.parse(
        RecordTextExchange.exportText(
          tree,
          GameMetadata(reference.tags),
          TextExportFormat.pgnIccs,
        ),
      );
      expect(
        full.tree.path.skip(1).map((n) => n.move.toString()),
        reference.tree.path.skip(1).map((n) => n.move.toString()),
      );
      expect(full.tree.nodeCount, 6);
      final partial = PgnCodec.parse(
        RecordTextExchange.exportText(
          tree,
          GameMetadata.empty,
          TextExportFormat.pgnIccs,
          includeFuture: false,
        ),
      );
      expect(partial.tree.nodeCount, 4);
      for (final format in [
        TextExportFormat.fen,
        TextExportFormat.uci,
        TextExportFormat.chinese,
      ]) {
        final defaultText = RecordTextExchange.exportText(
          tree,
          GameMetadata.empty,
          format,
        );
        expect(
          defaultText,
          RecordTextExchange.exportText(
            tree,
            GameMetadata.empty,
            format,
            includeFuture: false,
          ),
        );
        if (format != TextExportFormat.fen) {
          expect(TextRecord.parse(defaultText).nodeCount, 4);
        } else {
          expect(
            Position.fromFen(defaultText).toFen(),
            tree.current.position.toFen(),
          );
        }
      }
    },
  );
}
