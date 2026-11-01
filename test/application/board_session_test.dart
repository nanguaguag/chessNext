import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/chess_next.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection, legal targets, illegal move, undo and reset', () {
    final s = BoardSession();
    addTearDown(s.dispose);
    s.tap(Square.parse('h2'));
    expect(s.targets, contains(Square.parse('e2')));
    s.tap(Square.parse('g4'));
    expect(s.notice, isNotNull);
    expect(s.canUndo, isFalse);
    s.tap(Square.parse('e2'));
    expect(s.moves.single.toString(), 'h2e2');
    expect(s.position.turn, Side.black);
    s.undo();
    expect(s.position.toFen(), Position.initialFen);
    expect(s.moves, isEmpty);
    s.tap(Square.parse('h2'));
    s.cancelSelection();
    expect(s.selected, isNull);
    s.tap(Square.parse('h2'));
    s.tap(Square.parse('e2'));
    s.newGame();
    expect(s.canUndo, isFalse);
    expect(s.position.toFen(), Position.initialFen);
  });
  test('flip changes display only and terminal boards reject moves', () {
    final s = BoardSession(
      initial: Position.fromFen('4k4/9/9/9/4p4/9/9/9/3r1r3/4K4 w - - 0 1'),
    );
    addTearDown(s.dispose);
    final before = s.position.toFen();
    s.flip();
    s.tap(Square.parse('e0'));
    expect(s.flipped, isTrue);
    expect(s.selected, isNull);
    expect(s.position.toFen(), before);
    expect(s.status, '黑方获胜 · 困毙');
  });
  test('navigation preserves variations, comments and revision semantics', () {
    final s = BoardSession();
    addTearDown(s.dispose);
    s.tap(Square.parse('h2'));
    s.tap(Square.parse('e2'));
    s.annotate('中炮');
    final revision = s.revision;
    s.first();
    expect(s.hasContent, isTrue);
    expect(s.revision, revision);
    s.forward();
    expect(s.tree.current.comment, '中炮');
    s.first();
    s.tap(Square.parse('c3'));
    s.tap(Square.parse('c4'));
    expect(s.tree.root.children.length, 2);
    final variant = s.tree.cursorId;
    s.promote(variant);
    s.first();
    s.forward();
    expect(s.tree.cursorId, variant);
    s.deleteBranch(variant);
    expect(s.tree.cursorId, 'n0');
    s.forward();
    expect(s.tree.current.comment, '中炮');
    expect(() => s.moves.clear(), throwsUnsupportedError);
  });
}
