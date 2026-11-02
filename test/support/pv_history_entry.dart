import 'package:chess_next/application/analysis_history.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

PvHistoryEntry previewEntry(
  List<Move> moves, {
  Position? position,
  int depth = 12,
}) {
  final history = AnalysisHistory();
  history.add(
    position: position ?? Position.initial(),
    epoch: 7,
    nodeId: 'n3',
    revision: 9,
    positionRevision: 4,
    info: EngineInfo(
      token: 2,
      depth: depth,
      multiPv: 1,
      score: 10,
      isMate: false,
      pv: moves,
    ),
  );
  return history.entries.single;
}
