import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

class GuidePreferences extends MemoryPreferencesRepository {
  Completer<void>? readGate;
  bool failRead = false, failWrite = false;
  int writes = 0;
  @override
  Future<LoadedPreferences?> load() async {
    await readGate?.future;
    if (failRead) throw StateError('bad preferences');
    return super.load();
  }

  @override
  Future<void> save(AppPreferences next) async {
    writes++;
    if (failWrite) throw StateError('disk full');
    await super.save(next);
  }
}

void main() {
  test(
    'optional version is backward compatible, bounded and part of value identity',
    () {
      final old = AppPreferences().toJson();
      expect(old.containsKey('guideVersion'), isFalse);
      expect(AppPreferences.fromJson(old).guideVersion, 0);
      final next = AppPreferences(guideVersion: 1);
      expect(AppPreferences.fromJson(next.toJson()), next);
      expect(next, isNot(AppPreferences()));
      expect(next.copyWith(theme: ThemePreference.dark).guideVersion, 1);
      for (final invalid in [-1, 1000001, 1.5, null]) {
        expect(
          () => AppPreferences.fromJson({...old, 'guideVersion': invalid}),
          throwsFormatException,
        );
      }
    },
  );
  late BoardSession session;
  late FakeEngine fake;
  late EngineSessionController engine;
  late GuidePreferences repository;
  late PreferencesController preferences;
  var factories = 0;
  setUp(() {
    factories = 0;
    session = BoardSession();
    fake = FakeEngine();
    engine = EngineSessionController(session, () async {
      factories++;
      return fake;
    }, deviceThreads: 4);
    repository = GuidePreferences();
    preferences = PreferencesController(engine, repository);
  });
  tearDown(() {
    preferences.dispose();
    engine.dispose();
    session.dispose();
  });
  test(
    'acknowledgment preserves settings and future versions without starting engine',
    () async {
      repository.value = AppPreferences(
        theme: ThemePreference.dark,
        threads: 4,
        hashMb: 128,
        multiPv: 3,
        thinkTimeMs: 3000,
        guideVersion: 8,
      );
      await preferences.initialize();
      final before = preferences.value;
      final tree = session.tree;
      expect(await preferences.markGuideSeen(), isTrue);
      expect(preferences.value, before);
      expect(preferences.value.guideVersion, 8);
      expect(session.tree, same(tree));
      expect(factories, 0);
      expect(fake.requests, isEmpty);
    },
  );
  test(
    'guide edit during delayed load merges independently of stored resources and theme',
    () async {
      repository.readGate = Completer<void>();
      repository.value = AppPreferences(
        theme: ThemePreference.dark,
        threads: 4,
        hashMb: 128,
      );
      final loading = preferences.initialize();
      final editing = preferences.apply(
        preferences.value.copyWith(guideVersion: 1),
      );
      repository.readGate!.complete();
      await loading;
      await editing;
      await preferences.flush();
      expect(preferences.value.guideVersion, 1);
      expect(preferences.value.theme, ThemePreference.dark);
      expect(preferences.value.threads, 4);
      expect(preferences.value.hashMb, 128);
      expect(repository.value!.guideVersion, 1);
    },
  );
  test(
    'read failure cannot be overwritten by acknowledgment; retry is explicit',
    () async {
      repository.failRead = true;
      await preferences.initialize();
      expect(await preferences.markGuideSeen(), isFalse);
      expect(repository.writes, 0);
      expect(preferences.value.guideVersion, 0);
      expect(preferences.error, contains('原文件已保留'));
      repository.failRead = false;
      await preferences.initialize();
      expect(await preferences.markGuideSeen(), isTrue);
      expect(repository.value!.guideVersion, 1);
    },
  );
  test(
    'failed write is visible, keeps in-memory state and can be retried',
    () async {
      await preferences.initialize();
      repository.failWrite = true;
      expect(await preferences.markGuideSeen(), isFalse);
      expect(preferences.error, contains('保存失败'));
      expect(repository.value, isNull);
      expect(preferences.value.guideVersion, 1);
      repository.failWrite = false;
      expect(await preferences.markGuideSeen(), isTrue);
      expect(repository.value!.guideVersion, 1);
    },
  );
}
