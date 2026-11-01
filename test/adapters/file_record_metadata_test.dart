import 'dart:convert';
import 'dart:io';
import 'package:chess_next/adapters/storage/file_draft_repository.dart';
import 'package:chess_next/adapters/storage/file_game_repository.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  late Directory directory;
  late FileGameRepository repository;
  final metadata = GameMetadata({
    'Event': '自制比赛',
    'Custom': '保留😀',
    'Result': '0-1',
  });
  SavedGame game(GameMetadata info) => SavedGame(
    id: 'record',
    title: '资料',
    tree: GameTree(),
    modifiedAt: DateTime.utc(2026),
    metadata: info,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('chessnext-metadata-');
    repository = FileGameRepository(() async => directory);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test(
    'old schema without optional data opens empty and new adapters retain unknown fields',
    () async {
      await repository.save(game(GameMetadata.empty));
      final file = File('${directory.path}/chessnext-records/record.json');
      expect(
        (jsonDecode(await file.readAsString()) as Map).containsKey('metadata'),
        isFalse,
      );
      expect((await repository.load('record')).metadata.isEmpty, isTrue);
      await repository.save(game(metadata));
      expect(
        (await FileGameRepository(
          () async => directory,
        ).load('record')).metadata,
        metadata,
      );
    },
  );
  test(
    'invalid metadata recovers valid backup and repair preserves damaged originals',
    () async {
      await repository.save(game(metadata));
      await repository.save(game(metadata.copyWith({'Event': '新版'})));
      final primary = File('${directory.path}/chessnext-records/record.json');
      final original =
          jsonDecode(await primary.readAsString()) as Map<String, dynamic>;
      for (final bad in [
        null,
        {'Event': 123},
        {'Result': 'win'},
        {for (var i = 0; i < 65; i++) 'X$i': 'x'},
      ]) {
        final text = jsonEncode({...original, 'metadata': bad});
        await primary.writeAsString(text);
        final restored = await repository.load('record');
        expect(restored.recovered, isTrue);
        expect(restored.metadata, metadata);
        expect(await primary.readAsString(), text);
      }
      final damaged = await primary.readAsString();
      await repository.save(game(metadata.copyWith({'Event': '修复'})));
      final archive = await Directory('${directory.path}/chessnext-records')
          .list()
          .where((e) => e is Directory && e.path.contains('.damaged-record-'))
          .single;
      expect(
        await File('${archive.path}/original.json').readAsString(),
        damaged,
      );
      await primary.writeAsString('broken');
      expect((await repository.load('record')).metadata, metadata);
    },
  );
  test(
    'unreadable metadata is reported without replacing it with empty data',
    () async {
      await repository.save(game(metadata));
      final primary = File('${directory.path}/chessnext-records/record.json');
      final data =
          jsonDecode(await primary.readAsString()) as Map<String, dynamic>;
      final damaged = jsonEncode({
        ...data,
        'metadata': {'Event': 'bad\nline'},
      });
      await primary.writeAsString(damaged);
      final listed = await repository.list();
      expect(listed.games, isEmpty);
      expect(listed.unreadable, ['record']);
      expect(await primary.readAsString(), damaged);
    },
  );
  test('separate draft adapter forwards metadata and reopens it', () async {
    final drafts = FileDraftRepository(() async => directory);
    await drafts.save(game(metadata));
    final restored = await FileDraftRepository(() async => directory).load();
    expect(restored!.metadata, metadata);
    expect(restored.id, 'active');
    expect(restored.tree.nodeCount, 1);
  });
}
