import 'dart:convert';
import 'dart:io';
import 'package:chess_next/adapters/storage/file_recent_reading_repository.dart';
import 'package:chess_next/ports/recent_reading_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  late Directory directory;
  late FileRecentReadingRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('chessnext-reading-');
    repository = FileRecentReadingRepository(() async => directory);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  RecentReading entry(String id) => RecentReading.capture(
    id,
    id,
    GameTree().play(Move.parse('h2e2')),
    DateTime.utc(2026),
  );
  File primary() => File('${directory.path}/chessnext-reading/recent.json');
  test(
    'fresh adapter reopens ordered bounded metadata and valid backup',
    () async {
      expect((await repository.load()).entries, isEmpty);
      await repository.save([entry('one')]);
      await repository.save([entry('two'), entry('one')]);
      final reopened = FileRecentReadingRepository(() async => directory);
      expect((await reopened.load()).entries.map((e) => e.gameId), [
        'two',
        'one',
      ]);
      await primary().writeAsString('{broken');
      final recovered = await reopened.load();
      expect(recovered.recovered, isTrue);
      expect(recovered.entries.single.gameId, 'one');
      await reopened.save([entry('three')]);
      final archived = await Directory('${directory.path}/chessnext-reading')
          .list()
          .where((e) => e is Directory && e.path.contains('.damaged-'))
          .single;
      expect(
        await File('${archived.path}/original.json').readAsString(),
        '{broken',
      );
      expect((await reopened.load()).entries.single.gameId, 'three');
    },
  );
  test(
    'damaged originals, unknown schema and excessive metadata are rejected',
    () async {
      await repository.save([entry('one')]);
      for (final text in [
        '{bad',
        jsonEncode({'schema': 9, 'entries': []}),
        jsonEncode({
          'schema': 1,
          'entries': [entry('one').toJson(), entry('one').toJson()],
        }),
      ]) {
        await primary().writeAsString(text);
        await expectLater(repository.load(), throwsA(anything));
        expect(await primary().readAsString(), text);
      }
      await primary().writeAsBytes(
        List.filled(FileRecentReadingRepository.maximumBytes + 1, 32),
      );
      await expectLater(repository.load(), throwsA(anything));
      expect(
        await primary().length(),
        FileRecentReadingRepository.maximumBytes + 1,
      );
      await expectLater(
        repository.save(List.generate(51, (i) => entry('g$i'))),
        throwsArgumentError,
      );
      await expectLater(
        repository.save([entry('one'), entry('one')]),
        throwsArgumentError,
      );
    },
  );
  test(
    'concurrent saves are serialized and temporary directories are cleaned',
    () async {
      await Future.wait([
        repository.save([entry('one')]),
        repository.save([entry('two')]),
      ]);
      expect((await repository.load()).entries.single.gameId, 'two');
      final folders = await Directory('${directory.path}/chessnext-reading')
          .list()
          .where((e) => e is Directory && e.path.contains('.save-'))
          .toList();
      expect(folders, isEmpty);
    },
  );
}
