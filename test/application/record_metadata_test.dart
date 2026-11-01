import 'package:chess_next/application/metadata_editor.dart';
import 'dart:async';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/draft_controller.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/library_controller.dart';
import 'package:chess_next/ports/draft_repository.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

class DelayedMetadataSave extends MemoryGameRepository {
  final gate = Completer<void>();
  @override
  Future<void> save(SavedGame game) async {
    await gate.future;
    await super.save(game);
  }
}

void main() {
  late BoardSession session;
  late LibraryController library;
  late MemoryGameRepository repository;
  final metadata = GameMetadata({
    'Event': '自制比赛',
    'Red': '红方',
    'Custom': '保留',
    'Result': '1-0',
  });
  setUp(() {
    session = BoardSession();
    repository = MemoryGameRepository();
    library = LibraryController(session, repository);
  });
  tearDown(() {
    library.dispose();
    session.dispose();
  });
  test(
    'metadata-only edits are content; equal data is a no-op and navigation stays clean',
    () {
      final tree = session.tree;
      final positionRevision = session.positionRevision;
      final revision = session.revision;
      session.updateMetadata(metadata);
      expect(session.hasContent, isTrue);
      expect(session.dirty, isTrue);
      expect(session.tree, same(tree));
      expect(session.positionRevision, positionRevision);
      expect(session.revision, revision + 1);
      expect(session.outcome.isTerminal, isFalse);
      session.updateMetadata(
        GameMetadata(Map.fromEntries(metadata.tags.entries.toList().reversed)),
      );
      expect(session.revision, revision + 1);
      session.markSaved(session.revision);
      session.first();
      expect(session.dirty, isFalse);
      session.newGame();
      expect(session.metadata.isEmpty, isTrue);
      expect(session.hasContent, isFalse);
    },
  );
  test(
    'save and open preserve unknown metadata while import and new roots are explicit',
    () async {
      library.importTree(GameTree(), metadata: metadata);
      await library.save('资料棋谱');
      final id = library.currentId!;
      library.newGame();
      expect(session.metadata.isEmpty, isTrue);
      expect(await library.open(id), isTrue);
      expect(session.metadata, metadata);
      expect(session.dirty, isFalse);
      library.startPosition(Position.initial());
      expect(session.metadata.isEmpty, isTrue);
    },
  );
  test(
    'replacing tree and metadata is a single atomic session notification',
    () {
      var notifications = 0;
      session.addListener(() {
        notifications++;
        expect(session.metadata, metadata);
        expect(session.tree.nodeCount, 2);
      });
      session.replaceTree(
        GameTree().play(Move.parse('h2e2')),
        metadata: metadata,
      );
      expect(notifications, 1);
    },
  );
  test('late save cannot lose newer metadata or mark it clean', () async {
    final delayed = DelayedMetadataSave();
    final slow = LibraryController(session, delayed);
    addTearDown(slow.dispose);
    session.updateMetadata(metadata);
    final saving = slow.save('资料');
    session.updateMetadata(metadata.copyWith({'Red': '晚到编辑'}));
    delayed.gate.complete();
    expect(await saving, isTrue);
    expect(session.metadata.tags['Red'], '晚到编辑');
    expect(session.dirty, isTrue);
    expect((await delayed.load(slow.currentId!)).metadata, metadata);
  });
  test(
    'metadata-only draft flush and fresh-controller recovery preserve all tags',
    () async {
      final drafts = MemoryDraftRepository();
      final first = DraftController(
        session,
        library,
        drafts,
        debounce: const Duration(days: 1),
      );
      await first.initialize();
      session.updateMetadata(metadata);
      await first.flush();
      first.dispose();
      expect(drafts.draft!.metadata, metadata);
      library.newGame();
      final second = DraftController(
        session,
        library,
        drafts,
        debounce: const Duration(days: 1),
      );
      addTearDown(second.dispose);
      await second.initialize();
      expect(second.pending!.metadata, metadata);
      expect(second.restore(), isTrue);
      expect(session.metadata, metadata);
      expect(session.dirty, isTrue);
      expect(library.currentId, isNull);
      await second.flush();
    },
  );
  test(
    'metadata changes preserve running analysis and AI without new searches or adjudication',
    () async {
      final fake = FakeEngine();
      final engine = EngineSessionController(session, () async => fake);
      addTearDown(engine.dispose);
      await engine.enable();
      final searches = fake.requests.length;
      session.updateMetadata(metadata);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(fake.requests.length, searches);
      expect(engine.enabled, isTrue);
      await engine.disable();
      await engine.setAiSide(Side.red, true);
      final aiSearches = fake.requests.length;
      session.updateMetadata(metadata.copyWith({'Black': '另一位'}));
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(engine.playing, isTrue);
      expect(fake.requests.length, aiSearches);
      expect(session.outcome.isTerminal, isFalse);
      await engine.disable();
    },
  );
  test(
    'cleared data keeps named empty drafts recoverable and protects dirty replacements',
    () async {
      final drafts = MemoryDraftRepository();
      final first = DraftController(
        session,
        library,
        drafts,
        debounce: const Duration(days: 1),
      );
      await first.initialize();
      session.updateMetadata(metadata);
      await library.save('已命名资料');
      session.updateMetadata(GameMetadata.empty);
      await first.flush();
      first.dispose();
      library.newGame();
      final second = DraftController(
        session,
        library,
        drafts,
        debounce: const Duration(days: 1),
      );
      addTearDown(second.dispose);
      await second.initialize();
      expect(second.pending!.title, '已命名资料');
      expect(second.pending!.metadata.isEmpty, isTrue);
      session.updateMetadata(metadata);
      session.updateMetadata(GameMetadata.empty);
      expect(session.dirty, isTrue);
      expect(session.hasContent, isFalse);
      expect(second.restore(), isFalse);
      expect(second.restore(replaceCurrent: true), isTrue);
      expect(library.title, '已命名资料');
      await second.flush();
    },
  );
  test('invalid editor updates retain the document and can be corrected', () {
    final original = GameMetadata({
      for (var i = 0; i < 64; i++) 'Extra$i': '保留',
    });
    session.replaceTree(GameTree(), metadata: original);
    final editor = MetadataEditor(session);
    final revision = session.revision;
    expect(editor.apply({'Event': '超出项数'}), isFalse);
    expect(editor.error, contains('64'));
    expect(session.metadata, original);
    expect(session.revision, revision);
    expect(editor.apply({'Extra0': null, 'Event': '修正'}), isTrue);
    expect(session.metadata.tags['Event'], '修正');
    expect(editor.error, isNull);
  });
}
