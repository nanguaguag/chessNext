import 'dart:typed_data';

import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/application/board_skin_package_codec.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/board_skin_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;

Uint8List _png() =>
    Uint8List.fromList(raster.encodePng(raster.Image(width: 3, height: 3)));

void main() {
  test('round trips geometry and all four validated board image layers', () {
    final profile = BoardSkinDefinition(
      id: 'custom-12345678-abcd',
      name: '晚风棋盘',
      baseSkin: BoardSkin.jade,
      geometry: BoardSkinGeometry(
        leftPercent: 10,
        topPercent: 8,
        rightPercent: 90,
        bottomPercent: 92,
        pieceScalePercent: 112,
        rotateLandingMarker: true,
      ),
    );
    final images = {
      for (final slot in BoardSkinImageSlot.values) slot: _png(),
    };
    final decoded = BoardSkinPackageCodec.decode(
      BoardSkinPackageCodec.encode(profile, images),
    );
    expect(decoded.profile, profile);
    for (final slot in BoardSkinImageSlot.values) {
      expect(decoded.images[slot], orderedEquals(images[slot]!));
    }
  });

  test('rejects oversized and non-ZIP package bytes', () {
    expect(
      () => BoardSkinPackageCodec.decode(Uint8List(22)),
      throwsFormatException,
    );
    expect(
      () => BoardSkinPackageCodec.decode(
        Uint8List(BoardSkinPackageCodec.maxArchiveBytes + 1),
      ),
      throwsFormatException,
    );
  });
}
