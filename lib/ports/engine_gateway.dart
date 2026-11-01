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
  EngineRequest({
    required this.token,
    required this.root,
    Iterable<Move> moves = const [],
    this.depth,
    this.moveTimeMs,
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
  }) : moves = List.unmodifiable(moves) {
    if ((depth != null && depth! < 1) ||
        (moveTimeMs != null && moveTimeMs! < 1) ||
        (depth != null && moveTimeMs != null) ||
        threads < 1 ||
        hashMb < 1 ||
        multiPv < 1) {
      throw ArgumentError('Invalid search parameters');
    }
  }
  final int token;
  final Position root;
  final List<Move> moves;
  final int? depth;
  final int? moveTimeMs;
  final int threads;
  final int hashMb;
  final int multiPv;
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
