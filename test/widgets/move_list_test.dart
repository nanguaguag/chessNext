import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/features/records/move_list.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget shell(BoardSession session) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 326,
        child: MoveList(session: session, onNavigate: session.navigate),
      ),
    ),
  ),
);
void main() {
  testWidgets(
    'future moves remain clickable on the selected variation after undo',
    (tester) async {
      final session = BoardSession();
      addTearDown(session.dispose);
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      session.first();
      session.playMove(Move.parse('b2e2'));
      session.playMove(Move.parse('h9g7'));
      session.first();
      final revision = session.revision;
      await tester.pumpWidget(shell(session));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('move-n3')), findsOneWidget);
      expect(find.byKey(const ValueKey('move-n1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('move-n4')));
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n4');
      expect(session.revision, revision);
      session.undo();
      session.undo();
      await tester.pumpAndSettle();
      session.forward();
      expect(session.tree.cursorId, 'n3');
      session.last();
      expect(session.tree.cursorId, 'n4');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'a thousand-ply record builds a bounded viewport and reveals the cursor',
    (tester) async {
      final session = BoardSession();
      addTearDown(session.dispose);
      var tree = GameTree();
      final cycle = ['b0c2', 'h9g7', 'c2b0', 'g7h9'].map(Move.parse).toList();
      for (var i = 0; i < 1000; i++) {
        tree = tree.play(cycle[i % 4]);
      }
      session.replaceTree(tree);
      await tester.pumpWidget(shell(session));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile).evaluate().length, lessThan(30));
      expect(find.byKey(const ValueKey('move-n1000')), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('move-n1000')))
            .selected,
        isTrue,
      );
      expect(find.byKey(const ValueKey('move-n1')), findsNothing);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('move-n1000')), findsOneWidget);
      expect(tester.takeException(), isNull);
      session.first();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('move-n0')), findsOneWidget);
      expect(find.byType(ListTile).evaluate().length, lessThan(30));
      expect(session.tree.currentLine.length, 1001);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
