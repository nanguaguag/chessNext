import 'dart:async';
import 'dart:io';
import 'package:chess_next/adapters/engine/engine_transport.dart';
import 'package:chess_next/adapters/engine/uci_engine.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/candidate_models.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

class CandidateFake extends FakeEngine {
  Completer<void>? barrier;
  bool failStop = false;
  @override
  Future<void> stop() async {
    await barrier?.future;
    if (failStop) throw StateError('stop failed');
    await super.stop();
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  late BoardSession session;
  late CandidateFake fake;
  late EngineSessionController engine;
  setUp(() {
    session = BoardSession();
    session.playMove(Move.parse('h2e2'));
    session.playMove(Move.parse('b9c7'));
    fake = CandidateFake();
    engine = EngineSessionController(session, () async => fake);
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Future<void> finish(String move, {bool score = true, String? pv}) async {
    if (score) fake.emit(fake.requests.last.token, score: 25, pv: pv ?? move);
    fake.results.last.complete(Move.parse(move));
    await tick();
  }

  Future<CandidateRun> complete() async {
    final job = engine.startCandidates(
      limits: ReviewLimits(depth: 3, moveTimeMs: 1000, nodeLimit: 10000),
      maximum: 2,
    );
    await tick();
    await finish('b9c7');
    await finish('h9g7');
    await job;
    return engine.candidates!;
  }

  test(
    'different candidates use parent history and a shrinking legal allowed set',
    () async {
      await complete();
      expect(engine.candidates!.phase, ReviewPhase.completed);
      expect(engine.candidates!.parentId, 'n1');
      expect(
        fake.requests.map((r) => r.moves.map((m) => m.toString()).toList()),
        [
          ['h2e2'],
          ['h2e2'],
        ],
      );
      expect(fake.requests.every((r) => r.position.turn == Side.black), isTrue);
      expect(fake.requests.first.searchMoves, isNull);
      expect(
        fake.requests.last.searchMoves,
        isNot(contains(Move.parse('b9c7'))),
      );
      expect(fake.requests.last.searchMoves, contains(Move.parse('h9g7')));
      expect(
        fake.requests.every(
          (r) => r.depth == 3 && r.moveTimeMs == 1000 && r.nodeLimit == 10000,
        ),
        isTrue,
      );
      expect(session.tree.cursorId, 'n2');
      expect(session.tree.nodeCount, 3);
      expect(engine.infos, isEmpty);
    },
  );
  test(
    'trial adds a sibling atomically, preserves original branch and reuses saved moves',
    () async {
      final run = await complete();
      final positions = <String>[];
      session.addListener(() => positions.add(session.tree.cursorId));
      final revision = session.revision;
      expect(await engine.tryCandidate(run, Move.parse('h9g7')), isTrue);
      expect(positions, ['n3']);
      expect(session.tree.node('n1').children, ['n2', 'n3']);
      expect(session.tree.current.move, Move.parse('h9g7'));
      expect(session.position.turn, Side.red);
      expect(session.revision, revision + 1);
      final savedRevision = session.revision;
      expect(session.playVariation('n1', Move.parse('b9c7')), isTrue);
      expect(session.tree.cursorId, 'n2');
      expect(session.revision, savedRevision);
      final positionRevision = session.positionRevision;
      expect(session.playVariation('n1', Move.parse('b9c7')), isTrue);
      expect(session.positionRevision, positionRevision);
      expect(session.playVariation('missing', Move.parse('h9g7')), isFalse);
    },
  );
  test(
    'trial while calculating waits for stop and discards the late candidate',
    () async {
      final job = engine.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      await finish('h9g7');
      final run = engine.candidates!;
      fake.stopMove = Move.parse('b9c7');
      expect(await engine.tryCandidate(run, Move.parse('h9g7')), isTrue);
      await job;
      expect(session.tree.current.move, Move.parse('h9g7'));
      expect(session.tree.node('n1').children.length, 2);
      expect(engine.candidates!.phase, ReviewPhase.stale);
    },
  );
  test('new human edit while stopping makes the trial stale', () async {
    final job = engine.startCandidates(
      limits: ReviewLimits(depth: 3),
      maximum: 2,
    );
    await tick();
    await finish('h9g7');
    fake.barrier = Completer<void>();
    final trial = engine.tryCandidate(engine.candidates!, Move.parse('h9g7'));
    session.annotate('保留当前着');
    fake.barrier!.complete();
    expect(await trial, isFalse);
    await job;
    expect(session.tree.cursorId, 'n2');
    expect(session.tree.current.comment, '保留当前着');
  });
  test(
    'reading navigation invalidates single-step results and cannot trial reused ids',
    () async {
      final run = await complete();
      await engine.navigateToNode('n0');
      expect(engine.candidates!.phase, ReviewPhase.stale);
      expect(await engine.tryCandidate(run, Move.parse('h9g7')), isFalse);
      session.newGame();
      session.playMove(Move.parse('b2e2'));
      session.playMove(Move.parse('b9c7'));
      expect(await engine.tryCandidate(run, Move.parse('h9g7')), isFalse);
      expect(session.tree.nodeCount, 3);
    },
  );
  test(
    'illegal or duplicate bestmove fails instead of producing another ranked score',
    () async {
      final job = engine.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      await finish('b9c7');
      await finish('b9c7');
      await job;
      expect(engine.candidates!.phase, ReviewPhase.failed);
      expect(engine.candidates!.results.length, 1);
      expect(session.tree.nodeCount, 3);
    },
  );
  test(
    'missing score and mismatched final PV remain unscored legal candidates',
    () async {
      final job = engine.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      await finish('b9c7', score: false);
      await finish('h9g7', pv: 'h9i7');
      await job;
      expect(engine.candidates!.results.every((r) => r.info == null), isTrue);
      expect(engine.candidates!.results.map((r) => r.move.toString()), [
        'b9c7',
        'h9g7',
      ]);
    },
  );
  test(
    'analysis, AI and batch review preempt the same candidate engine',
    () async {
      var job = engine.startCandidates(limits: ReviewLimits(depth: 3));
      await tick();
      await engine.enable();
      await job;
      expect(engine.candidates!.phase, ReviewPhase.cancelled);
      expect(engine.enabled, isTrue);
      job = engine.startCandidates(limits: ReviewLimits(depth: 3));
      await tick();
      expect(engine.enabled, isFalse);
      await engine.setAiSide(Side.red, true);
      await job;
      expect(engine.candidates!.phase, ReviewPhase.cancelled);
      expect(engine.thinking, isTrue);
      job = engine.startCandidates(limits: ReviewLimits(depth: 3));
      await tick();
      expect(engine.playing, isFalse);
      final review = engine.startReview(limits: ReviewLimits(depth: 3));
      await tick();
      await job;
      expect(engine.candidates!.phase, ReviewPhase.cancelled);
      await engine.disable();
      await review;
    },
  );
  test(
    'a synchronous cancellation sends no go and count limits are validated',
    () async {
      await expectLater(
        engine.startCandidates(limits: ReviewLimits(), maximum: 1),
        throwsArgumentError,
      );
      var cancelled = false;
      void listener() {
        if (!cancelled && engine.inspectingCandidates) {
          cancelled = true;
          unawaited(engine.disable());
        }
      }

      engine.addListener(listener);
      await engine.startCandidates(limits: ReviewLimits());
      await tick();
      engine.removeListener(listener);
      expect(engine.candidates!.phase, ReviewPhase.cancelled);
      expect(fake.requests, isEmpty);
    },
  );
  test(
    'a failed stop barrier rejects trial and preserves the original game',
    () async {
      final job = engine.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      await finish('h9g7');
      fake.failStop = true;
      expect(
        await engine.tryCandidate(engine.candidates!, Move.parse('h9g7')),
        isFalse,
      );
      await job;
      expect(session.tree.cursorId, 'n2');
      expect(session.tree.nodeCount, 3);
      expect(engine.candidates!.phase, ReviewPhase.failed);
    },
  );
  test(
    'a factory failure after cancellation does not poison the next retry',
    () async {
      final opening = Completer<EngineGateway>();
      var calls = 0;
      final coordinator = EngineSessionController(session, () {
        calls++;
        return calls == 1 ? opening.future : Future.value(fake);
      });
      addTearDown(coordinator.dispose);
      final first = coordinator.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      await coordinator.disable();
      opening.completeError(StateError('late launch failure'));
      await first;
      final second = coordinator.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      await finish('b9c7');
      await finish('h9g7');
      await second;
      expect(calls, 2);
      expect(coordinator.candidates!.phase, ReviewPhase.completed);
    },
  );
  test(
    'no bestmove completes without invented zero and keeps the actual reason',
    () async {
      final job = engine.startCandidates(
        limits: ReviewLimits(depth: 3),
        maximum: 2,
      );
      await tick();
      fake.results.last.complete(null);
      await job;
      expect(engine.candidates!.phase, ReviewPhase.completed);
      expect(engine.candidates!.results, isEmpty);
      expect(engine.candidates!.notice, '引擎未返回更多可评估着法');
    },
  );
  final executable = Platform.environment['PIKAFISH_EXECUTABLE'];
  test(
    'real NNUE computes unique parent candidates and trials a different sibling',
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
          .startCandidates(
            limits: ReviewLimits(depth: 4, moveTimeMs: 1000),
            maximum: 2,
          )
          .timeout(const Duration(seconds: 30));
      final run = coordinator.candidates!;
      expect(run.phase, ReviewPhase.completed);
      expect(run.results.length, 2);
      expect(run.results.map((r) => r.move).toSet().length, 2);
      expect(
        run.results.every(
          (r) => run.position.legalMoves.contains(r.move) && r.info != null,
        ),
        isTrue,
      );
      final alternative = run.results.firstWhere(
        (r) => r.move != session.tree.current.move,
      );
      expect(await coordinator.tryCandidate(run, alternative.move), isTrue);
      expect(session.tree.node('n1').children.length, 2);
      expect(session.tree.hasNode('n2'), isTrue);
    },
    skip: executable == null
        ? 'Set PIKAFISH_EXECUTABLE for actual NNUE'
        : false,
  );
}
