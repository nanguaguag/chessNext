import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ports/preferences_repository.dart';
import 'app_preferences.dart';
import 'board_appearance.dart';
import 'engine_session_controller.dart';

class PreferencesController extends ChangeNotifier {
  PreferencesController(this.engine, this.repository) {
    engine.addListener(_engineChanged);
  }
  final EngineSessionController engine;
  final PreferencesRepository repository;
  AppPreferences value = AppPreferences();
  bool loading = false;
  bool _initialized = false;
  bool _allowWrite = true;
  bool _disposed = false;
  bool _applying = false;
  bool get saving => _writing != null;
  bool get initialized => _initialized;
  String? error;
  String status = '使用默认设置';
  final Set<String> _edited = {};
  AppPreferences? _queued;
  AppPreferences? _persisted;
  Future<void>? _writing;
  Future<void>? _loadingTask;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  AppPreferences _bounded(AppPreferences next) => next.copyWith(
    threads: next.threads.clamp(1, engine.maxThreads),
    hashMb: next.hashMb.clamp(1, engine.maxHash),
    multiPv: next.multiPv.clamp(1, engine.maxPv),
  );
  void _applyEngine() {
    final current = engine.settings;
    if (current.threads == value.threads &&
        current.hashMb == value.hashMb &&
        current.multiPv == value.multiPv &&
        engine.thinkTimeMs == value.thinkTimeMs) {
      return;
    }
    _applying = true;
    try {
      unawaited(
        engine.configureSession(
          AnalysisSettings(
            threads: value.threads,
            hashMb: value.hashMb,
            multiPv: value.multiPv,
          ),
          value.thinkTimeMs,
        ),
      );
    } finally {
      _applying = false;
    }
  }

  Future<void> initialize() {
    if (_disposed) return Future.value();
    if (_loadingTask != null) return _loadingTask!;
    final task = _load();
    _loadingTask = task;
    return task.whenComplete(() => _loadingTask = null);
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    _notify();
    var shouldSave = false;
    try {
      final loaded = await repository.load();
      if (_disposed) return;
      _allowWrite = true;
      if (loaded != null) {
        final previous = value;
        final stored = loaded.value;
        value = _bounded(
          stored.copyWith(
            showAnalysisArrows: _edited.contains('showAnalysisArrows')
                ? previous.showAnalysisArrows
                : null,
            arrowHead: _edited.contains('arrowHead')
                ? previous.arrowHead
                : null,
            theme: _edited.contains('theme') ? previous.theme : null,
            textSize: _edited.contains('textSize') ? previous.textSize : null,
            pieceSizePercent: _edited.contains('pieceSizePercent')
                ? previous.pieceSizePercent
                : null,
            showCoordinates: _edited.contains('showCoordinates')
                ? previous.showCoordinates
                : null,
            guideVersion: _edited.contains('guideVersion')
                ? previous.guideVersion
                : null,
            threads: _edited.contains('threads') ? previous.threads : null,
            hashMb: _edited.contains('hashMb') ? previous.hashMb : null,
            multiPv: _edited.contains('multiPv') ? previous.multiPv : null,
            thinkTimeMs: _edited.contains('thinkTimeMs')
                ? previous.thinkTimeMs
                : null,
          ),
        );
        _persisted = stored;
        _applyEngine();
        shouldSave = value != stored || loaded.recovered;
        status = loaded.recovered ? '已从备份恢复设置' : '设置已加载';
      }
      shouldSave = shouldSave || _edited.isNotEmpty;
    } catch (_) {
      if (!_disposed) error = '设置读取失败，使用安全默认值；原文件已保留';
      shouldSave = _edited.isNotEmpty;
      _allowWrite = shouldSave;
    } finally {
      loading = false;
      _initialized = true;
      _notify();
      if (!_disposed && shouldSave) unawaited(flush());
    }
  }

