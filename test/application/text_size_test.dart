import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

class SizePreferences extends MemoryPreferencesRepository {
  Completer<void>? readGate, writeGate;
  bool failRead = false, failWrite = false;
  int writes = 0;
  @override
  Future<LoadedPreferences?> load() async {
    await readGate?.future;
    if (failRead) throw StateError('read failed');
    return super.load();
  }

  @override
  Future<void> save(AppPreferences next) async {
    writes++;
    if (writes == 1) await writeGate?.future;
    if (failWrite) throw StateError('write failed');
    return super.save(next);
  }
}

void main() {
  late BoardSession session;
  late FakeEngine fake;
  late EngineSessionController engine;
  late SizePreferences repository;
  late PreferencesController preferences;
  setUp(() {
    session = BoardSession();
    fake = FakeEngine();
    engine = EngineSessionController(
      session,
      () async => fake,
      deviceThreads: 4,
    );
    repository = SizePreferences();
    preferences = PreferencesController(engine, repository);
  });
  tearDown(() {
    preferences.dispose();
    engine.dispose();
    session.dispose();
  });

  test(
    'optional text size defaults legacy data to system and round trips all modes',
    () {
      final legacy = AppPreferences(guideVersion: 99).toJson();
      expect(legacy.containsKey('textSize'), isFalse);
      expect(
        AppPreferences.fromJson(legacy).textSize,
        TextSizePreference.system,
      );
      for (final mode in TextSizePreference.values) {
        final value = AppPreferences(guideVersion: 99, textSize: mode);
        expect(AppPreferences.fromJson(value.toJson()), value);
        expect(value.copyWith(theme: ThemePreference.dark).textSize, mode);
        expect(value.copyWith().hashCode, value.hashCode);
        expect(
          value.copyWith(
            textSize: mode == TextSizePreference.large
                ? TextSizePreference.standard
                : TextSizePreference.large,
          ),
          isNot(value),
        );
      }
      for (final malformed in [
        null,
        130,
        1.3,
        true,
        'unknown',
        {'manual': 1.3},
      ]) {
        expect(
          () => AppPreferences.fromJson({...legacy, 'textSize': malformed}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'late loaded settings merge other fields without undoing a chosen size',
    () async {
      repository.value = AppPreferences(
        theme: ThemePreference.dark,
        textSize: TextSizePreference.standard,
        hashMb: 128,
        guideVersion: 77,
      );
      repository.readGate = Completer<void>();
      final loading = preferences.initialize();
      final choosing = preferences.setTextSize(TextSizePreference.extraLarge);
      repository.readGate!.complete();
      await loading;
      await choosing;
      await preferences.flush();
      expect(preferences.value.textSize, TextSizePreference.extraLarge);
      expect(preferences.value.theme, ThemePreference.dark);
      expect(preferences.value.hashMb, 128);
      expect(preferences.value.guideVersion, 77);
      expect(repository.value, preferences.value);
    },
  );
  test(
    'loading preserves stored size if only another field was edited',
    () async {
      repository.value = AppPreferences(textSize: TextSizePreference.large);
      repository.readGate = Completer<void>();
      final loading = preferences.initialize();
      final theme = preferences.setTheme(ThemePreference.dark);
      repository.readGate!.complete();
      await loading;
      await theme;
      await preferences.flush();
      expect(preferences.value.textSize, TextSizePreference.large);
      expect(repository.value!.textSize, TextSizePreference.large);
    },
  );
  test(
    'font-only changes do not restart running analysis or mutate a document',
    () async {
      await preferences.initialize();
      await engine.enable();
      final requests = fake.requests.length;
      final tree = session.tree, metadata = session.metadata;
      final revision = session.revision,
          positionRevision = session.positionRevision;
      for (final mode in TextSizePreference.values) {
        await preferences.setTextSize(mode);
      }
      expect(fake.requests.length, requests);
      expect(session.tree, same(tree));
      expect(session.metadata, same(metadata));
      expect(session.revision, revision);
      expect(session.positionRevision, positionRevision);
      expect(session.dirty, isFalse);
      expect(engine.aiSides, isEmpty);
    },
  );
  test('rapid size changes serialize and preserve unrelated fields', () async {
    repository.value = AppPreferences(guideVersion: 123);
    await preferences.initialize();
    repository.writeGate = Completer<void>();
    final one = preferences.setTextSize(TextSizePreference.large);
    final two = preferences.setTextSize(TextSizePreference.extraLarge);
    final three = preferences.setTheme(ThemePreference.dark);
    repository.writeGate!.complete();
    await Future.wait([one, two, three]);
    expect(repository.value!.textSize, TextSizePreference.extraLarge);
    expect(repository.value!.theme, ThemePreference.dark);
    expect(repository.value!.guideVersion, 123);
    expect(repository.writes, 2);
  });
  test(
    'retry distinguishes unreadable settings from an unpersisted user choice',
    () async {
      repository.failRead = true;
      await preferences.initialize();
      await preferences.retryPersistence();
      expect(repository.writes, 0);
      repository.failRead = false;
      repository.value = AppPreferences(textSize: TextSizePreference.large);
      await preferences.retryPersistence();
      expect(preferences.value.textSize, TextSizePreference.large);
      repository.failWrite = true;
      await preferences.setTextSize(TextSizePreference.extraLarge);
      expect(preferences.error, contains('保存失败'));
      expect(preferences.value.textSize, TextSizePreference.extraLarge);
      repository.failWrite = false;
      await preferences.retryPersistence();
      expect(preferences.error, isNull);
      expect(repository.value!.textSize, TextSizePreference.extraLarge);
    },
  );
}
