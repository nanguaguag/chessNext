import 'dart:async';

import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedStore extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test('skin scale values are bounded, independent and schema compatible', () {
    final defaults = AppPreferences();
    expect(defaults.roundSealPieceScalePercent, 100);
    expect(defaults.squareInkPieceScalePercent, 100);
    expect(AppPreferences.fromJson(defaults.toJson()), defaults);
    for (final percent in [80, 100, 120]) {
      final next = defaults.copyWith(
        roundSealPieceScalePercent: percent,
        squareInkPieceScalePercent: 100,
      );
      expect(AppPreferences.fromJson(next.toJson()), next);
    }
    expect(
      () => AppPreferences(roundSealPieceScalePercent: 79),
      throwsArgumentError,
    );
    expect(
      () => AppPreferences(squareInkPieceScalePercent: 121),
      throwsArgumentError,
    );
  });

  test(
    'skin offsets are independent, bounded and have a default alignment',
    () {
      final defaults = AppPreferences();
      expect(defaults.roundSealPieceOffsetX, 0);
      expect(defaults.squareInkPieceOffsetY, 0);
      final custom = defaults.copyWith(
        roundSealPieceOffsetX: 8,
        squareInkPieceOffsetX: -8,
        squareInkPieceOffsetY: 4,
      );
      expect(AppPreferences.fromJson(custom.toJson()), custom);
      expect(
        custom.copyWith(theme: ThemePreference.dark).squareInkPieceOffsetY,
        4,
      );
      expect(
        () => AppPreferences(roundSealPieceOffsetY: -9),
        throwsArgumentError,
      );
      expect(
        () => AppPreferences(squareInkPieceOffsetX: 9),
        throwsArgumentError,
      );
    },
  );

  test(
    'setting one skin size preserves the other across late storage read',
    () async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final store = _DelayedStore()
        ..value = AppPreferences(
          roundSealPieceScalePercent: 105,
          squareInkPieceScalePercent: 95,
        );
      final preferences = PreferencesController(engine, store);
      try {
        final loading = preferences.initialize();
        final edit = preferences.setPieceSkinScale(PieceSkin.squareInk, 120);
        store.gate.complete();
        await loading;
        await edit;
        await preferences.flush();
        expect(preferences.value.roundSealPieceScalePercent, 105);
        expect(preferences.value.squareInkPieceScalePercent, 120);
        expect(store.value!.roundSealPieceScalePercent, 105);
        expect(store.value!.squareInkPieceScalePercent, 120);
        await preferences.setPieceSkinOffset(PieceSkin.squareInk, x: 5, y: -3);
        expect(preferences.value.roundSealPieceOffsetX, 0);
        expect(preferences.value.squareInkPieceOffsetX, 5);
        expect(preferences.value.squareInkPieceOffsetY, -3);
        await preferences.setPieceSkinOffset(PieceSkin.squareInk, x: 0, y: 0);
        expect(store.value!.squareInkPieceOffsetY, 0);
      } finally {
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
