import 'package:chess_next/application/finite_search_executor.dart';
import 'package:chess_next/application/review_cache_access.dart';
import 'package:chess_next/application/review_cache_key.dart';
import 'package:chess_next/ports/review_cache_repository.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  late FakeEngine fake;
  late MemoryReviewCacheRepository repository;
  late ReviewCacheAccess cache;
  late FiniteSearchExecutor executor;
  EngineRequest request({List<Move>? allowed, int? depth = 3}) => EngineRequest(
    token: 71,
    root: Position.initial(),
    depth: depth,
    searchMoves: allowed,
  );
  setUp(() {
    fake = FakeEngine();
    repository = MemoryReviewCacheRepository();
    final identity = EngineIdentity(
      release: 'Synthetic fixture',
      commit: 'a' * 40,
      sourceBinarySha256: 'b' * 64,
      binarySha256: 'c' * 64,
      networkSha256: 'd' * 64,
      target: 'test',
    );
    cache = ReviewCacheAccess(identity, fake.options, repository);
    executor = FiniteSearchExecutor(fake, cache);
  });
  tearDown(() => fake.dispose());
  test(
    'one finite request stores only matching complete PV and removes its listener',
    () async {
      final result = executor.execute(request(), isCurrent: () => true);
      await tick();
      expect(fake.events.hasListener, isTrue);
      fake.emit(71, pv: 'h2e2 b9c7');
      fake.results.last.complete(Move.parse('h2e2'));
      final outcome = (await result)!;
      expect(outcome.info!.score, 10);
      expect(outcome.cached, isFalse);
      expect(fake.events.hasListener, isFalse);
      expect(repository.length, 1);
      final reused = (await executor.execute(
        request(),
        isCurrent: () => true,
      ))!;
      expect(reused.cached, isTrue);
      expect(fake.requests.length, 1);
    },
  );
  test('mismatched or illegal full PV is unscored and never cached', () async {
    for (final pv in ['b0c2', 'h2e2 b0c2']) {
      final result = executor.execute(request(), isCurrent: () => true);
      await tick();
      fake.emit(71, pv: pv);
      fake.results.last.complete(Move.parse('h2e2'));
      expect((await result)!.info, isNull);
    }
    expect(repository.length, 0);
    expect(fake.events.hasListener, isFalse);
  });
  test(
    'excluded bestmove fails and stream errors cannot leak a subscription',
    () async {
      var result = executor.execute(
        request(allowed: [Move.parse('h2e2')]),
        isCurrent: () => true,
      );
      await tick();
      fake.results.last.complete(Move.parse('b0c2'));
      await expectLater(result, throwsStateError);
      expect(fake.events.hasListener, isFalse);
      result = executor.execute(request(), isCurrent: () => true);
      await tick();
      fake.events.addError(StateError('protocol stream failed'));
      await expectLater(result, throwsStateError);
      expect(fake.events.hasListener, isFalse);
    },
  );
  test(
    'cancellation discards a completed move and makes subsequent info inert',
    () async {
      var current = true;
      var infos = 0;
      final result = executor.execute(
        request(),
        isCurrent: () => current,
        onInfo: (_) => infos++,
      );
      await tick();
      current = false;
      fake.emit(71);
      fake.results.last.complete(Move.parse('h2e2'));
      expect(await result, isNull);
      expect(infos, 0);
      expect(repository.length, 0);
      expect(fake.events.hasListener, isFalse);
    },
  );
  test(
    'invalid cached PV is evicted so future jobs can regenerate it',
    () async {
      final key = reviewCacheKey(cache.identity!, request(), fake.options);
      await repository.save(
        CachedEngineScore(
          key: key,
          info: EngineInfo(
            token: 0,
            depth: 3,
            multiPv: 1,
            score: 99,
            isMate: false,
            pv: [Move.parse('h2e2'), Move.parse('b0c2')],
          ),
        ),
      );
      expect(await cache.read(request()), isNull);
      expect(await repository.load(key), isNull);
      expect(cache.notice, '缓存读取失败，本次重新计算');
    },
  );
  test(
    'unbounded requests and illegal allowed sets never reach the gateway',
    () async {
      await expectLater(
        executor.execute(request(depth: null), isCurrent: () => true),
        throwsArgumentError,
      );
      await expectLater(
        executor.execute(
          request(allowed: [Move.parse('a9a8')]),
          isCurrent: () => true,
        ),
        throwsArgumentError,
      );
      expect(fake.requests, isEmpty);
    },
  );
}
