import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;

import 'package:chess_next/adapters/storage/file_board_skin_image_repository.dart';
import 'package:chess_next/application/board_skin_image_library_controller.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/piece_images.dart';

Uint8List _png() =>
    Uint8List.fromList(raster.encodePng(raster.Image(width: 2, height: 2)));

class _Picker implements PieceImagePicker {
  _Picker(this.value);
  SelectedPieceImage? value;

  @override
  Future<SelectedPieceImage?> pickImage() async => value;
}

void main() {
  test(
    'controller replaces, rejects invalid image, and resets a layer',
    () async {
      final repository = MemoryBoardSkinImageRepository();
      final picker = _Picker(SelectedPieceImage('png', _png()));
      final controller = BoardSkinImageLibraryController(picker, repository);
      await controller.initialize();

      expect(
        await controller.replace(
          BoardSkin.parchment,
          BoardSkinImageSlot.boardBackground,
        ),
        isTrue,
      );
      final original = controller.imageFor(
        BoardSkin.parchment,
        BoardSkinImageSlot.boardBackground,
      );
      picker.value = SelectedPieceImage('png', Uint8List.fromList([1, 2, 3]));
      expect(
        await controller.replace(
          BoardSkin.parchment,
          BoardSkinImageSlot.boardBackground,
        ),
        isFalse,
      );
      expect(
        controller.imageFor(
          BoardSkin.parchment,
          BoardSkinImageSlot.boardBackground,
        ),
        original,
      );
      expect(
        await controller.reset(
          BoardSkin.parchment,
          BoardSkinImageSlot.boardBackground,
        ),
        isTrue,
      );
      expect(
        controller.imageFor(
          BoardSkin.parchment,
          BoardSkinImageSlot.boardBackground,
        ),
        isNull,
      );
      controller.dispose();
    },
  );

  test('file repository round-trips and removes skin layers', () async {
    final temp = await Directory.systemTemp.createTemp('chessnext-board-');
    addTearDown(() => temp.delete(recursive: true));
    final repository = FileBoardSkinImageRepository(() async => temp);
    final bytes = _png();
    await repository.save(
      BoardSkin.jade,
      BoardSkinImageSlot.selectionFrame,
      'png',
      bytes,
    );
    expect(
      (await repository
          .load())[BoardSkin.jade]![BoardSkinImageSlot.selectionFrame],
      orderedEquals(bytes),
    );
    await repository.remove(BoardSkin.jade, BoardSkinImageSlot.selectionFrame);
    expect((await repository.load()).containsKey(BoardSkin.jade), isFalse);
  });
}
