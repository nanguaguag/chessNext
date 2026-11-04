import 'dart:io';
import 'dart:typed_data';

import 'package:chess_next/adapters/storage/file_board_skin_library_repository.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/application/board_skin_image_library_controller.dart';
import 'package:chess_next/application/board_skin_library_controller.dart';
import 'package:chess_next/application/board_skin_package_codec.dart';
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

  test('board skin package and import preserve license metadata', () async {
    final source = BoardSkinDefinition(
      id: 'custom-12345678-abcd',
      name: 'Licensed board',
      baseSkin: BoardSkin.jade,
      license: 'CC-BY-4.0',
      attribution: 'Original artist',
    );
    final encoded = BoardSkinPackageCodec.encode(source, const {});
    final decoded = BoardSkinPackageCodec.decode(encoded);
    expect(decoded.profile.license, 'CC-BY-4.0');
    expect(decoded.profile.attribution, 'Original artist');
    expect(
      BoardSkinDefinition.fromJson({
        'id': 'custom-12345678-abcd',
        'name': 'Legacy board',
        'baseSkin': 'jade',
        'geometry': BoardSkinGeometry.standard().toJson(),
      }).license,
      isEmpty,
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
        license: 'CC-BY-4.0',
        attribution: '棋手甲',
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

  test(
    'package import allocates a fresh id and selects the new profile',
    () async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      final repository = MemoryBoardSkinLibraryRepository();
      final imageRepository = MemoryBoardSkinImageRepository();
      final boardImages = BoardSkinImageLibraryController(
        _NoopPicker(),
        imageRepository,
      );
      final controller = BoardSkinLibraryController(
        repository,
        boardImages,
        preferences,
      );
      try {
        await preferences.initialize();
        await boardImages.initialize();
        await controller.initialize();
        final source = BoardSkinDefinition(
          id: 'custom-12345678-abcd',
          name: '外来棋盘',
          baseSkin: BoardSkin.jade,
          geometry: const BoardSkinGeometry.standard().copyWith(
            rotateLandingMarker: true,
          ),
          license: 'CC-BY-4.0',
          attribution: '站点作者',
        );
        final image = _png();
        expect(
          await controller.importPackage(
            BoardSkinPackage(
              profile: source,
              images: {BoardSkinImageSlot.landingMarker: image},
            ),
          ),
          isTrue,
        );
        final imported = controller.profiles.single;
        expect(imported.id, isNot(source.id));
        expect(imported.name, source.name);
        expect(imported.geometry, source.geometry);
        expect(imported.license, source.license);
        expect(imported.attribution, source.attribution);
        expect(preferences.value.selectedBoardSkinId, imported.id);
        expect(
          (await imageRepository
              .load())[imported.id]![BoardSkinImageSlot.landingMarker],
          orderedEquals(image),
        );
      } finally {
        controller.dispose();
        boardImages.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}

final class _NoopPicker implements PieceImagePicker {
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
}
