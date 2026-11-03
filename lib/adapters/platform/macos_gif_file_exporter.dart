import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../ports/gif_file_exporter.dart';
import 'macos_record_file_exporter.dart'
    show ExportLocationChooser, AtomicTextWriter;

final class MacOsGifFileExporter implements GifFileExporter {
  MacOsGifFileExporter({
    ExportLocationChooser? chooser,
    AtomicTextWriter? writer,
  }) : _chooser = chooser ?? _choose,
       _writer = writer ?? _write;
  final ExportLocationChooser _chooser;
  final AtomicTextWriter _writer;
  static const channel = MethodChannel('dev.chessnext/record-file-writer');

  static Future<String?> _choose(String _) async => (await getSaveLocation(
    suggestedName: 'chessnext.gif',
    acceptedTypeGroups: [
      const XTypeGroup(label: 'GIF动态图', extensions: ['gif']),
    ],
  ))?.path;
  static Future<void> _write(String path, Uint8List bytes) => channel
      .invokeMethod<void>('writeGifAtomic', {'path': path, 'bytes': bytes});

  @override
  Future<RecordFileExportResult> saveGif(
    GifImage image, {
    required FileExportCancellation cancellation,
  }) async {
    if (cancellation.isCancelled) return RecordFileExportResult.cancelled;
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      throw const GifExportException(GifExportFailure.unavailable);
    }
    String? path;
    try {
      path = await _chooser('gif');
    } on MissingPluginException {
      throw const GifExportException(GifExportFailure.unavailable);
    } catch (_) {
      throw const GifExportException(GifExportFailure.selection);
    }
    if (path == null || cancellation.isCancelled) {
      return RecordFileExportResult.cancelled;
    }
    try {
      await _writer(path, image.bytes);
    } on MissingPluginException {
      throw const GifExportException(GifExportFailure.unavailable);
    } catch (_) {
      throw const GifExportException(GifExportFailure.write);
    }
    return RecordFileExportResult.saved;
  }
}
