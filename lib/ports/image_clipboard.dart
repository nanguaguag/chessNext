import 'png_file_exporter.dart' show PngImage;
export 'png_file_exporter.dart' show PngImage;

enum ImageCopyFailure { unavailable, write }

class ImageCopyException implements Exception {
  const ImageCopyException(this.failure);
  final ImageCopyFailure failure;
  String get message => switch (failure) {
    ImageCopyFailure.unavailable => '当前设备暂不支持图片复制。',
    ImageCopyFailure.write => '图片复制失败，请重试。',
  };
}

enum ImageCopyResult { copied, cancelled }

class ImageCopyCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

abstract interface class ImageClipboard {
  /// A late image is not written after cancellation. Once native pasteboard
  /// writing starts it completes independently and cannot be rolled back.
  Future<ImageCopyResult> copyPng(
    PngImage image, {
    required ImageCopyCancellation cancellation,
  });
}
