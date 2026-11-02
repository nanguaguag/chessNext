import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';

class PvHistoryEntry {
  const PvHistoryEntry._({
    required this.id,
    required this.position,
    required this.epoch,
    required this.nodeId,
    required this.revision,
    required this.positionRevision,
    required this.info,
    required this.originalPvLength,
    required this.sourcePly,
    this.sourceMoveLabel,
  });
  final int id, epoch, revision, positionRevision, originalPvLength;
  final int sourcePly;
  final String? sourceMoveLabel;
  String get sourceLabel => sourcePly == 0
      ? '起始局面'
      : '第$sourcePly步后${sourceMoveLabel == null ? "" : "：$sourceMoveLabel"}';
  final String nodeId;
  final Position position;
  final EngineInfo info;
  bool get truncated => originalPvLength > info.pv.length;
  int scoreFor(Side side) => position.turn == side ? info.score : -info.score;
  String? boundFor(Side side) => position.turn == side
      ? info.bound
      : switch (info.bound) {
          'lower' => 'upper',
          'upper' => 'lower',
          _ => null,
        };
  WdlEstimate? wdlFor(Side side) =>
      position.turn == side ? info.wdl : info.wdl?.flipped();
}

/// Current-document display samples, independent of caches and saved records.
class AnalysisHistory {
  static const maxEntries = 64, maxPlies = 128;
  List<PvHistoryEntry> _entries = const [];
  List<PvHistoryEntry> get entries => _entries;
  int _nextId = 0;
  void clear() => _entries = const [];
  void add({
    required Position position,
    required int epoch,
    required String nodeId,
    required int revision,
    required int positionRevision,
    required EngineInfo info,
    int sourcePly = 0,
    String? sourceMoveLabel,
  }) {
    if (sourcePly < 0 ||
        info.pv.isEmpty ||
        info.multiPv < 1 ||
        info.multiPv > 256 ||
        info.depth < 0 ||
        info.depth > 255) {
      return;
    }
    final moves = List<Move>.unmodifiable(info.pv.take(maxPlies));
    final previous = _entries
        .where(
          (e) =>
              e.info.token == info.token &&
              e.info.multiPv == info.multiPv &&
              e.epoch == epoch &&
              e.positionRevision == positionRevision,
        )
        .firstOrNull;
    if (previous != null &&
        previous.info.depth == info.depth &&
        previous.info.score == info.score &&
        previous.info.isMate == info.isMate &&
        previous.info.bound == info.bound &&
        previous.originalPvLength == info.pv.length &&
        previous.info.wdl?.wins == info.wdl?.wins &&
        previous.info.wdl?.draws == info.wdl?.draws &&
        previous.info.wdl?.losses == info.wdl?.losses &&
        previous.info.pv.length == moves.length &&
        Iterable<int>.generate(
          moves.length,
        ).every((i) => previous.info.pv[i] == moves[i])) {
      return;
    }
    final copy = EngineInfo(
      token: info.token,
      depth: info.depth,
      multiPv: info.multiPv,
      score: info.score,
      isMate: info.isMate,
      bound: info.bound,
      pv: moves,
      nodes: info.nodes,
      nps: info.nps,
      timeMs: info.timeMs,
      wdl: info.wdl,
    );
    _entries = List.unmodifiable([
      PvHistoryEntry._(
        id: ++_nextId,
        position: position,
        epoch: epoch,
        nodeId: nodeId,
        revision: revision,
        positionRevision: positionRevision,
        info: copy,
        originalPvLength: info.pv.length,
        sourcePly: sourcePly,
        sourceMoveLabel: sourceMoveLabel,
      ),
      ..._entries.take(maxEntries - 1),
    ]);
  }
}
