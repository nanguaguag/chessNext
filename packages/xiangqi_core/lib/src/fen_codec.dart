import 'board_types.dart';

/// Structural FEN codec shared by valid positions and incomplete editor drafts.
final class FenData {
  FenData(List<Piece?> board, this.turn, this.halfmove, this.fullmove)
    : board = List.unmodifiable(board) {
    if (board.length != 90) throw ArgumentError('Expected 90 squares');
  }
  final List<Piece?> board;
  final Side turn;
  final int halfmove;
  final int fullmove;
  factory FenData.parse(String fen) {
    if (fen.length > 4096) throw const FormatException('FEN input too long');
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
    return FenData(board, fields[1] == 'w' ? Side.red : Side.black, half, full);
  }
  String encode() {
    final rows = <String>[];
    for (var rank = 9; rank >= 0; rank--) {
      var row = '';
      var empty = 0;
      for (var file = 0; file < 9; file++) {
        final piece = board[Square(file, rank).index];
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
}
