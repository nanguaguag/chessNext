import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class DelayedMarkerPreferences extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'old settings default to halo and malformed marker values are rejected',
    () {
      final old = AppPreferences().toJson();
      expect(old.containsKey('lastMoveMarker'), isFalse);
      expect(
        AppPreferences.fromJson(old).lastMoveMarker,
        LastMoveMarkerStyle.halo,
      );
      final box = AppPreferences(lastMoveMarker: LastMoveMarkerStyle.box);
      expect(AppPreferences.fromJson(box.toJson()), box);
      expect(
        box.copyWith(theme: ThemePreference.dark).lastMoveMarker,
        LastMoveMarkerStyle.box,
      );
      for (final bad in [null, 0, true, 'square', '']) {
        expect(
          () => AppPreferences.fromJson({...old, 'lastMoveMarker': bad}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'explicit marker choice survives a late settings read independently',
    () async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final store = DelayedMarkerPreferences();
      final preferences = PreferencesController(engine, store);
      store.value = AppPreferences(
        pieceSizePercent: 150,
        showEvaluationBar: false,
      );
      try {
        final loading = preferences.initialize();
        final saving = preferences.setLastMoveMarker(LastMoveMarkerStyle.box);
        store.gate.complete();
        await loading;
        await saving;
        await preferences.flush();
        expect(preferences.value.lastMoveMarker, LastMoveMarkerStyle.box);
        expect(preferences.value.pieceSizePercent, 150);
        expect(preferences.value.showEvaluationBar, isFalse);
        expect(store.value, preferences.value);
        expect(session.dirty, isFalse);
      } finally {
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
