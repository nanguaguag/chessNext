import 'dart:io';
import 'package:chess_next/adapters/storage/file_draft_repository.dart';
import 'package:chess_next/adapters/storage/file_game_repository.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'drafts survive reopening, recover backups and remain separate from saved records',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chessnext-draft-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final drafts = FileDraftRepository(() async => directory);
      final records = FileGameRepository(() async => directory);
      expect(await drafts.load(), isNull);
      SavedGame game(String move) => SavedGame(
        id: 'active',
        title: 'draft',
        tree: GameTree().play(Move.parse(move)),
        modifiedAt: DateTime(2026),
      );
      await drafts.save(game('h2e2'));
      await drafts.save(game('b2e2'));
      expect((await records.list()).games, isEmpty);
      final reopened = FileDraftRepository(() async => directory);
      expect((await reopened.load())!.tree.current.move.toString(), 'b2e2');
      final primary = File('${directory.path}/chessnext-drafts/active.json');
      final backup = File('${directory.path}/chessnext-drafts/active.bak');
      await primary.writeAsString('broken-primary');
      final recovered = (await reopened.load())!;
      expect(recovered.recovered, isTrue);
      expect(recovered.tree.current.move.toString(), 'h2e2');
      await backup.writeAsString('broken-backup');
      await expectLater(reopened.load(), throwsStateError);
      await reopened.save(game('h2e2'));
      expect((await reopened.load())!.recovered, isFalse);
      final archives = await Directory('${directory.path}/chessnext-drafts')
          .list()
          .where((e) => e is Directory && e.path.contains('.damaged-'))
          .toList();
      expect(archives, hasLength(1));
      expect(
        await File('${archives.single.path}/original.json').readAsString(),
        'broken-primary',
      );
      expect(
        () =>
            FileGameRepository(() async => directory, folderName: '../escape'),
        throwsArgumentError,
      );
    },
  );
}
