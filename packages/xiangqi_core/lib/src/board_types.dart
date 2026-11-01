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
