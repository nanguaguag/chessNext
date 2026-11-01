part of 'engine_session_controller.dart';

extension EngineCandidates on EngineSessionController {
  CandidateRun? get candidates => _candidates;
  bool get inspectingCandidates => _candidates?.active ?? false;
  bool get batching => reviewing || inspectingCandidates;
  bool _candidateValid(int job) =>
      !_disposed &&
      job == _candidateJob &&
      _candidates?.phase == ReviewPhase.running &&
      _candidateSnapshotValid(_candidates!);
  bool _candidateSnapshotValid(CandidateRun run) =>
      !_disposed &&
      run.epoch == session.epoch &&
      run.revision == session.revision &&
      run.positionRevision == session.positionRevision &&
      session.tree.hasNode(run.parentId);

  Future<void> startCandidates({
    required ReviewLimits limits,
    int maximum = 5,
    bool skipExisting = true,
  }) async {
    if (maximum < 2 || maximum > 256) {
      throw ArgumentError('Invalid candidate count');
    }
    if (_disposed) return;
    final epoch = session.epoch;
    final revision = session.revision;
    final positionRevision = session.positionRevision;
    final stopping = disable();
    final intent = _generation;
    await stopping;
    if (_disposed ||
        intent != _generation ||
        epoch != session.epoch ||
        revision != session.revision ||
        positionRevision != session.positionRevision) {
      return;
    }
    final tree = session.tree;
    final parentId = tree.current.parentId ?? tree.root.id;
    final target = tree.goTo(parentId);
    final remaining = target.current.position.legalMoves.toList();
    _candidates = CandidateRun(
      tree: tree,
      parentId: parentId,
      epoch: epoch,
      revision: revision,
      positionRevision: positionRevision,
      limits: limits,
      maxCandidates: maximum,
      total: math.min(maximum, remaining.length),
    );
    final job = ++_candidateJob;
    _error = null;
    _notify();
    if (!_candidateValid(job)) return;
    if (remaining.isEmpty) {
      _clearBatchInfo();
      _candidates = _candidates!.copy(
        phase: ReviewPhase.completed,
        notice: '父局面无合法候选',
      );
      _notify();
      return;
    }
    try {
      final engine = await _getEngine();
      if (!_candidateValid(job)) return;
      await engine.initialize();
      if (!_candidateValid(job)) return;
      _settings = AnalysisSettings(
        threads: _settings.threads.clamp(1, maxThreads),
        hashMb: _settings.hashMb.clamp(1, maxHash),
        multiPv: _settings.multiPv.clamp(1, maxPv),
      );
      _notify();
      if (!_candidateValid(job)) return;
      final cache = ReviewCacheAccess(
        engine.identity,
        engine.options,
        reviewCache,
      );
      final collection =
          await CandidateCollector(FiniteSearchExecutor(engine, cache)).collect(
            position: target.current.position,
            maximum: maximum,
            skipExisting: skipExisting,
            isCurrent: () => _candidateValid(job),
            makeRequest: (allowed) => EngineRequest.fromTree(
              token: ++_generation,
              gameId: epoch,
              tree: target,
              depth: limits.depth,
              moveTimeMs: limits.moveTimeMs,
              nodeLimit: limits.nodeLimit,
              threads: _settings.threads,
              hashMb: _settings.hashMb,
              multiPv: 1,
              preferWdl: true,
              searchMoves: allowed,
            ),
            onSearch: (_, _) {
              _clearBatchInfo();
              _notify();
            },
            onInfo: (info) =>
                _recordBatchInfo(info, () => _candidateValid(job)),
            onCandidate: (entries, hits) {
              _candidates = _candidates!.copy(
                results: entries,
                cachedCount: hits,
                notice: cache.notice,
              );
              _notify();
            },
          );
      if (!_candidateValid(job) || collection == null) return;
      if (collection.notice != null) {
        _candidates = _candidates!.copy(notice: collection.notice);
      }
      if (!_candidateValid(job)) return;
      _clearBatchInfo();
      _candidates = _candidates!.copy(
        phase: ReviewPhase.completed,
        notice: _candidates!.notice ?? cache.notice,
      );
      _status = '候选分析已完成';
      _notify();
    } catch (e) {
      if (!_candidateValid(job)) return;
      _candidates = _candidates!.copy(
        phase: ReviewPhase.failed,
        error: '候选分析失败，可重试',
      );
      _failed(e, _generation);
    }
  }

  void _candidatesChanged() {
    final run = _candidates;
    if (run == null ||
        run.phase == ReviewPhase.stale ||
        _candidateSnapshotValid(run)) {
      return;
    }
    _candidateJob++;
    _candidates = run.copy(phase: ReviewPhase.stale);
    if (run.active) {
      unawaited(disable());
    } else {
      _notify();
    }
  }

  Future<bool> tryCandidate(CandidateRun run, Move move) async {
    if (!identical(run, _candidates) ||
        !_candidateSnapshotValid(run) ||
        !run.results.any((r) => r.move == move)) {
      return false;
    }
    final stopping = disable();
    final generation = _generation;
    await stopping;
    if (generation != _generation ||
        _stopFailedGeneration == generation ||
        !_candidateSnapshotValid(run)) {
      return false;
    }
    return session.playVariation(run.parentId, move);
  }
}
