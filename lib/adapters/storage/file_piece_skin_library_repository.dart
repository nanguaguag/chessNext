import 'dart:convert';
import 'dart:io';

import '../../ports/piece_skin_library.dart';

class FilePieceSkinLibraryRepository implements PieceSkinLibraryRepository {
  FilePieceSkinLibraryRepository(this.directory);
  final Future<Directory> Function() directory;

  Future<File> _file() async {
    final support = await directory();
    final folder = Directory('${support.path}/chessnext-piece-skins');
    if (await FileSystemEntity.type(folder.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException('Skin library path is a link');
    }
    await folder.create(recursive: true);
    final file = File('${folder.path}/profiles.json');
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException('Skin library manifest is a link');
    }
    return file;
  }

  @override
  Future<List<PieceSkinDefinition>> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return const [];
    }
    if (await file.length() > 64 * 1024) {
      throw const FormatException('Skin library too large');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['schema'] != 1 ||
        decoded['profiles'] is! List) {
      throw const FormatException('Invalid skin library');
    }
    final profiles = (decoded['profiles'] as List)
        .map((item) {
          if (item is! Map || item.keys.any((key) => key is! String)) {
            throw const FormatException('Invalid profile');
          }
          return PieceSkinDefinition.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
    _validate(profiles);
    return profiles;
  }

  @override
  Future<void> save(List<PieceSkinDefinition> definitions) async {
    _validate(definitions);
    final file = await _file();
    final temporary = File('${file.path}.pending');
    await temporary.writeAsString(
      jsonEncode({
        'schema': 1,
        'profiles': definitions.map((item) => item.toJson()).toList(),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  void _validate(List<PieceSkinDefinition> profiles) {
    if (profiles.length > 64 ||
        profiles.map((item) => item.id).toSet().length != profiles.length ||
        profiles.map((item) => item.name.toLowerCase()).toSet().length !=
            profiles.length) {
      throw const FormatException('Invalid skin library entries');
    }
  }
}
