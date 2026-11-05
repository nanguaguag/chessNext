import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skin_catalog_server/skin_catalog_server.dart';

void main() {
  late Directory root;
  final valid = {
    'schema': 1,
    'releases': [
      {
        'version': '1.2.0',
        'build': 12,
        'publishedAt': '2026-11-05T00:00:00Z',
        'notes': 'A release.',
      },
      {
        'version': '1.1.0',
        'build': 11,
        'publishedAt': '2026-10-05T00:00:00Z',
        'notes': 'Earlier release.',
      },
    ],
  };

  setUp(() async {
    root = await Directory.systemTemp.createTemp('release-manifest-');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<void> write(Object value) =>
      File('${root.path}/releases.json').writeAsString(jsonEncode(value));

  test(
    'loads newest-first release history as immutable public metadata',
    () async {
      await write(valid);
      final manifest = await ReleaseManifest.load(root);
      expect(manifest.current.version, '1.2.0');
      expect(manifest.current.build, 12);
      expect(manifest.releases, hasLength(2));
      expect(manifest.toJson()['schema'], 1);
      expect(
        () => manifest.releases.add(manifest.current),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'rejects invalid, unknown, duplicate or out-of-order release data',
    () async {
      final invalidManifests = [
        {...valid, 'unexpected': true},
        {
          'schema': 1,
          'releases': [
            {
              ...(valid['releases'] as List).first as Map<String, Object>,
              'build': 0,
            },
          ],
        },
        {
          'schema': 1,
          'releases': [
            (valid['releases'] as List)[1],
            (valid['releases'] as List)[0],
          ],
        },
        {
          'schema': 1,
          'releases': [
            (valid['releases'] as List).first,
            (valid['releases'] as List).first,
          ],
        },
        {
          'schema': 1,
          'releases': [
            {
              ...(valid['releases'] as List).first as Map<String, Object>,
              'notes': 'x' * 4001,
            },
          ],
        },
      ];
      for (final invalid in invalidManifests) {
        await write(invalid);
        await expectLater(ReleaseManifest.load(root), throwsFormatException);
      }
    },
  );
}
