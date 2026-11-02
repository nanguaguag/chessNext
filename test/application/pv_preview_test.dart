import '../support/pv_history_entry.dart';
import 'package:chess_next/application/pv_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test(
    'real worker replays a frozen legal PV and Chinese notation without changing source',
    () async {
      final entry = previewEntry(
        'h2e2 b9c7 b0c2 h9g7'.split(' ').map(Move.parse).toList(),
      );
      final fen = entry.position.toFen();
      final preview = await PvPreview.prepareInWorker(entry);
      expect(preview.positions.length, 5);
      expect(preview.notation.take(2), ['炮二平五', '马２进３']);
      var position = entry.position;
      for (var i = 0; i < entry.info.pv.length; i++) {
        position = position.play(entry.info.pv[i]);
        expect(preview.positions[i + 1].toFen(), position.toFen());
      }
      expect(entry.position.toFen(), fen);
      expect(() => preview.positions.clear(), throwsUnsupportedError);
      expect(() => preview.notation.clear(), throwsUnsupportedError);
      expect(preview.entry.epoch, 7);
    },
  );
  test(
    'illegal suffix rejects the entire preview through the worker error DTO',
    () async {
      final entry = previewEntry([Move.parse('h2e2'), Move.parse('h2h3')]);
      await expectLater(
        PvPreview.prepareInWorker(entry),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'step',
            contains('第2步'),
          ),
        ),
      );
      expect(entry.position.toFen(), Position.initial().toFen());
      expect(entry.info.pv.length, 2);
    },
  );
  test(
    'black source and 128-ply bound stay exact without pretending the omitted tail was checked',
    () async {
      final black = previewEntry([
        Move.parse('b9c7'),
      ], position: Position.initial().play(Move.parse('h2e2')));
      expect((await PvPreview.prepareInWorker(black)).notation.single, '马２进３');
      final cycle = 'b0c2 b9c7 c2b0 c7b9'.split(' ').map(Move.parse).toList();
      final entry = previewEntry(List.generate(140, (i) => cycle[i % 4]));
      final preview = await PvPreview.prepareInWorker(entry);
      expect(preview.length, 128);
      expect(preview.positions.length, 129);
      expect(preview.entry.originalPvLength, 140);
      expect(preview.entry.truncated, isTrue);
      expect(
        preview.positions.last.at(Square.parse('b0'))?.type,
        PieceType.horse,
      );
    },
  );
}
