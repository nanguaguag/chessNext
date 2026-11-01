/// A user-selected text file. Paths and platform handles stay in the adapter.
class PickedRecordText {
  const PickedRecordText({required this.displayName, required this.text});
  final String displayName;
  final String text;
}

enum RecordFileFailure { tooLarge, encoding, read, unavailable, timeout }

class RecordFileException implements Exception {
  const RecordFileException(this.failure);
  final RecordFileFailure failure;
  String get message => switch (failure) {
    RecordFileFailure.tooLarge => '文件超过256000字节或64000字符限制。',
    RecordFileFailure.encoding => '无法按UTF8读取文件，请先转换编码。',
    RecordFileFailure.read => '无法读取所选文件，请确认文件仍存在且可读取。',
    RecordFileFailure.unavailable => '当前平台的文件选择器不可用，请使用文字导入。',
    RecordFileFailure.timeout => '读取文件超时，请重试或选择本机文件。',
  };
}

abstract interface class RecordFilePicker {
  /// Null means user cancellation. Never writes the selected file.
  Future<PickedRecordText?> openText();
}
