import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../ports/board_skin_images.dart';
import '../ports/board_skin_library.dart';
import '../ports/piece_images.dart';
import 'piece_image_validator.dart';

/// Project-owned bounded ZIP format for a user board skin.
final class BoardSkinPackageCodec {
  static const maxImageBytes = 7 * 1024 * 1024;
  static const maxArchiveBytes = 8 * 1024 * 1024;

  static Uint8List encode(
    BoardSkinDefinition profile,
    Map<BoardSkinImageSlot, Uint8List> images,
  ) {
    if (images.length > BoardSkinImageSlot.values.length ||
        images.values.fold<int>(0, (sum, bytes) => sum + bytes.length) >
            maxImageBytes) {
      throw const FormatException('Board skin package exceeds limits');
    }
    final archive = Archive();
    final entries = <Map<String, Object>>[];
    for (final slot in BoardSkinImageSlot.values) {
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
      jsonEncode({
        'schema': 1,
        'profile': profile.toJson(),
        'images': entries,
      }),
    );
    archive.addFile(ArchiveFile('board-skin.json', manifest.length, manifest));
    final encoded = Uint8List.fromList(ZipEncoder().encode(archive));
    if (encoded.length > maxArchiveBytes) {
      throw const FormatException('Board skin package exceeds limits');
    }
    return encoded;
  }

  static BoardSkinPackage decode(Uint8List bytes) {
    try {
      return _decode(bytes);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid board skin package');
    }
  }

  static BoardSkinPackage _decode(Uint8List bytes) {
    if (bytes.length < 22 || bytes.length > maxArchiveBytes) {
      throw const FormatException('Invalid board skin package size');
    }
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes, verify: true);
    if (archive.files.isEmpty ||
        archive.files.length > BoardSkinImageSlot.values.length + 1 ||
        decoder.directory.fileHeaders.length != archive.files.length) {
      throw const FormatException('Invalid board skin package entries');
    }
    final files = <String, ArchiveFile>{};
    var totalImageBytes = 0;
    for (final file in archive.files) {
      if (!file.isFile || file.isSymbolicLink || files.containsKey(file.name)) {
        throw const FormatException('Invalid board skin package entry');
      }
      final size = file.size.toInt();
      if (file.size != size || size < 0) {
        throw const FormatException('Invalid board skin package size');
      }
      if (file.name == 'board-skin.json') {
        if (size > 64 * 1024) {
          throw const FormatException('Board skin manifest too large');
        }
      } else {
        if (!RegExp(
          r'^images/(boardBackground|startMarker|landingMarker|selectionFrame)\.(png|jpg)$',
        ).hasMatch(file.name) ||
            size > PieceImageLimits.maxBytes) {
          throw const FormatException('Invalid board skin image entry');
        }
        totalImageBytes += size;
        if (totalImageBytes > maxImageBytes) {
          throw const FormatException('Board skin images exceed limits');
        }
      }
      files[file.name] = file;
    }
    final manifestBytes = files['board-skin.json']?.readBytes();
    if (manifestBytes == null) {
      throw const FormatException('Board skin manifest missing');
    }
    final manifest = jsonDecode(utf8.decode(manifestBytes));
    if (manifest is! Map<String, dynamic> ||
        manifest.keys.toSet().difference({'schema', 'profile', 'images'}).isNotEmpty ||
        manifest['schema'] != 1 ||
        manifest['profile'] is! Map ||
        manifest['images'] is! List) {
      throw const FormatException('Invalid board skin manifest');
    }
    final profile = BoardSkinDefinition.fromJson(
      Map<String, dynamic>.from(manifest['profile'] as Map),
    );
    final imageEntries = manifest['images'] as List;
    if (imageEntries.length != files.length - 1 ||
        imageEntries.length > BoardSkinImageSlot.values.length) {
      throw const FormatException('Board skin image manifest mismatch');
    }
    final images = <BoardSkinImageSlot, Uint8List>{};
    final expected = <String>{'board-skin.json'};
    for (final value in imageEntries) {
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw const FormatException('Invalid board skin image metadata');
      }
      final entry = Map<String, dynamic>.from(value);
      if (entry.keys.toSet().difference({'slot', 'path', 'sha256'}).isNotEmpty ||
          entry['slot'] is! String ||
          entry['path'] is! String ||
          entry['sha256'] is! String) {
        throw const FormatException('Invalid board skin image metadata');
      }
      final slot = BoardSkinImageSlot.values
          .where((item) => item.name == entry['slot'])
          .firstOrNull;
      final path = entry['path'] as String;
      final file = files[path];
      if (slot == null ||
          images.containsKey(slot) ||
          !expected.add(path) ||
          file == null ||
          !path.startsWith('images/${slot.name}.')) {
        throw const FormatException('Invalid board skin image mapping');
      }
      final content = file.readBytes();
      if (content == null || sha256.convert(content).toString() != entry['sha256']) {
        throw const FormatException('Board skin image checksum mismatch');
      }
      PieceImageValidator.validate(
        SelectedPieceImage(path.substring(path.lastIndexOf('.') + 1), content),
      );
      images[slot] = content;
    }
    if (expected.length != files.length) {
      throw const FormatException('Unreferenced board skin package entry');
    }
    return BoardSkinPackage(profile: profile, images: Map.unmodifiable(images));
  }

  static String _extension(Uint8List bytes) {
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4e && bytes[3] == 0x47) return 'png';
    if (bytes.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) return 'jpg';
    throw const FormatException('Unsupported board image');
  }
}

final class BoardSkinPackage {
  const BoardSkinPackage({required this.profile, required this.images});
  final BoardSkinDefinition profile;
  final Map<BoardSkinImageSlot, Uint8List> images;
}
