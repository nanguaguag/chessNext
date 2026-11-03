import 'dart:typed_data';

import 'package:image/image.dart' as raster;

import '../ports/piece_images.dart';

abstract final class PieceImageValidator {
  static void validate(SelectedPieceImage file) {
    final bytes = file.bytes;
    if (!const {'png', 'jpg', 'jpeg'}.contains(file.extension) ||
        bytes.isEmpty) {
      throw const PieceImageException(PieceImageFailure.format);
    }
    if (bytes.length > PieceImageLimits.maxBytes) {
      throw const PieceImageException(PieceImageFailure.tooLarge);
    }
    final dimensions = _dimensions(bytes);
    if (dimensions == null) {
      throw const PieceImageException(PieceImageFailure.format);
    }
    final (width, height) = dimensions;
    if (width < 1 ||
        height < 1 ||
        width > PieceImageLimits.maxDimension ||
        height > PieceImageLimits.maxDimension ||
        width * height > PieceImageLimits.maxPixels) {
      throw const PieceImageException(PieceImageFailure.dimensions);
    }
    final decoded = raster.decodeImage(bytes);
    if (decoded == null ||
        decoded.width > PieceImageLimits.maxDimension ||
        decoded.height > PieceImageLimits.maxDimension ||
        decoded.width * decoded.height > PieceImageLimits.maxPixels) {
      throw const PieceImageException(PieceImageFailure.format);
    }
  }

  static (int, int)? _dimensions(Uint8List bytes) {
    const png = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length >= 24 &&
        _hasPngSignature(bytes, png) &&
        String.fromCharCodes(bytes.sublist(12, 16)) == 'IHDR') {
      return (_uint32(bytes, 16), _uint32(bytes, 20));
    }
    if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) return null;
    var offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xff) return null;
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0xd9 || marker == 0xda) return null;
      if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
      if (offset + 2 > bytes.length) return null;
      final length = bytes[offset] << 8 | bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) return null;
      if (_isStartOfFrame(marker)) {
        if (length < 7) return null;
        final height = bytes[offset + 3] << 8 | bytes[offset + 4];
        final width = bytes[offset + 5] << 8 | bytes[offset + 6];
        return (width, height);
      }
      offset += length;
    }
    return null;
  }

  static bool _hasPngSignature(Uint8List bytes, List<int> signature) {
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  static bool _isStartOfFrame(int marker) =>
      marker >= 0xc0 &&
      marker <= 0xcf &&
      marker != 0xc4 &&
      marker != 0xc8 &&
      marker != 0xcc;

  static int _uint32(Uint8List bytes, int offset) =>
      bytes[offset] << 24 |
      bytes[offset + 1] << 16 |
      bytes[offset + 2] << 8 |
      bytes[offset + 3];
}
