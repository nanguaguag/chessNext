import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

class DelayedSizeStore extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'piece size accepts exact discrete range, rejects bad values and preserves other fields',
    () {
      final old = AppPreferences().toJson();
      expect(old.containsKey('pieceSizePercent'), isFalse);
      expect(AppPreferences.fromJson(old).pieceSizePercent, 100);
      for (final size in [10, 15, 100, 125, 200]) {
        final value = AppPreferences(
          pieceSizePercent: size,
          showCoordinates: false,
          textSize: TextSizePreference.large,
          guideVersion: 77,
        );
        expect(AppPreferences.fromJson(value.toJson()), value);
        expect(value.copyWith().hashCode, value.hashCode);
        expect(
          value.copyWith(theme: ThemePreference.dark).pieceSizePercent,
          size,
        );
      }
      for (final invalid in [null, '100', 100.0, true, 9, 201, 11, 99, -5]) {
        expect(
          () => AppPreferences.fromJson({...old, 'pieceSizePercent': invalid}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'late read respects edited size and loads untouched size without losing display flags',
    () async {
      for (final editSize in [true, false]) {
        final session = BoardSession(), store = DelayedSizeStore();
        store.value = AppPreferences(
          pieceSizePercent: 125,
          showCoordinates: false,
          textSize: TextSizePreference.large,
          guideVersion: 66,
        );
        final engine = EngineSessionController(session, null);
        final prefs = PreferencesController(engine, store);
        try {
          final loading = prefs.initialize();
          final edit = editSize
              ? prefs.setPieceSize(200)
              : prefs.setTheme(ThemePreference.dark);
          store.gate.complete();
          await loading;
          await edit;
          await prefs.flush();
          expect(prefs.value.pieceSizePercent, editSize ? 200 : 125);
          expect(store.value!.pieceSizePercent, editSize ? 200 : 125);
          expect(prefs.value.showCoordinates, isFalse);
          expect(prefs.value.textSize, TextSizePreference.large);
          expect(prefs.value.guideVersion, 66);
        } finally {
          prefs.dispose();
          engine.dispose();
          session.dispose();
        }
      }
    },
  );
  test(
    'size changes preserve live engine request and complete document state',
    () async {
      final session = BoardSession(), fake = FakeEngine();
      final engine = EngineSessionController(session, () async => fake);
      final prefs = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      try {
        await prefs.initialize();
        await engine.enable();
        final requests = fake.requests.length, revision = session.revision;
        final tree = session.tree;
        await prefs.setPieceSize(10);
        await prefs.setPieceSize(200);
        await prefs.setPieceSize(100);
        expect(fake.requests.length, requests);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.dirty, isFalse);
      } finally {
        prefs.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
