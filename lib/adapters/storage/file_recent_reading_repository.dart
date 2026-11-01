import 'dart:convert';
import 'dart:io';
import '../../ports/recent_reading_repository.dart';

class FileRecentReadingRepository implements RecentReadingRepository {
  FileRecentReadingRepository(this.directory);
  final Future<Directory> Function() directory;
  static const maximumBytes = 2 * 1024 * 1024;
  Future<Directory> _folder() async => Directory(
    '${(await directory()).path}/chessnext-reading',
  ).create(recursive: true);
  Future<List<RecentReading>> _read(File file) async {
    if (await file.length() > maximumBytes) {
      throw const FormatException('Reading file too large');
    }
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map<String, dynamic> ||
        raw['schema'] != 1 ||
        raw['entries'] is! List ||
        (raw['entries'] as List).length > RecentReadingRepository.maximum) {
      throw const FormatException('Invalid reading schema');
    }
    final entries = (raw['entries'] as List)
        .map(RecentReading.fromJson)
        .toList();
    if (entries.map((e) => e.gameId).toSet().length != entries.length) {
      throw const FormatException('Duplicate reading IDs');
    }
    return entries;
  }

  @override
  Future<LoadedRecentReadings> load() async {
    final folder = await _folder();
    final primary = File('${folder.path}/recent.json');
    final backup = File('${folder.path}/recent.bak');
    if (!await primary.exists() && !await backup.exists()) {
      return LoadedRecentReadings([]);
    }
    try {
      return LoadedRecentReadings(await _read(primary));
    } on FileSystemException {
      return LoadedRecentReadings(await _read(backup), recovered: true);
    } on FormatException {
      return LoadedRecentReadings(await _read(backup), recovered: true);
    }
  }

  Future<void> _tail = Future.value();
  @override
  Future<void> save(List<RecentReading> entries) {
    // Freeze before awaiting, and serialize adapter calls as well as controller writes.
    final snapshot = List<RecentReading>.unmodifiable(entries);
    final result = _tail.then((_) => _save(snapshot));
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _save(List<RecentReading> entries) async {
    if (entries.length > RecentReadingRepository.maximum ||
        entries.map((e) => e.gameId).toSet().length != entries.length) {
      throw ArgumentError('Invalid reading count');
    }
    final bytes = utf8.encode(
      jsonEncode({
        'schema': 1,
        'entries': entries.map((e) => e.toJson()).toList(),
      }),
    );
    if (bytes.length > maximumBytes) {
      throw ArgumentError('Reading data too large');
    }
    final folder = await _folder();
    final primary = File('${folder.path}/recent.json');
    final temp = await folder.createTemp('.save-');
    try {
      final pending = File('${temp.path}/recent.json');
      await pending.writeAsBytes(bytes, flush: true);
      if (await primary.exists()) {
        try {
          await _read(primary);
          await primary.copy('${folder.path}/recent.bak');
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
