import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;

import 'package:chess_next/adapters/storage/file_piece_image_repository.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/application/piece_image_validator.dart';
import 'package:chess_next/ports/piece_images.dart';

Uint8List png({int width = 2, int height = 2}) => Uint8List.fromList(
  raster.encodePng(raster.Image(width: width, height: height)),
);

class _Picker implements PieceImagePicker {
  _Picker(this.value);
  SelectedPieceImage? value;
  @override
  Future<SelectedPieceImage?> pickImage() async => value;
}

void main() {
  group('PieceImageValidator', () {
    test('accepts PNG and JPEG with valid dimensions', () {
      PieceImageValidator.validate(SelectedPieceImage('png', png()));
      final jpeg = raster.encodeJpg(raster.Image(width: 2, height: 2));
      PieceImageValidator.validate(
        SelectedPieceImage('jpg', Uint8List.fromList(jpeg)),
      );
    });

    test('rejects unsupported, malformed, oversized and huge images', () {
      expect(
        () => PieceImageValidator.validate(SelectedPieceImage('gif', png())),
        throwsA(isA<PieceImageException>()),
      );
      expect(
        () => PieceImageValidator.validate(
          SelectedPieceImage('png', Uint8List(0)),
        ),
        throwsA(isA<PieceImageException>()),
      );
      expect(
        () => PieceImageValidator.validate(
          SelectedPieceImage('png', Uint8List(PieceImageLimits.maxBytes + 1)),
        ),
        throwsA(isA<PieceImageException>()),
      );
      expect(
        () => PieceImageValidator.validate(
          SelectedPieceImage('png', png(width: 1025)),
        ),
        throwsA(isA<PieceImageException>()),
      );
    });
  });

  test(
    'controller replaces, restores, and rejects without losing prior image',
    () async {
      final repository = MemoryPieceImageRepository();
      final picker = _Picker(SelectedPieceImage('png', png()));
      final controller = PieceImageLibraryController(picker, repository);
      await controller.initialize();
      expect(
        await controller.replace(PieceSkin.roundSeal, PieceImageSlot.redRook),
        isTrue,
      );
      final original = controller.imageFor(
        PieceSkin.roundSeal,
        PieceImageSlot.redRook,
      );
      picker.value = SelectedPieceImage('png', Uint8List.fromList([1, 2, 3]));
      expect(
        await controller.replace(PieceSkin.roundSeal, PieceImageSlot.redRook),
        isFalse,
      );
      expect(
        controller.imageFor(PieceSkin.roundSeal, PieceImageSlot.redRook),
        original,
      );
      expect(
        await controller.reset(PieceSkin.roundSeal, PieceImageSlot.redRook),
        isTrue,
      );
      expect(
        controller.imageFor(PieceSkin.roundSeal, PieceImageSlot.redRook),
        isNull,
      );
      controller.dispose();
    },
  );

  test('file repository round-trips and removes a validated image', () async {
    final temp = await Directory.systemTemp.createTemp(
      'chessnext-piece-images-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final repository = FilePieceImageRepository(() async => temp);
    final bytes = png();
    await repository.save(
      PieceSkin.squareInk,
      PieceImageSlot.blackHorse,
      'png',
      bytes,
    );
    final loaded = await repository.load();
    expect(
      loaded[PieceSkin.squareInk]![PieceImageSlot.blackHorse],
      orderedEquals(bytes),
    );
    await repository.remove(PieceSkin.squareInk, PieceImageSlot.blackHorse);
    expect((await repository.load()).containsKey(PieceSkin.squareInk), isFalse);
  });
}
