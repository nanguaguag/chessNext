import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';

enum ReviewScope { line, tree }

enum ReviewPhase { running, stopping, cancelled, completed, failed, stale }

enum ReviewScoreStatus { scored, noScore, terminal }

/// At least one finite limit is mandatory for a batch job.
class ReviewLimits {
  ReviewLimits({this.depth = 16, this.moveTimeMs = 2000, this.nodeLimit}) {
    if (depth == null && moveTimeMs == null && nodeLimit == null) {
      throw ArgumentError('Review requires a finite search budget');
    }
    // Keep the same policy validation at the engine port boundary.
    EngineRequest(
      token: 0,
      root: Position.initial(),
      depth: depth,
      moveTimeMs: moveTimeMs,
      nodeLimit: nodeLimit,
    );
  }
  final int? depth;
  final int? moveTimeMs;
  final int? nodeLimit;
}

class ReviewedPosition {
  const ReviewedPosition({
    required this.nodeId,
    required this.turn,
    required this.status,
    this.info,
  });
  final String nodeId;
  final Side turn;
  final ReviewScoreStatus status;

  /// Original engine data, including score kind and bounds. Null is never zero.
  final EngineInfo? info;
  int? get redScore => info == null
      ? null
      : turn == Side.red
      ? info!.score
      : -info!.score;
  String? get redBound => turn == Side.red
      ? info?.bound
      : info?.bound == 'lower'
      ? 'upper'
      : info?.bound == 'upper'
      ? 'lower'
      : null;
  String get label {
    final score = redScore;
    if (score == null) {
      return status == ReviewScoreStatus.terminal ? '终局（无引擎评分）' : '未取得评分';
    }
    final bound = redBound == 'lower'
        ? '≥'
        : redBound == 'upper'
        ? '≤'
        : '';
    return info!.isMate
        ? '红方 $bound杀棋 $score'
        : '红方 $bound${score >= 0 ? '+' : ''}${(score / 100).toStringAsFixed(2)}';
  }
}

/// Immutable snapshot: cursor navigation is allowed, document edits invalidate it.
class ReviewRun {
  ReviewRun({
    required this.epoch,
    required this.revision,
    required this.tree,
    required this.scope,
    required this.limits,
    required Iterable<String> nodeIds,
    this.phase = ReviewPhase.running,
    Map<String, ReviewedPosition> results = const {},
    this.currentNodeId,
    this.error,
  }) : nodeIds = List.unmodifiable(nodeIds),
       results = Map.unmodifiable(results);
  final int epoch;
  final int revision;
  final GameTree tree;
  final ReviewScope scope;
  final ReviewLimits limits;
  final List<String> nodeIds;
  final ReviewPhase phase;
  final Map<String, ReviewedPosition> results;
  final String? currentNodeId;
  final String? error;
  bool get active =>
      phase == ReviewPhase.running || phase == ReviewPhase.stopping;
  ReviewRun copy({
    ReviewPhase? phase,
    Map<String, ReviewedPosition>? results,
    String? currentNodeId,
    String? error,
  }) => ReviewRun(
    epoch: epoch,
    revision: revision,
    tree: tree,
    scope: scope,
    limits: limits,
    nodeIds: nodeIds,
    phase: phase ?? this.phase,
    results: results ?? this.results,
    currentNodeId: currentNodeId ?? this.currentNodeId,
    error: error ?? this.error,
  );
}
