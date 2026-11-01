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
  Map<String, Object?> toJson() => {
    'schema': 1,
    'rootFen': root.position.toFen(),
    'cursor': cursorId,
    'nextId': _nextId,
    'nodes': [
      for (final node
          in (_nodes.values.toList()..sort((a, b) => a.id.compareTo(b.id))))
        {
          'id': node.id,
          'parent': node.parentId,
          'move': node.move?.toString(),
          'comment': node.comment,
          'children': node.children,
        },
    ],
  };
  factory GameTree.fromJson(Map<String, dynamic> json) {
    try {
      if (json['schema'] != 1 ||
          json['rootFen'] is! String ||
          json['nodes'] is! List ||
          json['cursor'] is! String ||
          json['nextId'] is! int) {
        throw const FormatException('Unsupported or incomplete game schema');
      }
      final rawNodes = json['nodes'] as List;
      if (rawNodes.isEmpty || rawNodes.length > 2000)
        throw const FormatException('Node limit exceeded');
      final raw = <String, Map<String, dynamic>>{};
      var maxId = 0;
      for (final value in rawNodes) {
        if (value is! Map<String, dynamic> ||
            value['id'] is! String ||
            !RegExp(r'^n[0-9]{1,9}$').hasMatch(value['id'] as String) ||
            value['comment'] is! String ||
            (value['comment'] as String).length > 10000 ||
            value['children'] is! List ||
            (value['children'] as List).any((e) => e is! String)) {
          throw const FormatException('Malformed node');
        }
        final id = value['id'] as String;
        if (raw.containsKey(id))
          throw const FormatException('Duplicate node ID');
        raw[id] = value;
        final number = int.parse(id.substring(1));
        if (number > maxId) maxId = number;
      }
      if (!raw.containsKey('n0') ||
          raw['n0']!['parent'] != null ||
          raw['n0']!['move'] != null ||
          (json['nextId'] as int) <= maxId ||
          !raw.containsKey(json['cursor'])) {
        throw const FormatException('Invalid tree root/cursor/sequence');
      }
      final initial = Position.fromFen(json['rootFen'] as String);
      if (!initial.validateForPlay().isValid)
        throw const FormatException('Invalid root setup');
      final nodes = <String, GameNode>{};
      final pending = <(String, Position)>[('n0', initial)];
      var cursor = 0;
      while (cursor < pending.length) {
        final (id, position) = pending[cursor++];
        if (nodes.containsKey(id))
          throw const FormatException('Cycle or repeated child');
        final data = raw[id];
        if (data == null) throw const FormatException('Missing child');
        final children = List<String>.from(data['children'] as List);
        nodes[id] = GameNode._(
          id: id,
          parentId: data['parent'] as String?,
          move: data['move'] == null
              ? null
              : Move.parse(data['move'] as String),
          position: position,
          comment: data['comment'] as String,
          children: children,
        );
        if (pending.length + children.length > raw.length)
          throw const FormatException('Tree is not acyclic');
        for (final child in children) {
          final entry = raw[child];
          if (entry == null ||
              entry['parent'] != id ||
              entry['move'] is! String) {
            throw const FormatException('Inconsistent parent/child');
          }
          pending.add((
            child,
            position.play(Move.parse(entry['move'] as String)),
          ));
        }
      }
      if (nodes.length != raw.length)
        throw const FormatException('Unreachable node');
      return GameTree._(nodes, json['cursor'] as String, json['nextId'] as int);
    } on ArgumentError catch (error) {
      throw FormatException('Illegal game data: $error');
    } on TypeError {
      throw const FormatException('Invalid game field type');
    }
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
