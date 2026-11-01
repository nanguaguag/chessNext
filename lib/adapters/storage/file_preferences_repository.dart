import 'dart:convert';
import 'dart:io';
import '../../application/app_preferences.dart';
import '../../ports/preferences_repository.dart';

class FilePreferencesRepository implements PreferencesRepository {
  FilePreferencesRepository(this.directory);
  final Future<Directory> Function() directory;
  Future<Directory> _folder() async => Directory(
    '${(await directory()).path}/chessnext-settings',
  ).create(recursive: true);
  Future<AppPreferences> _read(File file) async {
    if (await file.length() > 65536) {
      throw const FormatException('Settings too large');
    }
    final json = jsonDecode(await file.readAsString());
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected settings object');
    }
    return AppPreferences.fromJson(json);
  }

  @override
  Future<LoadedPreferences?> load() async {
    final folder = await _folder();
    final primary = File('${folder.path}/preferences.json');
    final backup = File('${folder.path}/preferences.bak');
    if (!await primary.exists() && !await backup.exists()) return null;
    try {
      return LoadedPreferences(await _read(primary));
    } on FileSystemException {
      return LoadedPreferences(await _read(backup), recovered: true);
    } on FormatException {
      return LoadedPreferences(await _read(backup), recovered: true);
    }
  }

  @override
  Future<void> save(AppPreferences value) async {
    final folder = await _folder();
    final primary = File('${folder.path}/preferences.json');
    final temp = await folder.createTemp('.save-');
    try {
      final pending = File('${temp.path}/preferences.json');
      await pending.writeAsString(jsonEncode(value.toJson()), flush: true);
      if (await primary.exists()) {
        try {
          await _read(primary);
          await primary.copy('${folder.path}/preferences.bak');
        } on FormatException {
          final archive = await folder.createTemp('.damaged-');
          await primary.copy('${archive.path}/original.json');
        }
      }
      await pending.rename(primary.path);
    } finally {
      await temp.delete(recursive: true);
    }
  }
}
