import 'dart:isolate';
import 'package:xiangqi_core/xiangqi_core.dart';

enum TextSourceFormat { plain, pgn }

enum TextExportFormat { fen, uci, chinese, pgnIccs, pgnChinese }

extension TextExportKind on TextExportFormat {
  bool get isPgn =>
      this == TextExportFormat.pgnIccs || this == TextExportFormat.pgnChinese;
}

class ImportedRecord {
  const ImportedRecord({
    required this.tree,
    required this.metadata,
    required this.source,
  });
  final GameTree tree;
  final GameMetadata metadata;
  final TextSourceFormat source;
}

typedef TextImporter = Future<ImportedRecord> Function(String text);

/// Format coordination has no Flutter, repository, clipboard or engine dependency.
abstract final class RecordTextExchange {
  static ImportedRecord parse(String text) {
    if (text.length > TextRecord.maxLength) {
      throw const FormatException('文字超过64000字符限制');
    }
    final source = text.trim().replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    if (source.startsWith('[')) {
      final record = PgnCodec.parse(source);
      return ImportedRecord(
        tree: record.tree,
        metadata: GameMetadata(record.tags),
        source: TextSourceFormat.pgn,
      );
    }
    return ImportedRecord(
      tree: TextRecord.parse(text),
      metadata: GameMetadata.empty,
      source: TextSourceFormat.plain,
    );
  }

  static Future<ImportedRecord> parseInWorker(String text) async {
    // Static scope captures only text; never a WidgetState or native resource.
    final outcome = await Isolate.run(() => _parseOutcome(text));
    final record = outcome.record;
    if (record != null) return record;
    throw FormatException(outcome.error!);
  }

  static String exportText(
    GameTree tree,
    GameMetadata metadata,
    TextExportFormat format, {
    bool includeComments = true,
    bool includeFuture = true,
  }) {
    if (format == TextExportFormat.fen) return tree.current.position.toFen();
    if (!format.isPgn) {
      return TextRecord.path(tree, chinese: format == TextExportFormat.chinese);
    }
    final pgnFormat = format == TextExportFormat.pgnIccs
        ? PgnMoveFormat.iccs
        : PgnMoveFormat.chinese;
    final exportTree = includeFuture
        ? tree.goTo(tree.currentLine.last.id)
        : tree;
    final record = PgnRecord(
      tree: exportTree,
      tags: {
        ...metadata.tags,
        'Game': 'Chinese Chess',
        'FEN': tree.root.position.toFen(),
        'Format': pgnFormat == PgnMoveFormat.iccs ? 'ICCS' : 'Chinese',
      },
    );
    return PgnCodec.path(
      record,
      format: pgnFormat,
      includeComments: includeComments,
    );
  }
}

({ImportedRecord? record, String? error}) _parseOutcome(String text) {
  try {
    return (record: RecordTextExchange.parse(text), error: null);
  } on FormatException catch (e) {
    return (record: null, error: e.message);
  }
}
