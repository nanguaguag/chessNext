import 'package:xiangqi_core/xiangqi_core.dart';

class SavedGame {
  const SavedGame({
    required this.id,
    required this.title,
    required this.tree,
    required this.modifiedAt,
    this.recovered = false,
  });
  final String id;
  final String title;
  final GameTree tree;
  final DateTime modifiedAt;
  final bool recovered;
}

class LibrarySnapshot {
  const LibrarySnapshot(this.games, {this.unreadable = const []});
  final List<SavedGame> games;
  final List<String> unreadable;
}

abstract interface class GameRepository {
  Future<LibrarySnapshot> list();
  Future<SavedGame> load(String id);
  Future<void> save(SavedGame game);
}

/// Explicit test/preview adapter. Production injects platform-backed storage.
class MemoryGameRepository implements GameRepository {
  final Map<String, SavedGame> _games = {};
  @override
  Future<LibrarySnapshot> list() async => LibrarySnapshot(
    _games.values.toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt)),
  );
  @override
  Future<SavedGame> load(String id) async =>
      _games[id] ?? (throw StateError('棋谱不存在'));
  @override
  Future<void> save(SavedGame game) async {
    _games[game.id] = game;
  }
}
