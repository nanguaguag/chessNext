import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/features/settings/board_geometry_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      await tester.dragFrom(start, const Offset(20, 24));
      await tester.pump();

      expect(geometry.leftPercent, closeTo(100 * .5 / 9 + 20 / 216 * 100, .01));
      expect(geometry.topPercent, closeTo(15, .01));
      expect(
        geometry.rightPercent,
        const BoardSkinGeometry.standard().rightPercent,
      );
      expect(geometry.bottomPercent, 95);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stale parent rebuild does not snap an active drag backwards', (
    tester,
  ) async {
    const persisted = BoardSkinGeometry.standard();
    var latest = persisted;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 216,
                child: BoardGeometryEditor(
                  geometry: persisted,
                  onChanged: (next) => setState(() => latest = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(const ValueKey('board-grid-handle-top-left'));
    final origin = tester.getCenter(handle);
    await tester.drag(handle, const Offset(48, 0), touchSlopY: 0);
    await tester.pump();

    expect(latest.leftPercent, greaterThan(persisted.leftPercent));
    expect(tester.getCenter(handle).dx, greaterThan(origin.dx + 20));
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('grid handles support keyboard arrows and announce values', (
    tester,
  ) async {
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
    await tester.tap(handle);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(
      geometry.leftPercent,
      closeTo(const BoardSkinGeometry.standard().leftPercent + 1, .001),
    );
    expect(geometry.topPercent, closeTo(4, .001));
    final semantics = tester.getSemantics(handle).getSemanticsData();
    expect(semantics.label, '左上格点');
    expect(
      semantics.value,
      '左 ${geometry.leftPercent.toStringAsFixed(1)}%，上 4.0%',
    );
    expect(semantics.hint, contains('方向键'));
    expect(semantics.customSemanticsActionIds, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard movement respects the minimum grid span', (
    tester,
  ) async {
    var geometry = const BoardSkinGeometry.standard().copyWith(
      leftPercent: 40,
      topPercent: 40,
      rightPercent: 95,
      bottomPercent: 95,
    );
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
    await tester.tap(handle);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(geometry.leftPercent, 40);
    expect(geometry.topPercent, 40);
    expect(tester.takeException(), isNull);
  });
}
