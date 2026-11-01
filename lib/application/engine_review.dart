part of 'engine_session_controller.dart';

extension EngineReview on EngineSessionController {
  ReviewRun? get review => _review;
  bool get reviewing => _review?.active ?? false;

  /// Starts a single finite queue, sharing the analysis/play engine and barriers.
  Future<void> startReview({
    ReviewScope scope = ReviewScope.line,
    required ReviewLimits limits,
    bool skipExisting = true,
    ReviewMode mode = ReviewMode.best,
    int maximum = 5,
  }) async {
    if (mode == ReviewMode.candidates && (maximum < 2 || maximum > 256)) {
      throw ArgumentError('Invalid candidate count');
    }
    if (_disposed) return;
    final stopping = disable();
    final intent = _generation;
    final epoch = session.epoch;
    final revision = session.revision;
    await stopping;
    if (_disposed ||
        intent != _generation ||
        epoch != session.epoch ||
        revision != session.revision) {
      return;
    }
    final tree = session.tree;
    final nodes = <String>[];
    if (scope == ReviewScope.line) {
      nodes.addAll(tree.currentLine.map((n) => n.id));
    } else {
      final pending = [tree.root.id];
      while (pending.isNotEmpty) {
        final id = pending.removeLast();
        nodes.add(id);
        pending.addAll(tree.node(id).children.reversed);
      }
    }
    // Children first, matching the observed reference queue. No cursor mutation.
    _review = ReviewRun(
      epoch: epoch,
      revision: revision,
      tree: tree,
      scope: scope,
      mode: mode,
      maximum: mode == ReviewMode.best ? 1 : maximum,
      limits: limits,
      nodeIds: List.unmodifiable(nodes.reversed),
    );
    _error = null;
    final job = ++_reviewJob;
    _notify();
    if (!_reviewValid(job)) return;
    try {
      final engine = await _getEngine();
      if (!_reviewValid(job)) return;
      await engine.initialize();
      if (!_reviewValid(job)) return;
      _settings = AnalysisSettings(
        threads: _settings.threads.clamp(1, maxThreads),
        hashMb: _settings.hashMb.clamp(1, maxHash),
        multiPv: _settings.multiPv.clamp(1, maxPv),
      );
      final cache = ReviewCacheAccess(
        engine.identity,
        engine.options,
        reviewCache,
      );
      _review = _review!.copy(cacheNotice: cache.notice);
      for (final id in _review!.nodeIds) {
        if (!_reviewValid(job)) return;
        final node = tree.node(id);
        _clearBatchInfo();
        _review = _review!.copy(
          currentNodeId: id,
          currentCandidate: 0,
          currentCandidateLimit: 0,
        );
        _notify();
        if (!_reviewValid(job)) return;
        ReviewedPosition result;
        if (node.position.boardOutcome().isTerminal) {
          result = ReviewedPosition(
            nodeId: id,
            turn: node.position.turn,
            status: ReviewScoreStatus.terminal,
          );
        } else {
          var previousHits = 0;
          final collection =
              await CandidateCollector(
                FiniteSearchExecutor(engine, cache),
              ).collect(
                position: node.position,
                maximum: _review!.maximum,
                skipExisting: skipExisting,
                isCurrent: () => _reviewValid(job),
                makeRequest: (allowed) => EngineRequest.fromTree(
                  token: ++_generation,
                  gameId: epoch,
                  tree: tree.goTo(id),
                  depth: limits.depth,
                  moveTimeMs: limits.moveTimeMs,
                  nodeLimit: limits.nodeLimit,
                  threads: _settings.threads,
                  hashMb: _settings.hashMb,
                  multiPv: 1,
                  preferWdl: true,
                  searchMoves: allowed,
                ),
                onSearch: (number, total) {
                  _clearBatchInfo();
                  _review = _review!.copy(
                    currentCandidate: number,
                    currentCandidateLimit: total,
                  );
                  _notify();
                },
                onInfo: (info) =>
                    _recordBatchInfo(info, () => _reviewValid(job)),
                onCandidate: (entries, hits) {
                  _review = _review!.copy(
                    candidateResults: {
                      ..._review!.candidateResults,
                      id: ReviewedCandidates(entries, complete: false),
                    },
                    cachedSearchCount:
                        _review!.cachedSearchCount + hits - previousHits,
                    cacheNotice: cache.notice,
                  );
                  previousHits = hits;
                  _notify();
                },
              );
          if (!_reviewValid(job) || collection == null) return;
          final info = collection.entries.firstOrNull?.info;
          if (collection.entries.isNotEmpty &&
              collection.cacheHits == collection.searches) {
            _review = _review!.copy(cachedCount: _review!.cachedCount + 1);
          }
          _review = _review!.copy(
            candidateResults: {
              ..._review!.candidateResults,
              id: ReviewedCandidates(
                collection.entries,
                complete: true,
                notice: collection.notice,
              ),
            },
            cacheNotice: cache.notice,
          );
          result = ReviewedPosition(
            nodeId: id,
            turn: node.position.turn,
            status: info == null
                ? ReviewScoreStatus.noScore
                : ReviewScoreStatus.scored,
            info: info,
          );
        }
        _review = _review!.copy(results: {..._review!.results, id: result});
        _notify();
      }
      if (!_reviewValid(job)) return;
      _clearBatchInfo();
      _review = _review!.copy(phase: ReviewPhase.completed);
      _status = '整谱分析已完成';
      _notify();
    } catch (e) {
      if (!_reviewValid(job)) return;
      _review = _review!.copy(
        phase: ReviewPhase.failed,
        error: '整谱分析失败，可调整参数后重试',
      );
      _failed(e, _generation);
    }
  }

  bool _reviewValid(int job) =>
      !_disposed &&
      job == _reviewJob &&
      _review?.phase == ReviewPhase.running &&
      _review!.epoch == session.epoch &&
      _review!.revision == session.revision;

  void _reviewChanged() {
    final value = _review;
    if (value == null ||
        value.phase == ReviewPhase.stale ||
        (value.epoch == session.epoch && value.revision == session.revision)) {
      return;
    }
    // Invalidate synchronously before any stop/bestmove can deliver late data.
    _reviewJob++;
    _review = value.copy(phase: ReviewPhase.stale);
    if (value.active) {
      unawaited(disable());
    } else {
      _notify();
    }
  }

  Future<void> cancelReview() => disable();
}
