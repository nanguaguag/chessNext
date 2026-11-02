import 'package:xiangqi_core/xiangqi_core.dart';

class VariationArrow {
  const VariationArrow({
    required this.nodeId,
    required this.move,
    required this.number,
    required this.selected,
    required this.notation,
  });
  final String nodeId, notation;
  final Move move;
  final int number;
  final bool selected;
}

class CurrentMoveArrows {
  CurrentMoveArrows._(Iterable<VariationArrow> arrows, this.total)
    : visible = List.unmodifiable(arrows);
  static const maxVisible = 64;
  final List<VariationArrow> visible;
  final int total;
  bool get truncated => total > visible.length;
  factory CurrentMoveArrows.fromTree(GameTree tree) {
    final parentId = tree.current.parentId;
    if (parentId == null) return CurrentMoveArrows._([], 0);
    final parent = tree.node(parentId);
    final selected = parent.children.indexOf(tree.cursorId);
    final indices = [
      for (var i = 0; i < parent.children.length && i < maxVisible; i++) i,
    ];
    if (selected >= maxVisible) indices[maxVisible - 1] = selected;
    return CurrentMoveArrows._(
      indices.map((index) {
        final node = tree.node(parent.children[index]);
        return VariationArrow(
          nodeId: node.id,
          move: node.move!,
          number: index + 1,
          selected: node.id == tree.cursorId,
          notation: ChineseNotation.format(parent.position, node.move!),
        );
      }),
      parent.children.length,
    );
  }
}
