import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../application/piece_image_validator.dart';
import '../../ports/board_skin_images.dart';
import '../../ports/piece_images.dart';

class FileBoardSkinImageRepository implements BoardSkinImageRepository {
  FileBoardSkinImageRepository(this.directory);

  final Future<Directory> Function() directory;

  Future<Directory> _base() async {
    final support = await directory();
    final base = Directory('${support.path}/chessnext-board-skin-images');
    if (await FileSystemEntity.type(base.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    await base.create(recursive: true);
    return base;
  }

  Future<Directory> _folder(String skinId) async {
    if (!BoardSkin.values.any((skin) => skin.name == skinId) &&
        !RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(skinId)) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    final base = await _base();
    final folder = Directory('${base.path}/$skinId');
    if (await FileSystemEntity.type(folder.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    await folder.create(recursive: true);
    return folder;
  }

  File _manifest(Directory folder, BoardSkinImageSlot slot) =>
      File('${folder.path}/${slot.name}.json');

  Future<Map<String, String>?> _readManifest(
    Directory folder,
    BoardSkinImageSlot slot,
  ) async {
    final manifest = _manifest(folder, slot);
    if (await FileSystemEntity.type(manifest.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    if (await manifest.length() > 256) return null;
    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['schema'] != 1) {
        return null;
      }
      final extension = decoded['extension'];
      final name = decoded['file'];
      if (extension is! String ||
          !const {'png', 'jpg', 'jpeg'}.contains(extension) ||
          name is! String ||
          !RegExp('^${slot.name}-[0-9]+\\.$extension\$').hasMatch(name)) {
        return null;
      }
      return {'extension': extension, 'file': name};
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, Map<BoardSkinImageSlot, Uint8List>>> load() async {
    final result = <String, Map<BoardSkinImageSlot, Uint8List>>{};
    final base = await _base();
    await for (final entity in base.list(followLinks: false)) {
      final skinId = entity.uri.pathSegments.lastWhere(
        (segment) => segment.isNotEmpty,
      );
      if (entity is! Directory ||
          (!BoardSkin.values.any((skin) => skin.name == skinId) &&
              !RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(skinId)) ||
          await FileSystemEntity.type(entity.path, followLinks: false) !=
              FileSystemEntityType.directory) {
        continue;
      }
      final folder = entity;
      final images = <BoardSkinImageSlot, Uint8List>{};
      for (final slot in BoardSkinImageSlot.values) {
        final manifest = await _readManifest(folder, slot);
        if (manifest == null) continue;
        final file = File('${folder.path}/${manifest['file']}');
        if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file) {
          continue;
        }
        if (await file.length() > PieceImageLimits.maxBytes) continue;
        try {
          final bytes = await file.readAsBytes();
          PieceImageValidator.validate(
            SelectedPieceImage(manifest['extension']!, bytes),
          );
          images[slot] = bytes;
        } on PieceImageException {
          // Ignore damaged local images without making the board unavailable.
        }
      }
      if (images.isNotEmpty) result[skinId] = images;
    }
    return result;
  }

  @override
  Future<void> save(
    String skinId,
    BoardSkinImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    PieceImageValidator.validate(SelectedPieceImage(extension, bytes));
    final folder = await _folder(skinId);
    final previous = await _readManifest(folder, slot);
    final staging = await folder.createTemp('.${slot.name}-pending-');
    final name =
        '${slot.name}-${DateTime.now().microsecondsSinceEpoch}.$extension';
    try {
      await File('${staging.path}/$name').writeAsBytes(bytes, flush: true);
      await File('${staging.path}/${slot.name}.json').writeAsString(
        jsonEncode({'schema': 1, 'extension': extension, 'file': name}),
        flush: true,
      );
      await File('${staging.path}/$name').rename('${folder.path}/$name');
      await File(
        '${staging.path}/${slot.name}.json',
      ).rename(_manifest(folder, slot).path);
      if (previous != null && previous['file'] != name) {
        final old = File('${folder.path}/${previous['file']}');
        if (await FileSystemEntity.type(old.path, followLinks: false) ==
            FileSystemEntityType.file) {
          await old.delete();
        }
      }
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  @override
  Future<void> remove(String skinId, BoardSkinImageSlot slot) async {
    final folder = await _folder(skinId);
    final manifest = _manifest(folder, slot);
    final previous = await _readManifest(folder, slot);
    if (await FileSystemEntity.type(manifest.path, followLinks: false) ==
        FileSystemEntityType.file) {
      await manifest.delete();
    }
    if (previous != null) {
      final image = File('${folder.path}/${previous['file']}');
      if (await FileSystemEntity.type(image.path, followLinks: false) ==
          FileSystemEntityType.file) {
        await image.delete();
      }
    }
  }

  @override
  Future<void> removeSkin(String skinId) async {
    final folder = await _folder(skinId);
    if (await FileSystemEntity.type(folder.path, followLinks: false) ==
        FileSystemEntityType.directory) {
      await folder.delete(recursive: true);
    }
  }

  @override
  Future<void> cloneSkin(String sourceId, String destinationId) async {
    if (!BoardSkin.values.any((skin) => skin.name == sourceId) &&
        !RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(sourceId)) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    final source = await _folder(sourceId);
    try {
      for (final slot in BoardSkinImageSlot.values) {
        final manifest = await _readManifest(source, slot);
        if (manifest == null) continue;
        final file = File('${source.path}/${manifest['file']}');
        if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file) {
          continue;
        }
        final bytes = await file.readAsBytes();
        PieceImageValidator.validate(
          SelectedPieceImage(manifest['extension']!, bytes),
        );
        await save(destinationId, slot, manifest['extension']!, bytes);
      }
    } catch (_) {
      await removeSkin(destinationId);
      rethrow;
    }
  }

  @override
  Future<void> pruneCustomSkins(Set<String> retainedIds) async {
    final base = await _base();
    await for (final entity in base.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final id = entity.uri.pathSegments.lastWhere(
        (segment) => segment.isNotEmpty,
      );
      if (!RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(id) ||
          retainedIds.contains(id) ||
          await FileSystemEntity.type(entity.path, followLinks: false) !=
              FileSystemEntityType.directory) {
        continue;
      }
      await entity.delete(recursive: true);
    }
  }
}
