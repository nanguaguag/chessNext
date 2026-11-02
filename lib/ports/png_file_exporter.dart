import 'dart:typed_data';
import 'record_file_exporter.dart'
    show FileExportCancellation, RecordFileExportResult;
export 'record_file_exporter.dart'
    show FileExportCancellation, RecordFileExportResult;

enum PngExportFailure {
  tooLarge,
  invalidData,
  unavailable,
  selection,
  write,
  render,
}

class PngExportException implements Exception {
  const PngExportException(this.failure);
  final PngExportFailure failure;
  String get message => switch (failure) {
    PngExportFailure.tooLarge => '图片超过尺寸或8MB限制，请重新生成。',
    PngExportFailure.invalidData => 'PNG图片数据无效，请重新生成。',
    PngExportFailure.unavailable => '当前设备暂不支持图片文件保存。',
    PngExportFailure.selection => '无法打开图片保存窗口，请重试。',
    PngExportFailure.write => '图片写入失败，请重试或选择其它位置。',
    PngExportFailure.render => '棋盘图片生成失败，请重试。',
  };
}

/// Owned, bounded PNG header/size validation. Native writer also decodes pixels.
class PngImage {
  PngImage._(this.bytes, this.width, this.height);
  static const maxBytes = 8 * 1024 * 1024,
      maxDimension = 4096,
      maxPixels = 4000000;
  final Uint8List bytes;
  final int width, height;
  factory PngImage.fromBytes(Uint8List value) {
    if (value.length > maxBytes) {
      throw const PngExportException(PngExportFailure.tooLarge);
    }
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (value.length < 33 ||
        !Iterable<int>.generate(8).every((i) => value[i] == signature[i]) ||
        value[12] != 73 ||
        value[13] != 72 ||
        value[14] != 68 ||
        value[15] != 82) {
      throw const PngExportException(PngExportFailure.invalidData);
    }
    final data = ByteData.sublistView(value);
    if (data.getUint32(8) != 13) {
      throw const PngExportException(PngExportFailure.invalidData);
    }
    final width = data.getUint32(16), height = data.getUint32(20);
    if (width == 0 || height == 0) {
      throw const PngExportException(PngExportFailure.invalidData);
    }
    if (width > maxDimension ||
        height > maxDimension ||
        width * height > maxPixels) {
      throw const PngExportException(PngExportFailure.tooLarge);
    }
    return PngImage._(
      Uint8List.fromList(value).asUnmodifiableView(),
      width,
      height,
    );
  }
}

abstract interface class PngFileExporter {
  /// Late chooser results are discarded when cancelled. A started atomic write
  /// completes independently and is never falsely described as rolled back.
  Future<RecordFileExportResult> savePng(
    PngImage image, {
    required FileExportCancellation cancellation,
  });
}
