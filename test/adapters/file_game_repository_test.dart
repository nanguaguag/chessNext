import 'dart:io';
import 'package:chess_next/adapters/storage/file_game_repository.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late FileGameRepository repository;
  SavedGame game(String title, {String id = 'sample'}) => SavedGame(
    id: id,
    title: title,
    tree: GameTree().play(Move.parse('h2e2')).annotate('注释'),
    modifiedAt: DateTime.utc(2026, 11, 1),
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('chessnext-storage-');
    repository = FileGameRepository(() async => temp);
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });
  test('fresh adapter restores saved tree and cursor from disk', () async {
    await repository.save(game('测试棋谱'));
    final restored = await FileGameRepository(() async => temp).load('sample');
    expect(restored.title, '测试棋谱');
    expect(restored.tree.current.comment, '注释');
    expect(restored.tree.current.move.toString(), 'h2e2');
    expect((await repository.list()).games.single.id, 'sample');
  });
  test(
    'corrupt primary recovers backup, and a repair save preserves the valid backup',
    () async {
      await repository.save(game('第一版'));
      await repository.save(game('第二版'));
      final primary = File('${temp.path}/chessnext-records/sample.json');
      await primary.writeAsString('broken');
      final recovered = await repository.load('sample');
      expect(recovered.recovered, isTrue);
      expect(recovered.title, '第一版');
      await repository.save(game('修复版'));
      expect((await repository.load('sample')).title, '修复版');
      await primary.writeAsString('broken-again');
      expect((await repository.load('sample')).title, '第一版');
    },
  );
  test('unreadable files are reported and left untouched', () async {
    final folder = await Directory('${temp.path}/chessnext-records').create();
    final damaged = File('${folder.path}/broken.json');
    await damaged.writeAsString('invalid');
    final result = await repository.list();
    expect(result.games, isEmpty);
    expect(result.unreadable, ['broken']);
    expect(await damaged.readAsString(), 'invalid');
  });
  test('path traversal and empty titles fail before writing', () async {
    await expectLater(
      repository.save(game('x', id: '../outside')),
      throwsArgumentError,
    );
    await expectLater(repository.save(game('  ')), throwsArgumentError);
    expect(await temp.list().isEmpty, isTrue);
  });
}
