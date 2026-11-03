import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as raster;

import 'package:chess_next/adapters/storage/file_piece_image_repository.dart';
import 'package:chess_next/adapters/platform/file_selector_piece_image_picker.dart';
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

class _BatchPicker implements PieceImagePicker, PieceImageBatchPicker {
  _BatchPicker(this.images);
  final List<NamedPieceImage> images;
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
  @override
  Future<List<NamedPieceImage>?> pickImages() async => images;
}

class _FailingBatchRepository extends MemoryPieceImageRepository {
  int saves = 0;
  @override
  Future<void> save(
    String skin,
    PieceImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    saves++;
    if (saves == 2) throw const PieceImageException(PieceImageFailure.write);
    await super.save(skin, slot, extension, bytes);
  }
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
      PieceSkin.squareInk.name,
      PieceImageSlot.blackHorse,
      'png',
      bytes,
    );
    final loaded = await repository.load();
    expect(
      loaded[PieceSkin.squareInk.name]![PieceImageSlot.blackHorse],
      orderedEquals(bytes),
    );
    await repository.remove(
      PieceSkin.squareInk.name,
      PieceImageSlot.blackHorse,
    );
    expect(
      (await repository.load()).containsKey(PieceSkin.squareInk.name),
      isFalse,
    );
  });

  test(
    'batch picker reads multiple named images and enforces count limit',
    () async {
      final bytes = png();
      final temp = await Directory.systemTemp.createTemp('piece-image-batch-');
      addTearDown(() => temp.delete(recursive: true));
      final rookPath = '${temp.path}/红车.png';
      final horsePath = '${temp.path}/blackHorse.jpg';
      await File(rookPath).writeAsBytes(bytes);
      await File(horsePath).writeAsBytes(bytes);
      final picker = FileSelectorPieceImagePicker(
        batchChooser: (_) async => [XFile(rookPath), XFile(horsePath)],
      );
      final images = await picker.pickImages();
      expect(images!.map((file) => file.name), ['红车.png', 'blackHorse.jpg']);
      expect(images.map((file) => file.image.extension), ['png', 'jpg']);
      expect(images, hasLength(2));

      final excessive = FileSelectorPieceImagePicker(
        batchChooser: (_) async => [
          for (var i = 0; i <= PieceImageLimits.maxBatchFiles; i++)
            XFile(rookPath),
        ],
      );
      await expectLater(
        excessive.pickImages(),
        throwsA(
          isA<PieceImageException>().having(
            (error) => error.failure,
            'failure',
            PieceImageFailure.batchLimit,
          ),
        ),
      );
    },
  );

  test(
    'batch import validates all first and reports partial storage failure',
    () async {
      final image = SelectedPieceImage('png', png());
      final picker = _BatchPicker([
        NamedPieceImage(name: '红车.png', image: image),
        NamedPieceImage(name: '黑马.png', image: image),
      ]);
      final repository = _FailingBatchRepository();
      final controller = PieceImageLibraryController(picker, repository);
      await controller.initialize();
      final selected = await controller.pickBatchImages();
      expect(selected, hasLength(2));
      final invalid = await controller.importBatch(PieceSkin.roundSeal, {
        PieceImageSlot.redRook: image,
        PieceImageSlot.blackHorse: SelectedPieceImage(
          'png',
          Uint8List.fromList([1]),
        ),
      });
      expect(invalid, 0);
      expect(
        repository.saves,
        0,
        reason: 'validate the entire batch before writes',
      );

      final imported = await controller.importBatch(PieceSkin.roundSeal, {
        PieceImageSlot.redRook: image,
        PieceImageSlot.blackHorse: image,
      });
      expect(imported, 1);
      expect(
        controller.imageFor(PieceSkin.roundSeal, PieceImageSlot.redRook),
        isNotNull,
      );
      expect(
        controller.imageFor(PieceSkin.roundSeal, PieceImageSlot.blackHorse),
        isNull,
      );
      expect(controller.error, contains('已导入1张'));
      final retried = await controller.importBatch(PieceSkin.roundSeal, {
        PieceImageSlot.redRook: image,
        PieceImageSlot.blackHorse: image,
      });
      expect(retried, 2);
      expect(repository.saves, 3, reason: 'retry skips the saved slot');
      expect(controller.batchImportedCount, 2);
      expect(controller.error, isNull);
      controller.dispose();
    },
  );
}
