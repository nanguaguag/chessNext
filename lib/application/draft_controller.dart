import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/draft_repository.dart';
import '../ports/game_repository.dart';
import 'board_session.dart';
import 'library_controller.dart';

typedef _DraftKey = (GameTree, String);

class DraftController extends ChangeNotifier {
  DraftController(
    this.session,
    this.library,
    this.repository, {
    this.debounce = const Duration(milliseconds: 300),
  }) {
    session.addListener(_changed);
    library.addListener(_changed);
  }
  final BoardSession session;
  final LibraryController library;
  final DraftRepository repository;
  final Duration debounce;
  bool loading = false;
  bool _ready = false;
  bool _disposed = false;
  SavedGame? pending;
  String? error;
  String status = '正在检查本地草稿';
  bool get saving => _writing != null;
  bool get canSave => _ready && !loading && pending == null;
  Timer? _timer;
  Future<void>? _writing;
  (SavedGame, _DraftKey)? _queued;
  _DraftKey? _observed;
  _DraftKey? _persisted;
  _DraftKey get _key => (session.tree, library.title);
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
      final draft = await repository.load();
      if (_disposed) return;
      final hasContent =
          draft != null &&
          (draft.tree.nodeCount > 1 ||
              draft.tree.root.comment.isNotEmpty ||
              draft.tree.root.position.toFen() != Position.initialFen);
      pending = hasContent ? draft : null;
      _ready = pending == null;
      status = pending == null ? '自动草稿已开启' : '发现上次的自动草稿';
    } catch (_) {
      if (!_disposed) error = '自动草稿读取失败，原文件已保留，请重试或继续当前棋谱';
    } finally {
      loading = false;
      if (!_disposed) {
        _notify();
        if (_ready && session.hasContent) _changed();
      }
    }
  }

  void _changed() {
    if (!_ready || _disposed || loading || pending != null) return;
    final key = _key;
    if (key == _observed) return;
    _observed = key;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Recovery always creates a new dirty copy; it never binds the saved record ID.
  bool restore({bool replaceCurrent = false}) {
    final draft = pending;
    if (draft == null ||
        (session.dirty && session.hasContent && !replaceCurrent)) {
      return false;
    }
    library.importTree(draft.tree, title: draft.title);
    pending = null;
    _ready = true;
    _observed = _key;
    _persisted = _key;
    error = null;
    status = draft.recovered ? '已从备份恢复草稿，请核对后保存' : '已恢复为未保存副本';
    _notify();
    return true;
  }

  void keepCurrent() {
    if (_disposed || loading) return;
    pending = null;
    error = null;
    _ready = true;
    _observed = null;
    _changed();
    _notify();
  }

  Future<void> flush() {
    _timer?.cancel();
    if (!_ready || _disposed || loading || pending != null) {
      return Future.value();
    }
    final key = _key;
    if (key == _persisted && _writing == null) return Future.value();
    _queued = (
      SavedGame(
        id: 'active',
        title: library.title,
        tree: session.tree,
        modifiedAt: DateTime.now(),
      ),
      key,
    );
    if (_writing != null) return _writing!;
    final completion = Completer<void>();
    _writing = completion.future;
    error = null;
    status = '正在保存自动草稿';
    _notify();
    unawaited(_drain(completion));
    return completion.future;
  }

  Future<void> _drain(Completer<void> completion) async {
    try {
      while (_queued != null) {
        final (draft, key) = _queued!;
        _queued = null;
        await repository.save(draft);
        _persisted = key;
      }
      status = '自动草稿已更新';
    } catch (_) {
      _queued = null;
      error = '自动草稿保存失败，请检查存储空间或权限后重试';
      status = '自动草稿尚未保存';
    } finally {
      _writing = null;
      completion.complete();
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    session.removeListener(_changed);
    library.removeListener(_changed);
    super.dispose();
  }
}
