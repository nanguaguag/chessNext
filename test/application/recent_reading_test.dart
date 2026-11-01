import 'dart:async';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/library_controller.dart';
import 'package:chess_next/application/recent_reading_controller.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:chess_next/ports/recent_reading_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class ReadingFake extends MemoryRecentReadingRepository {
  Completer<void>? readGate, writeGate;
  bool failRead = false, failWrite = false;
  int writes = 0;
  @override
  Future<LoadedRecentReadings> load() async {
    await readGate?.future;
    if (failRead) throw StateError('read failed');
    return super.load();
  }

  @override
  Future<void> save(List<RecentReading> entries) async {
    writes++;
    await writeGate?.future;
    if (failWrite) throw StateError('write failed');
    await super.save(entries);
  }
}

GameTree line() => GameTree().play(Move.parse('h2e2')).play(Move.parse('b9c7'));
RecentReading mark(String id, {GameTree? tree}) =>
    RecentReading.capture(id, id, tree ?? line(), DateTime.utc(2026));
void main() {
  test(
    'path restore rejects reused ID and root changes; JSON roundtrip is bounded',
    () {
      final old = mark('game', tree: line().goTo('n1'));
      final reused = GameTree().play(Move.parse('b2e2'));
      expect(old.restore(reused).matched, isFalse);
      expect(old.restore(reused).tree, same(reused));
      final matched = RecentReading.fromJson(old.toJson()).restore(line());
      expect(matched.matched, isTrue);
      expect(matched.tree.cursorId, 'n1');
      final changedRoot = GameTree(
        initial: Position.fromFen('4k4/9/9/9/4p4/9/9/3r5/5r3/4K4 b - - 0 1'),
      );
      expect(old.restore(changedRoot).matched, isFalse);
      expect(
        () => RecentReading.fromJson({
          ...old.toJson(),
          'path': ['z9e0'],
        }),
        throwsFormatException,
      );
      expect(
        () => RecentReading.fromJson({
          ...old.toJson(),
          'path': List.filled(2000, 'h2e2'),
        }),
        throwsFormatException,
      );
      expect(
        () => RecentReading.fromJson({...old.toJson(), 'id': '../private'}),
        throwsFormatException,
      );
    },
  );
  late BoardSession session;
  late MemoryGameRepository games;
  late LibraryController library;
  late ReadingFake repository;
  late RecentReadingController history;
  var time = DateTime.utc(2026);
  setUp(() {
    session = BoardSession();
    games = MemoryGameRepository();
    library = LibraryController(session, games);
    repository = ReadingFake();
    history = RecentReadingController(
      library,
      repository,
      debounce: const Duration(days: 1),
      now: () => time,
    );
  });
  tearDown(() {
    history.dispose();
    library.dispose();
    session.dispose();
  });
  test(
    'saved navigation persists separately; selections do not touch recency',
    () async {
      await history.initialize();
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      expect(history.entries, isEmpty);
      await library.save('测试');
      final id = library.currentId!;
      time = time.add(const Duration(minutes: 1));
      session.first();
      final readAt = history.entries.first.readAt;
      session.tap(Square.parse('h2'));
      session.tap(Square.parse('h2'));
      session.annotate('尚未保存注释');
      expect(history.entries.first.readAt, readAt);
      await history.flush();
      expect(repository.entries.single.path, isEmpty);
      expect((await games.load(id)).tree.cursorId, 'n2');
      expect((await games.load(id)).tree.root.comment, isEmpty);
      expect(session.dirty, isTrue);
      library.newGame();
      session.playMove(Move.parse('b2e2'));
      expect(history.entries.length, 1);
    },
  );
  test(
    'recent open restores position without rewriting record or marking dirty',
    () async {
      await history.initialize();
      session.replaceTree(line(), saved: false);
      await library.save('恢复位置');
      final id = library.currentId!;
      session.first();
      await history.flush();
      library.newGame();
      expect(await history.open(history.entries.single), isTrue);
      expect(session.tree.cursorId, 'n0');
      expect(session.dirty, isFalse);
      expect((await games.load(id)).tree.cursorId, 'n2');
      final changed = SavedGame(
        id: id,
        title: '恢复位置',
        tree: GameTree().play(Move.parse('b2e2')),
        modifiedAt: DateTime.now(),
      );
      await games.save(changed);
      expect(await history.open(mark(id, tree: line().goTo('n1'))), isTrue);
      expect(session.tree.current.move, Move.parse('b2e2'));
      expect(library.error, contains('原阅读位置已变化'));
    },
  );
  test(
    'late initial load merges current observations ahead of stored metadata',
    () async {
      repository.readGate = Completer<void>();
      repository.entries = [mark('old')];
      final loading = history.initialize();
      session.replaceTree(line());
      await library.save('本轮');
      final current = library.currentId!;
      session.first();
      repository.readGate!.complete();
      await loading;
      await history.flush();
      expect(history.entries.map((e) => e.gameId), [current, 'old']);
      expect(history.entries.first.path, isEmpty);
    },
  );
  test(
    'failed load keeps original and disables writing; retry merges pending data',
    () async {
      repository.failRead = true;
      repository.entries = [mark('old')];
      await history.initialize();
      await library.save('本轮');
      await history.flush();
      expect(history.canWrite, isFalse);
      expect(repository.writes, 0);
      expect(history.error, contains('原文件已保留'));
      repository.failRead = false;
      await history.initialize();
      await history.flush();
      expect(repository.entries.length, 2);
      expect(history.error, isNull);
    },
  );
  test(
    'failed write preserves dirty metadata and supports explicit retry',
    () async {
      await history.initialize();
      await library.save('测试');
      repository.failWrite = true;
      await history.flush();
      expect(history.error, contains('保存失败'));
      expect(session.dirty, isFalse);
      repository.failWrite = false;
      await history.flush();
      expect(repository.entries.length, 1);
      expect(history.error, isNull);
    },
  );
  test('a pending write serializes the newest cursor snapshot', () async {
    await history.initialize();
    session.replaceTree(line());
    await library.save('测试');
    repository.writeGate = Completer<void>();
    final pending = history.flush();
    session.first();
    repository.writeGate!.complete();
    await pending;
    expect(repository.entries.single.path, isEmpty);
    expect(repository.writes, 2);
  });
  test(
    'deduplicates, orders by visit and evicts to fifty without deleting games',
    () async {
      await history.initialize();
      for (var i = 0; i < 52; i++) {
        library.newGame();
        await library.save('棋谱$i');
      }
      expect(history.entries.length, 50);
      expect(history.entries.first.title, '棋谱51');
      final last = history.entries.last;
      time = time.subtract(
        const Duration(days: 1),
      ); // Clock changes do not reorder previous visits.
      await history.open(last);
      expect(history.entries.first.gameId, last.gameId);
      expect((await games.list()).games.length, 52);
      session.newGame();
      session.playMove(Move.parse('b2e2'));
      expect(
        history.entries.first.path,
        isEmpty,
      ); // Epoch change without rebinding is ignored.
    },
  );
  test(
    'library refresh cannot rebind a replaced document to an old saved ID',
    () async {
      await history.initialize();
      await library.save('旧谱');
      final oldId = library.currentId!;
      session.newGame();
      session.playMove(Move.parse('b2e2'));
      await library.refresh();
      expect(history.entries.single.path, isEmpty);
      await library.save('新谱');
      expect(library.currentId, isNot(oldId));
      expect((await games.load(oldId)).tree.nodeCount, 1);
      expect(history.entries.first.path, [Move.parse('b2e2')]);
      await history.flush();
    },
  );
  test(
    'backup recovery and a missing reading path are both reported',
    () async {
      await history.initialize();
      await games.save(
        SavedGame(
          id: 'recovered',
          title: '备份棋谱',
          tree: GameTree().play(Move.parse('b2e2')),
          modifiedAt: DateTime.utc(2026),
          recovered: true,
        ),
      );
      expect(
        await history.open(mark('recovered', tree: line().goTo('n1'))),
        isTrue,
      );
      expect(library.error, contains('原阅读位置已变化'));
      expect(library.error, contains('已从备份恢复'));
      expect(session.tree.current.move, Move.parse('b2e2'));
      await history.flush();
    },
  );
}
