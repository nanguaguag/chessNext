import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ports/recent_reading_repository.dart';
import 'library_controller.dart';

/// Keeps derived navigation metadata separate from saved game content and drafts.
class RecentReadingController extends ChangeNotifier {
  RecentReadingController(
    this.library,
    this.repository, {
    this.debounce = const Duration(milliseconds: 300),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    library.addListener(_libraryChanged);
    library.session.addListener(_sessionChanged);
  }
  final LibraryController library;
  final RecentReadingRepository repository;
  final Duration debounce;
  final DateTime Function() _now;
  List<RecentReading> _entries = [], _pending = [];
  List<RecentReading> get entries => List.unmodifiable(_entries);
  bool loading = false, _ready = false, _disposed = false;
  bool get canWrite => _ready;
  String? error, notice;
  int? _boundEpoch;
  String? _boundId;
  int _revision = 0, _persisted = 0;
  Timer? _timer;
  Future<void>? _writing;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (loading || _disposed) return;
    loading = true;
    _ready = false;
    error = null;
    _notify();
    try {
      final loaded = await repository.load();
      if (_disposed) return;
      final pendingIds = _pending.map((e) => e.gameId).toSet();
      _entries = [
        ..._pending,
        ...loaded.entries.where((e) => !pendingIds.contains(e.gameId)),
      ].take(RecentReadingRepository.maximum).toList();
      _pending = [];
      _ready = true;
      notice = loaded.recovered ? '阅读历史主文件异常，已从备份恢复。' : null;
    } catch (_) {
      if (!_disposed) error = '阅读历史读取失败，原文件已保留；重试后才会继续写入。';
    } finally {
      loading = false;
      _notify();
      if (_ready && _revision != _persisted) _schedule();
    }
  }

  void _libraryChanged() {
    if (_disposed || library.busy) return;
    final changed =
        _boundId != library.currentId || _boundEpoch != library.documentEpoch;
    _boundId = library.currentId;
    _boundEpoch = _boundId == null ? null : library.documentEpoch;
    _sessionChanged(force: changed);
  }

  void _sessionChanged({bool force = false}) {
    if (_disposed || _boundId == null || _boundEpoch != library.session.epoch) {
      return;
    }
    final entry = RecentReading.capture(
      _boundId!,
      library.title,
      library.session.tree,
      _now(),
    );
    if (!force && _entries.isNotEmpty && _entries.first.samePlace(entry)) {
      return;
    }
    _entries = [
      entry,
      ..._entries.where((e) => e.gameId != entry.gameId),
    ].take(RecentReadingRepository.maximum).toList();
    if (!_ready) {
      _pending = [
        entry,
        ..._pending.where((e) => e.gameId != entry.gameId),
      ].take(RecentReadingRepository.maximum).toList();
    }
    _revision++;
    _schedule();
    _notify();
  }

  void _schedule() {
    _timer?.cancel();
    if (_ready && !_disposed) {
      _timer = Timer(debounce, () => unawaited(flush()));
    }
  }

  Future<void> flush() {
    _timer?.cancel();
    if (!_ready || _disposed || _revision == _persisted) return Future.value();
    if (_writing != null) return _writing!;
    final completion = Completer<void>();
    _writing = completion.future;
    unawaited(_drain(completion));
    return completion.future;
  }

  Future<void> _drain(Completer<void> completion) async {
    try {
      while (_persisted != _revision) {
        final revision = _revision;
        final snapshot = List<RecentReading>.unmodifiable(_entries);
        await repository.save(snapshot);
        _persisted = revision;
      }
      error = null;
    } catch (_) {
      if (!_disposed) error = '阅读历史保存失败，棋谱内容未受影响；请重试。';
    } finally {
      _writing = null;
      completion.complete();
      _notify();
    }
  }

  Future<bool> open(RecentReading entry) =>
      library.open(entry.gameId, reading: entry);
  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    library.removeListener(_libraryChanged);
    library.session.removeListener(_sessionChanged);
    super.dispose();
  }
}
