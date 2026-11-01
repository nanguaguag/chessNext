import 'package:xiangqi_core/xiangqi_core.dart';

enum EngineLifecycle {
  stopped,
  starting,
  ready,
  searching,
  stopping,
  failed,
  closed,
}

class EngineOption {
  const EngineOption({
    required this.name,
    required this.type,
    this.defaultValue,
    this.minimum,
    this.maximum,
  });
  final String name;
  final String type;
  final String? defaultValue;
  final int? minimum;
  final int? maximum;
}

class EngineRequest {
  factory EngineRequest({
    required int token,
    required Position root,
    Iterable<Move> moves = const [],
    int? depth,
    int? moveTimeMs,
    int threads = 1,
    int hashMb = 16,
    int multiPv = 1,
    Iterable<Move>? searchMoves,
  }) {
    final history = List<Move>.unmodifiable(moves);
    var position = root;
    for (final move in history) {
      position = position.play(move);
    }
    return EngineRequest._(
      token: token,
      root: root,
      moves: history,
      position: position,
      depth: depth,
      moveTimeMs: moveTimeMs,
      threads: threads,
      hashMb: hashMb,
      multiPv: multiPv,
      searchMoves: searchMoves,
    );
  }
  factory EngineRequest.fromTree({
    required int token,
    required GameTree tree,
    int? depth,
    int? moveTimeMs,
    int threads = 1,
    int hashMb = 16,
    int multiPv = 1,
    Iterable<Move>? searchMoves,
  }) => EngineRequest._(
    token: token,
    root: tree.root.position,
    position: tree.current.position,
    moves: List.unmodifiable(tree.path.skip(1).map((n) => n.move!)),
    depth: depth,
    moveTimeMs: moveTimeMs,
    threads: threads,
    hashMb: hashMb,
    multiPv: multiPv,
    searchMoves: searchMoves,
  );
  EngineRequest._({
    required this.token,
    required this.root,
    required this.moves,
    required this.position,
    this.depth,
    this.moveTimeMs,
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
    Iterable<Move>? searchMoves,
  }) : searchMoves = searchMoves == null
           ? null
           : List.unmodifiable(searchMoves.toSet()) {
    if ((depth != null && depth! < 1) ||
        (moveTimeMs != null && moveTimeMs! < 1) ||
        (depth != null && moveTimeMs != null) ||
        threads < 1 ||
        hashMb < 1 ||
        multiPv < 1 ||
        (this.searchMoves != null && this.searchMoves!.isEmpty)) {
      throw ArgumentError('Invalid search parameters');
    }
  }
  final int token;
  final Position root;
  final Position position;
  final List<Move> moves;
  final int? depth;
  final int? moveTimeMs;
  final int threads;
  final int hashMb;
  final int multiPv;
  final List<Move>? searchMoves;
}

class EngineInfo {
  const EngineInfo({
    required this.token,
    required this.depth,
    required this.multiPv,
    required this.score,
    required this.isMate,
    required this.pv,
    this.bound,
    this.nodes,
    this.nps,
    this.timeMs,
  });
  final int token;
  final int depth;
  final int multiPv;

  /// Raw score from the side-to-move perspective, not a red-normalized score.
  final int score;
  final bool isMate;
  final String? bound;
  final List<Move> pv;
  final int? nodes;
  final int? nps;
  final int? timeMs;
}

class EngineSearch {
  const EngineSearch(this.token, this.bestMove);
  final int token;
  final Future<Move?> bestMove;
}

abstract interface class EngineGateway {
  Stream<EngineInfo> get info;
  EngineLifecycle get phase;
  Map<String, EngineOption> get options;
  Future<void> initialize();
  Future<EngineSearch> start(EngineRequest request);
  Future<void> stop();
  Future<void> dispose();
}
