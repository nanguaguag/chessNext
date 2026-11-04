import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/features/settings/board_geometry_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dragging top-left handle updates both edges in normalized space',
    (tester) async {
      var geometry = const BoardSkinGeometry.standard();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 216,
                child: BoardGeometryEditor(
                  geometry: geometry,
                  onChanged: (next) => geometry = next,
                ),
              ),
            ),
          ),
        ),
      );

      final handle = find.byKey(const ValueKey('board-grid-handle-top-left'));
      final start = tester.getCenter(handle);
      await tester.dragFrom(start, const Offset(10, 12));
      await tester.pump();

      expect(geometry.leftPercent, closeTo(100 * .5 / 9 + 10 / 216 * 100, .01));
      expect(geometry.topPercent, closeTo(10, .01));
      expect(
        geometry.rightPercent,
        const BoardSkinGeometry.standard().rightPercent,
      );
      expect(geometry.bottomPercent, 95);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dragging bottom-right handle respects grid span and canvas bounds',
    (tester) async {
      var geometry = const BoardSkinGeometry.standard();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 216,
                child: BoardGeometryEditor(
                  geometry: geometry,
                  onChanged: (next) => geometry = next,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey('board-grid-handle-bottom-right')),
        const Offset(1000, 1000),
      );
      await tester.pump();

      expect(geometry.rightPercent, 99);
      expect(geometry.bottomPercent, 99);
      expect(
        geometry.rightPercent - geometry.leftPercent,
        greaterThanOrEqualTo(BoardSkinGeometry.minSpanPercent),
      );
      expect(
        geometry.bottomPercent - geometry.topPercent,
        greaterThanOrEqualTo(BoardSkinGeometry.minSpanPercent),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
