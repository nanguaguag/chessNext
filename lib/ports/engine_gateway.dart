import 'package:xiangqi_core/xiangqi_core.dart';
import 'engine_identity.dart';
export 'engine_identity.dart';
import 'wdl_estimate.dart';
export 'wdl_estimate.dart';

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
  // App policy bounds, not claims about the engine's maximum useful depth.
  static const maxDepth = 255;
  static const maxMoveTimeMs = 24 * 60 * 60 * 1000;
  static const maxNodeLimit = 9007199254740991; // exact on Dart VM and web

  factory EngineRequest({
    required int token,
    int gameId = 0,
    required Position root,
    Iterable<Move> moves = const [],
    int? depth,
    int? moveTimeMs,
    int? nodeLimit,
    int threads = 1,
    int hashMb = 16,
    int multiPv = 1,
    bool preferWdl = false,
    Iterable<Move>? searchMoves,
  }) {
    final history = List<Move>.unmodifiable(moves);
    var position = root;
    for (final move in history) {
      position = position.play(move);
    }
    return EngineRequest._(
      token: token,
      gameId: gameId,
      root: root,
      moves: history,
      position: position,
      depth: depth,
      moveTimeMs: moveTimeMs,
      nodeLimit: nodeLimit,
      threads: threads,
      hashMb: hashMb,
      multiPv: multiPv,
      preferWdl: preferWdl,
      searchMoves: searchMoves,
    );
  }
  factory EngineRequest.fromTree({
    required int token,
    int gameId = 0,
    required GameTree tree,
    int? depth,
    int? moveTimeMs,
    int? nodeLimit,
    int threads = 1,
    int hashMb = 16,
    int multiPv = 1,
    bool preferWdl = false,
    Iterable<Move>? searchMoves,
  }) => EngineRequest._(
    token: token,
    gameId: gameId,
    root: tree.root.position,
    position: tree.current.position,
    moves: List.unmodifiable(tree.path.skip(1).map((n) => n.move!)),
    depth: depth,
    moveTimeMs: moveTimeMs,
    nodeLimit: nodeLimit,
    threads: threads,
    hashMb: hashMb,
    multiPv: multiPv,
    preferWdl: preferWdl,
    searchMoves: searchMoves,
  );
  EngineRequest._({
    required this.token,
    this.gameId = 0,
    required this.root,
    required this.moves,
    required this.position,
    this.depth,
    this.moveTimeMs,
    this.nodeLimit,
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
    this.preferWdl = false,
    Iterable<Move>? searchMoves,
  }) : searchMoves = searchMoves == null
           ? null
           : List.unmodifiable(searchMoves.toSet()) {
    if ((depth != null && (depth! < 1 || depth! > maxDepth)) ||
        (moveTimeMs != null &&
            (moveTimeMs! < 1 || moveTimeMs! > maxMoveTimeMs)) ||
        (nodeLimit != null && (nodeLimit! < 1 || nodeLimit! > maxNodeLimit)) ||
        threads < 1 ||
        hashMb < 1 ||
        multiPv < 1 ||
        (this.searchMoves != null && this.searchMoves!.isEmpty)) {
      throw ArgumentError('Invalid search parameters');
    }
  }
  final int token;

  /// Document epoch, independent of the per-search token. Changes request a cold game.
  final int gameId;
  final Position root;
  final Position position;
  final List<Move> moves;
  final int? depth;
  final int? moveTimeMs;

  /// Limits may be combined; the engine stops when the first applicable bound is reached.
  /// A null bound is unrestricted. With all three null the search is infinite.
  final int? nodeLimit;
  final int threads;
  final int hashMb;
  final int multiPv;

  /// Best effort; unsupported engines keep normal analysis without WDL.
  final bool preferWdl;
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
    this.wdl,
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
  final WdlEstimate? wdl;
}

class EngineSearch {
  const EngineSearch(this.token, this.bestMove);
  final int token;
  final Future<Move?> bestMove;
}

abstract interface class EngineGateway {
  EngineIdentity? get identity;
  String? get name;
  Stream<EngineInfo> get info;
  EngineLifecycle get phase;
  Map<String, EngineOption> get options;
  Future<void> initialize();
  Future<EngineSearch> start(EngineRequest request);
  Future<void> stop();
  Future<void> dispose();
}
