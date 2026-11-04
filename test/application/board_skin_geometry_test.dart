import 'dart:async';

import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedGeometryStore extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'normalized geometry validates bounds and round trips per board skin',
    () {
      final geometry = BoardSkinGeometry(
        leftPercent: 10,
        topPercent: 8,
        rightPercent: 90,
        bottomPercent: 92,
        pieceScalePercent: 110,
        rotateLandingMarker: true,
      );
      expect(BoardSkinGeometry.fromJson(geometry.toJson()), geometry);
      expect(geometry.copyWith().pieceScalePercent, 110);
      expect(geometry.copyWith().rotateLandingMarker, isTrue);
      expect(
        BoardSkinGeometry.fromJson({
          'left': 100 * .5 / 9,
          'top': 5,
          'right': 100 * 8.5 / 9,
          'bottom': 95,
          'pieceScale': 100,
        }).rotateLandingMarker,
        isFalse,
      );
      expect(
        () => BoardSkinGeometry(leftPercent: 20, rightPercent: 70),
        throwsArgumentError,
      );

      final preferences = AppPreferences(
        boardSkin: BoardSkin.jade,
        boardGeometries: {BoardSkin.jade: geometry},
      );
      expect(AppPreferences.fromJson(preferences.toJson()), preferences);
      final customSelection = AppPreferences(
        boardSkin: BoardSkin.jade,
        selectedBoardSkinId: 'custom-12345678-abcd',
      );
      expect(
        AppPreferences.fromJson(customSelection.toJson()),
        customSelection,
      );
      expect(
        () => AppPreferences.fromJson({
          ...AppPreferences().toJson(),
          'selectedBoardSkinId': '../outside',
        }),
        throwsFormatException,
      );
      expect(
        preferences.boardGeometries[BoardSkin.parchment],
        const BoardSkinGeometry.standard(),
      );
      expect(
        () => AppPreferences.fromJson({
          ...AppPreferences().toJson(),
          'boardGeometries': {
            'parchment': {
              'left': 20,
              'top': 5,
              'right': 70,
              'bottom': 95,
              'pieceScale': 100.5,
            },
          },
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'editing one skin geometry does not erase other late-loaded geometry',
    () async {
      final parchment = BoardSkinGeometry(
        leftPercent: 10,
        rightPercent: 90,
        topPercent: 7,
        bottomPercent: 93,
      );
      final store = _DelayedGeometryStore()
        ..value = AppPreferences(
          boardGeometries: {BoardSkin.parchment: parchment},
        );
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final controller = PreferencesController(engine, store);
      try {
        final loading = controller.initialize();
        final edit = controller.setBoardSkinGeometry(
          BoardSkin.jade,
          BoardSkinGeometry(
            leftPercent: 12,
            rightPercent: 88,
            topPercent: 9,
            bottomPercent: 91,
          ),
        );
        store.gate.complete();
        await loading;
        await edit;
        await controller.flush();
        expect(
          controller.value.boardGeometries[BoardSkin.parchment],
          parchment,
        );
        expect(
          controller.value.boardGeometries[BoardSkin.jade]!.leftPercent,
          12,
        );
      } finally {
        controller.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
