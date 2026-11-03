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

  static PieceSkinPackage decode(Uint8List bytes) {
    try {
      return _decode(bytes);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid skin package');
    }
  }

  static PieceSkinPackage _decode(Uint8List bytes) {
    if (bytes.length < 22 || bytes.length > maxArchiveBytes) {
      throw const FormatException('Invalid skin package size');
    }
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes, verify: true);
    if (archive.files.isEmpty ||
        archive.files.length > maxImages + 1 ||
        decoder.directory.fileHeaders.length != archive.files.length) {
      throw const FormatException('Invalid skin package entries');
    }
    final files = <String, ArchiveFile>{};
    var totalImageBytes = 0;
    for (final file in archive.files) {
      if (!file.isFile || file.isSymbolicLink || files.containsKey(file.name)) {
        throw const FormatException('Invalid skin package entry');
      }
      final fileSize = file.size.toInt();
      if (file.size != fileSize || fileSize < 0) {
        throw const FormatException('Invalid skin package entry size');
      }
      if (file.name == 'skin.json') {
        if (fileSize > 64 * 1024) {
          throw const FormatException('Skin manifest too large');
        }
      } else {
        final match = RegExp(
          r'^images/([a-zA-Z][a-zA-Z0-9]*)\.(png|jpg)$',
        ).firstMatch(file.name);
        if (match == null || fileSize > PieceImageLimits.maxBytes) {
          throw const FormatException('Invalid skin image entry');
        }
        totalImageBytes += fileSize;
        if (totalImageBytes > maxImageBytes) {
          throw const FormatException('Skin images exceed limits');
        }
      }
      files[file.name] = file;
    }
    final manifestFile = files['skin.json'];
    final manifestBytes = manifestFile?.readBytes();
    if (manifestBytes == null) {
      throw const FormatException('Skin manifest missing');
    }
    final decoded = jsonDecode(utf8.decode(manifestBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({
          'schema',
          'profile',
          'images',
        }).isNotEmpty ||
        decoded['schema'] != 1 ||
        decoded['profile'] is! Map ||
        decoded['images'] is! List) {
      throw const FormatException('Invalid skin manifest');
    }
    final profileMap = Map<String, dynamic>.from(decoded['profile'] as Map);
    final profile = PieceSkinDefinition.fromJson(profileMap);
    final imageEntries = decoded['images'] as List;
    if (imageEntries.length != files.length - 1 ||
        imageEntries.length > maxImages) {
      throw const FormatException('Skin image manifest mismatch');
    }
    final images = <PieceImageSlot, Uint8List>{};
    final expectedPaths = <String>{'skin.json'};
    for (final item in imageEntries) {
      if (item is! Map || item.keys.any((key) => key is! String)) {
        throw const FormatException('Invalid skin image metadata');
      }
      final entry = Map<String, dynamic>.from(item);
      if (entry.keys.toSet().difference({
            'slot',
            'path',
            'sha256',
          }).isNotEmpty ||
          entry['slot'] is! String ||
          entry['path'] is! String ||
          entry['sha256'] is! String) {
        throw const FormatException('Invalid skin image metadata');
      }
      final slot = PieceImageSlot.values
          .where((value) => value.name == entry['slot'])
          .firstOrNull;
      final path = entry['path'] as String;
      final file = files[path];
      if (slot == null ||
          images.containsKey(slot) ||
          !expectedPaths.add(path) ||
          file == null ||
          !path.startsWith('images/${slot.name}.')) {
        throw const FormatException('Invalid skin image mapping');
      }
      final imageBytes = file.readBytes();
      if (imageBytes == null ||
          sha256.convert(imageBytes).toString() != entry['sha256']) {
        throw const FormatException('Skin image checksum mismatch');
      }
      final extension = path.substring(path.lastIndexOf('.') + 1);
      PieceImageValidator.validate(SelectedPieceImage(extension, imageBytes));
      images[slot] = imageBytes;
    }
    if (expectedPaths.length != files.length) {
      throw const FormatException('Unreferenced skin package entry');
    }
    return PieceSkinPackage(profile: profile, images: Map.unmodifiable(images));
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

final class PieceSkinPackage {
  const PieceSkinPackage({required this.profile, required this.images});
  final PieceSkinDefinition profile;
  final Map<PieceImageSlot, Uint8List> images;
}
