import 'package:xiangqi_core/xiangqi_core.dart';

GameTree nestedBranches() {
  var tree = GameTree();
  for (final move in ['h2e2', 'b9c7', 'b0c2', 'h9g7', 'a0a1', 'i9i8', 'a1a2']) {
    tree = tree.play(Move.parse(move));
  }
  tree = tree.goTo('n4').play(Move.parse('g3g4')); // n8
  tree = tree.goTo('n2').play(Move.parse('h0g2')); // n9
  tree = tree.goTo('n0').play(Move.parse('c3c4')); // n10
  return tree.goTo('n7');
}
