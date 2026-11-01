import 'dart:io';
import '../../ports/draft_repository.dart';
import '../../ports/game_repository.dart';
import 'file_game_repository.dart';

/// Reuses the validated snapshot codec and backup protocol in a separate folder.
class FileDraftRepository implements DraftRepository {
  FileDraftRepository(Future<Directory> Function() directory)
    : _store = FileGameRepository(directory, folderName: 'chessnext-drafts');
  final FileGameRepository _store;
  @override
  Future<SavedGame?> load() async {
    final snapshot = await _store.list();
    if (snapshot.unreadable.contains('active')) {
      throw StateError('自动草稿读取失败，原文件已保留，请重试或继续当前棋谱');
    }
    return snapshot.games.where((game) => game.id == 'active').firstOrNull;
  }

  @override
  Future<void> save(SavedGame draft) => _store.save(
    SavedGame(
      id: 'active',
      title: draft.title,
      tree: draft.tree,
      modifiedAt: draft.modifiedAt,
    ),
  );
}
