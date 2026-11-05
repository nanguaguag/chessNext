import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chess_next/adapters/storage/file_board_skin_library_repository.dart';
import 'package:chess_next/adapters/storage/file_board_skin_image_repository.dart';
import 'package:chess_next/adapters/storage/file_preferences_repository.dart';
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
    'saved geometry and images survive fresh controllers without applying; use persists',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'chessnext-board-profile-restart-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final preferencesRepository = FilePreferencesRepository(() async => temp);
      final definitions = FileBoardSkinLibraryRepository(() async => temp);
      final imageRepository = FileBoardSkinImageRepository(() async => temp);

      Future<
        ({
          BoardSession session,
          EngineSessionController engine,
          PreferencesController preferences,
          BoardSkinImageLibraryController images,
          BoardSkinLibraryController library,
        })
      >
      openControllers() async {
        final session = BoardSession();
        final engine = EngineSessionController(session, null);
        final preferences = PreferencesController(
          engine,
          preferencesRepository,
        );
        final images = BoardSkinImageLibraryController(
          _NoopPicker(),
          imageRepository,
        );
        final library = BoardSkinLibraryController(
          definitions,
          images,
          preferences,
        );
        await preferences.initialize();
        await images.initialize();
        await library.initialize();
        return (
          session: session,
          engine: engine,
          preferences: preferences,
          images: images,
          library: library,
        );
      }

      void closeControllers(
        ({
          BoardSession session,
          EngineSessionController engine,
          PreferencesController preferences,
          BoardSkinImageLibraryController images,
          BoardSkinLibraryController library,
        })
        opened,
      ) {
        opened.library.dispose();
        opened.images.dispose();
        opened.preferences.dispose();
        opened.engine.dispose();
        opened.session.dispose();
      }

      final first = await openControllers();
      await first.preferences.setBoardSkin(BoardSkin.jade);
      expect(await first.library.create(name: '重载棋盘', apply: false), isTrue);
      final profile = first.library.profiles.single;
      final geometry = BoardSkinGeometry.standard().copyWith(
        leftPercent: 16,
        topPercent: 10,
        rightPercent: 84,
        bottomPercent: 90,
        pieceScalePercent: 118,
        rotateLandingMarker: true,
      );
      expect(await first.library.updateGeometry(profile.id, geometry), isTrue);
      await first.images.importImages(profile.id, {
        BoardSkinImageSlot.landingMarker: _png(),
      });
      const abandonedId = 'custom-87654321-dead';
      await imageRepository.save(
        abandonedId,
        BoardSkinImageSlot.boardBackground,
        'png',
        _png(),
      );
      expect(first.preferences.value.selectedBoardSkinId, BoardSkin.jade.name);
      closeControllers(first);

      final second = await openControllers();
      expect(second.library.profiles.single.geometry, geometry);
      expect(second.preferences.value.selectedBoardSkinId, BoardSkin.jade.name);
      expect(
        second.images.imagesFor(profile.id)[BoardSkinImageSlot.landingMarker],
        orderedEquals(_png()),
      );
      expect(second.images.imagesFor(abandonedId), isEmpty);
      expect((await imageRepository.load()).containsKey(abandonedId), isFalse);
      await second.library.select(profile.id);
      closeControllers(second);

      final third = await openControllers();
      expect(third.preferences.value.selectedBoardSkinId, profile.id);
      expect(third.library.geometryFor(profile.id), geometry);
      closeControllers(third);
    },
  );

  test('failed profile load never prunes custom board images', () async {
    final temp = await Directory.systemTemp.createTemp(
      'chessnext-board-corrupt-manifest-',
    );
    addTearDown(() => temp.delete(recursive: true));
    const profileId = 'custom-12345678-abcd';
    final imageRepository = FileBoardSkinImageRepository(() async => temp);
    await imageRepository.save(
      profileId,
      BoardSkinImageSlot.landingMarker,
      'png',
      _png(),
    );
    final manifest = File('${temp.path}/chessnext-board-skins/profiles.json');
    await manifest.parent.create(recursive: true);
    await manifest.writeAsString('{broken');

    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    final images = BoardSkinImageLibraryController(
      _NoopPicker(),
      imageRepository,
    );
    final controller = BoardSkinLibraryController(
      FileBoardSkinLibraryRepository(() async => temp),
      images,
      preferences,
    );
    try {
      await preferences.initialize();
      await images.initialize();
      await controller.initialize();

      expect(controller.error, isNotNull);
      expect(
        images.imageFor(profileId, BoardSkinImageSlot.landingMarker),
        orderedEquals(_png()),
      );
      expect((await imageRepository.load()).containsKey(profileId), isTrue);
    } finally {
      controller.dispose();
      images.dispose();
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });

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

  test(
    'coalesces rapid custom geometry writes and persists the latest drag',
    () async {
      const initial = BoardSkinGeometry.standard();
      final profile = BoardSkinDefinition(
        id: 'custom-12345678-abcd',
        name: '拖动测试',
        baseSkin: BoardSkin.parchment,
        geometry: initial,
      );
      final repository = _DelayedBoardSkinLibraryRepository([profile]);
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
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
        await boardImages.initialize();
        await controller.initialize();
        repository.blockNextSave();
        final intermediate = initial.copyWith(leftPercent: 12);
        final finalGeometry = initial.copyWith(leftPercent: 14);
        final firstWrite = controller.updateGeometry(profile.id, intermediate);
        await repository.saveStarted.future;
        final secondWrite = controller.updateGeometry(
          profile.id,
          initial.copyWith(leftPercent: 13),
        );
        final thirdWrite = controller.updateGeometry(profile.id, finalGeometry);
        repository.releaseSave.complete();

        expect(await firstWrite, isTrue);
        expect(await secondWrite, isTrue);
        expect(await thirdWrite, isTrue);
        expect(repository.profiles.single.geometry, finalGeometry);
        expect(controller.geometryFor(profile.id), finalGeometry);
      } finally {
        controller.dispose();
        boardImages.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );

  test('failed delete preserves the selected profile and its images', () async {
    final profile = BoardSkinDefinition(
      id: 'custom-12345678-abcd',
      name: '保留中的棋盘',
      baseSkin: BoardSkin.jade,
    );
    final repository = _FailingBoardSkinLibraryRepository([profile]);
    final imageRepository = MemoryBoardSkinImageRepository();
    await imageRepository.save(
      profile.id,
      BoardSkinImageSlot.boardBackground,
      'png',
      _png(),
    );
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
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
      await preferences.selectBoardSkin(profile.baseSkin, profile.id);
      repository.failNextSave = true;

      expect(await controller.delete(profile.id), isFalse);
      expect(preferences.value.selectedBoardSkinId, profile.id);
      expect(controller.profiles, [profile]);
      expect((await imageRepository.load()).containsKey(profile.id), isTrue);
    } finally {
      controller.dispose();
      boardImages.dispose();
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });

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

final class _DelayedBoardSkinLibraryRepository
    implements BoardSkinLibraryRepository {
  _DelayedBoardSkinLibraryRepository(this.profiles);

  List<BoardSkinDefinition> profiles;
  Completer<void> saveStarted = Completer<void>();
  Completer<void> releaseSave = Completer<void>();
  bool _blockNext = false;

  void blockNextSave() {
    _blockNext = true;
    saveStarted = Completer<void>();
    releaseSave = Completer<void>();
  }

  @override
  Future<List<BoardSkinDefinition>> load() async => profiles;

  @override
  Future<void> save(List<BoardSkinDefinition> profiles) async {
    if (_blockNext) {
      _blockNext = false;
      saveStarted.complete();
      await releaseSave.future;
    }
    this.profiles = List.unmodifiable(profiles);
  }
}

final class _FailingBoardSkinLibraryRepository
    implements BoardSkinLibraryRepository {
  _FailingBoardSkinLibraryRepository(this.profiles);

  List<BoardSkinDefinition> profiles;
  bool failNextSave = false;

  @override
  Future<List<BoardSkinDefinition>> load() async => profiles;

  @override
  Future<void> save(List<BoardSkinDefinition> profiles) async {
    if (failNextSave) {
      failNextSave = false;
      throw const FileSystemException('simulated manifest write failure');
    }
    this.profiles = List.unmodifiable(profiles);
  }
}
