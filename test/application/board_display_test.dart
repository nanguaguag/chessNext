import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

class DelayedBoardPreferences extends MemoryPreferencesRepository {
  final read = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await read.future;
    return super.load();
  }
}

void main() {
  test(
    'coordinate preference defaults old data on and rejects malformed optional values',
    () {
      final old = AppPreferences().toJson();
      expect(old.containsKey('showCoordinates'), isFalse);
      expect(AppPreferences.fromJson(old).showCoordinates, isTrue);
      final hidden = AppPreferences(
        showCoordinates: false,
        textSize: TextSizePreference.large,
        guideVersion: 33,
      );
      expect(AppPreferences.fromJson(hidden.toJson()), hidden);
      expect(
        hidden.copyWith(theme: ThemePreference.dark).showCoordinates,
        isFalse,
      );
      expect(hidden.copyWith().hashCode, hidden.hashCode);
      expect(hidden.copyWith(showCoordinates: true), isNot(hidden));
      for (final bad in [null, 0, 1, 'false', [], {}]) {
        expect(
          () => AppPreferences.fromJson({...old, 'showCoordinates': bad}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'late read preserves explicit coordinate choice and loads untouched coordinate field',
    () async {
      for (final editCoordinates in [true, false]) {
        final session = BoardSession();
        final engine = EngineSessionController(session, null);
        final store = DelayedBoardPreferences()
          ..value = AppPreferences(
            showCoordinates: editCoordinates,
            textSize: TextSizePreference.large,
            guideVersion: 44,
          );
        final prefs = PreferencesController(engine, store);
        try {
          final loading = prefs.initialize();
          final edit = editCoordinates
              ? prefs.setShowCoordinates(false)
              : prefs.setTheme(ThemePreference.dark);
          store.read.complete();
          await loading;
          await edit;
          await prefs.flush();
          expect(prefs.value.showCoordinates, isFalse);
          expect(store.value!.showCoordinates, isFalse);
          expect(prefs.value.textSize, TextSizePreference.large);
          expect(prefs.value.guideVersion, 44);
        } finally {
          prefs.dispose();
          engine.dispose();
          session.dispose();
        }
      }
    },
  );
  test(
    'coordinate changes preserve active search, metadata and document revisions',
    () async {
      final session = BoardSession();
      final fake = FakeEngine();
      final engine = EngineSessionController(session, () async => fake);
      final prefs = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      try {
        await prefs.initialize();
        await engine.enable();
        final requests = fake.requests.length;
        final tree = session.tree, metadata = session.metadata;
        final revision = session.revision,
            positionRevision = session.positionRevision;
        await prefs.setShowCoordinates(false);
        await prefs.setShowCoordinates(true);
        expect(fake.requests.length, requests);
        expect(session.tree, same(tree));
        expect(session.metadata, same(metadata));
        expect(session.revision, revision);
        expect(session.positionRevision, positionRevision);
        expect(session.dirty, isFalse);
      } finally {
        prefs.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
