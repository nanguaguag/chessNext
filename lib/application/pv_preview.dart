import 'dart:isolate';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'analysis_history.dart';

typedef PvPreviewLoader = Future<PvPreview> Function(PvHistoryEntry entry);

class PvPreview {
  PvPreview._(this.entry, List<Position> positions, List<String> notation)
    : positions = List.unmodifiable(positions),
      notation = List.unmodifiable(notation);
  final PvHistoryEntry entry;
  final List<Position> positions;
  final List<String> notation;
  int get length => notation.length;
  static PvPreview prepare(PvHistoryEntry entry) {
    if (entry.info.pv.isEmpty ||
        entry.info.pv.length > AnalysisHistory.maxPlies) {
      throw const FormatException('PV步数无效');
    }
    final positions = [entry.position], notation = <String>[];
    for (var i = 0; i < entry.info.pv.length; i++) {
      final move = entry.info.pv[i];
      try {
        final source = positions.last;
        final label = ChineseNotation.format(source, move);
        final next = source.play(move);
        notation.add(label);
        positions.add(next);
      } on ArgumentError {
        throw FormatException('第${i + 1}步PV不合法，未生成预览');
      } on StateError {
        throw FormatException('第${i + 1}步PV不合法，未生成预览');
      }
    }
    return PvPreview._(entry, positions, notation);
  }

  static Future<PvPreview> prepareInWorker(PvHistoryEntry entry) async {
    // Static scope captures no controller, WidgetState, native handle or IO.
    final result = await Isolate.run(() => _outcome(entry));
    if (result.preview != null) return result.preview!;
    throw FormatException(result.error!);
  }

  static ({PvPreview? preview, String? error}) _outcome(PvHistoryEntry entry) {
    try {
      return (preview: prepare(entry), error: null);
    } on FormatException catch (error) {
      return (preview: null, error: error.message);
    }
  }
}
