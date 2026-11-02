import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class LateModeStore extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'optional review mode defaults safely and rejects malformed or unknown values',
    () {
      final old = AppPreferences().toJson();
      expect(old.containsKey('reviewMode'), isFalse);
      expect(AppPreferences.fromJson(old).reviewMode, ReviewMode.best);
      final value = AppPreferences(reviewMode: ReviewMode.candidates);
      expect(AppPreferences.fromJson(value.toJson()), value);
      expect(
        value.copyWith(showMoveGrades: false).reviewMode,
        ReviewMode.candidates,
      );
      for (final bad in [null, false, 1, 'quick', '']) {
        expect(
          () => AppPreferences.fromJson({...old, 'reviewMode': bad}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'late settings merge preserves explicit mode without overwriting independent fields',
    () async {
      final session = BoardSession(),
          store = LateModeStore()
            ..value = AppPreferences(showMoveGrades: false, threads: 4);
      final engine = EngineSessionController(session, null, deviceThreads: 8);
      final prefs = PreferencesController(engine, store);
      try {
        final load = prefs.initialize();
        final save = prefs.setReviewMode(ReviewMode.candidates);
        store.gate.complete();
        await load;
        await save;
        await prefs.flush();
        expect(prefs.value.reviewMode, ReviewMode.candidates);
        expect(prefs.value.showMoveGrades, isFalse);
        expect(prefs.value.threads, 4);
        expect(store.value, prefs.value);
        expect(session.dirty, isFalse);
        expect(engine.enabled, isFalse);
        expect(engine.review, isNull);
      } finally {
        prefs.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
