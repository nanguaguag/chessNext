import 'board_types.dart';
import 'fen_codec.dart';
import 'position.dart' show Position;
import 'validation.dart';

/// An immutable editor board that may temporarily contain missing/extra pieces.
final class SetupDraft {
  SetupDraft._(this._data);
  factory SetupDraft.fromPosition(Position position) =>
      SetupDraft.fromFen(position.toFen());
  factory SetupDraft.fromFen(String fen) => SetupDraft._(FenData.parse(fen));
  final FenData _data;
  Side get turn => _data.turn;
  Piece? at(Square square) => _data.board[square.index];
  String toFen() => _data.encode();

  /// Available pieces in the editor box; raw imports may still exceed this cap.
  int remaining(Piece piece) {
    final limit = switch (piece.type) {
      PieceType.general => 1,
      PieceType.pawn => 5,
      _ => 2,
    };
    final used = _data.board.where((p) => p?.fen == piece.fen).length;
    return (limit - used).clamp(0, limit);
  }

  SetupDraft place(Square square, Piece? piece) {
    if (at(square)?.fen == piece?.fen) return this;
    final board = List<Piece?>.of(_data.board)..[square.index] = piece;
    return SetupDraft._(FenData(board, turn, 0, 1));
  }

  SetupDraft move(Square from, Square to) {
    final piece = at(from);
    if (piece == null) throw ArgumentError('No piece at source');
    if (from == to) return this;
    return place(from, null).place(to, piece);
  }

  SetupDraft withTurn(Side side) =>
      side == turn ? this : SetupDraft._(FenData(_data.board, side, 0, 1));
  SetupDraft initial() => SetupDraft.fromPosition(Position.initial());

  /// Reference site clears to non-facing generals and preserves the selected turn.
  SetupDraft clear() {
    final board = List<Piece?>.filled(90, null);
    board[Square(3, 9).index] = const Piece(Side.black, PieceType.general);
    board[Square(4, 0).index] = const Piece(Side.red, PieceType.general);
    return SetupDraft._(FenData(board, turn, 0, 1));
  }

  SetupDraft swapSides() {
    final board = List<Piece?>.filled(90, null);
    for (var rank = 0; rank < 10; rank++) {
      for (var file = 0; file < 9; file++) {
        final piece = at(Square(file, rank));
        if (piece != null)
          board[Square(file, 9 - rank).index] = Piece(
            piece.side.opponent,
            piece.type,
          );
      }
    }
    return SetupDraft._(FenData(board, turn.opponent, 0, 1));
  }

  PositionValidation get validation {
    final issues = <PositionIssue>[];
    for (final side in Side.values) {
      final generals = <Square>[];
      for (var rank = 0; rank < 10; rank++) {
        for (var file = 0; file < 9; file++) {
          final square = Square(file, rank);
          final piece = at(square);
          if (piece?.side == side && piece?.type == PieceType.general)
            generals.add(square);
        }
      }
      if (generals.isEmpty)
        issues.add(
          PositionIssue(PositionIssueCode.missingGeneral, side, generals),
        );
      else if (generals.length > 1)
        issues.add(
          PositionIssue(PositionIssueCode.tooManyPieces, side, generals),
        );
    }
    if (issues.isNotEmpty) return PositionValidation(issues);
    return Position.fromFen(toFen()).validateForPlay();
  }

  Position toPosition() {
    if (!validation.isValid) throw ArgumentError('Invalid setup draft');
    return Position.fromFen(toFen());
  }
}
