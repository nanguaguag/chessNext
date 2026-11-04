import 'dart:io';
import 'package:chess_next/adapters/storage/file_piece_skin_library_repository.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/application/piece_skin_library_controller.dart';
import 'package:chess_next/application/piece_skin_package_codec.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:chess_next/ports/piece_skin_shadow.dart';
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
        shadow: const PieceSkinShadow.standard(),
        license: 'CC-BY-4.0',
        attribution: '原创作者 / 作品链接',
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
        shadow: PieceSkinShadow(
          style: PieceShadowStyle.prominent,
          angleDegrees: 210,
        ),
      ),
      isTrue,
    );
    expect(library.definitionFor(created.id)!.scalePercent, 117);
    expect(library.definitionFor(created.id)!.offsetXPercent, -3);
    expect(
      library.definitionFor(created.id)!.shadow!.style,
      PieceShadowStyle.prominent,
    );
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
    'package import creates a fresh local ID and selects the skin',
    () async {
      final engine = EngineSessionController(BoardSession(), null);
      final prefs = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      await prefs.initialize();
      final images = PieceImageLibraryController(
        const CancelPieceImagePicker(),
        MemoryPieceImageRepository(),
      );
      await images.initialize();
      final repo = MemoryPieceSkinLibraryRepository();
      final library = PieceSkinLibraryController(repo, images, prefs);
      await library.initialize();
      final package = PieceSkinPackage(
        profile: PieceSkinDefinition(
          id: 'custom-exported1',
          name: '迁移皮肤',
          baseSkin: PieceSkin.squareInk,
          scalePercent: 108,
        ),
        images: const {},
      );

      expect(await library.importPackage(package), isTrue);
      final imported = library.profiles.single;
      expect(imported.id, isNot(package.profile.id));
      expect(imported.scalePercent, 108);
      expect(prefs.value.selectedPieceSkinId, imported.id);
      expect(await repo.load(), [imported]);
      library.dispose();
      images.dispose();
      prefs.dispose();
      engine.dispose();
    },
  );

  test(
    'collection import is all-or-none and selects the first chosen skin',
    () async {
      final engine = EngineSessionController(BoardSession(), null);
      final prefs = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      await prefs.initialize();
      final images = PieceImageLibraryController(
        const CancelPieceImagePicker(),
        MemoryPieceImageRepository(),
      );
      await images.initialize();
      final repo = MemoryPieceSkinLibraryRepository();
      final library = PieceSkinLibraryController(repo, images, prefs);
      await library.initialize();
      final packages = [
        for (final name in ['集合甲', '集合乙'])
          PieceSkinPackage(
            profile: PieceSkinDefinition(
              id: 'custom-exported${name == '集合甲' ? '01' : '02'}',
              name: name,
              baseSkin: PieceSkin.squareInk,
              license: 'CC-BY-4.0',
            ),
            images: const {},
          ),
      ];

      expect(await library.importPackages(packages), 2);
      expect(library.profiles.map((profile) => profile.name), ['集合甲', '集合乙']);
      expect(
        library.profiles.every(
          (profile) => profile.id != packages.first.profile.id,
        ),
        isTrue,
      );
      expect(library.profiles.first.license, 'CC-BY-4.0');
      expect(prefs.value.selectedPieceSkinId, library.profiles.first.id);

      final conflicting = await library.importPackages([
        packages[0],
        PieceSkinPackage(
          profile: PieceSkinDefinition(
            id: 'custom-exported03',
            name: '集合甲',
            baseSkin: PieceSkin.roundSeal,
          ),
          images: const {},
        ),
      ]);
      expect(conflicting, 0);
      expect(library.profiles, hasLength(2));
      expect((await repo.load()).map((profile) => profile.name), [
        '集合甲',
        '集合乙',
      ]);
      library.dispose();
      images.dispose();
      prefs.dispose();
      engine.dispose();
    },
  );

  test(
    'collection write failure removes every staged image and profile',
    () async {
      final engine = EngineSessionController(BoardSession(), null);
      final prefs = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      await prefs.initialize();
      final images = PieceImageLibraryController(
        const CancelPieceImagePicker(),
        MemoryPieceImageRepository(),
      );
      await images.initialize();
      final repo = _FailingCatalog();
      final library = PieceSkinLibraryController(repo, images, prefs);
      await library.initialize();
      final packages = [
        for (var i = 1; i <= 2; i++)
          PieceSkinPackage(
            profile: PieceSkinDefinition(
              id: 'custom-exported0$i',
              name: '回滚皮肤$i',
              baseSkin: PieceSkin.roundSeal,
            ),
            images: const {},
          ),
      ];
      repo.failNext = true;
      expect(await library.importPackages(packages), 0);
      expect(library.profiles, isEmpty);
      expect(images.snapshot, isEmpty);
      expect(await repo.load(), isEmpty);
      expect(prefs.value.selectedPieceSkinId, PieceSkin.roundSeal.name);
      library.dispose();
      images.dispose();
      prefs.dispose();
      engine.dispose();
    },
  );

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
