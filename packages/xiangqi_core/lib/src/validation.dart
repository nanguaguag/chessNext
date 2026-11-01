import 'position.dart';

/// Static setup errors; this does not prove historical reachability.
enum PositionIssueCode {
  missingGeneral,
  tooManyPieces,
  generalOutsidePalace,
  advisorOffPoint,
  elephantOffPoint,
  pawnBeforeStartingRank,
  pawnOffStartingFile,
  duplicateUncrossedPawnFile,
  facingGenerals,
  nonMovingSideInCheck,
}

final class PositionIssue {
  PositionIssue(this.code, this.side, Iterable<Square> squares)
    : squares = List.unmodifiable(squares);
  final PositionIssueCode code;
  final Side side;
  final List<Square> squares;
}

final class PositionValidation {
  PositionValidation(Iterable<PositionIssue> issues)
    : issues = List.unmodifiable(issues);
  final List<PositionIssue> issues;
  bool get isValid => issues.isEmpty;
}

extension PositionSetupValidation on Position {
  /// Checks local setup constraints before starting play or engine analysis.
  /// The moving side may be in check; the non-moving side must not be.
  /// Repetition, chase and history-dependent adjudication are not covered.
  PositionValidation validateForPlay() {
    final issues = <PositionIssue>[];
    final pieces = <Side, Map<PieceType, List<Square>>>{
      for (final side in Side.values)
        side: {for (final type in PieceType.values) type: <Square>[]},
    };
    void report(PositionIssueCode code, Side side, Iterable<Square> squares) {
      issues.add(PositionIssue(code, side, squares));
    }

    for (var rank = 0; rank < 10; rank++) {
      for (var file = 0; file < 9; file++) {
        final square = Square(file, rank);
        final piece = at(square);
        if (piece == null) continue;
        pieces[piece.side]![piece.type]!.add(square);
        // Mirror black to red's home-side coordinates.
        final homeRank = piece.side == Side.red ? rank : 9 - rank;
        final homePoint = '${String.fromCharCode(97 + file)}$homeRank';
        switch (piece.type) {
          case PieceType.general:
            if (file < 3 || file > 5 || homeRank > 2) {
              report(PositionIssueCode.generalOutsidePalace, piece.side, [
                square,
              ]);
            }
          case PieceType.advisor:
            if (!const {'d0', 'f0', 'e1', 'd2', 'f2'}.contains(homePoint)) {
              report(PositionIssueCode.advisorOffPoint, piece.side, [square]);
            }
          case PieceType.elephant:
            if (!const {
              'c0',
              'g0',
              'a2',
              'e2',
              'i2',
              'c4',
              'g4',
            }.contains(homePoint)) {
              report(PositionIssueCode.elephantOffPoint, piece.side, [square]);
            }
          case PieceType.pawn:
            if (homeRank < 3) {
              report(PositionIssueCode.pawnBeforeStartingRank, piece.side, [
                square,
              ]);
            } else if (homeRank < 5 && file.isOdd) {
              report(PositionIssueCode.pawnOffStartingFile, piece.side, [
                square,
              ]);
            }
          case PieceType.horse:
          case PieceType.rook:
          case PieceType.cannon:
            break;
        }
      }
    }
    const limits = {
      PieceType.general: 1,
      PieceType.advisor: 2,
      PieceType.elephant: 2,
      PieceType.horse: 2,
      PieceType.rook: 2,
      PieceType.cannon: 2,
      PieceType.pawn: 5,
    };
    for (final side in Side.values) {
      for (final entry in limits.entries) {
        final squares = pieces[side]![entry.key]!;
        if (squares.length > entry.value) {
          report(PositionIssueCode.tooManyPieces, side, squares);
        }
      }
    }
    for (final side in Side.values) {
      for (var file = 0; file < 9; file++) {
        final pawns = pieces[side]![PieceType.pawn]!.where(
          (square) =>
              square.file == file &&
              (side == Side.red ? square.rank < 5 : square.rank > 4),
        );
        if (pawns.length > 1) {
          report(PositionIssueCode.duplicateUncrossedPawnFile, side, pawns);
        }
      }
    }
    // Position.fromFen guarantees one general per side.
    final red = pieces[Side.red]![PieceType.general]!.single;
    final black = pieces[Side.black]![PieceType.general]!.single;
    if (red.file == black.file) {
      var blocked = false;
      final low = red.rank < black.rank ? red.rank : black.rank;
      final high = red.rank > black.rank ? red.rank : black.rank;
      for (var rank = low + 1; rank < high; rank++) {
        if (at(Square(red.file, rank)) != null) {
          blocked = true;
          break;
        }
      }
      if (!blocked) {
        report(PositionIssueCode.facingGenerals, Side.red, [red, black]);
      }
    }
    if (isInCheck(turn.opponent)) {
      report(
        PositionIssueCode.nonMovingSideInCheck,
        turn.opponent,
        pieces[turn.opponent]![PieceType.general]!,
      );
    }
    return PositionValidation(issues);
  }
}
