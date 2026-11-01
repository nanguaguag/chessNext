enum Side {
  red,
  black;

  Side get opponent => this == red ? black : red;
}

enum PieceType { general, advisor, elephant, horse, rook, cannon, pawn }

final class Piece {
  const Piece(this.side, this.type);
  final Side side;
  final PieceType type;
  String get fen {
    final letter = switch (type) {
      PieceType.general => 'k',
      PieceType.advisor => 'a',
      PieceType.elephant => 'b',
      PieceType.horse => 'n',
      PieceType.rook => 'r',
      PieceType.cannon => 'c',
      PieceType.pawn => 'p',
    };
    return side == Side.red ? letter.toUpperCase() : letter;
  }
}

/// UCI coordinates: a0 is red's left corner; a9 is black's right corner.
final class Square {
  factory Square(int file, int rank) {
    if (file < 0 || file > 8 || rank < 0 || rank > 9) {
      throw RangeError('Square outside 9×10 board: $file,$rank');
    }
    return Square._(file, rank);
  }
  const Square._(this.file, this.rank);
  factory Square.parse(String value) {
    if (!RegExp(r'^[a-i][0-9]$').hasMatch(value)) {
      throw FormatException('Invalid UCI square', value);
    }
    return Square(value.codeUnitAt(0) - 97, int.parse(value[1]));
  }
  final int file;
  final int rank;
  int get index => rank * 9 + file;
  @override
  String toString() => '${String.fromCharCode(97 + file)}$rank';
  @override
  bool operator ==(Object other) => other is Square && index == other.index;
  @override
  int get hashCode => index;
}

final class Move {
  const Move(this.from, this.to);
  factory Move.parse(String value) {
    if (value.length != 4) throw FormatException('Invalid UCI move', value);
    return Move(
      Square.parse(value.substring(0, 2)),
      Square.parse(value.substring(2)),
    );
  }
  final Square from;
  final Square to;
  @override
  String toString() => '$from$to';
  @override
  bool operator ==(Object other) =>
      other is Move && from == other.from && to == other.to;
  @override
  int get hashCode => Object.hash(from, to);
}

/// Immutable position. Parsing validates structure, not historical reachability.
final class Position {
  Position._(List<Piece?> board, this.turn, this.halfmove, this.fullmove)
    : _board = List.unmodifiable(board);
  static const initialFen =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';
  factory Position.initial() => Position.fromFen(initialFen);
  factory Position.fromFen(String fen) {
    final fields = fen.trim().split(RegExp(r'\s+'));
    if (fields.length != 2 && fields.length != 6) {
      throw FormatException('Expected 2 or 6 FEN fields', fen);
    }
    if (!['w', 'b'].contains(fields[1]) ||
        (fields.length == 6 && (fields[2] != '-' || fields[3] != '-'))) {
      throw FormatException('Invalid side or unsupported FEN rights', fen);
    }
    final half = fields.length == 6 ? int.tryParse(fields[4]) : 0;
    final full = fields.length == 6 ? int.tryParse(fields[5]) : 1;
    if (half == null || half < 0 || full == null || full < 1) {
      throw FormatException('Invalid FEN counters', fen);
    }
    final rows = fields[0].split('/');
    if (rows.length != 10) throw FormatException('Expected ten ranks', fen);
    final board = List<Piece?>.filled(90, null);
    const types = {
      'k': PieceType.general,
      'a': PieceType.advisor,
      'b': PieceType.elephant,
      'e': PieceType.elephant,
      'n': PieceType.horse,
      'h': PieceType.horse,
      'r': PieceType.rook,
      'c': PieceType.cannon,
      'p': PieceType.pawn,
    };
    for (var row = 0; row < 10; row++) {
      var file = 0;
      for (final char in rows[row].split('')) {
        final empty = int.tryParse(char);
        if (empty != null) {
          if (empty < 1 || empty > 9)
            throw FormatException('Invalid empty run', fen);
          file += empty;
        } else {
          final type = types[char.toLowerCase()];
          if (type == null || file >= 9)
            throw FormatException('Invalid piece/rank', fen);
          board[(9 - row) * 9 + file++] = Piece(
            char == char.toUpperCase() ? Side.red : Side.black,
            type,
          );
        }
        if (file > 9) throw FormatException('Rank overflow', fen);
      }
      if (file != 9) throw FormatException('Rank underflow', fen);
    }
    for (final side in Side.values) {
      if (board
              .where((p) => p?.side == side && p?.type == PieceType.general)
              .length !=
          1) {
        throw FormatException('Exactly one general required per side', fen);
      }
    }
    return Position._(
      board,
      fields[1] == 'w' ? Side.red : Side.black,
      half,
      full,
    );
  }
  final List<Piece?> _board;
  final Side turn;
  final int halfmove;
  final int fullmove;
  Piece? at(Square square) => _board[square.index];
  String toFen() {
    final rows = <String>[];
    for (var rank = 9; rank >= 0; rank--) {
      var row = '';
      var empty = 0;
      for (var file = 0; file < 9; file++) {
        final piece = at(Square(file, rank));
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) row += '$empty';
          empty = 0;
          row += piece.fen;
        }
      }
      if (empty > 0) row += '$empty';
      rows.add(row);
    }
    return '${rows.join('/')} ${turn == Side.red ? 'w' : 'b'} - - $halfmove $fullmove';
  }

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
