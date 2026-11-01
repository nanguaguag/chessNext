import 'board_types.dart';
import 'fen_codec.dart';
export 'board_types.dart';

/// Immutable legal-play board. Structural parsing does not prove reachability.
final class Position {
  Position._(List<Piece?> board, this.turn, this.halfmove, this.fullmove)
    : _board = List.unmodifiable(board);
  static const initialFen =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';
  factory Position.initial() => Position.fromFen(initialFen);
  factory Position.fromFen(String fen) {
    final data = FenData.parse(fen);
    for (final side in Side.values) {
      if (data.board
              .where((p) => p?.side == side && p?.type == PieceType.general)
              .length !=
          1) {
        throw FormatException('Exactly one general required per side', fen);
      }
    }
    return Position._(data.board, data.turn, data.halfmove, data.fullmove);
  }
  final List<Piece?> _board;
  final Side turn;
  final int halfmove;
  final int fullmove;
  Piece? at(Square square) => _board[square.index];
  String toFen() => FenData(_board, turn, halfmove, fullmove).encode();

  static bool _palace(Square s, Side side) =>
      s.file >= 3 &&
      s.file <= 5 &&
      (side == Side.red ? s.rank <= 2 : s.rank >= 7);
  int _screens(Square from, Square to) {
    final dx = (to.file - from.file).sign;
    final dy = (to.rank - from.rank).sign;
    var count = 0;
    var x = from.file + dx;
    var y = from.rank + dy;
    while (x != to.file || y != to.rank) {
      if (at(Square(x, y)) != null) count++;
      x += dx;
      y += dy;
    }
    return count;
  }

  bool _attacks(Square from, Square to) {
    final p = at(from);
    if (p == null || from == to) return false;
    final dx = to.file - from.file;
    final dy = to.rank - from.rank;
    final ax = dx.abs();
    final ay = dy.abs();
    switch (p.type) {
      case PieceType.general:
        if (dx == 0 &&
            at(to)?.type == PieceType.general &&
            _screens(from, to) == 0)
          return true;
        return ax + ay == 1 && _palace(to, p.side);
      case PieceType.advisor:
        return ax == 1 && ay == 1 && _palace(to, p.side);
      case PieceType.elephant:
        return ax == 2 &&
            ay == 2 &&
            (p.side == Side.red ? to.rank <= 4 : to.rank >= 5) &&
            at(Square(from.file + dx ~/ 2, from.rank + dy ~/ 2)) == null;
      case PieceType.horse:
        if (!((ax == 2 && ay == 1) || (ax == 1 && ay == 2))) return false;
        return at(
              Square(
                from.file + (ax == 2 ? dx.sign : 0),
                from.rank + (ay == 2 ? dy.sign : 0),
              ),
            ) ==
            null;
      case PieceType.rook:
        return (dx == 0 || dy == 0) && _screens(from, to) == 0;
      case PieceType.cannon:
        return (dx == 0 || dy == 0) &&
            _screens(from, to) == (at(to) == null ? 0 : 1);
      case PieceType.pawn:
        final forward = p.side == Side.red ? 1 : -1;
        return (dx == 0 && dy == forward) ||
            ((p.side == Side.red ? from.rank >= 5 : from.rank <= 4) &&
                ay == 0 &&
                ax == 1);
    }
  }

  bool isInCheck(Side side) {
    final king = _board.indexWhere(
      (p) => p?.side == side && p?.type == PieceType.general,
    );
    if (king < 0) throw StateError('Missing general');
    final target = Square(king % 9, king ~/ 9);
    for (var i = 0; i < 90; i++) {
      if (_board[i]?.side == side.opponent &&
          _attacks(Square(i % 9, i ~/ 9), target))
        return true;
    }
    return false;
  }

  Iterable<Move> get legalMoves sync* {
    for (var i = 0; i < 90; i++) {
      if (_board[i]?.side != turn) continue;
      final from = Square(i % 9, i ~/ 9);
      for (var j = 0; j < 90; j++) {
        final to = Square(j % 9, j ~/ 9);
        if (at(to)?.side == turn ||
            at(to)?.type == PieceType.general ||
            !_attacks(from, to))
          continue;
        final move = Move(from, to);
        if (!_apply(move).isInCheck(turn)) yield move;
      }
    }
  }

  Position play(Move move) {
    if (!legalMoves.contains(move))
      throw ArgumentError.value(move, 'move', 'Illegal move');
    return _apply(move);
  }

  Position _apply(Move move) {
    final board = List<Piece?>.of(_board);
    final capture = at(move.to) != null;
    board[move.to.index] = board[move.from.index];
    board[move.from.index] = null;
    return Position._(
      board,
      turn.opponent,
      capture ? 0 : halfmove + 1,
      fullmove + (turn == Side.black ? 1 : 0),
    );
  }

  /// Perft counts legal move trees, excluding history-dependent adjudication.
  int perft(int depth) {
    if (depth < 0) throw RangeError.value(depth, 'depth');
    if (depth == 0) return 1;
    var nodes = 0;
    for (final move in legalMoves) {
      nodes += _apply(move).perft(depth - 1);
    }
    return nodes;
  }
}
