import 'package:xiangqi_core/xiangqi_core.dart';

GameTree branchedRecord() {
  var tree = GameTree();
  for (final move in ['b2e2', 'b9c7', 'b0c2', 'h9g7']) {
    tree = tree.play(Move.parse(move));
  }
  return tree.goTo('n2').play(Move.parse('h2h4'));
}
