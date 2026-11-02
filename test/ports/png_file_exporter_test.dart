import 'dart:typed_data';

import 'package:chess_next/ports/png_file_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pngHeader(int width, int height, {int length = 33}) {
  final bytes = Uint8List(length);
  bytes.setAll(0, const [137, 80, 78, 71, 13, 10, 26, 10]);
  ByteData.sublistView(bytes).setUint32(8, 13);
  bytes.setAll(12, const [73, 72, 68, 82]);
  ByteData.sublistView(bytes).setUint32(16, width);
  ByteData.sublistView(bytes).setUint32(20, height);
  return bytes;
}

void main() {
  Matcher failure(PngExportFailure kind) => isA<PngExportException>().having(
    (error) => error.failure,
    'failure',
    kind,
  );

  test('owns valid PNG bytes and exposes bounded dimensions', () {
    final source = pngHeader(900, 1000);
    final image = PngImage.fromBytes(source);
    source[0] = 0;
    expect(image.width, 900);
    expect(image.height, 1000);
    expect(image.bytes.first, 137);
    expect(() => image.bytes[0] = 0, throwsUnsupportedError);
  });

  test('rejects signature, IHDR, zero size, dimensions, pixels and bytes', () {
    final badSignature = pngHeader(1, 1)..[0] = 0;
    final badChunk = pngHeader(1, 1)..[12] = 0;
    for (final bytes in [
      Uint8List(32),
      badSignature,
      badChunk,
      pngHeader(0, 1),
    ]) {
      expect(
        () => PngImage.fromBytes(bytes),
        throwsA(failure(PngExportFailure.invalidData)),
      );
    }
    for (final bytes in [pngHeader(4097, 1), pngHeader(2001, 2000)]) {
      expect(
        () => PngImage.fromBytes(bytes),
        throwsA(failure(PngExportFailure.tooLarge)),
      );
    }
    expect(
      () => PngImage.fromBytes(pngHeader(1, 1, length: PngImage.maxBytes + 1)),
      throwsA(failure(PngExportFailure.tooLarge)),
    );
  });
}
