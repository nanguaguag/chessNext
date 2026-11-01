import 'dart:async';
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

class ReviewFake extends FakeEngine {
  Completer<void>? stopBarrier;
  @override
  Future<void> stop() async {
    await stopBarrier?.future;
    await super.stop();
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  late BoardSession session;
  late ReviewFake fake;
  late EngineSessionController engine;
  setUp(() {
    session = BoardSession();
    session.playMove(Move.parse('h2e2'));
    session.playMove(Move.parse('b9c7'));
    session.first();
    session.playMove(Move.parse('b2e2'));
    session.first();
    fake = ReviewFake();
    engine = EngineSessionController(session, () async => fake);
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Future<void> finish({bool score = true, int cp = 25}) async {
    final request = fake.requests.last;
    if (score) {
      fake.emit(
        request.token,
        score: cp,
        pv: request.position.legalMoves.first.toString(),
      );
    }
    fake.results.last.complete(request.position.legalMoves.first);
    await tick();
  }

  test('finite limits reject all-zero/unbounded and invalid values', () {
    expect(
      () => ReviewLimits(depth: null, moveTimeMs: null),
      throwsArgumentError,
    );
    expect(() => ReviewLimits(depth: 0), throwsArgumentError);
    expect(() => ReviewLimits(nodeLimit: -1), throwsArgumentError);
  });
  test(
    'line includes future, reverse queue preserves cursor and normalizes bounds',
    () async {
      final revision = session.revision;
      final job = engine.startReview(
        limits: ReviewLimits(depth: 3, moveTimeMs: 100, nodeLimit: 1000),
      );
      await tick();
      expect(engine.review!.nodeIds, ['n3', 'n0']);
      expect(fake.requests.single.moves.map((m) => m.toString()), ['b2e2']);
      expect(fake.requests.single.gameId, session.epoch);
      expect(fake.requests.single.multiPv, 1);
      fake.emit(
        fake.requests.last.token,
        score: 25,
        bound: 'lower',
        pv: 'b9c7',
      );
      fake.results.last.complete(Move.parse('b9c7'));
      await tick();
      expect(engine.review!.results['n3']!.redScore, -25);
      expect(engine.review!.results['n3']!.redBound, 'upper');
      // Read navigation must not switch the queue's node or overwrite scores.
      await engine.navigateToNode('n2');
      expect(engine.reviewing, isTrue);
      await finish(cp: 40);
      await job;
      expect(engine.review!.phase, ReviewPhase.completed);
      expect(engine.review!.results['n0']!.redScore, 40);
      expect(session.tree.cursorId, 'n2');
      expect(session.revision, revision);
    },
  );
  test(
    'whole-tree scopes unique nodes, missing scores remain absent and mate stays distinct',
    () async {
      final job = engine.startReview(
        scope: ReviewScope.tree,
        limits: ReviewLimits(depth: 2),
      );
      await tick();
      expect(engine.review!.nodeIds.toSet(), {'n0', 'n1', 'n2', 'n3'});
      await finish(score: false);
      final missing = engine.review!.results.values.single;
      expect(missing.status, ReviewScoreStatus.noScore);
      expect(missing.redScore, isNull);
      while (engine.reviewing) {
        await finish();
      }
      await job;
      final mate = ReviewedPosition(
        nodeId: 'test',
        turn: Side.black,
        status: ReviewScoreStatus.scored,
        info: const EngineInfo(
          token: 1,
          depth: 5,
          multiPv: 1,
          score: -3,
          isMate: true,
          bound: 'upper',
          pv: [],
        ),
      );
      expect(mate.redScore, 3);
      expect(mate.label, '红方 ≥杀棋 3');
    },
  );
  test(
    'cancelling waits stop barrier, keeps partial and rejects late info',
    () async {
      final job = engine.startReview(
        scope: ReviewScope.tree,
        limits: ReviewLimits(depth: 2),
      );
      await tick();
      await finish();
      final token = fake.requests.last.token;
      fake.stopBarrier = Completer<void>();
      final stopping = engine.cancelReview();
      expect(engine.review!.phase, ReviewPhase.stopping);
      fake.emit(
        token,
        score: 999,
        pv: fake.requests.last.position.legalMoves.first.toString(),
      );
      fake.stopBarrier!.complete();
      await stopping;
      await job;
      expect(engine.review!.phase, ReviewPhase.cancelled);
      expect(engine.review!.results.length, 1);
      expect(engine.review!.results.values.single.redScore, -25);
    },
  );
  test('document edit invalidates partial result and stops queue', () async {
    final job = engine.startReview(limits: ReviewLimits(depth: 2));
    await tick();
    session.annotate('新注释');
    await job;
    await tick();
    expect(engine.review!.phase, ReviewPhase.stale);
    expect(engine.review!.results, isEmpty);
    expect(fake.requests.length, 1);
    expect(session.tree.root.comment, '新注释');
  });
  test('analysis and AI preempt review on the same engine', () async {
    var job = engine.startReview(limits: ReviewLimits(depth: 2));
    await tick();
    await engine.enable();
    await job;
    expect(engine.review!.phase, ReviewPhase.cancelled);
    expect(engine.enabled, isTrue);
    job = engine.startReview(limits: ReviewLimits(depth: 2));
    await tick();
    expect(engine.enabled, isFalse);
    await engine.setAiSide(Side.red, true);
    await job;
    expect(engine.review!.phase, ReviewPhase.cancelled);
    expect(engine.playing, isTrue);
    expect(engine.thinking, isTrue);
  });
  test('search failure is explicit and does not record a zero', () async {
    final job = engine.startReview(limits: ReviewLimits(depth: 2));
    await tick();
    fake.results.last.completeError(StateError('engine gone'));
    await job;
    expect(engine.review!.phase, ReviewPhase.failed);
    expect(engine.review!.results, isEmpty);
    expect(engine.error, isNotNull);
  });
  test(
    'new document cannot consume a previous queue with reused ids',
    () async {
      final job = engine.startReview(limits: ReviewLimits(depth: 2));
      await tick();
      session.newGame();
      session.playMove(Move.parse('h2e2'));
      await job;
      await tick();
      expect(engine.review!.phase, ReviewPhase.stale);
      expect(engine.review!.results, isEmpty);
      expect(session.tree.current.move, Move.parse('h2e2'));
    },
  );
  test('terminal position is recorded without a fabricated score', () async {
    session.replaceTree(
      GameTree(
        initial: Position.fromFen('4k4/9/9/9/4p4/9/9/9/3r1r3/4K4 w - - 0 1'),
      ),
    );
    await engine.startReview(limits: ReviewLimits(depth: 2));
    expect(fake.requests, isEmpty);
    expect(
      engine.review!.results.values.single.status,
      ReviewScoreStatus.terminal,
    );
    expect(engine.review!.results.values.single.info, isNull);
  });
  test('a synchronous listener can cancel before any search is sent', () async {
    var cancelled = false;
    void listener() {
      if (!cancelled && engine.reviewing) {
        cancelled = true;
        unawaited(engine.cancelReview());
      }
    }

    engine.addListener(listener);
    await engine.startReview(limits: ReviewLimits(depth: 2));
    await tick();
    expect(fake.requests, isEmpty);
    expect(engine.review!.phase, ReviewPhase.cancelled);
    engine.removeListener(listener);
  });
  final executable = Platform.environment['PIKAFISH_EXECUTABLE'];
  test(
    'real NNUE reviews an entire branching game using the shared coordinator',
    () async {
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
            limits: ReviewLimits(depth: 4, moveTimeMs: 1000),
          )
          .timeout(const Duration(seconds: 30));
      expect(coordinator.review!.phase, ReviewPhase.completed);
      expect(coordinator.review!.results.length, 4);
      for (final result in coordinator.review!.results.values) {
        expect(result.info, isNotNull);
        expect(result.info!.depth, lessThanOrEqualTo(4));
        expect(
          session.tree.node(result.nodeId).position.legalMoves,
          contains(result.info!.pv.first),
        );
      }
      await coordinator.enable();
      expect(coordinator.enabled, isTrue);
      await coordinator.disable();
    },
    skip: executable == null
        ? 'Set PIKAFISH_EXECUTABLE for actual NNUE'
        : false,
  );
}
