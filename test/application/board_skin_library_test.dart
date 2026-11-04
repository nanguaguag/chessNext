import 'dart:io';
import 'dart:typed_data';

import 'package:chess_next/adapters/storage/file_board_skin_library_repository.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/application/board_skin_image_library_controller.dart';
import 'package:chess_next/application/board_skin_library_controller.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/board_skin_library.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;

Uint8List _png() =>
    Uint8List.fromList(raster.encodePng(raster.Image(width: 2, height: 2)));

void main() {
  test('board skin definitions validate identity and preserve geometry', () {
    final profile = BoardSkinDefinition(
      id: 'custom-12345678-abcd',
      name: '  我的棋盘  ',
      baseSkin: BoardSkin.jade,
      geometry: BoardSkinGeometry(
        leftPercent: 10,
        topPercent: 8,
        rightPercent: 90,
        bottomPercent: 92,
        pieceScalePercent: 110,
        rotateLandingMarker: true,
      ),
    );
    expect(profile.name, '我的棋盘');
    expect(BoardSkinDefinition.fromJson(profile.toJson()), profile);
    expect(
      () => BoardSkinDefinition(
        id: 'bad-id',
        name: 'broken',
        baseSkin: BoardSkin.parchment,
      ),
      throwsArgumentError,
    );
  });

  test(
    'file library round-trips, replaces atomically, and rejects duplicates',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'chessnext-board-library-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final repository = FileBoardSkinLibraryRepository(() async => temp);
      final first = BoardSkinDefinition(
        id: 'custom-12345678-abcd',
        name: '书房',
        baseSkin: BoardSkin.parchment,
      );
      await repository.save([first]);
      expect(await repository.load(), [first]);
      expect(
        () => repository.save([first, first.copyWith(name: '另一个')]),
        throwsFormatException,
      );
      expect(await repository.load(), [first]);
    },
  );

  test(
    'create clones current geometry and images; select, edit, and delete restore base',
    () async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      final repository = MemoryBoardSkinLibraryRepository();
      final imageRepository = MemoryBoardSkinImageRepository();
      final geometry = BoardSkinGeometry(
        leftPercent: 10,
        topPercent: 8,
        rightPercent: 90,
        bottomPercent: 92,
        pieceScalePercent: 110,
      );
      await imageRepository.save(
        BoardSkin.parchment.name,
        BoardSkinImageSlot.boardBackground,
        'png',
        _png(),
      );
      final boardImages = BoardSkinImageLibraryController(
        _NoopPicker(),
        imageRepository,
      );
      await boardImages.initialize();
      final library = BoardSkinLibraryController(
        repository,
        boardImages,
        preferences,
      );
      try {
        await preferences.initialize();
        await library.initialize();
        await preferences.setBoardSkinGeometry(BoardSkin.parchment, geometry);
        expect(await library.create(name: '书房棋盘'), isTrue);
        final profile = library.profiles.single;
        expect(preferences.value.selectedBoardSkinId, profile.id);
        expect(preferences.value.boardSkin, BoardSkin.parchment);
        expect(library.geometryFor(profile.id), geometry);
        expect(
          (await imageRepository
              .load())[profile.id]![BoardSkinImageSlot.boardBackground],
          orderedEquals(_png()),
        );

        final changed = geometry.copyWith(rotateLandingMarker: true);
        expect(await library.updateGeometry(profile.id, changed), isTrue);
        expect(library.geometryFor(profile.id), changed);
        expect(await library.rename(profile.id, '晚间棋盘'), isTrue);
        expect(library.profiles.single.name, '晚间棋盘');
        await library.selectBuiltIn(BoardSkin.jade);
        expect(preferences.value.selectedBoardSkinId, BoardSkin.jade.name);
        await library.select(profile.id);
        expect(preferences.value.selectedBoardSkinId, profile.id);
        expect(await library.delete(profile.id), isTrue);
        expect(library.profiles, isEmpty);
        expect(preferences.value.selectedBoardSkinId, BoardSkin.parchment.name);
        expect((await imageRepository.load()).containsKey(profile.id), isFalse);
      } finally {
        library.dispose();
        boardImages.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );

  test('create rejects blank duplicate and over-capacity profiles', () async {
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    final repository = MemoryBoardSkinLibraryRepository();
    final boardImages = BoardSkinImageLibraryController(
      _NoopPicker(),
      MemoryBoardSkinImageRepository(),
    );
    final controller = BoardSkinLibraryController(
      repository,
      boardImages,
      preferences,
    );
    try {
      await preferences.initialize();
      await controller.initialize();
      expect(await controller.create(name: '  '), isFalse);
      expect(await controller.create(name: 'Same'), isTrue);
      expect(await controller.create(name: 'same'), isFalse);
    } finally {
      controller.dispose();
      boardImages.dispose();
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });
}

final class _NoopPicker implements PieceImagePicker {
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
}
