import 'engine_gateway.dart';

/// Only completed, exact single-PV engine scores qualify for reuse.
class CachedEngineScore {
  CachedEngineScore({required this.key, required EngineInfo info})
    : info = EngineInfo(
        token: 0,
        depth: info.depth,
        multiPv: 1,
        score: info.score,
        isMate: info.isMate,
        pv: List.unmodifiable(info.pv),
        timeMs: info.timeMs,
        nodes: info.nodes,
        nps: info.nps,
      ) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key) ||
        info.bound != null ||
        info.multiPv != 1 ||
        info.depth < 1 ||
        info.depth > EngineRequest.maxDepth ||
        info.pv.isEmpty ||
        info.pv.length > 256) {
      throw ArgumentError('Invalid reusable engine score');
    }
  }
  final String key;
  final EngineInfo info;
}

abstract interface class ReviewCacheRepository {
  Future<CachedEngineScore?> load(String key);
  Future<void> save(CachedEngineScore score);
}

/// Bounded LRU; no document, node ID, cursor or UI state is stored in an entry.
class MemoryReviewCacheRepository implements ReviewCacheRepository {
  MemoryReviewCacheRepository({this.capacity = 2048}) {
    if (capacity < 1 || capacity > 10000) {
      throw ArgumentError('Invalid cache capacity');
    }
  }
  final int capacity;
  final _entries = <String, CachedEngineScore>{};
  int get length => _entries.length;
  @override
  Future<CachedEngineScore?> load(String key) async {
    final entry = _entries.remove(key);
    if (entry != null) _entries[key] = entry;
    return entry;
  }

  @override
  Future<void> save(CachedEngineScore score) async {
    _entries.remove(score.key);
    _entries[score.key] = score;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}
