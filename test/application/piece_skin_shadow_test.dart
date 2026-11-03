import 'dart:async';

import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class _DelayedShadowStore extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test('piece shadow settings validate and round trip per skin', () {
    final shadow = PieceSkinShadow(
      style: PieceShadowStyle.prominent,
      angleDegrees: 210,
      distancePercent: 7.5,
      blurPercent: 3.5,
      opacityPercent: 80,
    );
    final preferences = AppPreferences(
      pieceSkinShadows: {PieceSkin.squareInk: shadow},
    );
    expect(AppPreferences.fromJson(preferences.toJson()), preferences);
    expect(
      AppPreferences().pieceSkinShadows[PieceSkin.roundSeal]!.style,
      PieceShadowStyle.soft,
    );
    expect(
      AppPreferences().pieceSkinShadows[PieceSkin.squareInk]!.style,
      PieceShadowStyle.none,
    );
    final legacy = AppPreferences().toJson()..remove('pieceSkinShadows');
    expect(AppPreferences.fromJson(legacy), AppPreferences());
    expect(
      () => AppPreferences.fromJson({
        ...legacy,
        'pieceSkinShadows': {
          'squareInk': {1: 'bad'},
        },
      }),
      throwsFormatException,
    );
    for (final malformed in [
      {'style': 'future', 'angle': 0, 'distance': 1, 'blur': 1, 'opacity': 50},
      {'style': 'soft', 'angle': 360, 'distance': 1, 'blur': 1, 'opacity': 50},
      {'style': 'soft', 'angle': 0, 'distance': 21, 'blur': 1, 'opacity': 50},
      {'style': 'soft', 'angle': 0, 'distance': 1, 'blur': 1, 'opacity': 101},
    ]) {
      expect(() => PieceSkinShadow.fromJson(malformed), throwsFormatException);
    }
  });

  test('editing one skin shadow preserves another late-loaded skin', () async {
    final loaded = PieceSkinShadow(
      style: PieceShadowStyle.prominent,
      angleDegrees: 220,
      distancePercent: 8,
      blurPercent: 4,
      opacityPercent: 70,
    );
    final store = _DelayedShadowStore()
      ..value = AppPreferences(pieceSkinShadows: {PieceSkin.squareInk: loaded});
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final controller = PreferencesController(engine, store);
    try {
      final loading = controller.initialize();
      final edited = PieceSkinShadow(
        style: PieceShadowStyle.soft,
        angleDegrees: 90,
        distancePercent: 6.7,
        blurPercent: 2.4,
        opacityPercent: 50,
      );
      final change = controller.setPieceSkinShadow(PieceSkin.roundSeal, edited);
      store.gate.complete();
      await loading;
      await change;
      await controller.flush();
      expect(controller.value.pieceSkinShadows[PieceSkin.roundSeal], edited);
      expect(controller.value.pieceSkinShadows[PieceSkin.squareInk], loaded);
    } finally {
      controller.dispose();
      engine.dispose();
      session.dispose();
    }
  });

  testWidgets('shadow controls render from the active piece skin', (
    tester,
  ) async {
    final shadow = PieceSkinShadow(
      style: PieceShadowStyle.prominent,
      angleDegrees: 90,
      distancePercent: 10,
      blurPercent: 5,
      opacityPercent: 40,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 450,
              child: BoardDisplayScope(
                showCoordinates: false,
                pieceSkin: PieceSkin.squareInk,
                pieceSkinShadow: shadow,
                child: BoardSurface(at: Position.initial().at, onTap: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    final face = find.descendant(
      of: find.byKey(const ValueKey('square-h2')),
      matching: find.byType(Container),
    );
    final decorations = tester
        .widgetList<Container>(face)
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.boxShadow?.isNotEmpty ?? false)
        .toList();
    expect(decorations, isNotEmpty);
    final rendered = decorations.first.boxShadow!.first;
    expect(rendered.offset.dx.abs(), lessThan(0.01));
    expect(rendered.offset.dy, greaterThan(0));
    expect(rendered.color.a, closeTo(.4, .01));
  });
}
