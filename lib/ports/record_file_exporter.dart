class FileExportCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

enum RecordFileExportResult { saved, cancelled }

enum RecordExportFailure { tooLarge, encoding, unavailable, selection, write }

class RecordExportException implements Exception {
  const RecordExportException(this.failure);
  final RecordExportFailure failure;
  String get message => switch (failure) {
    RecordExportFailure.tooLarge => '导出超过256000字节或64000字符限制。',
    RecordExportFailure.encoding => '文字含无法无损保存为UTF8的字符，请检查棋谱资料与评注。',
    RecordExportFailure.unavailable => '当前平台尚未提供文件导出，请使用复制文字。',
    RecordExportFailure.selection => '无法打开保存对话框，请重试或复制文字。',
    RecordExportFailure.write => '文件写入失败，请重试或选择其它位置。',
  };
}

abstract interface class RecordFileExporter {
  /// Cancellation before writing discards a late choice. A started atomic write
  /// completes independently; cancellation cannot roll it back.
  Future<RecordFileExportResult> saveText({
    required String text,
    required String extension,
    required FileExportCancellation cancellation,
  });
}
