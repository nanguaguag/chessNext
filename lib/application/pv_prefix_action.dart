import 'dart:isolate';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'analysis_history.dart';

enum PvApplyResult {
  applied,
  stale,
  cancelled,
  invalid,
  capacity,
  stopFailed,
  failed,
  busy,
}

class PvApplyCancellation {
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class PvPrefixAction {
  const PvPrefixAction({
    required bool Function() isCurrent,
    required this.perform,
  }) : _current = isCurrent;
  final bool Function() _current;
  final Future<PvApplyResult> Function(int, PvApplyCancellation) perform;
  bool get isCurrent => _current();
  Future<PvApplyResult> apply(int plies, PvApplyCancellation cancellation) =>
      perform(plies, cancellation);
}

typedef PvPrefixActionFactory = PvPrefixAction Function(PvHistoryEntry entry);
typedef PvPrefixPlanner =
    Future<({GameTree? tree, PvApplyResult? error})> Function(
      GameTree source,
      List<Move> moves,
    );

abstract final class PvPrefixPlan {
  // Same bound as the current GameTree serialization schema.
  static const maxDocumentNodes = 2000;
  static Future<({GameTree? tree, PvApplyResult? error})> prepareInWorker(
    GameTree source,
    List<Move> moves,
  ) {
    final frozen = List<Move>.unmodifiable(moves);
    return Isolate.run(() => _prepare(source, frozen));
  }

  static ({GameTree? tree, PvApplyResult? error}) _prepare(
    GameTree source,
    List<Move> moves,
  ) {
    if (moves.isEmpty || moves.length > AnalysisHistory.maxPlies) {
      return (tree: null, error: PvApplyResult.invalid);
    }
    var next = source;
    try {
      for (final move in moves) {
        next = next.play(move);
        if (next.nodeCount > maxDocumentNodes) {
          return (tree: null, error: PvApplyResult.capacity);
        }
      }
    } on ArgumentError {
      return (tree: null, error: PvApplyResult.invalid);
    }
    return (tree: next, error: null);
  }
}
