import '../ports/engine_gateway.dart';
import '../ports/review_cache_repository.dart';
import 'review_cache_key.dart';

/// Per-job cache health and bounded IO, shared by batch and candidate jobs.
class ReviewCacheAccess {
  ReviewCacheAccess(
    this.identity,
    Map<String, EngineOption> options,
    this.repository,
  ) : options = Map.unmodifiable(options),
      healthy = identity != null,
      notice = identity == null ? '引擎身份未验证，本次不复用缓存' : null;
  final EngineIdentity? identity;
  final Map<String, EngineOption> options;
  final ReviewCacheRepository repository;
  bool healthy;
  String? notice;
  Future<EngineInfo?> read(EngineRequest request) async {
    if (!healthy) return null;
    try {
      final key = reviewCacheKey(identity!, request, options);
      final cached = await repository
          .load(key)
          .timeout(const Duration(seconds: 2));
      if (cached == null) return null;
      try {
        if (request.preferWdl &&
            options['UCI_ShowWDL']?.type == 'check' &&
            cached.info.wdl == null) {
          throw const FormatException('Cached score lacks requested WDL');
        }
        if (cached.key != key) throw const FormatException('Wrong cache key');
        var position = request.position;
        for (final move in cached.info.pv) {
          position = position.play(move);
        }
        if (request.searchMoves != null &&
            !request.searchMoves!.contains(cached.info.pv.first)) {
          throw const FormatException('Cached move outside allowed set');
        }
      } catch (_) {
        await repository.remove(key).timeout(const Duration(seconds: 2));
        rethrow;
      }
      return cached.info;
    } catch (_) {
      healthy = false;
      notice = '缓存读取失败，本次重新计算';
      return null;
    }
  }

  Future<void> write(EngineRequest request, EngineInfo? info) async {
    if (!healthy ||
        info == null ||
        info.bound != null ||
        info.depth < 1 ||
        info.pv.isEmpty ||
        info.pv.length > 256) {
      return;
    }
    if (request.preferWdl &&
        options['UCI_ShowWDL']?.type == 'check' &&
        info.wdl == null) {
      return;
    }
    try {
      final key = reviewCacheKey(identity!, request, options);
      await repository
          .save(CachedEngineScore(key: key, info: info))
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      healthy = false;
      notice = '缓存保存失败，分析结果仍可查看';
    }
  }
}
