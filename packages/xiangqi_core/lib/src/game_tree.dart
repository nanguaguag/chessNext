import 'position.dart';
import 'validation.dart';

final class GameNode {
  GameNode._({
    required this.id,
    required this.position,
    this.parentId,
    this.move,
    this.comment = '',
    Iterable<String> children = const [],
  }) : children = List.unmodifiable(children);
  final String id;
  final String? parentId;
  final Move? move;
  final Position position;
  final String comment;

  /// The first child is the main continuation; remaining children are variants.
  final List<String> children;
  GameNode _copy({String? comment, Iterable<String>? children}) => GameNode._(
    id: id,
    position: position,
    parentId: parentId,
    move: move,
    comment: comment ?? this.comment,
    children: children ?? this.children,
  );
}

/// Immutable variation tree with stable document-local node IDs and a cursor.
final class GameTree {
  GameTree._(Map<String, GameNode> nodes, this.cursorId, this._nextId)
    : _nodes = Map.unmodifiable(nodes);
  factory GameTree({Position? initial}) {
    final position = initial ?? Position.initial();
    if (!position.validateForPlay().isValid)
      throw ArgumentError('Invalid root position');
    return GameTree._(
      {'n0': GameNode._(id: 'n0', position: position)},
      'n0',
      1,
    );
  }
  final Map<String, GameNode> _nodes;
  final String cursorId;
  final int _nextId;
  GameNode get root => _nodes['n0']!;
  GameNode get current => _nodes[cursorId]!;
  int get nodeCount => _nodes.length;
  GameNode node(String id) =>
      _nodes[id] ?? (throw ArgumentError.value(id, 'id', 'Unknown node'));
  List<GameNode> get path {
    final result = <GameNode>[];
    GameNode? entry = current;
    while (entry != null) {
      result.add(entry);
      entry = entry.parentId == null ? null : node(entry.parentId!);
    }
    return List.unmodifiable(result.reversed);
  }

  GameTree goTo(String id) {
    node(id);
    return GameTree._(_nodes, id, _nextId);
  }

  GameTree play(Move move) {
    for (final id in current.children) {
      if (node(id).move == move) return goTo(id);
    }
    final next = current.position.play(move);
    final id = 'n$_nextId';
    return GameTree._(
      {
        ..._nodes,
        current.id: current._copy(children: [...current.children, id]),
        id: GameNode._(
          id: id,
          position: next,
          parentId: current.id,
          move: move,
        ),
      },
      id,
      _nextId + 1,
    );
  }

  GameTree annotate(String comment) {
    if (comment.length > 10000)
      throw ArgumentError('Comment exceeds 10000 characters');
    return GameTree._(
      {..._nodes, current.id: current._copy(comment: comment)},
      cursorId,
      _nextId,
    );
  }

  GameTree promote(String id) {
    final entry = node(id);
    if (entry.parentId == null) return this;
    final parent = node(entry.parentId!);
    return GameTree._(
      {
        ..._nodes,
        parent.id: parent._copy(
          children: [id, ...parent.children.where((child) => child != id)],
        ),
      },
      cursorId,
      _nextId,
    );
  }

  GameTree deleteBranch(String id) {
    final entry = node(id);
    if (entry.parentId == null) throw ArgumentError('Cannot delete the root');
    final removed = <String>{};
    final pending = [id];
    while (pending.isNotEmpty) {
      final next = pending.removeLast();
      removed.add(next);
      pending.addAll(node(next).children);
    }
    final parent = node(entry.parentId!);
    return GameTree._(
      {
        for (final e in _nodes.entries)
          if (!removed.contains(e.key)) e.key: e.value,
        parent.id: parent._copy(
          children: parent.children.where((child) => child != id),
        ),
      },
      removed.contains(cursorId) ? parent.id : cursorId,
      _nextId,
    );
  }
}
