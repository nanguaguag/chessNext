import 'dart:async';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_cache_key.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:chess_next/ports/review_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

EngineIdentity testIdentity({String network = 'c'}) => EngineIdentity(
  release: 'Synthetic test engine',
  commit: 'a' * 40,
  sourceBinarySha256: 'b' * 64,
  binarySha256: 'd' * 64,
  networkSha256: network * 64,
  target: 'test',
);

class VerifiedFake extends FakeEngine {
  EngineIdentity provenance = testIdentity();
  @override
  EngineIdentity get identity => provenance;
}

class FailingCache extends MemoryReviewCacheRepository {
  bool failSave = false;
  bool failLoad = false;
  int loads = 0;
  Completer<CachedEngineScore?>? pending;
  @override
  Future<CachedEngineScore?> load(String key) async {
    loads++;
    if (pending != null) return pending!.future;
    if (failLoad) throw StateError('cache unavailable');
    return super.load(key);
  }

  @override
  Future<void> save(CachedEngineScore score) async {
    if (failSave) throw StateError('cache full');
    await super.save(score);
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  late BoardSession session;
  late VerifiedFake fake;
  late FailingCache cache;
  late EngineSessionController engine;
  setUp(() {
    session = BoardSession();
    fake = VerifiedFake();
    cache = FailingCache();
    engine = EngineSessionController(
      session,
      () async => fake,
      reviewCache: cache,
    );
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Future<void> finish({bool scored = true, String? bound}) async {
    final request = fake.requests.last;
    if (scored) {
      fake.emit(
        request.token,
        bound: bound,
        pv: request.position.legalMoves.first.toString(),
      );
    }
    fake.results.last.complete(request.position.legalMoves.first);
    await tick();
  }

  test(
    'key ignores transient IDs but distinguishes history, budgets, rules and NNUE',
    () {
      EngineRequest request({
        int token = 1,
        int game = 0,
        int depth = 3,
        List<Move> moves = const [],
      }) => EngineRequest(
        token: token,
        gameId: game,
        root: Position.initial(),
        moves: moves,
        depth: depth,
      );
      final base = reviewCacheKey(testIdentity(), request(), const {});
      expect(
        reviewCacheKey(testIdentity(), request(token: 9, game: 8), const {}),
        base,
      );
      expect(
        reviewCacheKey(testIdentity(network: 'e'), request(), const {}),
        isNot(base),
      );
      expect(
        reviewCacheKey(testIdentity(), request(depth: 4), const {}),
        isNot(base),
      );
      final cycle = ['b0c2', 'h9g7', 'c2b0', 'g7h9'].map(Move.parse).toList();
      final repeated = request(moves: cycle);
      expect(
        repeated.position.toFen().split(' ').first,
        Position.initialFen.split(' ').first,
      );
      expect(reviewCacheKey(testIdentity(), repeated, const {}), isNot(base));
      expect(
        reviewCacheKey(testIdentity(), request(), const {
          'Rule60': EngineOption(
            name: 'Rule60',
            type: 'spin',
            defaultValue: '120',
          ),
        }),
        isNot(base),
      );
    },
  );
  test(
    'completed exact scores reuse across navigation and comments without go',
    () async {
      session.playMove(Move.parse('h2e2'));
      session.first();
      final job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await finish();
      await finish();
      await job;
      expect(cache.length, 2);
      expect(fake.requests.length, 2);
      session.forward();
      session.annotate('只修改注释');
      await engine.startReview(limits: ReviewLimits(depth: 3));
      expect(fake.requests.length, 2);
      expect(engine.review!.cachedCount, 2);
      expect(engine.review!.phase, ReviewPhase.completed);
      expect(session.tree.cursorId, 'n1');
      expect(engine.review!.results['n1']!.redScore, -10);
    },
  );
  test(
    'forced recalculation and a changed budget or network never count as hits',
    () async {
      var job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await finish();
      await job;
      for (var i = 0; i < 3; i++) {
        if (i == 2) fake.provenance = testIdentity(network: 'e');
        job = engine.startReview(
          limits: ReviewLimits(depth: i == 0 ? 3 : 4),
          skipExisting: i != 0,
        );
        await tick();
        await finish();
        await job;
        expect(engine.review!.cachedCount, 0);
      }
      expect(fake.requests.length, 4);
    },
  );
  test(
    'bounds and missing scores are not reusable completed evaluations',
    () async {
      var job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await finish(bound: 'lower');
      await job;
      expect(cache.length, 0);
      job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await finish(scored: false);
      await job;
      expect(cache.length, 0);
      expect(engine.review!.cachedCount, 0);
    },
  );
  test(
    'cache IO failure degrades once per job and keeps real results',
    () async {
      session.playMove(Move.parse('h2e2'));
      session.first();
      cache.failLoad = true;
      var job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await finish();
      await finish();
      await job;
      expect(cache.loads, 1);
      expect(engine.review!.cacheNotice, '缓存读取失败，本次重新计算');
      expect(engine.review!.results.length, 2);
      cache.failLoad = false;
      cache.failSave = true;
      job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await finish();
      await finish();
      await job;
      expect(engine.review!.phase, ReviewPhase.completed);
      expect(engine.review!.cacheNotice, '缓存保存失败，分析结果仍可查看');
    },
  );
  test(
    'cancel during cache lookup prevents a late entry or search from appearing',
    () async {
      cache.pending = Completer<CachedEngineScore?>();
      final job = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await engine.cancelReview();
      cache.pending!.complete(null);
      await job;
      expect(engine.review!.phase, ReviewPhase.cancelled);
      expect(fake.requests, isEmpty);
      expect(engine.review!.results, isEmpty);
    },
  );
  test(
    'bounded memory LRU promotes reads and evicts only oldest cache entry',
    () async {
      final lru = MemoryReviewCacheRepository(capacity: 2);
      CachedEngineScore entry(String char) => CachedEngineScore(
        key: char * 64,
        info: EngineInfo(
          token: 9,
          depth: 3,
          multiPv: 1,
          score: 30,
          isMate: false,
          pv: [Move.parse('h2e2')],
        ),
      );
      await lru.save(entry('a'));
      await lru.save(entry('b'));
      await lru.load('a' * 64);
      await lru.save(entry('c'));
      expect(lru.length, 2);
      expect(await lru.load('b' * 64), isNull);
      expect((await lru.load('a' * 64))!.info.token, 0);
      expect(() => entry('x'), throwsArgumentError);
    },
  );
}
