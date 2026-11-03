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
  test('animation timing preference is backward compatible and typed', () {
    final old = AppPreferences().toJson();
    expect(old.containsKey('animationSpeed'), isFalse);
    expect(
      AppPreferences.fromJson(old).animationSpeed,
      AnimationSpeed.standard,
    );
    for (final speed in AnimationSpeed.values) {
      final value = AppPreferences(animationSpeed: speed);
      expect(AppPreferences.fromJson(value.toJson()), value);
      expect(value.copyWith(theme: ThemePreference.dark).animationSpeed, speed);
    }
    expect(
      () => AppPreferences.fromJson({...old, 'animationSpeed': 'instant'}),
      throwsFormatException,
    );
  });
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
  test('animation speed edited during loading is not overwritten', () async {
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final store = DelayedMarkerPreferences();
    final preferences = PreferencesController(engine, store);
    store.value = AppPreferences(pieceSizePercent: 150);
    try {
      final loading = preferences.initialize();
      final saving = preferences.setAnimationSpeed(AnimationSpeed.slow);
      store.gate.complete();
      await loading;
      await saving;
      await preferences.flush();
      expect(preferences.value.animationSpeed, AnimationSpeed.slow);
      expect(preferences.value.pieceSizePercent, 150);
      expect(store.value, preferences.value);
      expect(session.dirty, isFalse);
    } finally {
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });
  test('opposite piece orientation is backward compatible and persisted', () {
    final legacy = AppPreferences().toJson();
    expect(legacy.containsKey('rotateOppositePieces'), isFalse);
    expect(AppPreferences.fromJson(legacy).rotateOppositePieces, isFalse);
    final rotated = AppPreferences(rotateOppositePieces: true);
    expect(AppPreferences.fromJson(rotated.toJson()), rotated);
    expect(
      rotated.copyWith(theme: ThemePreference.dark).rotateOppositePieces,
      isTrue,
    );
    expect(
      () => AppPreferences.fromJson({...legacy, 'rotateOppositePieces': 'yes'}),
      throwsFormatException,
    );
  });
  test('local board skins default safely and round-trip as stable names', () {
    final legacy = AppPreferences().toJson();
    expect(legacy.containsKey('boardSkin'), isFalse);
    expect(AppPreferences.fromJson(legacy).boardSkin, BoardSkin.parchment);
    for (final skin in BoardSkin.values) {
      final preferences = AppPreferences(boardSkin: skin);
      expect(AppPreferences.fromJson(preferences.toJson()), preferences);
      expect(preferences.copyWith(theme: ThemePreference.dark).boardSkin, skin);
    }
    expect(
      () => AppPreferences.fromJson({...legacy, 'boardSkin': 'unknown'}),
      throwsFormatException,
    );
    expect(
      () => AppPreferences.fromJson({...legacy, 'boardSkin': 2}),
      throwsFormatException,
    );
  });
  test('orientation edited during settings load is not overwritten', () async {
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final store = DelayedMarkerPreferences();
    final preferences = PreferencesController(engine, store);
    store.value = AppPreferences(showCoordinates: false);
    try {
      final loading = preferences.initialize();
      final saving = preferences.setRotateOppositePieces(true);
      store.gate.complete();
      await loading;
      await saving;
      await preferences.flush();
      expect(preferences.value.rotateOppositePieces, isTrue);
      expect(preferences.value.showCoordinates, isFalse);
      expect(store.value, preferences.value);
      expect(session.dirty, isFalse);
    } finally {
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });
  test('board skin edited during settings load is not overwritten', () async {
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final store = DelayedMarkerPreferences();
    final preferences = PreferencesController(engine, store);
    store.value = AppPreferences(showCoordinates: false);
    try {
      final loading = preferences.initialize();
      final saving = preferences.setBoardSkin(BoardSkin.jade);
      store.gate.complete();
      await loading;
      await saving;
      await preferences.flush();
      expect(preferences.value.boardSkin, BoardSkin.jade);
      expect(preferences.value.showCoordinates, isFalse);
      expect(store.value, preferences.value);
    } finally {
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });
}
