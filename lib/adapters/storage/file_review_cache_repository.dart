import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../ports/review_cache_repository.dart';

/// Disposable single-window cache. Explicit records and drafts use other folders.
class FileReviewCacheRepository implements ReviewCacheRepository {
  FileReviewCacheRepository(
    this.directory, {
    this.capacity = 2048,
    this.maxBytes = 32 * 1024 * 1024,
  }) {
    if (capacity < 1 ||
        capacity > 10000 ||
        maxBytes < 1024 ||
        maxBytes > 512 * 1024 * 1024) {
      throw ArgumentError('Invalid file cache capacity');
    }
  }
  final Future<Directory> Function() directory;
  final int capacity;
  final int maxBytes;
  static const maxEntryBytes = 65536;
  final _sizes = <String, int>{};
  int _bytes = 0;
  Future<Directory>? _opening;
  Future<void> _tail = Future.value();
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _validateKey(String key) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key)) {
      throw ArgumentError('Invalid cache key');
    }
  }

  String _key(FileSystemEntity entry) =>
      entry.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), '');
  Future<Directory> _open() async {
    final folder = await Directory(
      '${(await directory()).path}/chessnext-analysis-cache',
    ).create(recursive: true);
    final existing = <(String, int, DateTime)>[];
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is Directory &&
          entry.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith('.pending-')) {
        // Only our disposable cache staging directories, never user records.
        await entry.delete(recursive: true);
      } else if (entry is File &&
          RegExp(
            r'^[a-f0-9]{64}\.json$',
          ).hasMatch(entry.uri.pathSegments.last)) {
        if (existing.length >= 10000) {
          throw const FormatException('Too many cache entries');
        }
        final stat = await entry.stat();
        existing.add((_key(entry), stat.size, stat.modified));
      }
    }
    existing.sort((a, b) => a.$3.compareTo(b.$3));
    _sizes.clear();
    _bytes = 0;
    for (final item in existing) {
      _record(item.$1, item.$2);
    }
    await _prune(folder);
    return folder;
  }

  Future<Directory> _folder() async {
    try {
      return await (_opening ??= _open());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  void _record(String key, int size) {
    _bytes -= _sizes.remove(key) ?? 0;
    _sizes[key] = size;
    _bytes += size;
  }

  void _forget(String key) {
    _bytes -= _sizes.remove(key) ?? 0;
  }

  Future<void> _prune(Directory folder) async {
    while (_sizes.length > capacity || _bytes > maxBytes) {
      final key = _sizes.keys.first;
      final file = File('${folder.path}/$key.json');
      if (await file.exists()) await file.delete();
      _forget(key);
    }
  }

  @override
  Future<CachedEngineScore?> load(String key) => _serial(() async {
    _validateKey(key);
    final folder = await _folder();
    final file = File('${folder.path}/$key.json');
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      _forget(key);
      return null;
    }
    if (type != FileSystemEntityType.file) {
      throw const FormatException('Cache entry must be a regular file');
    }
    try {
      final length = await file.length();
      if (length > maxEntryBytes) {
        throw const FormatException('Cache entry too large');
      }
      final bytes = await file
          .openRead(0, maxEntryBytes + 1)
          .fold<List<int>>([], (all, part) => all..addAll(part));
      if (bytes.length > maxEntryBytes) {
        throw const FormatException('Cache entry too large');
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic> ||
          json['schema'] != 1 ||
          json['payload'] is! Map<String, dynamic> ||
          json['sha256'] is! String) {
        throw const FormatException('Invalid cache envelope');
      }
      final payload = json['payload'] as Map<String, dynamic>;
      if (sha256.convert(utf8.encode(jsonEncode(payload))).toString() !=
          json['sha256']) {
        throw const FormatException('Cache checksum mismatch');
      }
      final score = CachedEngineScore.fromJson(payload);
      if (score.key != key) throw const FormatException('Cache key mismatch');
      _record(key, bytes.length);
      await _prune(folder);
      return score;
    } on FormatException {
      // Reproducible analysis only: remove the poisoned entry and report the miss
      // as an error so the application can explain why it is recomputing.
      await file.delete();
      _forget(key);
      rethrow;
    }
  });
  @override
  Future<void> save(CachedEngineScore score) => _serial(() async {
    _validateKey(score.key);
    final payload = score.toJson();
    final bytes = utf8.encode(
      jsonEncode({
        'schema': 1,
        'payload': payload,
        'sha256': sha256.convert(utf8.encode(jsonEncode(payload))).toString(),
      }),
    );
    if (bytes.length > maxEntryBytes || bytes.length > maxBytes) {
      throw const FormatException('Cache score too large');
    }
    final folder = await _folder();
    final staging = await folder.createTemp('.pending-');
    try {
      final file = File('${staging.path}/score.json');
      await file.writeAsBytes(bytes, flush: true);
      await file.rename('${folder.path}/${score.key}.json');
      _record(score.key, bytes.length);
      await _prune(folder);
    } finally {
      await staging.delete(recursive: true);
    }
  });
  @override
  Future<void> remove(String key) => _serial(() async {
    _validateKey(key);
    final folder = await _folder();
    final file = File('${folder.path}/$key.json');
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      await file.delete();
    } else if (type != FileSystemEntityType.notFound) {
      throw const FormatException('Cache entry must be a regular file');
    }
    _forget(key);
  });
}
