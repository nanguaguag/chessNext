import 'dart:io';
import 'package:chess_next/adapters/storage/file_piece_skin_library_repository.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/application/piece_skin_library_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingCatalog extends MemoryPieceSkinLibraryRepository {
  bool failNext = false;
  @override
  Future<void> save(List<PieceSkinDefinition> definitions) async {
    if (failNext) {
      failNext = false;
      throw StateError('write failed');
    }
    await super.save(definitions);
  }
}

class _FailingImageRemoval extends MemoryPieceImageRepository {
  bool failRemoval = false;
  @override
  Future<void> removeSkin(String skin) async {
    if (failRemoval) throw StateError('remove failed');
    await super.removeSkin(skin);
  }
}

void main() {
  test(
    'custom profile appearance has bounded, persisted scale and offsets',
    () {
      final profile = PieceSkinDefinition(
        id: 'custom-abcdefgh',
        name: '独立大小',
        baseSkin: PieceSkin.squareInk,
        scalePercent: 118,
        offsetXPercent: -7,
        offsetYPercent: 5,
      );
      expect(PieceSkinDefinition.fromJson(profile.toJson()), profile);
      expect(
        () => PieceSkinDefinition(
          id: profile.id,
          name: profile.name,
          baseSkin: profile.baseSkin,
          scalePercent: 121,
        ),
        throwsArgumentError,
      );
      expect(() => profile.copyWith(offsetXPercent: 9), throwsArgumentError);
    },
  );

  test('profile library persists definitions with safe validation', () async {
    final temp = await Directory.systemTemp.createTemp('piece-skins-');
    addTearDown(() => temp.delete(recursive: true));
    final repository = FilePieceSkinLibraryRepository(() async => temp);
    final profile = PieceSkinDefinition(
      id: 'custom-abcdefgh',
      name: '我的红章',
      baseSkin: PieceSkin.squareInk,
    );
    await repository.save([profile]);
    expect(await repository.load(), [profile]);
    await expectLater(
      repository.save([profile, profile]),
      throwsFormatException,
    );
  });

  test('create, rename, select and delete custom profiles', () async {
    final engine = EngineSessionController(BoardSession(), null);
    final preferencesRepository = MemoryPreferencesRepository();
    final prefs = PreferencesController(engine, preferencesRepository);
    await prefs.initialize();
    final images = PieceImageLibraryController(
      const CancelPieceImagePicker(),
      MemoryPieceImageRepository(),
    );
    await images.initialize();
    final repo = MemoryPieceSkinLibraryRepository();
    final library = PieceSkinLibraryController(repo, images, prefs);
    await library.initialize();

    expect(await library.create(name: '副本皮肤'), isTrue);
    final created = library.profiles.single;
    expect(prefs.value.selectedPieceSkinId, created.id);
    expect(preferencesRepository.value!.selectedPieceSkinId, created.id);
    expect(prefs.value.pieceSkin, PieceSkin.roundSeal);
    await library.select(PieceSkin.squareInk.name);
    expect(prefs.value.selectedPieceSkinId, PieceSkin.squareInk.name);
    await library.select(created.id);
    expect(prefs.value.selectedPieceSkinId, created.id);
    expect(
      await library.updateAppearance(
        created.id,
        scalePercent: 117,
        offsetXPercent: -3,
        offsetYPercent: 2,
      ),
      isTrue,
    );
    expect(library.definitionFor(created.id)!.scalePercent, 117);
    expect(library.definitionFor(created.id)!.offsetXPercent, -3);
    final restoredEngine = EngineSessionController(BoardSession(), null);
    final restoredPreferences = PreferencesController(
      restoredEngine,
      preferencesRepository,
    );
    await restoredPreferences.initialize();
    expect(restoredPreferences.value.selectedPieceSkinId, created.id);
    expect(await library.rename(created.id, '新名字'), isTrue);
    expect(library.selectedName, '新名字');
    expect(await library.delete(created.id), isTrue);
    expect(prefs.value.selectedPieceSkinId, PieceSkin.roundSeal.name);
    expect(library.profiles, isEmpty);

    library.dispose();
    images.dispose();
    restoredPreferences.dispose();
    restoredEngine.dispose();
    prefs.dispose();
    engine.dispose();
  });

  test(
    'failed create and delete preserve the old selectable profile',
    () async {
      final engine = EngineSessionController(BoardSession(), null);
      final prefs = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      await prefs.initialize();
      final images = PieceImageLibraryController(
        const CancelPieceImagePicker(),
        _FailingImageRemoval(),
      );
      await images.initialize();
      final repo = _FailingCatalog();
      final library = PieceSkinLibraryController(repo, images, prefs);
      await library.initialize();
      repo.failNext = true;
      expect(await library.create(name: '失败创建'), isFalse);
      expect(library.profiles, isEmpty);
      expect(prefs.value.selectedPieceSkinId, PieceSkin.roundSeal.name);

      expect(await library.create(name: '可删除皮肤'), isTrue);
      final created = library.profiles.single;
      (images.repository as _FailingImageRemoval).failRemoval = true;
      expect(await library.delete(created.id), isFalse);
      expect(library.profiles.single.id, created.id);
      expect(prefs.value.selectedPieceSkinId, created.id);
      library.dispose();
      images.dispose();
      prefs.dispose();
      engine.dispose();
    },
  );

  test(
    'missing saved custom profile falls back after preferences are loaded',
    () async {
      final engine = EngineSessionController(BoardSession(), null);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(selectedPieceSkinId: 'custom-abcdefgh');
      final prefs = PreferencesController(engine, store);
      await prefs.initialize();
      final images = PieceImageLibraryController(
        const CancelPieceImagePicker(),
        MemoryPieceImageRepository(),
      );
      await images.initialize();
      final library = PieceSkinLibraryController(
        MemoryPieceSkinLibraryRepository(),
        images,
        prefs,
      );
      await library.initialize();
      expect(prefs.value.selectedPieceSkinId, PieceSkin.roundSeal.name);
      library.dispose();
      images.dispose();
      prefs.dispose();
      engine.dispose();
    },
  );
}
