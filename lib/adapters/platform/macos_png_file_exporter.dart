import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../ports/png_file_exporter.dart';
import 'macos_record_file_exporter.dart'
    show ExportLocationChooser, AtomicTextWriter;

class MacOsPngFileExporter implements PngFileExporter {
  MacOsPngFileExporter({
    ExportLocationChooser? chooser,
    AtomicTextWriter? writer,
  }) : _chooser = chooser ?? _choose,
       _writer = writer ?? _write;
  final ExportLocationChooser _chooser;
  final AtomicTextWriter _writer;
  static const channel = MethodChannel('dev.chessnext/record-file-writer');
  static Future<String?> _choose(String _) async => (await getSaveLocation(
    suggestedName: 'chessnext.png',
    acceptedTypeGroups: [
      const XTypeGroup(label: 'PNG图片', extensions: ['png']),
    ],
  ))?.path;
  static Future<void> _write(String path, Uint8List bytes) => channel
      .invokeMethod<void>('writePngAtomic', {'path': path, 'bytes': bytes});
  @override
  Future<RecordFileExportResult> savePng(
    PngImage image, {
    required FileExportCancellation cancellation,
  }) async {
    if (cancellation.isCancelled) return RecordFileExportResult.cancelled;
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      throw const PngExportException(PngExportFailure.unavailable);
    }
    String? path;
    try {
      path = await _chooser('png');
    } on MissingPluginException {
      throw const PngExportException(PngExportFailure.unavailable);
    } catch (_) {
      throw const PngExportException(PngExportFailure.selection);
    }
    if (path == null || cancellation.isCancelled) {
      return RecordFileExportResult.cancelled;
    }
    try {
      await _writer(path, image.bytes);
    } on MissingPluginException {
      throw const PngExportException(PngExportFailure.unavailable);
    } catch (_) {
      throw const PngExportException(PngExportFailure.write);
    }
    return RecordFileExportResult.saved;
  }
}
