import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'support/capacity_tree.dart';

void main() {
  test(
    'last available node commits; overflow is typed, atomic and still serializable',
    () {
      final source = capacityTree(nodes: GameTree.maxNodes - 1);
      final move = source.current.position.legalMoves.first;
      final full = source.play(move);
      expect(full.nodeCount, GameTree.maxNodes);
      final json = full.toJson();
      expect(
        () => full.play(full.current.position.legalMoves.first),
        throwsA(isA<GameTreeCapacityException>()),
      );
      expect(full.toJson(), json);
      final restored = GameTree.fromJson(json);
      expect(restored.nodeCount, GameTree.maxNodes);
      expect(restored.current.position.toFen(), full.current.position.toFen());
      // Capacity does not replace ordinary legality errors.
      expect(() => full.play(Move.parse('a0a0')), throwsArgumentError);
      expect(source.nodeCount, GameTree.maxNodes - 1);
    },
  );
  test(
    'full tree can reuse, annotate and prune; freed space uses a fresh ID',
    () {
      final full = capacityTree();
      final root = full.goTo('n0');
      final old = root.node(root.current.children.first);
      final reused = root.play(old.move!);
      expect(reused.nodeCount, GameTree.maxNodes);
      expect(reused.cursorId, old.id);
      expect(reused.annotate('完整谱仍可评注').current.comment, '完整谱仍可评注');
      final leaf = full.current;
      final pruned = full.deleteBranch(leaf.id);
      expect(pruned.nodeCount, GameTree.maxNodes - 1);
      final replacement = pruned.play(leaf.move!);
      expect(replacement.nodeCount, GameTree.maxNodes);
      expect(replacement.current.id, 'n${GameTree.maxNodes}');
      expect(replacement.hasNode(leaf.id), isFalse);
      expect(
        GameTree.fromJson(replacement.toJson()).cursorId,
        replacement.cursorId,
      );
    },
  );
}
