import 'dart:async';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/features/records/variation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

class DelayedStop extends FakeEngine {
  Completer<void>? barrier;
  @override
  Future<void> stop() async {
    await barrier?.future;
    await super.stop();
  }
}

void main() {
  late BoardSession session;
  late EngineSessionController engine;
  late DelayedStop fake;
  setUp(() {
    session = BoardSession();
    session.playMove(Move.parse('h2e2'));
    session.playMove(Move.parse('b9c7'));
    session.first();
    session.playMove(Move.parse('b2e2'));
    fake = DelayedStop();
    engine = EngineSessionController(session, () async => fake);
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  Widget shell() => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 326,
        child: VariationPanel(session: session, engine: engine),
      ),
    ),
  );
  Future<void> action(WidgetTester tester, String id, String label) async {
    await tester.tap(find.byKey(ValueKey('sibling-actions-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'siblings switch without removing future and promote preserves cursor',
    (tester) async {
      await tester.pumpWidget(shell());
      expect(find.text('本步变着（2）'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('sibling-n3')))
            .selected,
        isTrue,
      );
      await action(tester, 'n3', '提升为主线');
      expect(session.tree.root.children.first, 'n3');
      expect(session.tree.cursorId, 'n3');
      final revision = session.revision;
      session.promote('n3');
      expect(session.revision, revision);
      await tester.tap(find.byKey(const ValueKey('sibling-n1')));
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n1');
      expect(find.text('继续 马２进３'), findsOneWidget);
      expect(session.tree.currentLine.last.id, 'n2');
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'delete cancellation preserves document, confirmation removes subtree',
    (tester) async {
      await tester.pumpWidget(shell());
      final revision = session.revision;
      await action(tester, 'n1', '删除变着');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(session.revision, revision);
      await action(tester, 'n1', '删除变着');
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(session.tree.hasNode('n1'), isFalse);
      expect(session.tree.hasNode('n2'), isFalse);
      expect(session.tree.cursorId, 'n3');
      await action(tester, 'n3', '删除变着');
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n0');
      expect(session.tree.nodeCount, 1);
    },
  );
  testWidgets(
    'confirmation cannot delete a later document with reused node ids',
    (tester) async {
      await tester.pumpWidget(shell());
      await action(tester, 'n1', '删除变着');
      session.newGame();
      session.playMove(Move.parse('h2e2'));
      await tester.pump();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(session.tree.hasNode('n1'), isTrue);
      expect(find.text('棋谱已变化，本次未删除，请重新选择。'), findsOneWidget);
    },
  );
  test('confirmed deletion pauses AI and ignores its late move', () async {
    await engine.setAiSide(Side.black, true);
    final result = fake.results.last;
    fake.stopMove = Move.parse('b9c7');
    expect(
      await engine.deleteConfirmedBranch(
        'n3',
        epoch: session.epoch,
        revision: session.revision,
      ),
      isTrue,
    );
    await Future<void>.delayed(Duration.zero);
    expect(result.isCompleted, isTrue);
    expect(engine.playing, isFalse);
    expect(session.tree.cursorId, 'n0');
    expect(session.tree.hasNode('n3'), isFalse);
  });
  test('an edit while stopping invalidates destructive intent', () async {
    await engine.setAiSide(Side.black, true);
    fake.barrier = Completer<void>();
    final deletion = engine.deleteConfirmedBranch(
      'n3',
      epoch: session.epoch,
      revision: session.revision,
    );
    session.annotate('保留这条分支');
    fake.barrier!.complete();
    expect(await deletion, isFalse);
    expect(session.tree.hasNode('n3'), isTrue);
  });
}
