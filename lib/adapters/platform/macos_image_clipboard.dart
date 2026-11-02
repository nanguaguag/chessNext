import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../ports/image_clipboard.dart';

typedef NativeImageWriter = Future<void> Function(Uint8List bytes);

class MacOsImageClipboard implements ImageClipboard {
  MacOsImageClipboard({NativeImageWriter? writer}) : _writer = writer ?? _copy;
  final NativeImageWriter _writer;
  static const channel = MethodChannel('dev.chessnext/image-clipboard');
  static Future<void> _copy(Uint8List bytes) =>
      channel.invokeMethod<void>('copyPng', {'bytes': bytes});

  @override
  Future<ImageCopyResult> copyPng(
    PngImage image, {
    required ImageCopyCancellation cancellation,
  }) async {
    if (cancellation.isCancelled) return ImageCopyResult.cancelled;
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      throw const ImageCopyException(ImageCopyFailure.unavailable);
    }
    if (cancellation.isCancelled) return ImageCopyResult.cancelled;
    try {
      await _writer(image.bytes);
    } on MissingPluginException {
      throw const ImageCopyException(ImageCopyFailure.unavailable);
    } catch (_) {
      throw const ImageCopyException(ImageCopyFailure.write);
    }
    return ImageCopyResult.copied;
  }
}
