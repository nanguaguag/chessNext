import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/reading_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/branch_tree.dart';

void main() {
  test('empty and unbranched lines have strict endpoint fallbacks', () {
    var tree = GameTree();
    expect(ReadingNavigation(tree).previousBranchId, isNull);
    expect(ReadingNavigation(tree).nextBranchId, isNull);
    for (final step in ['h2e2', 'b9c7', 'b0c2', 'h9g7']) {
      tree = tree.play(Move.parse(step));
    }
    expect(ReadingNavigation(tree).previousBranchId, 'n0');
    expect(ReadingNavigation(tree).nextBranchId, isNull);
    expect(ReadingNavigation(tree.goTo('n2')).previousBranchId, 'n0');
    expect(ReadingNavigation(tree.goTo('n2')).nextBranchId, 'n4');
    expect(ReadingNavigation(tree.goTo('n0')).nextBranchId, 'n4');
  });
  test('nested and root forks are strict, nearest and never self-loop', () {
    final tree = nestedBranches();
    final targets = {
      'n7': ('n4', null),
      'n4': ('n2', 'n7'),
      'n2': ('n0', 'n4'),
      'n0': (null, 'n2'),
      'n1': ('n0', 'n2'),
    };
    for (final entry in targets.entries) {
      final nav = ReadingNavigation(tree.goTo(entry.key));
      expect(nav.previousBranchId, entry.value.$1, reason: entry.key);
      expect(nav.nextBranchId, entry.value.$2, reason: entry.key);
    }
  });
  test(
    'only forks on the selected future line count and branch choice survives going back',
    () {
      final tree = nestedBranches().goTo('n9').goTo('n0');
      expect(tree.currentLine.last.id, 'n9');
      expect(ReadingNavigation(tree).nextBranchId, 'n2');
      final fork = tree.goTo('n2');
      expect(
        ReadingNavigation(fork).nextBranchId,
        'n9',
      ); // n4 is on another branch.
      final nested = nestedBranches().goTo('n8').goTo('n0');
      expect(ReadingNavigation(nested.goTo('n2')).nextBranchId, 'n4');
      expect(ReadingNavigation(nested.goTo('n4')).nextBranchId, 'n8');
    },
  );
  test(
    'deletion and promotion invalidate cached targets without navigation dirtying content',
    () {
      final session = BoardSession();
      addTearDown(session.dispose);
      session.replaceTree(nestedBranches().goTo('n0'));
      expect(session.readingNavigation.nextBranchId, 'n2');
      session.deleteBranch('n9');
      expect(session.readingNavigation.nextBranchId, 'n4');
      session.promote('n10');
      expect(
        session.readingNavigation.nextBranchId,
        'n4',
      ); // Existing selected line retained.
      final revision = session.revision;
      final count = session.tree.nodeCount;
      session.navigate(session.readingNavigation.nextBranchId!);
      expect(session.tree.cursorId, 'n4');
      expect(session.revision, revision);
      expect(session.tree.nodeCount, count);
      session.navigate('n10');
      expect(session.readingNavigation.previousBranchId, 'n0');
      expect(session.readingNavigation.nextBranchId, isNull);
    },
  );
  test(
    'long lines are scanned iteratively and get the exact selected endpoint',
    () {
      var tree = GameTree();
      final cycle = ['b0c2', 'h9g7', 'c2b0', 'g7h9'].map(Move.parse).toList();
      for (var i = 0; i < 1000; i++) {
        tree = tree.play(cycle[i % 4]);
      }
      final nav = ReadingNavigation(tree.goTo('n500'));
      expect(nav.previousBranchId, 'n0');
      expect(nav.nextBranchId, 'n1000');
    },
  );
}
