import 'dart:async';
import 'package:chess_next/application/analysis_history.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/pv_prefix_action.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/branched_record.dart';

class GatedPvEngine extends FakeEngine {
  Completer<void>? barrier;
  bool fail = false;
  @override
  Future<void> stop() async {
    await barrier?.future;
    if (fail) throw StateError('stop failed');
    await super.stop();
  }
}

PvHistoryEntry forSession(BoardSession session, List<Move> moves) {
  final history = AnalysisHistory();
  history.add(
    position: session.position,
    epoch: session.epoch,
    nodeId: session.tree.cursorId,
    revision: session.revision,
    positionRevision: session.positionRevision,
    info: EngineInfo(
      token: 1,
      depth: 12,
      multiPv: 1,
      score: 0,
      isMate: false,
      pv: moves,
    ),
  );
  return history.entries.single;
}

void main() {
  final rootMoves = 'h2e2 b9c7 b0c2 h9g7'.split(' ').map(Move.parse).toList();
  test(
    'worker continuation preserves all previous branches and comments and publishes exactly once',
    () async {
      var source = branchedRecord()
          .play(Move.parse('h9g7'))
          .play(Move.parse('h0g2'))
          .annotate('原未来评注');
      final futureId = source.cursorId;
      source = source.goTo('n5');
      final original = source.toJson();
      final result = await PvPrefixPlan.prepareInWorker(source, [
        Move.parse('b7a7'),
        Move.parse('b0c2'),
      ]);
      expect(result.error, isNull);
      final session = BoardSession();
      try {
        session.replaceTree(source, metadata: GameMetadata({'Event': '保持资料'}));
        var notifications = 0;
        session.addListener(() => notifications++);
        final revision = session.revision,
            positionRevision = session.positionRevision,
            epoch = session.epoch;
        expect(session.commitContinuation(source, result.tree!), isTrue);
        expect(notifications, 1);
        expect(session.revision, revision + 1);
        expect(session.positionRevision, positionRevision + 1);
        expect(session.epoch, epoch);
        expect(session.dirty, isTrue);
        expect(session.tree.nodeCount, source.nodeCount + 2);
        expect(session.tree.node(futureId).comment, '原未来评注');
        expect(
          session.tree.node('n5').children.first,
          source.node('n5').children.first,
        );
        expect(session.tree.node('n2').children, source.node('n2').children);
        expect(session.metadata.tags['Event'], '保持资料');
        expect(source.toJson(), original);
        expect(session.commitContinuation(source, result.tree!), isFalse);
      } finally {
        session.dispose();
      }
    },
  );
  test(
    'illegal suffix, 2000-node capacity and existing-prefix reuse never publish a partial tree',
    () async {
      final source = GameTree();
      final invalid = await PvPrefixPlan.prepareInWorker(source, [
        Move.parse('h2e2'),
        Move.parse('h2h3'),
      ]);
      expect(invalid.tree, isNull);
      expect(invalid.error, PvApplyResult.invalid);
      expect(source.nodeCount, 1);
      final cycle = 'b0c2 b9c7 c2b0 c7b9'.split(' ').map(Move.parse).toList();
      var large = GameTree();
      for (var i = 0; i < 1998; i++) {
        large = large.play(cycle[i % 4]);
      }
      expect(large.nodeCount, 1999);
      final atLimit = await PvPrefixPlan.prepareInWorker(large, [cycle[2]]);
      expect(atLimit.tree!.nodeCount, 2000);
      final overflow = await PvPrefixPlan.prepareInWorker(large, [
        cycle[2],
        cycle[3],
      ]);
      expect(overflow.error, PvApplyResult.capacity);
      expect(overflow.tree, isNull);
      expect(large.nodeCount, 1999);
      final existing = await PvPrefixPlan.prepareInWorker(
        atLimit.tree!.goTo('n0'),
        cycle,
      );
      expect(existing.error, isNull);
      expect(existing.tree!.nodeCount, 2000);
      expect(existing.tree!.cursorId, 'n4');
    },
  );
  test(
    'freshly reopened source history reuses existing nodes without making a clean document dirty',
    () async {
      final session = BoardSession();
      final controller = EngineSessionController(session, null);
      try {
        final entry = forSession(session, rootMoves);
        final first = controller.createPvPrefixAction(entry);
        expect(
          await first.apply(0, PvApplyCancellation()),
          PvApplyResult.invalid,
        );
        expect(
          await first.apply(5, PvApplyCancellation()),
          PvApplyResult.invalid,
        );
        expect(
          await first.apply(2, PvApplyCancellation()),
          PvApplyResult.applied,
        );
        expect(session.moves, rootMoves.take(2));
        expect(controller.enabled, isFalse);
        final endpoint = session.tree.cursorId, count = session.tree.nodeCount;
        session.first();
        session.updateMetadata(GameMetadata({'Event': '新资料'}));
        session.markSaved(session.revision);
        final revision = session.revision;
        final reopened = controller.createPvPrefixAction(entry);
        expect(reopened.isCurrent, isTrue);
        expect(
          await reopened.apply(2, PvApplyCancellation()),
          PvApplyResult.applied,
        );
        expect(session.tree.cursorId, endpoint);
        expect(session.tree.nodeCount, count);
        expect(session.revision, revision);
        expect(session.dirty, isFalse);
        expect(session.metadata.tags['Event'], '新资料');
        expect(first.isCurrent, isFalse);
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );
  test(
    'cancel and duplicate action during stop barrier cannot partially apply',
    () async {
      final session = BoardSession(), fake = GatedPvEngine();
      final controller = EngineSessionController(
        session,
        () => Future.value(fake),
      );
      try {
        await controller.enable();
        final tree = session.tree;
        final action = controller.createPvPrefixAction(
          forSession(session, rootMoves),
        );
        final cancellation = PvApplyCancellation();
        fake.barrier = Completer<void>();
        final pending = action.apply(2, cancellation);
        expect(
          await action.apply(2, PvApplyCancellation()),
          PvApplyResult.busy,
        );
        cancellation.cancel();
        fake.barrier!.complete();
        expect(await pending, PvApplyResult.cancelled);
        expect(session.tree, same(tree));
        expect(session.dirty, isFalse);
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );
  test(
    'document, cursor and metadata changes while stop is pending reject the old intent',
    () async {
      for (final change in ['document', 'cursor', 'metadata']) {
        final session = BoardSession(), fake = GatedPvEngine();
        final controller = EngineSessionController(
          session,
          () => Future.value(fake),
        );
        try {
          await controller.enable();
          final action = controller.createPvPrefixAction(
            forSession(session, rootMoves),
          );
          fake.barrier = Completer<void>();
          final pending = action.apply(2, PvApplyCancellation());
          switch (change) {
            case 'document':
              session.newGame();
            case 'cursor':
              session.playMove(rootMoves.first);
            case 'metadata':
              session.updateMetadata(GameMetadata({'Event': '迟到保护'}));
          }
          final tree = session.tree, revision = session.revision;
          fake.barrier!.complete();
          expect(await pending, PvApplyResult.stale);
          expect(session.tree, same(tree));
          expect(session.revision, revision);
        } finally {
          controller.dispose();
          session.dispose();
        }
      }
    },
  );
  test('failed engine stop leaves the current document untouched', () async {
    final session = BoardSession(), fake = GatedPvEngine();
    final controller = EngineSessionController(
      session,
      () => Future.value(fake),
    );
    try {
      await controller.enable();
      final tree = session.tree;
      final action = controller.createPvPrefixAction(
        forSession(session, rootMoves),
      );
      fake.fail = true;
      expect(
        await action.apply(2, PvApplyCancellation()),
        PvApplyResult.stopFailed,
      );
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      expect(controller.error, isNotNull);
    } finally {
      controller.dispose();
      session.dispose();
    }
  });
  test(
    'a new analysis intent during the stop barrier wins over a previous apply',
    () async {
      final session = BoardSession(), fake = GatedPvEngine();
      final controller = EngineSessionController(
        session,
        () => Future.value(fake),
      );
      try {
        await controller.enable();
        final tree = session.tree;
        final action = controller.createPvPrefixAction(
          forSession(session, rootMoves),
        );
        fake.barrier = Completer<void>();
        final pending = action.apply(2, PvApplyCancellation());
        final restarting = controller.enable();
        fake.barrier!.complete();
        expect(await pending, PvApplyResult.stale);
        await restarting;
        expect(controller.enabled, isTrue);
        expect(session.tree, same(tree));
      } finally {
        controller.dispose();
        session.dispose();
      }
    },
  );
  test(
    'cancellation and source changes during worker preparation never publish a late tree',
    () async {
      for (final variant in ['cancel', 'metadata']) {
        final session = BoardSession();
        final engine = EngineSessionController(session, null);
        final started = Completer<void>(),
            gate = Completer<({GameTree? tree, PvApplyResult? error})>();
        try {
          final source = session.tree,
              entry = forSession(session, rootMoves),
              cancel = PvApplyCancellation();
          final action = engine.createPvPrefixAction(
            entry,
            planner: (tree, moves) {
              started.complete();
              return gate.future;
            },
          );
          final pending = action.apply(2, cancel);
          await started.future;
          if (variant == 'cancel') {
            cancel.cancel();
          } else {
            session.updateMetadata(GameMetadata({'Event': '准备中已变'}));
          }
          final revision = session.revision;
          gate.complete(
            await PvPrefixPlan.prepareInWorker(
              source,
              rootMoves.take(2).toList(),
            ),
          );
          expect(
            await pending,
            variant == 'cancel' ? PvApplyResult.cancelled : PvApplyResult.stale,
          );
          expect(session.tree, same(source));
          expect(session.revision, revision);
        } finally {
          engine.dispose();
          session.dispose();
        }
      }
    },
  );
}
