import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'piece_skin_package_codec.dart';

/// Project-defined bounded ZIP containing several validated single-skin ZIPs.
final class PieceSkinCollectionPackageCodec {
  static const maxSkins = 16;
  static const maxArchiveBytes = 8 * 1024 * 1024;
  static const _maxManifestBytes = 64 * 1024;

  static Uint8List encode(List<PieceSkinPackage> packages) {
    if (packages.length < 2 || packages.length > maxSkins) {
      throw const FormatException('Invalid skin collection count');
    }
    final names = <String>{};
    final archive = Archive();
    final entries = <Map<String, Object>>[];
    for (var index = 0; index < packages.length; index++) {
      final package = packages[index];
      final normalizedName = package.profile.name.trim().toLowerCase();
      if (!names.add(normalizedName)) {
        throw const FormatException('Duplicate skin collection name');
      }
      final bytes = PieceSkinPackageCodec.encode(
        package.profile,
        package.images,
      );
      final path = 'skins/${index.toString().padLeft(2, '0')}.zip';
      entries.add({
        'id': package.profile.id,
        'name': package.profile.name,
        'path': path,
        'sha256': sha256.convert(bytes).toString(),
      });
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    final manifest = utf8.encode(jsonEncode({'schema': 1, 'skins': entries}));
    archive.addFile(ArchiveFile('collection.json', manifest.length, manifest));
    final result = Uint8List.fromList(ZipEncoder().encode(archive));
    if (result.length > maxArchiveBytes) {
      throw const FormatException('Skin collection exceeds size limit');
    }
    return result;
  }

  static PieceSkinCollectionPackage decode(Uint8List bytes) {
    try {
      return _decode(bytes);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid skin collection package');
    }
  }

  static PieceSkinCollectionPackage _decode(Uint8List bytes) {
    if (bytes.length < 22 || bytes.length > maxArchiveBytes) {
      throw const FormatException('Invalid collection size');
    }
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(bytes, verify: true);
    if (archive.files.length < 3 ||
        archive.files.length > maxSkins + 1 ||
        decoder.directory.fileHeaders.length != archive.files.length) {
      throw const FormatException('Invalid collection entries');
    }
    final files = <String, ArchiveFile>{};
    for (final file in archive.files) {
      final fileSize = file.size.toInt();
      if (!file.isFile ||
          file.isSymbolicLink ||
          files.containsKey(file.name) ||
          file.size != fileSize ||
          fileSize < 0 ||
          fileSize > maxArchiveBytes) {
        throw const FormatException('Invalid collection entry');
      }
      files[file.name] = file;
    }
    final manifestFile = files['collection.json'];
    if (manifestFile == null || manifestFile.size > _maxManifestBytes) {
      throw const FormatException('Missing or oversized collection manifest');
    }
    final manifestBytes = manifestFile.readBytes();
    if (manifestBytes == null) {
      throw const FormatException('Unreadable collection manifest');
    }
    final decoded = jsonDecode(utf8.decode(manifestBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({'schema', 'skins'}).isNotEmpty ||
        decoded['schema'] != 1 ||
        decoded['skins'] is! List) {
      throw const FormatException('Invalid collection manifest');
    }
    final metadata = decoded['skins'] as List;
    if (metadata.length < 2 ||
        metadata.length > maxSkins ||
        metadata.length != files.length - 1) {
      throw const FormatException('Invalid collection profile count');
    }
    final expectedPaths = <String>{'collection.json'};
    final names = <String>{};
    final packages = <PieceSkinPackage>[];
    for (final item in metadata) {
      if (item is! Map || item.keys.any((key) => key is! String)) {
        throw const FormatException('Invalid collection profile metadata');
      }
      final entry = Map<String, dynamic>.from(item);
      if (entry.keys.toSet().difference({
            'id',
            'name',
            'path',
            'sha256',
          }).isNotEmpty ||
          entry['id'] is! String ||
          entry['name'] is! String ||
          entry['path'] is! String ||
          entry['sha256'] is! String) {
        throw const FormatException('Invalid collection profile metadata');
      }
      final path = entry['path'] as String;
      final file = files[path];
      final id = entry['id'] as String;
      final name = entry['name'] as String;
      final expectedPath =
          'skins/${packages.length.toString().padLeft(2, '0')}.zip';
      if (path != expectedPath ||
          !expectedPaths.add(path) ||
          file == null ||
          !RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
          name.trim().isEmpty ||
          !names.add(name.trim().toLowerCase()) ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(entry['sha256'] as String)) {
        throw const FormatException('Invalid collection profile');
      }
      final packageBytes = file.readBytes();
      if (packageBytes == null ||
          sha256.convert(packageBytes).toString() != entry['sha256']) {
        throw const FormatException('Collection profile checksum mismatch');
      }
      final package = PieceSkinPackageCodec.decode(packageBytes);
      if (package.profile.id != id || package.profile.name != name) {
        throw const FormatException('Collection profile identity mismatch');
      }
      packages.add(package);
    }
    if (expectedPaths.length != files.length) {
      throw const FormatException('Unreferenced collection entry');
    }
    return PieceSkinCollectionPackage(List.unmodifiable(packages));
  }
}

final class PieceSkinCollectionPackage {
  const PieceSkinCollectionPackage(this.packages);
  final List<PieceSkinPackage> packages;
}
