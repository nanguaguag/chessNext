import 'dart:convert';
import 'dart:io';

import '../../ports/board_skin_library.dart';

final class FileBoardSkinLibraryRepository
    implements BoardSkinLibraryRepository {
  FileBoardSkinLibraryRepository(this.directory);

  final Future<Directory> Function() directory;

  Future<Directory> _folder() async {
    final support = await directory();
    final folder = Directory('${support.path}/chessnext-board-skins');
    if (await FileSystemEntity.type(folder.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException('Board skin directory cannot be a link');
    }
    await folder.create(recursive: true);
    return folder;
  }

  File _manifest(Directory folder) => File('${folder.path}/profiles.json');

  @override
  Future<List<BoardSkinDefinition>> load() async {
    final folder = await _folder();
    final file = _manifest(folder);
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return const [];
    }
    if (await file.length() > 256 * 1024) {
      throw const FormatException('Board skin manifest is too large');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference({'schema', 'profiles'}).isNotEmpty ||
        decoded['schema'] != 1 ||
        decoded['profiles'] is! List ||
        (decoded['profiles'] as List).length > 64) {
      throw const FormatException('Invalid board skin manifest');
    }
    final profiles = (decoded['profiles'] as List)
        .map(
          (item) => item is Map<String, dynamic>
              ? BoardSkinDefinition.fromJson(item)
              : throw const FormatException('Invalid board skin profile'),
        )
        .toList(growable: false);
    _validate(profiles);
    return profiles;
  }

  @override
  Future<void> save(List<BoardSkinDefinition> profiles) async {
    _validate(profiles);
    final folder = await _folder();
    final temp = File(
      '${folder.path}/.profiles-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final destination = _manifest(folder);
    await temp.writeAsString(
      jsonEncode({
        'schema': 1,
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
      }),
      flush: true,
    );
    try {
      if (await FileSystemEntity.type(destination.path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const FileSystemException('Board skin manifest cannot be a link');
      }
      await temp.rename(destination.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  void _validate(List<BoardSkinDefinition> profiles) {
    if (profiles.length > 64 ||
        profiles.map((profile) => profile.id).toSet().length !=
            profiles.length ||
        profiles.map((profile) => profile.name.toLowerCase()).toSet().length !=
            profiles.length) {
      throw const FormatException('Invalid board skin profile collection');
    }
  }
}
