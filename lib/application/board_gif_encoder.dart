import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as image;
import '../ports/gif_file_exporter.dart';

typedef BoardGifEncoder =
    Future<GifImage> Function(
      List<Uint8List> pngFrames,
      List<int> durationsCentiseconds,
    );

Future<GifImage> encodeBoardGif(
  List<Uint8List> pngFrames,
  List<int> durationsCentiseconds,
) async {
  if (pngFrames.isEmpty ||
      pngFrames.length != durationsCentiseconds.length ||
      pngFrames.length > 64) {
    throw const GifExportException(GifExportFailure.invalidData);
  }
  try {
    final encoded = await Isolate.run(() {
      final encoder = image.GifEncoder(
        repeat: 0,
        dispose: 1,
        samplingFactor: 20,
      );
      int? width, height;
      for (var i = 0; i < pngFrames.length; i++) {
        final frame = image.decodePng(pngFrames[i]);
        if (frame == null) throw const FormatException('Invalid PNG frame');
        width ??= frame.width;
        height ??= frame.height;
        if (frame.width != width || frame.height != height) {
          throw const FormatException('Mismatched frame size');
        }
        encoder.addFrame(frame, duration: durationsCentiseconds[i]);
      }
      final bytes = encoder.finish();
      if (bytes == null) throw const FormatException('Empty GIF');
      return (bytes: bytes, width: width!, height: height!);
    });
    return GifImage.fromEncoded(
      encoded.bytes,
      width: encoded.width,
      height: encoded.height,
      frameDurations: durationsCentiseconds,
    );
  } on GifExportException {
    rethrow;
  } catch (_) {
    throw const GifExportException(GifExportFailure.encode);
  }
}
