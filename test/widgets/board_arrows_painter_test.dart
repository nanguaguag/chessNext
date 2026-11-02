import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

Future<Uint8List> raster(BoardArrowsPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const ui.Size(450, 500));
  final picture = recorder.endRecording();
  final image = await picture.toImage(450, 500);
  try {
    return (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final move = Move.parse('h2e2');
  test(
    'actual pixels show ordered head widths while common shaft stays identical',
    () async {
      final counts = <int>[], shafts = <List<int>>[];
      for (final style in ArrowHeadStyle.values) {
        final bytes = await raster(
          BoardArrowsPainter(recommendation: move, headStyle: style),
        );
        counts.add(
          [
            for (var i = 3; i < bytes.length; i += 4)
              if (bytes[i] > 0) 1,
          ].length,
        );
        shafts.add([
          for (var y = 370; y <= 380; y++)
            for (var x = 295; x <= 305; x++)
              ...bytes.sublist((y * 450 + x) * 4, (y * 450 + x) * 4 + 4),
        ]);
      }
      expect(counts[0], lessThan(counts[1]));
      expect(counts[1], lessThan(counts[2]));
      expect(shafts[0], shafts[1]);
      expect(shafts[1], shafts[2]);
    },
  );
  test(
    'raster follows all four grid orientations and has no output without PV',
    () async {
      for (final (flipped, mirrored, x, y) in [
        (false, false, 300, 375),
        (false, true, 150, 375),
        (true, false, 150, 125),
        (true, true, 300, 125),
      ]) {
        final pixels = await raster(
          BoardArrowsPainter(
            recommendation: move,
            flipped: flipped,
            mirrored: mirrored,
          ),
        );
        expect(pixels[(y * 450 + x) * 4 + 3], greaterThan(0));
        expect(pixels[((500 - y) * 450 + x) * 4 + 3], 0);
      }
      final blank = await raster(const BoardArrowsPainter());
      expect(blank.any((value) => value != 0), isFalse);
    },
  );
  test(
    'both colored arrows paint and a style-only change requests repaint',
    () async {
      final reply = Move.parse('b9c7');
      final pixels = await raster(
        BoardArrowsPainter(recommendation: move, reply: reply),
      );
      var blue = false, purple = false;
      for (var i = 0; i < pixels.length; i += 4) {
        if (pixels[i + 3] != 255) continue;
        blue |=
            pixels[i] == 0x22 && pixels[i + 1] == 0x6b && pixels[i + 2] == 0x9c;
        purple |=
            pixels[i] == 0x96 && pixels[i + 1] == 0x5b && pixels[i + 2] == 0xa3;
      }
      expect(blue, isTrue);
      expect(purple, isTrue);
      final old = BoardArrowsPainter(recommendation: move, reply: reply);
      expect(
        BoardArrowsPainter(
          recommendation: move,
          reply: reply,
        ).shouldRepaint(old),
        isFalse,
      );
      expect(
        BoardArrowsPainter(
          recommendation: move,
          reply: reply,
          headStyle: ArrowHeadStyle.wide,
        ).shouldRepaint(old),
        isTrue,
      );
    },
  );
}
