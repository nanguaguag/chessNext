import 'package:chess_next/chess_next.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Flutter host consumes immutable offline rules through package boundary',
    () {
      final start = Position.initial();
      final next = start.play(Move.parse('h2e2'));
      expect(start.toFen(), Position.initialFen);
      expect(next.turn, Side.black);
      expect(next.at(Square.parse('e2'))?.type, PieceType.cannon);
      expect(next.isInCheck(Side.black), isFalse);
    },
  );
  test('Flutter host rejects illegal moves without mutating the board', () {
    final start = Position.initial();
    expect(() => start.play(Move.parse('b0b3')), throwsArgumentError);
    expect(start.toFen(), Position.initialFen);
    expect(start.legalMoves.length, 44);
  });
}
