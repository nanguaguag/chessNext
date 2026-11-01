import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:chess_next/adapters/storage/file_review_cache_repository.dart';
import 'package:chess_next/ports/review_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

CachedEngineScore sample(String c, {int score = 25}) => CachedEngineScore(
  key: c * 64,
  info: EngineInfo(
    token: 9,
    depth: 8,
    multiPv: 1,
    score: score,
    isMate: false,
    pv: [Move.parse('h2e2'), Move.parse('b9c7')],
    nodes: 2000,
    timeMs: 30,
    nps: 10000,
  ),
);
void main() {
  late Directory directory;
  late FileReviewCacheRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('chessnext-cache-');
    repository = FileReviewCacheRepository(() async => directory);
  });
  tearDown(() => directory.delete(recursive: true));
  File file(String c) =>
      File('${directory.path}/chessnext-analysis-cache/${c * 64}.json');
  Future<void> writePayload(
    String c,
    Map<String, Object?> payload, {
    int schema = 1,
  }) async {
    await file(c).parent.create(recursive: true);
    await file(c).writeAsString(
      jsonEncode({
        'schema': schema,
        'payload': payload,
        'sha256': sha256.convert(utf8.encode(jsonEncode(payload))).toString(),
      }),
    );
  }

  test(
    'independent repository reopens scores without transient engine or node IDs',
    () async {
      expect(await repository.load('a' * 64), isNull);
      await repository.save(sample('a'));
      final reopened = FileReviewCacheRepository(() async => directory);
      final entry = (await reopened.load('a' * 64))!;
      expect(entry.info.score, 25);
      expect(entry.info.depth, 8);
      expect(entry.info.pv.map((m) => m.toString()), ['h2e2', 'b9c7']);
      expect(entry.info.token, 0);
      expect(entry.info.nodes, 2000);
      expect(
        await Directory('${directory.path}/chessnext-records').exists(),
        isFalse,
      );
    },
  );
  test(
    'checksum damage is reported and removed, next analysis can regenerate',
    () async {
      await repository.save(sample('a'));
      final data =
          jsonDecode(await file('a').readAsString()) as Map<String, dynamic>;
      (data['payload'] as Map)['score'] = 999;
      await file('a').writeAsString(jsonEncode(data));
      await expectLater(repository.load('a' * 64), throwsFormatException);
      expect(await file('a').exists(), isFalse);
      expect(await repository.load('a' * 64), isNull);
      await repository.save(sample('a', score: 40));
      expect((await repository.load('a' * 64))!.info.score, 40);
    },
  );
  test(
    'future schema, wrong key, partial bounds, invalid numbers and PV fail closed',
    () async {
      final good = sample('a').toJson();
      for (final payload in [
        {...good, 'key': 'b' * 64},
        {...good, 'depth': 0},
        {...good, 'score': 1.5},
        {...good, 'mate': 'false'},
        {...good, 'nodes': -1},
        {
          ...good,
          'pv': ['invalid'],
        },
        {...good, 'pv': List.filled(257, 'h2e2')},
        {...good, 'bound': 'lower'},
      ]) {
        await writePayload('a', payload);
        await expectLater(repository.load('a' * 64), throwsFormatException);
      }
      await writePayload('a', good, schema: 2);
      await expectLater(repository.load('a' * 64), throwsFormatException);
    },
  );
  test('count LRU and total-byte budgets bound disposable files', () async {
    repository = FileReviewCacheRepository(() async => directory, capacity: 2);
    await repository.save(sample('a'));
    await repository.save(sample('b'));
    await repository.load('a' * 64);
    await repository.save(sample('c'));
    expect(await file('b').exists(), isFalse);
    expect(await file('a').exists(), isTrue);
    final bounded = FileReviewCacheRepository(
      () async => directory,
      capacity: 10,
      maxBytes: 1024,
    );
    for (final c in ['d', 'e', 'f', 'a', 'b']) {
      await bounded.save(sample(c));
    }
    var bytes = 0;
    await for (final entity in file('a').parent.list()) {
      if (entity is File) bytes += await entity.length();
    }
    expect(bytes, lessThanOrEqualTo(1024));
    expect((await bounded.load('b' * 64))!.info.score, 25);
  });
  test(
    'oversize, UTF8 damage and interrupted staging do not enter application records',
    () async {
      await file('a').parent.create(recursive: true);
      await file('a').writeAsString('x' * 65537);
      await expectLater(repository.load('a' * 64), throwsFormatException);
      await file('a').writeAsBytes([255, 255]);
      await expectLater(repository.load('a' * 64), throwsFormatException);
      final staging = await Directory(
        '${file('a').parent.path}/.pending-orphan',
      ).create();
      await File('${staging.path}/score.json').writeAsString('incomplete');
      final sentinel = File('${directory.path}/user-record.txt');
      await sentinel.writeAsString('keep');
      final reopened = FileReviewCacheRepository(() async => directory);
      expect(await reopened.load('a' * 64), isNull);
      expect(await staging.exists(), isFalse);
      expect(await sentinel.readAsString(), 'keep');
    },
  );
  test(
    'path traversal and symlink reads cannot follow data outside cache',
    () async {
      await expectLater(repository.load('../outside'), throwsArgumentError);
      await file('a').parent.create(recursive: true);
      final outside = File('${directory.path}/outside');
      await outside.writeAsString('keep');
      await Link(file('a').path).create(outside.path);
      await expectLater(repository.load('a' * 64), throwsFormatException);
      expect(await outside.readAsString(), 'keep');
      expect(await Link(file('a').path).exists(), isTrue);
    },
    skip: Platform.isWindows
        ? 'Windows symlink permission not verified'
        : false,
  );
  test(
    'serial writes commit whole entries and failure preserves unrelated files',
    () async {
      await Future.wait([
        repository.save(sample('a')),
        repository.save(sample('a', score: 45)),
      ]);
      expect((await repository.load('a' * 64))!.info.score, 45);
      final blocked = await Directory('${directory.path}/blocked').create();
      final obstacle = File('${blocked.path}/chessnext-analysis-cache');
      await obstacle.writeAsString('keep');
      final failing = FileReviewCacheRepository(() async => blocked);
      await expectLater(
        failing.save(sample('b')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await obstacle.readAsString(), 'keep');
    },
  );
}
