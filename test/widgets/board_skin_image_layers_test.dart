import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;
import 'package:xiangqi_core/xiangqi_core.dart';

import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/board_skin_images.dart';

void main() {
  testWidgets('custom board background and selected frame render', (
    tester,
  ) async {
    final image = Uint8List.fromList(
      raster.encodePng(raster.Image(width: 2, height: 2)),
    );
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
}
