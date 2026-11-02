import 'package:xiangqi_core/xiangqi_core.dart';

/// Legal, shallow, deterministic document; avoids engine repetition shortcuts.
GameTree capacityTree({int nodes = GameTree.maxNodes}) {
  if (nodes < 1 || nodes > GameTree.maxNodes)
    throw ArgumentError('fixture size');
  var tree = GameTree();
  final queue = ['n0'];
  for (var index = 0; tree.nodeCount < nodes; index++) {
    final parent = queue[index];
    final moves = tree.node(parent).position.legalMoves.toList();
    // Keep one legal root alternative absent for bounded trial/AI tests.
    if (parent == 'n0') moves.removeLast();
    for (final move in moves) {
      tree = tree.goTo(parent).play(move);
      queue.add(tree.cursorId);
      if (tree.nodeCount == nodes) return tree;
    }
  }
  return tree;
}
