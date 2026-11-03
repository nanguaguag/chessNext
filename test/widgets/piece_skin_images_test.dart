import 'dart:typed_data';

import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  testWidgets('custom image replaces only the matching piece slot', (
    tester,
  ) async {
    final bytes = Uint8List.fromList(
      raster.encodePng(raster.Image(width: 2, height: 2)),
    );
    final position = Position.initial();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 450,
              child: BoardSurface(
                at: position.at,
                onTap: (_) {},
                pieceImages: {PieceImageSlot.blackRook: bytes},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('square-a9')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('square-a8')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });
}
