import 'game_repository.dart';

/// Emergency working copy, independent of the explicitly saved record library.
abstract interface class DraftRepository {
  Future<SavedGame?> load();
  Future<void> save(SavedGame draft);
}

class MemoryDraftRepository implements DraftRepository {
  SavedGame? draft;
  @override
  Future<SavedGame?> load() async => draft;
  @override
  Future<void> save(SavedGame value) async {
    draft = value;
  }
}
