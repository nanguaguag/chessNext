import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../application/piece_image_validator.dart';
import '../../ports/piece_images.dart';
import '../../ports/piece_skin_library.dart';

class FilePieceImageRepository implements PieceImageRepository {
  FilePieceImageRepository(this.directory);

  final Future<Directory> Function() directory;

  Future<Directory> _folder(String skinId) async {
    if (!PieceSkin.values.any((skin) => skin.name == skinId) &&
        !PieceSkinDefinition.isValidId(skinId)) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    final support = await directory();
    final base = Directory('${support.path}/chessnext-piece-images');
    if (await FileSystemEntity.type(base.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    final folder = Directory('${base.path}/$skinId');
    if (await FileSystemEntity.type(folder.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    await folder.create(recursive: true);
    return folder;
  }

  File _manifest(Directory folder, PieceImageSlot slot) =>
      File('${folder.path}/${slot.name}.json');

  Future<Map<String, String>?> _readManifest(
    Directory folder,
    PieceImageSlot slot,
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
  Future<Map<String, Map<PieceImageSlot, Uint8List>>> load() async {
    final support = await directory();
    final base = Directory('${support.path}/chessnext-piece-images');
    if (await FileSystemEntity.type(base.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    await base.create(recursive: true);
    final skinIds = <String>{for (final skin in PieceSkin.values) skin.name};
    await for (final entity in base.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final id = entity.uri.pathSegments.where((part) => part.isNotEmpty).last;
      if (PieceSkinDefinition.isValidId(id)) skinIds.add(id);
    }
    final result = <String, Map<PieceImageSlot, Uint8List>>{};
    for (final skinId in skinIds) {
      final folder = await _folder(skinId);
      final images = <PieceImageSlot, Uint8List>{};
      for (final slot in PieceImageSlot.values) {
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
    PieceImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    final selected = SelectedPieceImage(extension, bytes);
    PieceImageValidator.validate(selected);
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
  Future<void> remove(String skinId, PieceImageSlot slot) async {
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
    if (PieceSkin.values.any((skin) => skin.name == skinId)) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    final folder = await _folder(skinId);
    await folder.delete(recursive: true);
  }

  @override
  Future<void> cloneSkin(String sourceId, String destinationId) async {
    if (PieceSkin.values.any((skin) => skin.name == destinationId)) {
      throw const PieceImageException(PieceImageFailure.write);
    }
    final source = await _folder(sourceId);
    final destination = await _folder(destinationId);
    for (final slot in PieceImageSlot.values) {
      final manifest = await _readManifest(source, slot);
      if (manifest == null) continue;
      final sourceFile = File('${source.path}/${manifest['file']}');
      if (await FileSystemEntity.type(sourceFile.path, followLinks: false) !=
          FileSystemEntityType.file) {
        continue;
      }
      final targetName =
          '${slot.name}-${DateTime.now().microsecondsSinceEpoch}.${manifest['extension']}';
      await sourceFile.copy('${destination.path}/$targetName');
      await File('${destination.path}/${slot.name}.json').writeAsString(
        jsonEncode({
          'schema': 1,
          'extension': manifest['extension'],
          'file': targetName,
        }),
        flush: true,
      );
    }
  }
}
