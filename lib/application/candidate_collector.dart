import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';
import 'finite_search_executor.dart';
import 'review_models.dart';

class CandidateCollection {
  CandidateCollection(
    Iterable<CandidateEvaluation> entries,
    this.cacheHits,
    this.notice,
    this.searches,
  ) : entries = List.unmodifiable(entries);
  final List<CandidateEvaluation> entries;
  final int cacheHits;
  final int searches;
  final String? notice;
}

/// Shared by one-position inspection and each position in a batch review.
class CandidateCollector {
  CandidateCollector(this.executor);
  final FiniteSearchExecutor executor;
  Future<CandidateCollection?> collect({
    required Position position,
    required int maximum,
    required EngineRequest Function(List<Move>? remaining) makeRequest,
    required bool Function() isCurrent,
    bool skipExisting = true,
    void Function(int number, int total)? onSearch,
    void Function(List<CandidateEvaluation> entries, int hits)? onCandidate,
    void Function(EngineInfo)? onInfo,
  }) async {
    if (maximum < 1 || maximum > 256) {
      throw ArgumentError('Invalid candidate count');
    }
    final remaining = position.legalMoves.toList();
    final total = remaining.length < maximum ? remaining.length : maximum;
    final entries = <CandidateEvaluation>[];
    var hits = 0;
    var searches = 0;
    String? notice;
    while (remaining.isNotEmpty && entries.length < maximum) {
      if (!isCurrent()) return null;
      onSearch?.call(entries.length + 1, total);
      if (!isCurrent()) return null;
      final request = makeRequest(entries.isEmpty ? null : remaining);
      searches++;
      final result = await executor.execute(
        request,
        isCurrent: isCurrent,
        skipExisting: skipExisting,
        onInfo: onInfo,
      );
      if (!isCurrent() || result == null) return null;
      final move = result.move;
      if (move == null) {
        notice = '引擎未返回更多可评估着法';
        break;
      }
      if (!remaining.remove(move)) {
        throw StateError('Duplicate candidate');
      }
      if (result.cached) hits++;
      entries.add(CandidateEvaluation(move, result.info));
      onCandidate?.call(List.unmodifiable(entries), hits);
    }
    if (!isCurrent()) return null;
    return CandidateCollection(entries, hits, notice, searches);
  }
}
