import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test(
    'E20 self-created reference PGN parses and semantically roundtrips',
    () async {
      final text = await File(
        'docs/research/samples/E20-self-created-iccs.pgn',
      ).readAsString();
      final record = PgnCodec.parse(text);
      expect(record.tree.path.skip(1).map((n) => n.move.toString()), [
        'b2e2',
        'b9c7',
        'h2h4',
      ]);
      expect(record.tree.nodeCount, 4);
      expect(record.tags['Format'], 'ICCS');
      final restored = PgnCodec.parse(PgnCodec.path(record));
      expect(
        restored.tree.current.position.toFen(),
        record.tree.current.position.toFen(),
      );
      expect(restored.tags, record.tags);
    },
  );
}
