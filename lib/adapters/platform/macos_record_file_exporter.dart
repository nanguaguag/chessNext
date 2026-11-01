import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../ports/record_file_exporter.dart';

typedef ExportLocationChooser = Future<String?> Function(String extension);
typedef AtomicTextWriter = Future<void> Function(String path, Uint8List bytes);

class MacOsRecordFileExporter implements RecordFileExporter {
  MacOsRecordFileExporter({
    ExportLocationChooser? chooser,
    AtomicTextWriter? writer,
  }) : _chooser = chooser ?? _choose,
       _writer = writer ?? _write;
  final ExportLocationChooser _chooser;
  final AtomicTextWriter _writer;
  static const channel = MethodChannel('dev.chessnext/record-file-writer');

  static Future<String?> _choose(String extension) async =>
      (await getSaveLocation(
        suggestedName: 'chessnext.$extension',
        acceptedTypeGroups: [
          XTypeGroup(label: '文字棋谱', extensions: [extension]),
        ],
      ))?.path;

  static Future<void> _write(String path, Uint8List bytes) =>
      channel.invokeMethod<void>('writeAtomic', {'path': path, 'bytes': bytes});

  @override
  Future<RecordFileExportResult> saveText({
    required String text,
    required String extension,
    required FileExportCancellation cancellation,
  }) async {
    if (!{'pgn', 'fen', 'txt'}.contains(extension)) {
      throw ArgumentError.value(extension, 'extension');
    }
    if (text.length > 64000) {
      throw const RecordExportException(RecordExportFailure.tooLarge);
    }
    final bytes = Uint8List.fromList(utf8.encode(text));
    if (utf8.decode(bytes) != text) {
      throw const RecordExportException(RecordExportFailure.encoding);
    }
    if (bytes.length > 256000) {
      throw const RecordExportException(RecordExportFailure.tooLarge);
    }
    if (cancellation.isCancelled) return RecordFileExportResult.cancelled;
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      throw const RecordExportException(RecordExportFailure.unavailable);
    }
    String? path;
    try {
      path = await _chooser(extension);
    } on MissingPluginException {
      throw const RecordExportException(RecordExportFailure.unavailable);
    } catch (_) {
      throw const RecordExportException(RecordExportFailure.selection);
    }
    if (path == null || cancellation.isCancelled) {
      return RecordFileExportResult.cancelled;
    }
    try {
      await _writer(path, bytes);
    } on MissingPluginException {
      throw const RecordExportException(RecordExportFailure.unavailable);
    } catch (_) {
      throw const RecordExportException(RecordExportFailure.write);
    }
    return RecordFileExportResult.saved;
  }
}
