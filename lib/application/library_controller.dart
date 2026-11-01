import 'package:xiangqi_core/xiangqi_core.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../ports/game_repository.dart';
import '../ports/recent_reading_repository.dart';
import 'board_session.dart';

class LibraryController extends ChangeNotifier {
  LibraryController(this.session, this.repository);
  final BoardSession session;
  final GameRepository repository;
  bool busy = false;
  String? error;
  String? currentId;
  int? _documentEpoch;
  int? get documentEpoch => _documentEpoch;
  String title = '未命名棋谱';
  LibrarySnapshot snapshot = const LibrarySnapshot([]);
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> _perform(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
      return true;
    } catch (e) {
      error = e is StateError ? e.message : '无法读写本地棋谱，请检查存储空间或权限后重试';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> refresh() => _perform(() async {
    snapshot = await repository.list();
  });
  Future<bool> save(String name) => _perform(() async {
    if (name.trim().isEmpty || name.trim().length > 120) {
      throw StateError('棋谱名称需要1至120个字符');
    }
    final epoch = session.epoch;
    final revision = session.revision;
    final id =
        (documentEpoch == epoch ? currentId : null) ??
        List.generate(
          16,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
    final game = SavedGame(
      id: id,
      title: name.trim(),
      tree: session.tree,
      modifiedAt: DateTime.now(),
    );
    await repository.save(game);
    if (!_disposed && session.epoch == epoch) {
      currentId = id;
      _documentEpoch = epoch;
      title = name.trim();
      session.markSaved(revision);
    }
    final games = [...snapshot.games.where((g) => g.id != id), game]
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    snapshot = LibrarySnapshot(
      List.unmodifiable(games),
      unreadable: snapshot.unreadable,
    );
  });
  Future<bool> open(String id, {RecentReading? reading}) => _perform(() async {
    final epoch = session.epoch;
    final revision = session.revision;
    final positionRevision = session.positionRevision;
    final game = await repository.load(id);
    if (_disposed) return;
    if (session.epoch != epoch ||
        session.revision != revision ||
        session.positionRevision != positionRevision) {
      throw StateError('读取期间对局已变化，请重新打开');
    }
    if (reading != null && reading.gameId != id) {
      throw StateError('阅读标记与棋谱不匹配');
    }
    final restored = reading?.restore(game.tree);
    session.replaceTree(restored?.tree ?? game.tree);
    if (restored?.matched == false) {
      error = '原阅读位置已变化，已打开棋谱保存时的位置。未保存的分支请从自动草稿恢复。';
    }
    currentId = game.id;
    _documentEpoch = session.epoch;
    title = game.title;
    if (game.recovered) {
      error = [?error, '主文件异常，已从备份恢复，请核对棋谱后保存'].join('；');
    }
  });
  void startPosition(Position position) =>
      importTree(GameTree(initial: position), title: '局面分析');

  void importTree(GameTree tree, {String title = '导入棋谱'}) {
    session.replaceTree(tree, saved: false);
    currentId = null;
    _documentEpoch = null;
    this.title = title;
    _notify();
  }

  void newGame() {
    session.newGame();
    currentId = null;
    _documentEpoch = null;
    title = '未命名棋谱';
    _notify();
  }
}
