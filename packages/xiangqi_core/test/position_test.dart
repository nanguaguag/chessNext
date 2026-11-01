import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

// Original hand-placed fixtures. e0/e9 generals with an e5 blocker by default.
Position board(Map<String, String> pieces, {String turn = 'w'}) {
  final cells = <String, String>{'e0': 'K', 'e9': 'k', 'e5': 'P', ...pieces};
  final rows = <String>[];
  for (var r = 9; r >= 0; r--) {
    var row = '';
    var empty = 0;
    for (var f = 0; f < 9; f++) {
      final p = cells['${String.fromCharCode(97 + f)}$r'];
      if (p == null || p.isEmpty) {
        empty++;
      } else {
        if (empty > 0) row += '$empty';
        empty = 0;
        row += p;
      }
    }
    if (empty > 0) row += '$empty';
    rows.add(row);
  }
  return Position.fromFen('${rows.join('/')} $turn - - 0 1');
}

Set<String> moves(Position p, String from) => p.legalMoves
    .where((m) => m.from.toString() == from)
    .map((m) => m.to.toString())
    .toSet();

void main() {
  test('coordinates and moves are value types with runtime validation', () {
    expect(Square.parse('i9'), Square(8, 9));
    expect(Move.parse('h2e2').toString(), 'h2e2');
    for (final value in ['a10', 'j0', 'A0', '', ' a0']) {
      expect(() => Square.parse(value), throwsFormatException);
    }
    expect(() => Square(-1, 0), throwsRangeError);
    expect(() => Move.parse('a0a0x'), throwsFormatException);
  });
  test('FEN roundtrip and aliases; malformed boards rejected', () {
    expect(Position.initial().toFen(), Position.initialFen);
    expect(
      Position.fromFen(
        Position.initialFen.replaceAll('n', 'h').replaceAll('B', 'E'),
      ).toFen(),
      Position.initialFen,
    );
    expect(
      Position.fromFen(Position.initialFen.split(' - ')[0]).toFen(),
      Position.initialFen,
    );
    for (final fen in [
      '9/9 w',
      Position.initialFen.replaceFirst('rnbakabnr', 'rnbakabn'),
      Position.initialFen.replaceFirst('rnbakabnr', 'rnbakabnrr'),
      Position.initialFen.replaceFirst('k', 'x'),
      Position.initialFen.replaceFirst('k', '1'),
      Position.initialFen.replaceFirst(' w ', ' r '),
      Position.initialFen.replaceFirst('0 1', '-1 1'),
      Position.initialFen.replaceFirst('- -', 'K -'),
    ]) {
      expect(() => Position.fromFen(fen), throwsFormatException, reason: fen);
    }
  });
  test('initial position, turn enforcement and immutable application', () {
    final p = Position.initial();
    expect(p.legalMoves.length, 44);
    expect(p.perft(2), 1920);
    expect(() => p.play(Move.parse('a9a8')), throwsArgumentError);
    final next = p.play(Move.parse('h2e2'));
    expect(next.turn, Side.black);
    expect(next.at(Square.parse('h2')), isNull);
    expect(next.at(Square.parse('e2'))?.type, PieceType.cannon);
    expect(p.toFen(), Position.initialFen);
    expect(next.halfmove, 1);
    expect(next.play(Move.parse('b9c7')).fullmove, 2);
  });
  test('horse leg blocks only corresponding long-axis directions', () {
    expect(moves(board({'b0': 'N'}), 'b0'), {'a2', 'c2', 'd1'});
    expect(moves(board({'b0': 'N', 'b1': 'P'}), 'b0'), {'d1'});
    expect(moves(board({'b0': 'N', 'c0': 'P'}), 'b0'), {'a2', 'c2'});
  });
  test('elephant eye, river and advisor palace', () {
    expect(moves(board({'c0': 'B'}), 'c0'), {'a2', 'e2'});
    expect(moves(board({'c0': 'B', 'd1': 'P'}), 'c0'), {'a2'});
    expect(moves(board({'e4': 'B'}), 'e4'), {'c2', 'g2'});
    expect(moves(board({'d0': 'A'}), 'd0'), {'e1'});
    expect(moves(board({'d9': 'a'}, turn: 'b'), 'd9'), {'e8'});
  });
  test('rook cannot jump or capture friendly pieces', () {
    final m = moves(board({'a0': 'R', 'a2': 'P', 'c0': 'p'}), 'a0');
    expect(m, {'a1', 'b0', 'c0'});
  });
  test('cannon requires exactly one screen for captures', () {
    expect(moves(board({'a0': 'C', 'a3': 'p'}), 'a0'), isNot(contains('a3')));
    final m = moves(board({'a0': 'C', 'a1': 'P', 'a3': 'p'}), 'a0');
    expect(m, contains('a3'));
    expect(m, isNot(contains('a2')));
    expect(
      moves(board({'a0': 'C', 'a1': 'P', 'a2': 'P', 'a3': 'p'}), 'a0'),
      isNot(contains('a3')),
    );
    final next = board({
      'a0': 'C',
      'a1': 'P',
      'a3': 'p',
    }).play(Move.parse('a0a3'));
    expect(next.halfmove, 0);
  });
  test('pawn river crossing and direction for both sides', () {
    expect(moves(board({'a3': 'P'}), 'a3'), {'a4'});
    expect(moves(board({'a5': 'P'}), 'a5'), {'a6', 'b5'});
    expect(moves(board({'a6': 'p'}, turn: 'b'), 'a6'), {'a5'});
    expect(moves(board({'a4': 'p'}, turn: 'b'), 'a4'), {'a3', 'b4'});
  });
  test('general stays in palace and may not expose facing generals', () {
    expect(moves(board({}), 'e0'), {'d0', 'f0', 'e1'});
    final p = board({'e5': '', 'e4': 'R'});
    expect(moves(p, 'e4'), isNot(contains('d4')));
    expect(p.isInCheck(Side.red), isFalse);
    expect(board({'e5': ''}).isInCheck(Side.red), isTrue);
  });
  test('checks by horse, cannon, pawn and rook are filtered', () {
    for (final pieces in [
      {'e5': '', 'e8': 'r'},
      {'e3': 'c', 'e1': 'P'},
      {'d2': 'n'},
      {'e1': 'p'},
    ]) {
      final p = board(pieces);
      expect(p.isInCheck(Side.red), isTrue, reason: '$pieces');
      for (final m in p.legalMoves) {
        expect(p.play(m).isInCheck(Side.red), isFalse);
      }
    }
  });
  test('pinned piece cannot expose rook check', () {
    final p = board({'e5': '', 'e8': 'r', 'e2': 'R'});
    expect(moves(p, 'e2'), isNot(contains('a2')));
    expect(moves(p, 'e2'), contains('e8'));
  });
}
