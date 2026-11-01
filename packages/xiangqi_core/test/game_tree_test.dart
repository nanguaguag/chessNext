import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test('old snapshots and stable IDs survive sibling branches and replay', () {
    final root = GameTree();
    final first = root.play(Move.parse('h2e2')).annotate('中炮');
    final variant = first.goTo('n0').play(Move.parse('c3c4'));
    expect(root.nodeCount, 1);
    expect(first.current.comment, '中炮');
    expect(variant.root.children, ['n1', 'n2']);
    expect(variant.goTo('n0').play(Move.parse('h2e2')).cursorId, 'n1');
    expect(variant.nodeCount, 3);
    expect(variant.path.map((n) => n.id), ['n0', 'n2']);
    expect(() => variant.root.children.clear(), throwsUnsupportedError);
  });
  test(
    'promotion changes the mainline without changing cursor or positions',
    () {
      final tree = GameTree()
          .play(Move.parse('h2e2'))
          .goTo('n0')
          .play(Move.parse('c3c4'));
      final promoted = tree.promote('n2');
      expect(promoted.root.children, ['n2', 'n1']);
      expect(identical(promoted.promote('n2'), promoted), isTrue);
      expect(promoted.cursorId, tree.cursorId);
      expect(promoted.current.position.toFen(), tree.current.position.toFen());
      expect(tree.root.children, ['n1', 'n2']);
    },
  );
  test(
    'deletion removes descendants, restores cursor and never reuses IDs',
    () {
      final tree = GameTree().play(Move.parse('h2e2')).play(Move.parse('b9c7'));
      final pruned = tree.deleteBranch('n1');
      expect(pruned.cursorId, 'n0');
      expect(pruned.nodeCount, 1);
      expect(pruned.play(Move.parse('h2e2')).cursorId, 'n3');
      expect(() => pruned.node('n2'), throwsArgumentError);
      expect(() => pruned.deleteBranch('n0'), throwsArgumentError);
    },
  );
  test(
    'invalid navigation, illegal moves and oversize comments fail atomically',
    () {
      final tree = GameTree();
      expect(() => tree.goTo('missing'), throwsArgumentError);
      expect(() => tree.play(Move.parse('a9a8')), throwsArgumentError);
      expect(() => tree.annotate('x' * 10001), throwsArgumentError);
      expect(tree.nodeCount, 1);
      expect(tree.current.comment, isEmpty);
    },
  );
}
