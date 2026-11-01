import 'dart:async';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/library_controller.dart';
import 'package:chess_next/application/draft_controller.dart';
import 'package:chess_next/ports/draft_repository.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledDrafts extends MemoryDraftRepository {
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? readGate;
  Completer<void>? writeGate;
  final writes = <SavedGame>[];
  @override
  Future<SavedGame?> load() async {
    await readGate?.future;
    if (failRead) throw StateError('disk read failed');
    return super.load();
  }

  @override
  Future<void> save(SavedGame value) async {
    writes.add(value);
    if (writes.length == 1) await writeGate?.future;
    if (failWrite) throw StateError('disk full');
    await super.save(value);
  }
}

void main() {
  late BoardSession session;
  late LibraryController library;
  late ControlledDrafts repository;
  late DraftController drafts;
  setUp(() {
    session = BoardSession();
    library = LibraryController(session, MemoryGameRepository());
    repository = ControlledDrafts();
    drafts = DraftController(
      session,
      library,
      repository,
      debounce: const Duration(hours: 1),
    );
  });
  tearDown(() {
    drafts.dispose();
    library.dispose();
    session.dispose();
  });
  void move(String text) => session.playMove(Move.parse(text));
  test(
    'serializes immutable snapshots and drains the latest queued document',
    () async {
      await drafts.initialize();
      move('h2e2');
      repository.writeGate = Completer<void>();
      final first = drafts.flush();
      expect(repository.writes.single.tree.path.length, 2);
      move('b9c7');
      session.annotate('latest');
      final last = drafts.flush();
      expect(identical(first, last), isTrue);
      repository.writeGate!.complete();
      await last;
      expect(repository.writes.length, 2);
      expect(repository.draft!.tree.path.length, 3);
      expect(repository.draft!.tree.current.comment, 'latest');
      expect(repository.writes.first.tree.path.length, 2);
      expect(session.dirty, isTrue);
    },
  );
  test(
    'pending recovery blocks autosave and never silently replaces current edits',
    () async {
      final old = GameTree().play(Move.parse('b2e2')).annotate('recovery');
      repository.draft = SavedGame(
        id: 'active',
        title: 'old',
        tree: old,
        modifiedAt: DateTime(2026),
      );
      repository.readGate = Completer<void>();
      final loading = drafts.initialize();
      move('h2e2');
      repository.readGate!.complete();
      await loading;
      await drafts.flush();
      expect(repository.writes, isEmpty);
      expect(drafts.restore(), isFalse);
      expect(session.moves.single.toString(), 'h2e2');
      expect(drafts.restore(replaceCurrent: true), isTrue);
      expect(session.moves.single.toString(), 'b2e2');
      expect(session.tree.current.comment, 'recovery');
      expect(session.dirty, isTrue);
      expect(library.currentId, isNull);
    },
  );
  test(
    'read and write failures pause or retry without marking the document saved',
    () async {
      repository.failRead = true;
      await drafts.initialize();
      move('h2e2');
      await drafts.flush();
      expect(repository.writes, isEmpty);
      expect(drafts.error, isNotNull);
      drafts.keepCurrent();
      repository.failWrite = true;
      await drafts.flush();
      expect(drafts.error, contains('保存失败'));
      expect(session.dirty, isTrue);
      repository.failWrite = false;
      await drafts.flush();
      expect(drafts.error, isNull);
      expect(repository.draft!.tree.path.length, 2);
    },
  );
  test(
    'intentional new game replaces old recovery with an empty checkpoint',
    () async {
      await drafts.initialize();
      move('h2e2');
      await drafts.flush();
      library.newGame();
      await drafts.flush();
      expect(repository.draft!.tree.nodeCount, 1);
      final second = DraftController(session, library, repository);
      await second.initialize();
      expect(second.pending, isNull);
      second.dispose();
    },
  );
  test(
    'a write finishing after disposal never notifies or reads a disposed session',
    () async {
      final s = BoardSession();
      final l = LibraryController(s, MemoryGameRepository());
      final r = ControlledDrafts()..writeGate = Completer<void>();
      final d = DraftController(s, l, r);
      await d.initialize();
      s.playMove(Move.parse('h2e2'));
      final future = d.flush();
      d.dispose();
      l.dispose();
      s.dispose();
      r.writeGate!.complete();
      await future;
      expect(r.draft!.tree.path.length, 2);
    },
  );
}
