import 'dart:async';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';
import 'review_cache_access.dart';

class FiniteSearchResult {
  const FiniteSearchResult(this.move, this.info, {this.cached = false});
  final Move? move;
  final EngineInfo? info;
  final bool cached;
}

/// Executes one finite single-PV request. The session coordinator owns the engine
/// and stop barrier; this class never spawns a process or starts another job.
class FiniteSearchExecutor {
  FiniteSearchExecutor(this.engine, this.cache);
  final EngineGateway engine;
  final ReviewCacheAccess cache;
  Future<FiniteSearchResult?> execute(
    EngineRequest request, {
    required bool Function() isCurrent,
    bool skipExisting = true,
    void Function(EngineInfo)? onInfo,
  }) async {
    if (request.depth == null &&
        request.moveTimeMs == null &&
        request.nodeLimit == null) {
      throw ArgumentError('Finite search requires a budget');
    }
    if (request.multiPv != 1) {
      throw ArgumentError('Finite search requires single PV');
    }
    if (!isCurrent()) return null;
    final legal = request.position.legalMoves.toSet();
    final allowed = request.searchMoves?.toSet() ?? legal;
    if (allowed.isEmpty || !legal.containsAll(allowed)) {
      throw ArgumentError('Invalid allowed move set');
    }
    final cached = skipExisting ? await cache.read(request) : null;
    if (!isCurrent()) return null;
    if (cached != null) {
      return FiniteSearchResult(cached.pv.first, cached, cached: true);
    }
    EngineInfo? latest;
    final streamFailure = Completer<Move?>();
    streamFailure.future.ignore();
    final subscription = engine.info.listen(
      (info) {
        if (!isCurrent() ||
            info.token != request.token ||
            info.multiPv != 1 ||
            info.pv.isEmpty ||
            !allowed.contains(info.pv.first)) {
          return;
        }
        latest = info;
        onInfo?.call(info);
      },
      onError: (Object e) {
        if (!streamFailure.isCompleted) streamFailure.completeError(e);
      },
      onDone: () {
        if (!streamFailure.isCompleted) {
          streamFailure.completeError(StateError('Engine info stream closed'));
        }
      },
    );
    try {
      final search = await engine.start(request);
      if (!isCurrent()) return null;
      final move = await Future.any([search.bestMove, streamFailure.future]);
      await Future<void>.delayed(Duration.zero);
      if (!isCurrent()) return null;
      if (move != null && !allowed.contains(move)) {
        throw StateError('Engine returned an illegal or excluded bestmove');
      }
      var info = latest?.pv.firstOrNull == move && move != null ? latest : null;
      if (info != null) {
        var position = request.position;
        try {
          for (final step in info.pv) {
            position = position.play(step);
          }
        } on ArgumentError {
          info = null;
        }
      }
      await cache.write(request, info);
      if (!isCurrent()) return null;
      return FiniteSearchResult(move, info);
    } catch (_) {
      if (!isCurrent()) return null;
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }
}
