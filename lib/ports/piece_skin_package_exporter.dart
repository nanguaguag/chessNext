import 'dart:typed_data';

import 'record_file_exporter.dart';

abstract interface class PieceSkinPackageExporter {
  Future<RecordFileExportResult> saveZip({
    required String suggestedName,
    required Uint8List bytes,
    required FileExportCancellation cancellation,
  });
}