  Future<bool> markGuideSeen() async {
    if (!_initialized || loading) await initialize();
    if (_disposed) return false;
    if (!_allowWrite) {
      error = '新手引导标记未保存，请先重试读取或恢复设置。原文件已保留。';
      _notify();
      return false;
    }
    final version = value.guideVersion < AppPreferences.currentGuideVersion
        ? AppPreferences.currentGuideVersion
        : value.guideVersion;
    await apply(value.copyWith(guideVersion: version));
    return !_disposed && error == null;
  }

  Future<void> setTheme(ThemePreference theme) =>
      apply(value.copyWith(theme: theme));
  Future<void> setTextSize(TextSizePreference size) =>
      apply(value.copyWith(textSize: size));
  Future<void> setShowCoordinates(bool visible) =>
      apply(value.copyWith(showCoordinates: visible));
  Future<void> setPieceSize(int percent) =>
      apply(value.copyWith(pieceSizePercent: percent));
  Future<void> setAnalysisArrows(bool visible) =>
      apply(value.copyWith(showAnalysisArrows: visible));
  Future<void> setArrowHead(ArrowHeadStyle style) =>
      apply(value.copyWith(arrowHead: style));
  Future<void> retryPersistence() =>
      _allowWrite ? flush(force: true) : initialize();
  Future<void> apply(AppPreferences next) {
    next = _bounded(next);
    _recordEdits(next);
    value = next;
    _applyEngine();
    _notify();
    return flush(force: true);
  }

  void _recordEdits(AppPreferences next) {
    if (next.showAnalysisArrows != value.showAnalysisArrows) {
      _edited.add('showAnalysisArrows');
    }
    if (next.arrowHead != value.arrowHead) {
      _edited.add('arrowHead');
    }
    if (next.theme != value.theme) _edited.add('theme');
    if (next.textSize != value.textSize) _edited.add('textSize');
    if (next.pieceSizePercent != value.pieceSizePercent) {
      _edited.add('pieceSizePercent');
    }
    if (next.showCoordinates != value.showCoordinates) {
      _edited.add('showCoordinates');
    }
    if (next.guideVersion != value.guideVersion) _edited.add('guideVersion');
    if (next.threads != value.threads) _edited.add('threads');
    if (next.hashMb != value.hashMb) _edited.add('hashMb');
    if (next.multiPv != value.multiPv) _edited.add('multiPv');
    if (next.thinkTimeMs != value.thinkTimeMs) _edited.add('thinkTimeMs');
  }

  void _engineChanged() {
    if (_applying || _disposed) return;
    final settings = engine.settings;
    final next = value.copyWith(
      threads: settings.threads,
      hashMb: settings.hashMb,
      multiPv: settings.multiPv,
      thinkTimeMs: engine.thinkTimeMs,
    );
    if (value == next) return;
    _recordEdits(next);
    value = next;
    _allowWrite = true;
    _notify();
    unawaited(flush());
  }

  Future<void> flush({bool force = false}) {
    if (force) _allowWrite = true;
    if (_disposed) return Future.value();
    if (loading) {
      return _loadingTask?.then((_) => flush(force: force)) ?? Future.value();
    }
    if (!_initialized || !_allowWrite) return Future.value();
    if (value == _persisted && _writing == null) return Future.value();
    _queued = value;
    if (_writing != null) return _writing!;
    final completion = Completer<void>();
    _writing = completion.future;
    error = null;
    _notify();
    unawaited(_drain(completion));
    return completion.future;
  }

  Future<void> _drain(Completer<void> completion) async {
    try {
      while (_queued != null) {
        final next = _queued!;
        _queued = null;
        await repository.save(next);
        _persisted = next;
      }
      status = '设置已保存';
    } catch (_) {
      _queued = null;
      error = '设置保存失败，当前设置仍生效，请重试';
    } finally {
      _writing = null;
      completion.complete();
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    engine.removeListener(_engineChanged);
    super.dispose();
  }
}
