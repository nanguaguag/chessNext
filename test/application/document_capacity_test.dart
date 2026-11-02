import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../packages/xiangqi_core/test/support/capacity_tree.dart';
import '../support/fake_engine.dart';

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 10));
void main() {
  test(
    'manual, direct engine and sibling additions reject with one notice and no document mutation',
    () {
      final session = BoardSession();
      try {
        session.replaceTree(
          capacityTree(),
          metadata: GameMetadata({'Event': '容量自制'}),
        );
        final tree = session.tree,
            revision = session.revision,
            position = session.positionRevision,
            epoch = session.epoch,
            metadata = session.metadata;
        final move = session.legalMoves.first;
        session.tap(move.from);
        var notifications = 0;
        session.addListener(() => notifications++);
        session.tap(move.to);
        expect(notifications, 1);
        expect(session.selected, move.from);
        expect(session.moveRejection, MoveRejection.capacity);
        expect(session.notice, BoardSession.capacityNotice);
        expect(session.tree, same(tree));
        expect(session.metadata, same(metadata));
        expect(session.revision, revision);
        expect(session.positionRevision, position);
        expect(session.epoch, epoch);
        expect(session.dirty, isFalse);
        expect(session.playMove(move, fromEngine: true), isFalse);
        expect(session.tree, same(tree));
        expect(session.moveRejection, MoveRejection.capacity);
        final source = 'n0';
        final parent = tree.node(source);
        final alternative = parent.position.legalMoves.firstWhere(
          (m) => !parent.children.any((id) => tree.node(id).move == m),
        );
        expect(session.playVariation(source, alternative), isFalse);
        expect(session.moveRejection, MoveRejection.capacity);
        expect(session.tree, same(tree));
        final existing = tree.node(tree.root.children.first);
        expect(session.playVariation('n0', existing.move!), isTrue);
        expect(session.tree.nodeCount, GameTree.maxNodes);
        expect(session.revision, revision);
        expect(session.dirty, isFalse);
        session.navigate(tree.current.id);
        final removed = session.tree.current;
        session.deleteBranch(removed.id);
        expect(session.dirty, isTrue);
        expect(session.playMove(removed.move!), isTrue);
        expect(session.tree.nodeCount, GameTree.maxNodes);
        expect(session.tree.current.id, 'n${GameTree.maxNodes}');
        expect(session.moveRejection, isNull);
        expect(
          GameTree.fromJson(session.tree.toJson()).nodeCount,
          GameTree.maxNodes,
        );
      } finally {
        session.dispose();
      }
    },
  );
  test(
    'capacity pauses AI, unlocks and keeps the same engine usable without a retry loop',
    () async {
      final session = BoardSession()..replaceTree(capacityTree());
      final fake = FakeEngine();
      var opens = 0;
      final engine = EngineSessionController(session, () async {
        opens++;
        return fake;
      });
      try {
        final tree = session.tree;
        await engine.setAiSide(session.position.turn, true);
        await tick();
        final move = fake.requests.last.position.legalMoves.first;
        fake.results.last.complete(move);
        await tick();
        expect(session.tree, same(tree));
        expect(engine.playing, isFalse);
        expect(session.inputLocked, isFalse);
        expect(engine.error, isNull);
        expect(engine.status, '棋谱容量已满，自动对弈已暂停');
        expect(session.moveRejection, MoveRejection.capacity);
        expect(fake.phase.toString(), isNot(contains('closed')));
        final count = fake.requests.length;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(fake.requests.length, count);
        await engine.enable();
        await tick();
        expect(opens, 1);
        expect(fake.requests.length, count + 1);
        expect(engine.enabled, isTrue);
        await engine.disable();
      } finally {
        engine.dispose();
        session.dispose();
      }
    },
  );
  test(
    'candidate capacity is typed and leaves completed results available',
    () async {
      final session = BoardSession()..replaceTree(capacityTree());
      // The fixture reserves one unrecorded legal root move.
      session.first();
      final parent = session.tree.current;
      final existing = session.tree.node(parent.children.first);
      session.navigate(existing.id);
      final fake = FakeEngine();
      final coordinator = EngineSessionController(session, () async => fake);
      try {
        final source = session.tree;
        final job = coordinator.startCandidates(
          limits: ReviewLimits(depth: 2),
          maximum: 2,
        );
        var handled = 0;
        for (
          var i = 0;
          i < 100 && coordinator.candidates?.phase != ReviewPhase.completed;
          i++
        ) {
          if (fake.requests.length > handled) {
            handled = fake.requests.length;
            final request = fake.requests.last;
            final allowed =
                request.searchMoves ?? request.position.legalMoves.toList();
            final alternate = allowed.firstWhere(
              (m) => !parent.children.any((id) => source.node(id).move == m),
              orElse: () => allowed.first,
            );
            fake.emit(request.token, pv: alternate.toString());
            await tick();
            fake.results.last.complete(alternate);
          }
          await tick();
        }
        await job;
        final run = coordinator.candidates!;
        final extra = run.results.firstWhere(
          (r) => !parent.children.any((id) => source.node(id).move == r.move),
        );
        expect(
          await coordinator.applyCandidate(run, extra.move),
          CandidateApplyResult.capacity,
        );
        expect(session.tree, same(source));
        expect(coordinator.candidates, same(run));
        expect(session.dirty, isFalse);
        expect(coordinator.error, isNull);
        expect(await coordinator.tryCandidate(run, extra.move), isFalse);
      } finally {
        coordinator.dispose();
        session.dispose();
      }
    },
  );
}
