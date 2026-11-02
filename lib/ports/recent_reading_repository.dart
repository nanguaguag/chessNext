import 'package:xiangqi_core/xiangqi_core.dart';

class RestoredReading {
  const RestoredReading(this.tree, this.matched);
  final GameTree tree;
  final bool matched;
}

/// Navigation metadata only. It never owns or replaces saved game content.
class RecentReading {
  RecentReading({
    required this.gameId,
    required this.title,
    required this.readAt,
    required this.rootFen,
    required Iterable<Move> path,
  }) : path = List.unmodifiable(path) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(gameId) ||
        title.trim().isEmpty ||
        title.length > 120 ||
        rootFen.length > 200 ||
        this.path.length > GameTree.maxNodes - 1) {
      throw ArgumentError('Invalid reading metadata');
    }
    Position.fromFen(rootFen);
  }
  factory RecentReading.capture(
    String id,
    String title,
    GameTree tree,
    DateTime at,
  ) => RecentReading(
    gameId: id,
    title: title,
    readAt: at,
    rootFen: tree.root.position.toFen(),
    path: tree.path.skip(1).map((n) => n.move!),
  );
  final String gameId, title, rootFen;
  final DateTime readAt;
  final List<Move> path;
  bool samePlace(RecentReading other) =>
      gameId == other.gameId &&
      title == other.title &&
      rootFen == other.rootFen &&
      path.length == other.path.length &&
      Iterable<int>.generate(
        path.length,
      ).every((i) => path[i] == other.path[i]);
  RestoredReading restore(GameTree tree) {
    if (tree.root.position.toFen() != rootFen) {
      return RestoredReading(tree, false);
    }
    var node = tree.root;
    for (final move in path) {
      final children = node.children
          .map(tree.node)
          .where((n) => n.move == move);
      if (children.isEmpty) return RestoredReading(tree, false);
      node = children.first;
    }
    return RestoredReading(tree.goTo(node.id), true);
  }

  Map<String, Object> toJson() => {
    'id': gameId,
    'title': title,
    'at': readAt.toUtc().toIso8601String(),
    'rootFen': rootFen,
    'path': path.map((m) => m.toString()).toList(),
  };
  factory RecentReading.fromJson(Object? raw) {
    try {
      if (raw is! Map<String, dynamic> ||
          raw['id'] is! String ||
          raw['title'] is! String ||
          raw['at'] is! String ||
          raw['rootFen'] is! String ||
          raw['path'] is! List ||
          (raw['path'] as List).length > GameTree.maxNodes - 1) {
        throw const FormatException('Invalid reading entry');
      }
      final moves = (raw['path'] as List).map((m) {
        if (m is! String || !RegExp(r'^[a-i][0-9][a-i][0-9]$').hasMatch(m)) {
          throw const FormatException('Invalid reading move');
        }
        return Move.parse(m);
      }).toList();
      return RecentReading(
        gameId: raw['id'] as String,
        title: raw['title'] as String,
        readAt: DateTime.parse(raw['at'] as String),
        rootFen: raw['rootFen'] as String,
        path: moves,
      );
    } on ArgumentError {
      throw const FormatException('Invalid reading data');
    }
  }
}

class LoadedRecentReadings {
  LoadedRecentReadings(
    Iterable<RecentReading> entries, {
    this.recovered = false,
  }) : entries = List.unmodifiable(entries);
  final List<RecentReading> entries;
  final bool recovered;
}

abstract interface class RecentReadingRepository {
  static const maximum = 50;
  Future<LoadedRecentReadings> load();
  Future<void> save(List<RecentReading> entries);
}

class MemoryRecentReadingRepository implements RecentReadingRepository {
  List<RecentReading> entries = [];
  @override
  Future<LoadedRecentReadings> load() async => LoadedRecentReadings(entries);
  @override
  Future<void> save(List<RecentReading> entries) async {
    this.entries = List.unmodifiable(entries);
  }
}
