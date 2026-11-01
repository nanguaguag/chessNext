import 'package:chess_next/chess_next.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'application can distinguish stalemate from checkmate and show winner',
    () {
      final p = Position.fromFen('4k4/9/9/9/4p4/9/9/9/3r1r3/4K4 w - - 0 1');
      final result = p.boardOutcome();
      expect(result.status, BoardStatus.stalemate);
      expect(result.isTerminal, isTrue);
      expect(result.winner, Side.black);
    },
  );
  test('application cannot label an invalid editor draft as game over', () {
    final p = Position.fromFen('4k4/9/9/9/9/9/9/9/9/4K4 w - - 0 1');
    expect(p.boardOutcome, throwsStateError);
  });
}
