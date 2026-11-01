import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';
import 'board_session.dart';

part 'engine_play.dart';

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
  }) {
    _lastRevision = session.positionRevision;
    _lastSessionEpoch = session.epoch;
    session.addListener(_changed);
  }
  final BoardSession session;
  final EngineFactory? factory;
  final int deviceThreads;
  EngineGateway? _engine;
  Future<EngineGateway>? _opening;
  StreamSubscription<EngineInfo>? _subscription;
  final Map<int, EngineInfo> _infos = {};
  final Map<int, EngineInfo> _pending = {};
  List<EngineInfo> get infos => List.unmodifiable(
    _infos.values.toList()..sort((a, b) => a.multiPv.compareTo(b.multiPv)),
  );
  Map<String, EngineOption> get options => _engine?.options ?? const {};
  int get maxThreads => math.max(
    1,
    math.min(deviceThreads, options['Threads']?.maximum ?? deviceThreads),
  );
  int get maxHash => math.min(1024, options['Hash']?.maximum ?? 1024);
  int get maxPv => options['MultiPV']?.maximum ?? 1;
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
    if (_lastRevision == session.positionRevision) return;
    _lastRevision = session.positionRevision;
    _clear();
    _restart?.cancel();
    if (_suppressRestart) return;
    if (_lastSessionEpoch != session.epoch) {
      _lastSessionEpoch = session.epoch;
      _lastAiNode = null;
      _exclusions.clear();
    }
    if (!_applyingEngine) _exclusions.clear();
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
    final engine = await (_opening ??= factory!());
    if (_disposed) {
      await engine.dispose();
      throw StateError('Analysis disposed');
    }
    if (_engine == null) {
      _engine = engine;
      _subscription = engine.info.listen(_onInfo);
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
      _pending.clear();
      _notify();
    });
  }

  Future<void> enable() async {
    if (_disposed || _enabled) return;
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
          tree: session.tree,
          threads: _settings.threads,
          hashMb: _settings.hashMb,
          multiPv: _settings.multiPv,
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
    _aiSides.clear();
    _thinking = false;
    _playSearch = null;
    session.setInputLocked(false);
    _enabled = false;
    _busy = false;
    _error = exception is StateError && exception.message == '本地分析引擎尚未安装'
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
    } catch (e) {
      _failed(e, generation);
    }
  }

  Future<void> configure(AnalysisSettings value) async {
    if (value.threads < 1 ||
        value.threads > maxThreads ||
        value.hashMb < 1 ||
        value.hashMb > maxHash ||
        value.multiPv < 1 ||
        value.multiPv > maxPv) {
      throw ArgumentError('Unsupported settings');
    }
    _settings = value;
    _clear();
    _notify();
    if (_enabled) {
      _busy = true;
      await _run(++_generation);
    } else if (playing) {
      await _syncPlay(++_generation);
    }
  }

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
    _generation++;
    _restart?.cancel();
    _flush?.cancel();
    session.removeListener(_changed);
    unawaited(_subscription?.cancel());
    if (_engine != null) unawaited(_engine!.dispose());
    super.dispose();
  }
}
