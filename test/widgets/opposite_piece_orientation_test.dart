import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  testWidgets('only pieces on the visual top side are rotated', (tester) async {
    for (final (flipped, topSquare, bottomSquare) in [
      (false, 'square-a9', 'square-a0'),
      (true, 'square-a0', 'square-a9'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: BoardDisplayScope(
              showCoordinates: false,
              rotateOppositePieces: true,
              child: Center(
                child: SizedBox(
                  width: 450,
                  child: BoardSurface(
                    at: Position.initial().at,
                    flipped: flipped,
                    onTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final topCell = find.descendant(
        of: find.byKey(ValueKey(topSquare)),
        matching: find.byType(RotatedBox),
      );
      final bottomCell = find.descendant(
        of: find.byKey(ValueKey(bottomSquare)),
        matching: find.byType(RotatedBox),
      );
      expect(tester.widget<RotatedBox>(topCell).quarterTurns, 2);
      expect(tester.widget<RotatedBox>(bottomCell).quarterTurns, 0);
    }
  });

  testWidgets('orientation remains upright when the preference is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: SizedBox(
              width: 450,
              child: BoardSurface(at: Position.initial().at, onTap: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final square in ['square-a9', 'square-a0']) {
      final glyph = find.descendant(
        of: find.byKey(ValueKey(square)),
        matching: find.byType(RotatedBox),
      );
      expect(tester.widget<RotatedBox>(glyph).quarterTurns, 0);
    }
  });
}
