import 'dart:async';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/library_controller.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class DelayedRepository extends MemoryGameRepository {
  final gate = Completer<void>();
  bool fail = false;
  @override
  Future<void> save(SavedGame game) async {
    await gate.future;
    if (fail) throw StateError('模拟磁盘失败');
    await super.save(game);
  }
}

class DelayedReadRepository extends MemoryGameRepository {
  final gate = Completer<void>();
  @override
  Future<SavedGame> load(String id) async {
    await gate.future;
    return super.load(id);
  }
}

void main() {
  test(
    'saved content opens after a new game and dirty tracks content, not navigation',
    () async {
      final s = BoardSession();
      final library = LibraryController(s, MemoryGameRepository());
      addTearDown(() {
        library.dispose();
        s.dispose();
      });
      s.tap(Square.parse('h2'));
      s.tap(Square.parse('e2'));
      s.annotate('中炮');
      expect(s.dirty, isTrue);
      expect(await library.save('本地测试'), isTrue);
      final id = library.currentId!;
      expect(s.dirty, isFalse);
      s.first();
      expect(s.dirty, isFalse);
      library.newGame();
      expect(s.moves, isEmpty);
      expect(await library.open(id), isTrue);
      expect(s.tree.current.comment, '中炮');
      expect(s.dirty, isFalse);
    },
  );
  test(
    'late save cannot mark newer content clean or bind a new document to an old ID',
    () async {
      final s = BoardSession();
      final repo = DelayedRepository();
      final library = LibraryController(s, repo);
      addTearDown(() {
        library.dispose();
        s.dispose();
      });
      s.annotate('旧注释');
      final pending = library.save('旧棋谱');
      library.newGame();
      s.annotate('新注释');
      repo.gate.complete();
      expect(await pending, isTrue);
      expect(s.dirty, isTrue);
      expect(library.currentId, isNull);
      expect(s.tree.current.comment, '新注释');
    },
  );
  test('failed save leaves modifications dirty and can be retried', () async {
    final s = BoardSession();
    final repo = DelayedRepository()..fail = true;
    final library = LibraryController(s, repo);
    addTearDown(() {
      library.dispose();
      s.dispose();
    });
    s.annotate('尚未保存');
    repo.gate.complete();
    expect(await library.save('测试'), isFalse);
    expect(s.dirty, isTrue);
    expect(library.currentId, isNull);
    repo.fail = false;
    expect(await library.save('测试'), isTrue);
    expect(s.dirty, isFalse);
  });
  test('disposing during a write does not notify a disposed session', () async {
    final s = BoardSession();
    final repo = DelayedRepository();
    final library = LibraryController(s, repo);
    final pending = library.save('测试');
    library.dispose();
    s.dispose();
    repo.gate.complete();
    expect(await pending, isTrue);
  });
  test(
    'navigation during a pending open is preserved rather than overwritten',
    () async {
      final s = BoardSession();
      final repo = DelayedReadRepository();
      final library = LibraryController(s, repo);
      addTearDown(() {
        library.dispose();
        s.dispose();
      });
      await repo.save(
        SavedGame(
          id: 'target',
          title: '目标',
          tree: GameTree(),
          modifiedAt: DateTime.now(),
        ),
      );
      s.tap(Square.parse('h2'));
      s.tap(Square.parse('e2'));
      final pending = library.open('target');
      s.undo();
      repo.gate.complete();
      expect(await pending, isFalse);
      expect(s.tree.nodeCount, 2);
      expect(s.tree.cursorId, 'n0');
      expect(library.currentId, isNull);
    },
  );
}
