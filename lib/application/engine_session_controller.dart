import 'analysis_history.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';
import 'board_session.dart';

import 'review_models.dart';
import 'candidate_models.dart';
import 'review_cache_access.dart';
import 'finite_search_executor.dart';
import 'candidate_collector.dart';
import '../ports/review_cache_repository.dart';

part 'engine_play.dart';
part 'engine_review.dart';
part 'engine_candidates.dart';

typedef EngineFactory = Future<EngineGateway> Function();

class AnalysisSettings {
  const AnalysisSettings({
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
  });
  final int threads;
  final int hashMb;
  final int multiPv;
}

class EngineSessionController extends ChangeNotifier {
  EngineSessionController(
    this.session,
    this.factory, {
    this.deviceThreads = 1,
    ReviewCacheRepository? reviewCache,
  }) : reviewCache = reviewCache ?? MemoryReviewCacheRepository() {
    _lastRevision = session.positionRevision;
    _lastSessionEpoch = session.epoch;
    session.addListener(_changed);
  }
  final BoardSession session;
  final EngineFactory? factory;
  final int deviceThreads;
  final ReviewCacheRepository reviewCache;
  CandidateRun? _candidates;
  int _candidateJob = 0;
  EngineInfo? _batchInfo, _batchPending;
  Timer? _batchTimer;
  EngineInfo? get batchInfo =>
      batching && _batchInfo?.token == _generation ? _batchInfo : null;
  void _clearBatchInfo() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _batchInfo = null;
    _batchPending = null;
  }

  void _recordBatchInfo(EngineInfo info, bool Function() valid) {
    if (!valid() || info.token != _generation) return;
    _batchPending = info;
    _batchTimer ??= Timer(const Duration(milliseconds: 100), () {
      _batchTimer = null;
      if (!valid() || _batchPending?.token != _generation) return;
      _batchInfo = _batchPending;
      _batchPending = null;
      _notify();
    });
  }

  ReviewRun? _review;
  int _reviewJob = 0;
  EngineGateway? _engine;
  Future<EngineGateway>? _opening;
  StreamSubscription<EngineInfo>? _subscription;
  final AnalysisHistory _history = AnalysisHistory();
  List<PvHistoryEntry> get history => _history.entries;
  void clearAnalysisHistory() {
    if (_disposed || history.isEmpty) return;
    _history.clear();
    _notify();
  }

  final Map<int, EngineInfo> _infos = {};
  final Map<int, EngineInfo> _pending = {};
  List<EngineInfo> get infos => List.unmodifiable(
    _infos.values.toList()..sort((a, b) => a.multiPv.compareTo(b.multiPv)),
  );
  String? get engineName => _engine?.name;
  EngineIdentity? get engineIdentity => _engine?.identity;
  Map<String, EngineOption> get options => _engine?.options ?? const {};
  int get maxThreads => math.max(
    1,
    math.min(
      1024,
      math.min(deviceThreads, options['Threads']?.maximum ?? deviceThreads),
    ),
  );
  int get maxHash =>
      math.max(1, math.min(1024, options['Hash']?.maximum ?? 1024));
  int get maxPv =>
      math.max(1, math.min(256, options['MultiPV']?.maximum ?? 256));
  AnalysisSettings _settings = const AnalysisSettings();
  AnalysisSettings get settings => _settings;
  bool _enabled = false;
  bool get enabled => _enabled;
  bool _busy = false;
  bool get busy => _busy;
  String _status = '尚未开始分析';
  String get status => _status;
  String? _error;
  String? get error => _error;
  bool _disposed = false;
  int _generation = 0;
  int? _stopFailedGeneration;
  int _lastRevision = 0;
  int _searchRevision = 0;
  final Set<Side> _aiSides = {};
  bool _thinking = false;
  bool _changingAlternative = false;
  bool _suppressRestart = false;
  bool _applyingEngine = false;
  int _thinkTimeMs = 1000;
  int _lastSessionEpoch = 0;
  String? _lastAiNode;
  int _lastAiEpoch = -1;
  Move? _lastAiMove;
  EngineSearch? _playSearch;
  final Map<(int, String), Set<Move>> _exclusions = {};
  Timer? _restart;
  Timer? _flush;
  Move? get recommended {
    final move = _infos[1]?.pv.firstOrNull;
    return move != null && session.isLegalMove(move) ? move : null;
  }

  Move? get reply => (_infos[1]?.pv.length ?? 0) > 1 ? _infos[1]!.pv[1] : null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _clear() {
    _flush?.cancel();
    _flush = null;
    _pending.clear();
    _infos.clear();
  }

  void _changed() {
    _reviewChanged();
    _candidatesChanged();
    if (_lastRevision == session.positionRevision) return;
    _lastRevision = session.positionRevision;
    _history.clear();
    _clear();
    _restart?.cancel();
    if (_suppressRestart) return;
    if (_lastSessionEpoch != session.epoch) {
      _lastSessionEpoch = session.epoch;
      _lastAiNode = null;
      _exclusions.clear();
    }
    if (!_applyingEngine) _exclusions.clear();
    if (batching) {
      _notify();
      return;
    }
    final generation = ++_generation;
    if (playing) {
      unawaited(_syncPlay(generation, delayed: true));
      return;
    }

    if (_enabled) {
      _busy = true;
      _status = '正在切换局面';
      _restart = Timer(
        const Duration(milliseconds: 150),
        () => _run(generation),
      );
    }
    _notify();
  }

  Future<EngineGateway> _getEngine() async {
    if (factory == null) throw StateError('本地分析引擎不可用');
    if (_engine?.phase == EngineLifecycle.failed) {
      final previous = _engine!;
      unawaited(_subscription?.cancel());
      _subscription = null;
      _engine = null;
      _opening = null;
      unawaited(previous.dispose());
    }
    final opening = _opening ??= factory!();
    EngineGateway engine;
    try {
      engine = await opening;
    } catch (_) {
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
    if (_disposed) {
      await engine.dispose();
      throw StateError('Analysis disposed');
    }
    if (_engine == null) {
      _engine = engine;
      _subscription = engine.info.listen(_onInfo);
      _settings = AnalysisSettings(
        threads: _settings.threads.clamp(1, maxThreads),
        hashMb: _settings.hashMb.clamp(1, maxHash),
        multiPv: _settings.multiPv.clamp(1, maxPv),
      );
      _notify();
    }
    return engine;
  }

  void _onInfo(EngineInfo info) {
    if (_disposed ||
        !_enabled ||
        info.token != _generation ||
        session.positionRevision != _searchRevision) {
      return;
    }
    _pending[info.multiPv] = info;
    _flush ??= Timer(const Duration(milliseconds: 100), () {
      _flush = null;
      _infos.addAll(_pending);
      for (final info in _pending.values) {
        _history.add(
          position: session.position,
          epoch: session.epoch,
          nodeId: session.tree.cursorId,
          revision: session.revision,
          positionRevision: session.positionRevision,
          info: info,
        );
      }
      _pending.clear();
      _notify();
    });
  }

  Future<void> enable() async {
    if (_disposed || _enabled) return;
    if (batching) {
      final stopping = disable();
      final intent = _generation;
      await stopping;
      if (_disposed || intent != _generation) return;
    }
    _aiSides.clear();
    _thinking = false;
    _playSearch = null;
    session.setInputLocked(false);
    _enabled = true;
    _error = null;
    _busy = true;
    _status = '正在启动本地引擎';
    _clear();
    final generation = ++_generation;
    _notify();
    await _run(generation);
  }

  Future<void> _run(int generation) async {
    if (_disposed || !_enabled || generation != _generation) return;
    try {
      final engine = await _getEngine();
      if (_disposed || !_enabled || generation != _generation) return;
      if (session.outcome.isTerminal) {
        await engine.stop();
        _busy = false;
        _status = '当前局面已结束';
        _notify();
        return;
      }
      _searchRevision = session.positionRevision;
      final search = await engine.start(
        EngineRequest.fromTree(
          token: generation,
          gameId: session.epoch,
          tree: session.tree,
          threads: _settings.threads,
          hashMb: _settings.hashMb,
          multiPv: _settings.multiPv,
          preferWdl: true,
        ),
      );
      if (_disposed || !_enabled || generation != _generation) return;
      _busy = false;
      _status = '本地分析中';
      _notify();
      unawaited(
        search.bestMove.then((_) {
          if (!_disposed && generation == _generation && _enabled) {
            _status = '本次搜索已结束';
            _notify();
          }
        }, onError: (Object e) => _failed(e, generation)),
      );
    } catch (e) {
      _failed(e, generation);
    }
  }

  void _failed(Object exception, int generation) {
    if (_disposed || generation != _generation) return;
    _clearBatchInfo();
    _aiSides.clear();
    _thinking = false;
    _playSearch = null;
    session.setInputLocked(false);
    _enabled = false;
    _busy = false;
    _error =
        exception is StateError &&
            const {
              '本地分析引擎尚未安装',
              '本地引擎文件校验失败，请重新安装或构建',
            }.contains(exception.message)
        ? exception.message
        : '本地引擎操作失败，请重新尝试';
    _status = '本地引擎不可用';
    _clear();
    _opening = null;
    final engine = _engine;
    _engine = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (engine != null) unawaited(engine.dispose());
    _notify();
  }

  Future<void> disable() async {
    _clearBatchInfo();
    final stoppingCandidates = inspectingCandidates;
    final candidateJob = ++_candidateJob;
    if (stoppingCandidates) {
      _candidates = _candidates!.copy(phase: ReviewPhase.stopping);
    }
    final stoppingReview = _review?.active ?? false;
    final reviewJob = ++_reviewJob;
    if (stoppingReview) _review = _review!.copy(phase: ReviewPhase.stopping);
    _aiSides.clear();
    _thinking = false;
    _playSearch = null;
    session.setInputLocked(false);
    _enabled = false;
    _busy = false;
    _status = '分析已停止';
    _restart?.cancel();
    final generation = ++_generation;
    _flush?.cancel();
    _flush = null;
    _pending.clear();
    _notify();
    try {
      await _engine?.stop();
      if (!_disposed && candidateJob == _candidateJob && stoppingCandidates) {
        _candidates = _candidates!.copy(phase: ReviewPhase.cancelled);
        _notify();
      }
      if (!_disposed && reviewJob == _reviewJob && stoppingReview) {
        _review = _review!.copy(phase: ReviewPhase.cancelled);
        _notify();
      }
    } catch (e) {
      _stopFailedGeneration = generation;
      if (candidateJob == _candidateJob && stoppingCandidates) {
        _candidates = _candidates!.copy(
          phase: ReviewPhase.failed,
          error: '停止引擎失败',
        );
      }
      if (reviewJob == _reviewJob && stoppingReview) {
        _review = _review!.copy(phase: ReviewPhase.failed, error: '停止引擎失败');
      }
      _failed(e, generation);
    }
  }

  Future<void> configure(AnalysisSettings value) =>
      configureSession(value, _thinkTimeMs);

  /// Applies settings and play budget together, then restarts at most one search.
  Future<void> configureSession(AnalysisSettings value, int thinkTimeMs) async {
    if (thinkTimeMs < 50 ||
        thinkTimeMs > 600000 ||
        value.threads < 1 ||
        value.threads > maxThreads ||
        value.hashMb < 1 ||
        value.hashMb > maxHash ||
        value.multiPv < 1 ||
        value.multiPv > maxPv) {
      throw ArgumentError('Unsupported settings');
    }
    if (batching) {
      final stopping = disable();
      final intent = _generation;
      await stopping;
      if (_disposed || intent != _generation) return;
    }
    _settings = value;
    _thinkTimeMs = thinkTimeMs;
    _clear();
    _notify();
    if (_enabled) {
      _busy = true;
      await _run(++_generation);
    } else if (playing) {
      await _syncPlay(++_generation);
    }
  }

  /// Reading a node pauses automatic play, while an active analysis may follow it.
  Future<void> navigateToNode(String id) async {
    if (_disposed || !session.tree.hasNode(id)) return;
    if (!playing) {
      session.navigate(id);
      return;
    }
    final epoch = session.epoch;
    final positionRevision = session.positionRevision;
    final stopping = disable();
    final generation = _generation;
    await stopping;
    if (!_disposed &&
        generation == _generation &&
        session.epoch == epoch &&
        session.positionRevision == positionRevision &&
        session.tree.hasNode(id)) {
      session.navigate(id);
    }
  }

  /// Deletes only the exact document revision the user confirmed. Stop automatic
  /// play before editing so a late bestmove cannot recreate the removed branch.
  Future<bool> deleteConfirmedBranch(
    String id, {
    required int epoch,
    required int revision,
  }) async {
    bool valid() =>
        !_disposed &&
        session.epoch == epoch &&
        session.revision == revision &&
        session.tree.hasNode(id) &&
        session.tree.node(id).parentId != null;
    if (!valid()) return false;
    if (playing) {
      final stopping = disable();
      final generation = _generation;
      await stopping;
      if (generation != _generation || !valid()) return false;
    }
    if (!valid()) return false;
    session.deleteBranch(id);
    return true;
  }

  WdlEstimate? wdlFor(EngineInfo info, Side viewSide) =>
      session.position.turn == viewSide ? info.wdl : info.wdl?.flipped();

  int scoreFor(EngineInfo info, Side viewSide) =>
      session.position.turn == viewSide ? info.score : -info.score;
  String? boundFor(EngineInfo info, Side viewSide) {
    if (session.position.turn == viewSide) return info.bound;
    return info.bound == 'lower'
        ? 'upper'
        : info.bound == 'upper'
        ? 'lower'
        : null;
  }

  @override
  void dispose() {
    _disposed = true;
    _clearBatchInfo();
    _generation++;
    _restart?.cancel();
    _flush?.cancel();
    session.removeListener(_changed);
    unawaited(_subscription?.cancel());
    if (_engine != null) unawaited(_engine!.dispose());
    super.dispose();
  }
}
