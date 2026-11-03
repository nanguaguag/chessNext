import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  testWidgets('main board animates moved piece at the selected speed', (
    tester,
  ) async {
    var position = Position.initial();
    Move? lastMove;
    var identity = 0;
    late void Function(VoidCallback) update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardDisplayScope(
            showCoordinates: false,
            animationSpeed: AnimationSpeed.slow,
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return BoardSurface(
                  at: position.at,
                  onTap: (_) {},
                  lastMove: lastMove,
                  lastMoveIdentity: identity,
                  animatePieceMoves: true,
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('moving-piece-overlay')), findsNothing);

    final move = Move.parse('h2e2');
    update(() {
      position = position.play(move);
      lastMove = move;
      identity++;
    });
    await tester.pump();
    final overlay = find.byKey(const ValueKey('moving-piece-overlay'));
    expect(overlay, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final positioned = tester.widget<Positioned>(
      find.descendant(of: overlay, matching: find.byType(Positioned)),
    );
    final step = tester.getSize(find.byType(BoardSurface)).width / 9;
    expect(positioned.left, greaterThan(4 * step));
    expect(positioned.left, lessThan(7 * step));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reduce Motion renders the final position without animation', (
    tester,
  ) async {
    var position = Position.initial();
    Move? lastMove;
    var identity = 0;
    late void Function(VoidCallback) update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: BoardDisplayScope(
              showCoordinates: false,
              animationSpeed: AnimationSpeed.slow,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return BoardSurface(
                    at: position.at,
                    onTap: (_) {},
                    lastMove: lastMove,
                    lastMoveIdentity: identity,
                    animatePieceMoves: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    final move = Move.parse('h2e2');
    update(() {
      position = position.play(move);
      lastMove = move;
      identity++;
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('moving-piece-overlay')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('off speed skips the movement animation', (tester) async {
    var position = Position.initial();
    Move? lastMove;
    var identity = 0;
    late void Function(VoidCallback) update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardDisplayScope(
            showCoordinates: false,
            animationSpeed: AnimationSpeed.off,
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return BoardSurface(
                  at: position.at,
                  onTap: (_) {},
                  lastMove: lastMove,
                  lastMoveIdentity: identity,
                  animatePieceMoves: true,
                );
              },
            ),
          ),
        ),
      ),
    );
    final move = Move.parse('h2e2');
    update(() {
      position = position.play(move);
      lastMove = move;
      identity++;
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('moving-piece-overlay')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
