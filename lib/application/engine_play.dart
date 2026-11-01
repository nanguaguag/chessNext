part of 'engine_session_controller.dart';

extension EnginePlay on EngineSessionController {
  Set<Side> get aiSides => Set.unmodifiable(_aiSides);
  bool get playing => _aiSides.isNotEmpty;
  bool get thinking => _thinking;
  int get thinkTimeMs => _thinkTimeMs;
  bool get canImmediate =>
      _thinking && _playSearch?.token == _generation && !_changingAlternative;
  bool get canAlternative {
    if (!playing || _changingAlternative) return false;
    if (_thinking) {
      final excluded =
          _exclusions[(session.epoch, session.tree.cursorId)] ?? const <Move>{};
      return canImmediate &&
          session.legalMoves.where((m) => !excluded.contains(m)).length > 1;
    }
    if (_lastAiNode != session.tree.cursorId ||
        _lastAiEpoch != session.epoch ||
        _lastAiMove == null) {
      return false;
    }
    final parent = session.tree.current.parentId;
    if (parent == null) return false;
    final excluded = {...?_exclusions[(session.epoch, parent)], _lastAiMove!};
    return session.tree
        .node(parent)
        .position
        .legalMoves
        .any((m) => !excluded.contains(m));
  }

  Future<void> setAiSide(Side side, bool active) async {
    if (_disposed) return;
    _enabled = false;
    _busy = false;
    _error = null;
    _clear();
    _restart?.cancel();
    _exclusions.clear();
    if (active) {
      _aiSides.add(side);
    } else {
      _aiSides.remove(side);
    }
    await _syncPlay(++_generation);
  }

  Future<void> setThinkTime(int milliseconds) =>
      configureSession(_settings, milliseconds);

  Future<void> _stopPlay(int generation) async {
    try {
      await _engine?.stop();
    } catch (e) {
      _failed(e, generation);
    }
  }

  Future<void> _syncPlay(int generation, {bool delayed = false}) async {
    if (_disposed || generation != _generation) return;
    _playSearch = null;
    _restart?.cancel();
    _thinking =
        playing &&
        _aiSides.contains(session.position.turn) &&
        !session.outcome.isTerminal;
    _busy = _thinking;
    session.setInputLocked(_thinking);
    _status = session.outcome.isTerminal
        ? '对局已结束'
        : !playing
        ? '自动对弈已停止'
        : _thinking
        ? '${session.position.turn == Side.red ? '红方' : '黑方'}引擎正在思考'
        : '等待${session.position.turn == Side.red ? '红方' : '黑方'}走棋';
    _notify();
    if (!_thinking) {
      await _stopPlay(generation);
      return;
    }
    if (delayed) {
      _restart = Timer(
        const Duration(milliseconds: 150),
        () => _runPlay(generation),
      );
    } else {
      await _runPlay(generation);
    }
  }

  Future<void> _runPlay(int generation) async {
    if (_disposed || generation != _generation || !playing || !_thinking) {
      return;
    }
    try {
      final engine = await _getEngine();
      if (_disposed || generation != _generation || !playing || !_thinking) {
        return;
      }
      final revision = session.positionRevision;
      final epoch = session.epoch;
      final parent = session.tree.cursorId;
      final excluded = _exclusions[(epoch, parent)] ?? const <Move>{};
      final candidates = session.legalMoves
          .where((m) => !excluded.contains(m))
          .toList(growable: false);
      if (candidates.isEmpty) throw StateError('No alternate moves available');
      final search = await engine.start(
        EngineRequest.fromTree(
          token: generation,
          tree: session.tree,
          moveTimeMs: _thinkTimeMs,
          threads: _settings.threads,
          hashMb: _settings.hashMb,
          multiPv: 1,
          searchMoves: excluded.isEmpty ? null : candidates,
        ),
      );
      if (_disposed || generation != _generation || !playing) return;
      _playSearch = search;
      _busy = false;
      _notify();
      unawaited(
        search.bestMove.then<void>((move) {
          if (_disposed ||
              generation != _generation ||
              !playing ||
              session.positionRevision != revision ||
              session.epoch != epoch) {
            return;
          }
          try {
            if (move == null ||
                !session.isLegalMove(move) ||
                excluded.contains(move)) {
              throw StateError('Engine returned an illegal move');
            }
            _thinking = false;
            _playSearch = null;
            _applyingEngine = true;
            try {
              if (!session.playMove(move, fromEngine: true)) {
                throw StateError('Move could not be applied');
              }
              if (excluded.isNotEmpty) session.promote(session.tree.cursorId);
            } finally {
              _applyingEngine = false;
            }
            _lastAiNode = session.tree.cursorId;
            _lastAiEpoch = epoch;
            _lastAiMove = move;
            _notify();
          } catch (e) {
            _failed(e, _generation);
          }
        }, onError: (Object e) => _failed(e, generation)),
      );
    } catch (e) {
      _failed(e, generation);
    }
  }

  Future<void> immediateMove() async {
    if (!canImmediate) return;
    await _stopPlay(_generation);
  }

  Future<void> alternative() async {
    if (!canAlternative) {
      _error = '当前没有可替换的着法';
      _notify();
      return;
    }
    _changingAlternative = true;
    final generation = ++_generation;
    _error = null;
    _restart?.cancel();
    try {
      if (_thinking) {
        final search = _playSearch!;
        _playSearch = null;
        await _engine?.stop();
        final move = await search.bestMove;
        if (_disposed || generation != _generation || move == null) return;
        _exclusions
            .putIfAbsent((session.epoch, session.tree.cursorId), () => <Move>{})
            .add(move);
      } else {
        final parent = session.tree.current.parentId!;
        _exclusions
            .putIfAbsent((session.epoch, parent), () => <Move>{})
            .add(_lastAiMove!);
        _suppressRestart = true;
        try {
          session.navigate(parent);
        } finally {
          _suppressRestart = false;
        }
        _lastAiNode = null;
      }
      await _syncPlay(generation);
    } catch (e) {
      _failed(e, generation);
    } finally {
      _changingAlternative = false;
      _notify();
    }
  }

  Future<void> undoForPlay() async {
    _restart?.cancel();
    final generation = ++_generation;
    final dual = _aiSides.length == 2;
    if (dual) _aiSides.clear();
    _thinking = false;
    _playSearch = null;
    _exclusions.clear();
    _lastAiNode = null;
    session.setInputLocked(false);
    _suppressRestart = true;
    try {
      var count = 0;
      while (session.canUndo && count < 2) {
        session.undo();
        count++;
        if (!dual && !_aiSides.contains(session.position.turn)) break;
      }
    } finally {
      _suppressRestart = false;
    }
    // At an AI-to-move root there is no earlier human turn to restore.
    if (_aiSides.contains(session.position.turn)) _aiSides.clear();
    await _syncPlay(generation);
  }
}
