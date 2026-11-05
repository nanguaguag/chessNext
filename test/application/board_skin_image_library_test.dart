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
          BoardSkin.parchment.name,
          BoardSkinImageSlot.boardBackground,
        ),
        isTrue,
      );
      final original = controller.imageFor(
        BoardSkin.parchment.name,
        BoardSkinImageSlot.boardBackground,
      );
      picker.value = SelectedPieceImage('png', Uint8List.fromList([1, 2, 3]));
      expect(
        await controller.replace(
          BoardSkin.parchment.name,
          BoardSkinImageSlot.boardBackground,
        ),
        isFalse,
      );
      expect(
        controller.imageFor(
          BoardSkin.parchment.name,
          BoardSkinImageSlot.boardBackground,
        ),
        original,
      );
      expect(
        await controller.reset(
          BoardSkin.parchment.name,
          BoardSkinImageSlot.boardBackground,
        ),
        isTrue,
      );
      expect(
        controller.imageFor(
          BoardSkin.parchment.name,
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
      BoardSkin.jade.name,
      BoardSkinImageSlot.selectionFrame,
      'png',
      bytes,
    );
    expect(
      (await repository
          .load())[BoardSkin.jade.name]![BoardSkinImageSlot.selectionFrame],
      orderedEquals(bytes),
    );
    await repository.remove(
      BoardSkin.jade.name,
      BoardSkinImageSlot.selectionFrame,
    );
    expect((await repository.load()).containsKey(BoardSkin.jade.name), isFalse);
  });

  test(
    'file repository prunes orphaned and empty custom skin directories',
    () async {
      final temp = await Directory.systemTemp.createTemp('chessnext-board-');
      addTearDown(() => temp.delete(recursive: true));
      final repository = FileBoardSkinImageRepository(() async => temp);
      const retainedId = 'custom-12345678-abcd';
      const abandonedId = 'custom-87654321-dead';
      const emptyAbandonedId = 'custom-11111111-beef';
      final bytes = _png();
      await repository.save(
        retainedId,
        BoardSkinImageSlot.landingMarker,
        'png',
        bytes,
      );
      await repository.save(
        abandonedId,
        BoardSkinImageSlot.boardBackground,
        'png',
        bytes,
      );
      final emptyFolder = Directory(
        '${temp.path}/chessnext-board-skin-images/$emptyAbandonedId',
      );
      await emptyFolder.create(recursive: true);
      await repository.save(
        BoardSkin.parchment.name,
        BoardSkinImageSlot.startMarker,
        'png',
        bytes,
      );

      await repository.pruneCustomSkins({retainedId});

      final loaded = await repository.load();
      expect(loaded.keys, containsAll([retainedId, BoardSkin.parchment.name]));
      expect(loaded.containsKey(abandonedId), isFalse);
      expect(
        await Directory(
          '${temp.path}/chessnext-board-skin-images/$emptyAbandonedId',
        ).exists(),
        isFalse,
      );
    },
  );

  test(
    'file image repository clones and removes a custom skin by id',
    () async {
      final temp = await Directory.systemTemp.createTemp('chessnext-board-');
      addTearDown(() => temp.delete(recursive: true));
      final repository = FileBoardSkinImageRepository(() async => temp);
      final bytes = _png();
      await repository.save(
        BoardSkin.parchment.name,
        BoardSkinImageSlot.boardBackground,
        'png',
        bytes,
      );
      const customId = 'custom-12345678-abcd';
      await repository.cloneSkin(BoardSkin.parchment.name, customId);
      expect(
        (await repository
            .load())[customId]![BoardSkinImageSlot.boardBackground],
        orderedEquals(bytes),
      );
      await repository.removeSkin(customId);
      expect((await repository.load()).containsKey(customId), isFalse);
      expect(
        (await repository.load()).containsKey(BoardSkin.parchment.name),
        isTrue,
      );
    },
  );
}
