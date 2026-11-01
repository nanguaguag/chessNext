import 'package:xiangqi_core/xiangqi_core.dart';

/// Strictly previous/next fork on the selected reading line, with endpoint fallback.
/// Sibling branches outside the selected line never become forward targets.
class ReadingNavigation {
  ReadingNavigation(GameTree tree) {
    String? previous, next;
    var ancestor = tree.current.parentId;
    while (ancestor != null) {
      final node = tree.node(ancestor);
      if (node.children.length > 1 || node.parentId == null) {
        previous = node.id;
        break;
      }
      ancestor = node.parentId;
    }
    final line = tree.currentLine;
    final cursor = line.indexWhere((node) => node.id == tree.cursorId);
    for (var i = cursor + 1; i < line.length; i++) {
      final node = line[i];
      if (node.children.length > 1 || i == line.length - 1) {
        next = node.id;
        break;
      }
    }
    previousBranchId = previous;
    nextBranchId = next;
  }
  late final String? previousBranchId;
  late final String? nextBranchId;
}
