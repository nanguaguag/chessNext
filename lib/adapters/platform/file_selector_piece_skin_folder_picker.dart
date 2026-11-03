import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../application/piece_skin_package_codec.dart';
import '../../ports/piece_skin_folder_picker.dart';
import '../../ports/piece_skin_package_picker.dart';

typedef SkinFolderChooser = Future<String?> Function();

class FileSelectorPieceSkinFolderPicker implements PieceSkinFolderPicker {
  FileSelectorPieceSkinFolderPicker({SkinFolderChooser? chooser})
    : _chooser = chooser ?? getDirectoryPath;
  final SkinFolderChooser _chooser;

  @override
  Future<Uint8List?> pickFolderPackage() async {
    try {
      final path = await _chooser();
      if (path == null) return null;
      final root = Directory(path);
      if (await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const FormatException('Not a directory');
      }
      final entries = <String, List<int>>{};
      var total = 0;
      final rootItems = await _boundedEntries(root, 2);
      for (final entity in rootItems) {
        final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (name == 'skin.json' && entity is File) {
          total += await _addFile(entity, name, entries, 64 * 1024);
        } else if (name == 'images' && entity is Directory) {
          if (await FileSystemEntity.type(entity.path, followLinks: false) !=
              FileSystemEntityType.directory) {
            throw const FormatException('Invalid images directory');
          }
          final images = await _boundedEntries(
            entity,
            PieceSkinPackageCodec.maxImages,
          );
          for (final image in images) {
            final leaf = image.uri.pathSegments.where((s) => s.isNotEmpty).last;
            final archivePath = 'images/$leaf';
            if (image is! File ||
                !RegExp(r'^[a-zA-Z][a-zA-Z0-9]*\.(png|jpg)$').hasMatch(leaf)) {
              throw const FormatException('Unexpected folder entry');
            }
            total += await _addFile(
              image,
              archivePath,
              entries,
              PieceImageLimit.maxBytes,
            );
          }
        } else {
          throw const FormatException('Unexpected folder entry');
        }
      }
      if (!entries.containsKey('skin.json') ||
          total > PieceSkinPackageCodec.maxImageBytes + 64 * 1024) {
        throw const FormatException('Folder package exceeds limits');
      }
      final archive = Archive();
      for (final entry in entries.entries) {
        archive.addFile(
          ArchiveFile(entry.key, entry.value.length, entry.value),
        );
      }
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      if (bytes.length > PieceSkinPackageCodec.maxArchiveBytes) {
        throw const FormatException('Folder package exceeds limits');
      }
      return bytes;
    } on PieceSkinPackageReadException {
      rethrow;
    } on MissingPluginException {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.unavailable,
      );
    } on UnsupportedError {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.unavailable,
      );
    } catch (_) {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.read,
      );
    }
  }

  Future<int> _addFile(
    File file,
    String path,
    Map<String, List<int>> entries,
    int limit,
  ) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FormatException('Links are not accepted');
    }
    final length = await file.length();
    if (length > limit) throw const FormatException('File too large');
    final bytes = await file.readAsBytes();
    if (bytes.length != length || entries.containsKey(path)) {
      throw const FormatException('Invalid folder file');
    }
    entries[path] = bytes;
    return bytes.length;
  }

  Future<List<FileSystemEntity>> _boundedEntries(
    Directory directory,
    int limit,
  ) async {
    final entries = <FileSystemEntity>[];
    await for (final entry in directory.list(followLinks: false)) {
      if (entries.length >= limit) {
        throw const FormatException('Too many folder entries');
      }
      entries.add(entry);
    }
    return entries;
  }
}

abstract final class PieceImageLimit {
  static const maxBytes = 512 * 1024;
}
