import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';
import 'review_models.dart';

class CandidateEvaluation {
  const CandidateEvaluation(this.move, this.info);
  final Move move;
  final EngineInfo? info;
}

class CandidateRun {
  CandidateRun({
    required this.tree,
    required this.parentId,
    required this.epoch,
    required this.revision,
    required this.positionRevision,
    required this.limits,
    required this.maxCandidates,
    required this.total,
    this.phase = ReviewPhase.running,
    Iterable<CandidateEvaluation> results = const [],
    this.cachedCount = 0,
    this.notice,
    this.error,
  }) : results = List.unmodifiable(results);
  final GameTree tree;
  final String parentId;
  final int epoch,
      revision,
      positionRevision,
      maxCandidates,
      total,
      cachedCount;
  final ReviewLimits limits;
  final ReviewPhase phase;
  final List<CandidateEvaluation> results;
  final String? notice, error;
  bool get active =>
      phase == ReviewPhase.running || phase == ReviewPhase.stopping;
  Position get position => tree.node(parentId).position;
  CandidateRun copy({
    ReviewPhase? phase,
    Iterable<CandidateEvaluation>? results,
    int? cachedCount,
    String? notice,
    String? error,
  }) => CandidateRun(
    tree: tree,
    parentId: parentId,
    epoch: epoch,
    revision: revision,
    positionRevision: positionRevision,
    limits: limits,
    maxCandidates: maxCandidates,
    total: total,
    phase: phase ?? this.phase,
    results: results ?? this.results,
    cachedCount: cachedCount ?? this.cachedCount,
    notice: notice ?? this.notice,
    error: error ?? this.error,
  );
}
