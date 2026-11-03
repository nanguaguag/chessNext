import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;
import 'package:xiangqi_core/xiangqi_core.dart';

import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/board_skin_images.dart';

void main() {
  final image = Uint8List.fromList(
    raster.encodePng(raster.Image(width: 2, height: 2)),
  );

  testWidgets('custom board background and selected frame render', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 450,
              child: BoardDisplayScope(
                showCoordinates: false,
                boardSkinImages: {
                  BoardSkinImageSlot.boardBackground: image,
                  BoardSkinImageSlot.selectionFrame: image,
                },
                child: BoardSurface(
                  at: Position.initial().at,
                  selected: Square(4, 4),
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('board-skin-image-boardBackground')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('board-skin-image-selectionFrame')),
      findsOneWidget,
    );
  });

  testWidgets('only custom landing image rotates once for a changed move', (
    tester,
  ) async {
    Widget board(Object identity) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 450,
            child: BoardDisplayScope(
              showCoordinates: false,
              geometry: const BoardSkinGeometry.standard().copyWith(
                rotateLandingMarker: true,
              ),
              boardSkinImages: {
                BoardSkinImageSlot.startMarker: image,
                BoardSkinImageSlot.landingMarker: image,
              },
              child: BoardSurface(
                at: Position.initial().at,
                lastMove: Move.parse('h2e2'),
                lastMoveIdentity: identity,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(board('move-a'));
    final rotation = find.byKey(
      const ValueKey('landing-marker-image-rotation'),
    );
    expect(rotation, findsOneWidget);
    expect(tester.widget<AnimatedRotation>(rotation).turns, 0);
    expect(
      find.byKey(const ValueKey('board-skin-image-startMarker')),
      findsOneWidget,
    );

    await tester.pumpWidget(board('move-a'));
    expect(tester.widget<AnimatedRotation>(rotation).turns, 0);
    await tester.pumpWidget(board('move-b'));
    expect(tester.widget<AnimatedRotation>(rotation).turns, 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<AnimatedRotation>(rotation).turns, 1);
  });

  testWidgets('landing image rotation respects animation preferences', (
    tester,
  ) async {
    Widget board({
      required bool disableAnimations,
      required AnimationSpeed speed,
    }) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 450,
              child: BoardDisplayScope(
                showCoordinates: false,
                animationSpeed: speed,
                geometry: const BoardSkinGeometry.standard().copyWith(
                  rotateLandingMarker: true,
                ),
                boardSkinImages: {BoardSkinImageSlot.landingMarker: image},
                child: BoardSurface(
                  at: Position.initial().at,
                  lastMove: Move.parse('h2e2'),
                  lastMoveIdentity: Object(),
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      board(disableAnimations: true, speed: AnimationSpeed.standard),
    );
    final rotation = find.byKey(
      const ValueKey('landing-marker-image-rotation'),
    );
    expect(tester.widget<AnimatedRotation>(rotation).duration, Duration.zero);
    await tester.pumpWidget(
      board(disableAnimations: false, speed: AnimationSpeed.off),
    );
    expect(tester.widget<AnimatedRotation>(rotation).duration, Duration.zero);
    await tester.pumpWidget(
      board(disableAnimations: false, speed: AnimationSpeed.fast),
    );
    expect(
      tester.widget<AnimatedRotation>(rotation).duration,
      const Duration(milliseconds: 300),
    );
  });
}
