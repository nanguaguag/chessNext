import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class DelayedMarkers extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'old settings keep visible standard arrows and new fields validate strictly',
    () {
      final old = AppPreferences().toJson();
      expect(old.containsKey('showAnalysisArrows'), isFalse);
      expect(old.containsKey('arrowHead'), isFalse);
      expect(AppPreferences.fromJson(old).showAnalysisArrows, isTrue);
      expect(AppPreferences.fromJson(old).arrowHead, ArrowHeadStyle.standard);
      for (final head in ArrowHeadStyle.values) {
        final value = AppPreferences(
          showAnalysisArrows: false,
          arrowHead: head,
          pieceSizePercent: 125,
        );
        expect(AppPreferences.fromJson(value.toJson()), value);
        expect(value.copyWith(theme: ThemePreference.dark).arrowHead, head);
        expect(value.copyWith().hashCode, value.hashCode);
      }
      for (final bad in [null, 'true', 1]) {
        expect(
          () => AppPreferences.fromJson({...old, 'showAnalysisArrows': bad}),
          throwsFormatException,
        );
      }
      for (final bad in [null, 1, 'unknown']) {
        expect(
          () => AppPreferences.fromJson({...old, 'arrowHead': bad}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'late loading merges each marker field independently and retains other display fields',
    () async {
      for (final editVisibility in [true, false]) {
        final session = BoardSession();
        final engine = EngineSessionController(session, null);
        final store = DelayedMarkers()
          ..value = AppPreferences(
            showAnalysisArrows: editVisibility,
            arrowHead: ArrowHeadStyle.wide,
            showCoordinates: false,
            pieceSizePercent: 125,
          );
        final prefs = PreferencesController(engine, store);
        try {
          final loading = prefs.initialize();
          final change = editVisibility
              ? prefs.setAnalysisArrows(false)
              : prefs.setArrowHead(ArrowHeadStyle.sharp);
          store.gate.complete();
          await loading;
          await change;
          await prefs.flush();
          expect(prefs.value.showAnalysisArrows, isFalse);
          expect(
            prefs.value.arrowHead,
            editVisibility ? ArrowHeadStyle.wide : ArrowHeadStyle.sharp,
          );
          expect(store.value, prefs.value);
          expect(prefs.value.showCoordinates, isFalse);
          expect(prefs.value.pieceSizePercent, 125);
        } finally {
          prefs.dispose();
          engine.dispose();
          session.dispose();
        }
      }
    },
  );
}
