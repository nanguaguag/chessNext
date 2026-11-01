import 'dart:io';
import 'package:chess_next/adapters/engine/engine_transport.dart';
import 'package:chess_next/adapters/engine/uci_engine.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

class CacheableFake extends FakeEngine {
  @override
  EngineIdentity get identity => EngineIdentity(
    release: 'Synthetic fixture',
    commit: 'a' * 40,
    sourceBinarySha256: 'b' * 64,
    binarySha256: 'c' * 64,
    networkSha256: 'd' * 64,
    target: 'test',
  );
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  late BoardSession session;
  late CacheableFake fake;
  late EngineSessionController engine;
  setUp(() {
    session = BoardSession();
    session.playMove(Move.parse('h2e2'));
    session.playMove(Move.parse('b9c7'));
    session.first();
    fake = CacheableFake();
    engine = EngineSessionController(session, () async => fake);
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Future<void> finishOne() async {
    final request = fake.requests.last;
    final move =
        request.searchMoves?.first ?? request.position.legalMoves.first;
    fake.emit(
      request.token,
      pv: move.toString(),
      score: request.searchMoves == null ? 30 : 999,
    );
    fake.results.last.complete(move);
    await tick();
  }

  Future<void> drain(Future<void> job) async {
    var done = false;
    final pending = job.whenComplete(() => done = true);
    for (var i = 0; i < 50 && !done; i++) {
      if (fake.results.isNotEmpty && !fake.results.last.isCompleted) {
        await finishOne();
      } else {
        await tick();
      }
    }
    expect(done, isTrue);
    await pending;
  }

  ReviewLimits budget() => ReviewLimits(depth: 3, moveTimeMs: 1000);
  test(
    'whole-tree review computes distinct parent candidates without moving the cursor',
    () async {
      session.playMove(Move.parse('b2e2'));
      session.first();
      final revision = session.revision;
      await drain(
        engine.startReview(
          scope: ReviewScope.tree,
          mode: ReviewMode.candidates,
          maximum: 2,
          limits: budget(),
        ),
      );
      final run = engine.review!;
      expect(run.results.length, 4);
      expect(run.candidateResults.length, 4);
      expect(fake.requests.length, 8);
      expect(run.cachedSearchCount, 0);
      for (final id in run.nodeIds) {
        final set = run.candidateResults[id]!;
        expect(set.complete, isTrue);
        expect(set.entries.length, 2);
        expect(set.entries.map((e) => e.move).toSet().length, 2);
        expect(
          set.entries.every(
            (e) => run.tree.node(id).position.legalMoves.contains(e.move),
          ),
          isTrue,
        );
        expect(
          run.results[id]!.info!.score,
          30,
        ); // Not the later restricted score 999.
        expect(() => set.entries.clear(), throwsUnsupportedError);
      }
      expect(session.tree.cursorId, 'n0');
      expect(session.revision, revision);
    },
  );
  test(
    'best-mode subqueries reuse but partial collections do not count as complete hits',
    () async {
      await drain(engine.startReview(limits: budget()));
      expect(fake.requests.length, 3);
      await drain(
        engine.startReview(
          mode: ReviewMode.candidates,
          maximum: 2,
          limits: budget(),
        ),
      );
      expect(engine.review!.cachedCount, 0);
      expect(engine.review!.cachedSearchCount, 3);
      expect(fake.requests.length, 6);
      await drain(
        engine.startReview(
          mode: ReviewMode.candidates,
          maximum: 2,
          limits: budget(),
        ),
      );
      expect(engine.review!.cachedCount, 3);
      expect(engine.review!.cachedSearchCount, 6);
      expect(fake.requests.length, 6);
      await drain(
        engine.startReview(
          mode: ReviewMode.candidates,
          maximum: 3,
          limits: budget(),
        ),
      );
      expect(engine.review!.cachedCount, 0);
      expect(engine.review!.cachedSearchCount, 6);
      expect(fake.requests.length, 9);
    },
  );
  test(
    'cancellation retains partial candidates without counting the position complete',
    () async {
      final job = engine.startReview(
        mode: ReviewMode.candidates,
        maximum: 2,
        limits: budget(),
      );
      await tick();
      await finishOne();
      final id = engine.review!.currentNodeId!;
      expect(engine.review!.candidateResults[id]!.entries.length, 1);
      expect(engine.review!.candidateResults[id]!.complete, isFalse);
      expect(engine.review!.results, isEmpty);
      await engine.cancelReview();
      await job;
      expect(engine.review!.phase, ReviewPhase.cancelled);
      expect(engine.review!.candidateResults[id]!.complete, isFalse);
      expect(engine.review!.results, isEmpty);
    },
  );
  test(
    'navigation keeps the queue target, editing invalidates the whole run',
    () async {
      final job = engine.startReview(
        mode: ReviewMode.candidates,
        maximum: 2,
        limits: budget(),
      );
      await tick();
      await engine.navigateToNode('n1');
      expect(engine.reviewing, isTrue);
      expect(fake.requests.last.moves.length, 2);
      await drain(job);
      expect(session.tree.cursorId, 'n1');
      final edited = engine.startReview(
        mode: ReviewMode.candidates,
        maximum: 2,
        limits: budget(),
        skipExisting: false,
      );
      await tick();
      session.annotate('新注释');
      await edited;
      expect(engine.review!.phase, ReviewPhase.stale);
    },
  );
  test('candidate count is bounded at the controller boundary', () async {
    await expectLater(
      engine.startReview(
        mode: ReviewMode.candidates,
        maximum: 1,
        limits: budget(),
      ),
      throwsArgumentError,
    );
    expect(fake.requests, isEmpty);
  });
  test(
    'a cache hit followed by an actual empty search is not a fully reused position',
    () async {
      session.replaceTree(GameTree());
      await drain(engine.startReview(limits: budget()));
      final job = engine.startReview(
        mode: ReviewMode.candidates,
        maximum: 2,
        limits: budget(),
      );
      await tick();
      fake.results.last.complete(null);
      await job;
      expect(engine.review!.cachedSearchCount, 1);
      expect(engine.review!.cachedCount, 0);
      expect(engine.review!.candidateResults['n0']!.entries.length, 1);
    },
  );
  final executable = Platform.environment['PIKAFISH_EXECUTABLE'];
  test(
    'real NNUE completes multiple candidates for every position of a branching tree',
    () async {
      session.playMove(Move.parse('b2e2'));
      session.first();
      final transport = await ProcessEngineTransport.spawn(
        executable!,
        workingDirectory: File(executable).parent.path,
      );
      final real = UciEngine(
        transport,
        networkPath: Platform.environment['PIKAFISH_NETWORK'],
      );
      final coordinator = EngineSessionController(session, () async => real);
      addTearDown(coordinator.dispose);
      await coordinator
          .startReview(
            scope: ReviewScope.tree,
            mode: ReviewMode.candidates,
            maximum: 2,
            limits: ReviewLimits(depth: 3, moveTimeMs: 1000),
          )
          .timeout(const Duration(seconds: 30));
      final run = coordinator.review!;
      expect(run.phase, ReviewPhase.completed);
      expect(run.results.length, 4);
      for (final set in run.candidateResults.values) {
        expect(set.entries.length, 2);
        expect(set.complete, isTrue);
        expect(set.entries.map((e) => e.move).toSet().length, 2);
        expect(set.entries.every((e) => e.info != null), isTrue);
      }
    },
    skip: executable == null
        ? 'Set PIKAFISH_EXECUTABLE for actual NNUE'
        : false,
  );
}
