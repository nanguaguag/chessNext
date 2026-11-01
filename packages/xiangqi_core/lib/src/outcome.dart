import 'position.dart';
import 'validation.dart';

/// Board-only result, excluding repetition, chase and move-count adjudication.
enum BoardStatus { ongoing, checkmate, stalemate }

final class BoardOutcome {
  const BoardOutcome._(this.status, this.winner);
  final BoardStatus status;

  /// In Xiangqi, both checkmate and stalemate lose for the side to move.
  final Side? winner;
  bool get isTerminal => status != BoardStatus.ongoing;
}

extension PositionOutcome on Position {
  /// Rejects invalid editor setups rather than misreporting a game result.
  BoardOutcome boardOutcome() {
    if (!validateForPlay().isValid) {
      throw StateError('Cannot adjudicate an invalid setup');
    }
    if (legalMoves.isNotEmpty) {
      return const BoardOutcome._(BoardStatus.ongoing, null);
    }
    return BoardOutcome._(
      isInCheck(turn) ? BoardStatus.checkmate : BoardStatus.stalemate,
      turn.opponent,
    );
  }
}
