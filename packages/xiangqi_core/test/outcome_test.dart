import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'support/position_fixture.dart';

void main() {
  test('initial position is ongoing without a winner', () {
    final result = Position.initial().boardOutcome();
    expect(result.status, BoardStatus.ongoing);
    expect(result.winner, isNull);
    expect(result.isTerminal, isFalse);
  });
  test('check alone is not checkmate if an escape is legal', () {
    final p = board({'e3': 'r'});
    expect(p.isInCheck(Side.red), isTrue);
    expect(p.boardOutcome().isTerminal, isFalse);
  });
  test('checkmate loses for the moving side', () {
    final p = board({'e1': 'r', 'd1': 'r', 'f1': 'p'});
    expect(p.validateForPlay().isValid, isTrue);
    expect(p.isInCheck(Side.red), isTrue);
    expect(p.legalMoves, isEmpty);
    expect(p.boardOutcome().status, BoardStatus.checkmate);
    expect(p.boardOutcome().winner, Side.black);
  });
  test('red stalemate loses rather than drawing', () {
    final p = board({'e5': 'p', 'd1': 'r', 'f1': 'r'});
    expect(p.validateForPlay().isValid, isTrue);
    expect(p.isInCheck(Side.red), isFalse);
    expect(p.legalMoves, isEmpty);
    expect(p.boardOutcome().status, BoardStatus.stalemate);
    expect(p.boardOutcome().winner, Side.black);
  });
  test('black stalemate loses rather than drawing', () {
    final p = board({'e5': '', 'e4': 'P', 'd8': 'R', 'f8': 'R'}, turn: 'b');
    expect(p.validateForPlay().isValid, isTrue);
    expect(p.isInCheck(Side.black), isFalse);
    expect(p.boardOutcome().status, BoardStatus.stalemate);
    expect(p.boardOutcome().winner, Side.red);
  });
  test('invalid facing generals are not reported as a normal outcome', () {
    expect(() => board({'e5': ''}).boardOutcome(), throwsStateError);
  });
}
