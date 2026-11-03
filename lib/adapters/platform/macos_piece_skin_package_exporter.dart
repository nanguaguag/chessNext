import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/record_file_exporter.dart';
import 'macos_record_file_exporter.dart'
    show AtomicTextWriter, ExportLocationChooser;

class MacOsPieceSkinPackageExporter implements PieceSkinPackageExporter {
  MacOsPieceSkinPackageExporter({
    ExportLocationChooser? chooser,
    AtomicTextWriter? writer,
  }) : _chooser = chooser ?? _choose,
       _writer = writer ?? _write;

  final ExportLocationChooser _chooser;
  final AtomicTextWriter _writer;
  static const channel = MethodChannel('dev.chessnext/record-file-writer');

  static Future<String?> _choose(String name) async => (await getSaveLocation(
    suggestedName: '$name.zip',
    acceptedTypeGroups: [
      const XTypeGroup(label: '棋子皮肤压缩包', extensions: ['zip']),
    ],
  ))?.path;

  static Future<void> _write(String path, Uint8List bytes) => channel
      .invokeMethod<void>('writeZipAtomic', {'path': path, 'bytes': bytes});

  @override
  Future<RecordFileExportResult> saveZip({
    required String suggestedName,
    required Uint8List bytes,
    required FileExportCancellation cancellation,
  }) async {
    if (cancellation.isCancelled) return RecordFileExportResult.cancelled;
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      throw const RecordExportException(RecordExportFailure.unavailable);
    }
    String? path;
    try {
      path = await _chooser(suggestedName);
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
