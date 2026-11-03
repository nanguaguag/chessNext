import 'dart:typed_data';
import 'record_file_exporter.dart'
    show FileExportCancellation, RecordFileExportResult;
export 'record_file_exporter.dart'
    show FileExportCancellation, RecordFileExportResult;

enum GifExportFailure {
  tooLarge,
  invalidData,
  unavailable,
  selection,
  write,
  render,
  encode,
}

final class GifExportException implements Exception {
  const GifExportException(this.failure);
  final GifExportFailure failure;
  String get message => switch (failure) {
    GifExportFailure.tooLarge => '动态图超过64帧或12MB限制，请缩短所选线路。',
    GifExportFailure.invalidData => 'GIF动态图数据无效，请重新生成。',
    GifExportFailure.unavailable => '当前设备暂不支持GIF文件保存。',
    GifExportFailure.selection => '无法打开GIF保存窗口，请重试。',
    GifExportFailure.write => 'GIF写入失败，请重试或选择其它位置。',
    GifExportFailure.render => '动态图画面生成失败，请重试。',
    GifExportFailure.encode => 'GIF编码失败，请重试。',
  };
}

final class GifImage {
  GifImage._(this.bytes, this.width, this.height, this.frameDurations);
  static const maxBytes = 12 * 1024 * 1024, maxDimension = 1024;
  final Uint8List bytes;
  final int width, height;
  final List<int> frameDurations;
  int get frameCount => frameDurations.length;

  factory GifImage.fromEncoded(
    Uint8List value, {
    required int width,
    required int height,
    required Iterable<int> frameDurations,
  }) {
    final durations = List<int>.unmodifiable(frameDurations);
    final gif87 =
        value.length >= 10 && String.fromCharCodes(value.take(6)) == 'GIF87a';
    final gif89 =
        value.length >= 10 && String.fromCharCodes(value.take(6)) == 'GIF89a';
    final headerWidth = value.length >= 10 ? value[6] | (value[7] << 8) : 0;
    final headerHeight = value.length >= 10 ? value[8] | (value[9] << 8) : 0;
    if ((!gif87 && !gif89) ||
        width < 1 ||
        height < 1 ||
        width > maxDimension ||
        height > maxDimension ||
        headerWidth != width ||
        headerHeight != height ||
        durations.isEmpty ||
        durations.length > 64 ||
        durations.any((value) => value < 20 || value > 3000)) {
      throw const GifExportException(GifExportFailure.invalidData);
    }
    if (value.length > maxBytes) {
      throw const GifExportException(GifExportFailure.tooLarge);
    }
    return GifImage._(
      Uint8List.fromList(value).asUnmodifiableView(),
      width,
      height,
      durations,
    );
  }
}

abstract interface class GifFileExporter {
  Future<RecordFileExportResult> saveGif(
    GifImage image, {
    required FileExportCancellation cancellation,
  });
}
