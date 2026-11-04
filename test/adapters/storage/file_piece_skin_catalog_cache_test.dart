import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_next/adapters/storage/file_piece_skin_catalog_cache.dart';

void main() {
  late Directory supportDirectory;
  late FilePieceSkinCatalogCache cache;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'skin-catalog-cache-',
    );
    cache = FilePieceSkinCatalogCache(() async => supportDirectory);
  });

  tearDown(() => supportDirectory.delete(recursive: true));

  test('persists page body and timestamp under a nonrevealing key', () async {
    final cachedAt = DateTime.utc(2026, 11, 4, 8);
    const key = 'https://catalog.example.test/v1/catalog?q=red';
    await cache.write(key, '{"schema":1}', cachedAt);

    final reopened = FilePieceSkinCatalogCache(() async => supportDirectory);
    final result = await reopened.read(key);
    expect(result?.body, '{"schema":1}');
    expect(result?.cachedAt, cachedAt);
    final names = Directory(
      '${supportDirectory.path}/skin_catalog_cache',
    ).listSync().map((entity) => entity.uri.pathSegments.last);
    expect(names, everyElement(matches(RegExp(r'^[0-9a-f]{64}\.json$'))));
  });

  test('keeps at most 24 cache pages and retains the newest write', () async {
    for (var i = 0; i < 25; i++) {
      await cache.write('query-$i', '{"page":$i}', DateTime.utc(2026));
    }
    final files = Directory(
      '${supportDirectory.path}/skin_catalog_cache',
    ).listSync().whereType<File>();
    expect(files, hasLength(24));
    expect((await cache.read('query-24'))?.body, '{"page":24}');
  });
}
