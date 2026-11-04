import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../ports/piece_skin_catalog.dart';

const _maxBodyBytes = 2 * 1024 * 1024;
const _maxCacheEntries = 24;

/// A bounded cache of successful catalog pages. Search keys are hashed so
/// service URLs and queries are not exposed in filenames.
final class FilePieceSkinCatalogCache implements PieceSkinCatalogCache {
  FilePieceSkinCatalogCache(this._supportDirectory);

  final Future<Directory> Function() _supportDirectory;

  Future<Directory> _directory() async {
    final directory = Directory(
      '${(await _supportDirectory()).path}/skin_catalog_cache',
    );
    await directory.create(recursive: true);
    return directory;
  }

  File _file(Directory directory, String key) =>
      File('${directory.path}/${sha256.convert(utf8.encode(key))}.json');

  @override
  Future<CachedPieceSkinCatalogResponse?> read(String key) async {
    final file = _file(await _directory(), key);
    try {
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file) {
        return null;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) return null;
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic> ||
          value.keys.toSet().difference({
            'schema',
            'cachedAt',
            'body',
          }).isNotEmpty ||
          value['schema'] != 1 ||
          value['cachedAt'] is! String ||
          value['body'] is! String) {
        return null;
      }
      final cachedAt = DateTime.tryParse(value['cachedAt'] as String);
      final body = value['body'] as String;
      if (cachedAt == null || utf8.encode(body).length > _maxBodyBytes) {
        return null;
      }
      await file.setLastModified(DateTime.now());
      return CachedPieceSkinCatalogResponse(body, cachedAt.toUtc());
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String key, String body, DateTime cachedAt) async {
    final bodyBytes = utf8.encode(body);
    if (bodyBytes.length > _maxBodyBytes) return;
    final directory = await _directory();
    final file = _file(directory, key);
    final temporary = File(
      '${file.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final json = jsonEncode({
      'schema': 1,
      'cachedAt': cachedAt.toUtc().toIso8601String(),
      'body': body,
    });
    try {
      await temporary.writeAsString(json, encoding: utf8, flush: true);
      await temporary.rename(file.path);
      await _prune(directory, keep: file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _prune(Directory directory, {required String keep}) async {
    final entries = <File>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File &&
          RegExp(
            r'^[0-9a-f]{64}\.json$',
          ).hasMatch(entity.uri.pathSegments.last)) {
        entries.add(entity);
      }
    }
    final modified = <File, DateTime>{
      for (final entry in entries) entry: await entry.lastModified(),
    };
    entries.sort((a, b) {
      if (a.path == keep) return -1;
      if (b.path == keep) return 1;
      return modified[b]!.compareTo(modified[a]!);
    });
    for (final stale in entries.skip(_maxCacheEntries)) {
      await stale.delete();
    }
  }
}
