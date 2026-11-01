part of 'engine_session_controller.dart';

extension EngineReview on EngineSessionController {
  ReviewRun? get review => _review;
  bool get reviewing => _review?.active ?? false;

  /// Starts a single finite queue, sharing the analysis/play engine and barriers.
  Future<void> startReview({
    ReviewScope scope = ReviewScope.line,
    required ReviewLimits limits,
  }) async {
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
      for (final id in _review!.nodeIds) {
        if (!_reviewValid(job)) return;
        final node = tree.node(id);
        _review = _review!.copy(currentNodeId: id);
        _reviewInfo = null;
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
          final token = ++_generation;
          _reviewToken = token;
          final search = await engine.start(
            EngineRequest.fromTree(
              token: token,
              gameId: epoch,
              tree: tree.goTo(id),
              depth: limits.depth,
              moveTimeMs: limits.moveTimeMs,
              nodeLimit: limits.nodeLimit,
              threads: _settings.threads,
              hashMb: _settings.hashMb,
              multiPv: 1,
            ),
          );
          if (!_reviewValid(job)) return;
          await search.bestMove;
          // Broadcast info and bestmove have separate futures; drain that turn.
          await Future<void>.delayed(Duration.zero);
          if (!_reviewValid(job)) return;
          final info = _reviewInfo;
          result = ReviewedPosition(
            nodeId: id,
            turn: node.position.turn,
            status: info == null
                ? ReviewScoreStatus.noScore
                : ReviewScoreStatus.scored,
            info: info,
          );
        }
        _reviewToken = null;
        _review = _review!.copy(results: {..._review!.results, id: result});
        _notify();
      }
      if (!_reviewValid(job)) return;
      _review = _review!.copy(phase: ReviewPhase.completed);
      _status = '整谱分析已完成';
      _notify();
    } catch (e) {
      if (!_reviewValid(job)) return;
      _reviewToken = null;
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
    _reviewToken = null;
    _review = value.copy(phase: ReviewPhase.stale);
    if (value.active) {
      unawaited(disable());
    } else {
      _notify();
    }
  }

  void _onReviewInfo(EngineInfo info) {
    if (_disposed ||
        _review?.phase != ReviewPhase.running ||
        info.token != _reviewToken ||
        info.multiPv != 1 ||
        _review?.currentNodeId == null) {
      return;
    }
    final node = _review!.tree.node(_review!.currentNodeId!);
    if (info.pv.isEmpty || !node.position.legalMoves.contains(info.pv.first)) {
      return;
    }
    _reviewInfo = info;
  }

  Future<void> cancelReview() => disable();
}
