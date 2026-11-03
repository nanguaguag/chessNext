import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../ports/piece_images.dart';
import '../ports/piece_skin_library.dart';
import 'piece_image_validator.dart';

/// A bounded, deterministic ZIP representation for a user-created skin.
final class PieceSkinPackageCodec {
  static const maxImages = 14;
  static const maxImageBytes = 7 * 1024 * 1024;
  static const maxArchiveBytes = 8 * 1024 * 1024;

  static Uint8List encode(
    PieceSkinDefinition profile,
    Map<PieceImageSlot, Uint8List> images,
  ) {
    if (images.length > maxImages ||
        images.values.fold<int>(0, (sum, item) => sum + item.length) >
            maxImageBytes) {
      throw const FormatException('Skin package exceeds limits');
    }
    final archive = Archive();
    final entries = <Map<String, Object>>[];
    for (final slot in PieceImageSlot.values) {
      final bytes = images[slot];
      if (bytes == null) continue;
      final extension = _extension(bytes);
      PieceImageValidator.validate(SelectedPieceImage(extension, bytes));
      final path = 'images/${slot.name}.$extension';
      entries.add({
        'slot': slot.name,
        'path': path,
        'sha256': sha256.convert(bytes).toString(),
      });
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    final manifest = utf8.encode(
      jsonEncode({'schema': 1, 'profile': profile.toJson(), 'images': entries}),
    );
    archive.addFile(ArchiveFile('skin.json', manifest.length, manifest));
    final encoded = Uint8List.fromList(ZipEncoder().encode(archive));
    if (encoded.length > maxArchiveBytes) {
      throw const FormatException('Skin package exceeds limits');
    }
    return encoded;
  }

  static String _extension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'jpg';
    }
    throw const FormatException('Unsupported piece image');
  }
}
