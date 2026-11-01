import 'engine_gateway.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

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
        info.pv.length > 256 ||
        info.score.abs() > 1000000000 ||
        [
          info.timeMs,
          info.nodes,
          info.nps,
        ].any((n) => n != null && (n < 0 || n > EngineRequest.maxNodeLimit))) {
      throw ArgumentError('Invalid reusable engine score');
    }
  }
  final String key;
  final EngineInfo info;
  Map<String, Object?> toJson() => {
    'key': key,
    'depth': info.depth,
    'score': info.score,
    'mate': info.isMate,
    'pv': info.pv.map((m) => m.toString()).toList(),
    'timeMs': info.timeMs,
    'nodes': info.nodes,
    'nps': info.nps,
  };
  factory CachedEngineScore.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
          (name) => !{
            'key',
            'depth',
            'score',
            'mate',
            'pv',
            'timeMs',
            'nodes',
            'nps',
          }.contains(name),
        ) ||
        json['key'] is! String ||
        json['depth'] is! int ||
        json['score'] is! int ||
        json['mate'] is! bool ||
        json['pv'] is! List ||
        (json['pv'] as List).any((m) => m is! String) ||
        [
          'timeMs',
          'nodes',
          'nps',
        ].any((name) => json[name] != null && json[name] is! int)) {
      throw const FormatException('Invalid cached score');
    }
    final pv = json['pv'] as List;
    if (pv.isEmpty || pv.length > 256) {
      throw const FormatException('Invalid cached PV size');
    }
    try {
      return CachedEngineScore(
        key: json['key'] as String,
        info: EngineInfo(
          token: 0,
          depth: json['depth'] as int,
          multiPv: 1,
          score: json['score'] as int,
          isMate: json['mate'] as bool,
          pv: pv.map((m) => Move.parse(m as String)).toList(),
          timeMs: json['timeMs'] as int?,
          nodes: json['nodes'] as int?,
          nps: json['nps'] as int?,
        ),
      );
    } on ArgumentError {
      throw const FormatException('Invalid cached score values');
    }
  }
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
