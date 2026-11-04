import 'dart:async';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/ports/book_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

class DelayedStopFake extends FakeEngine {
  Completer<void>? stopGate;
  @override
  Future<void> stop() async {
    await stopGate?.future;
    await super.stop();
  }
}

class FailedStopFake extends FakeEngine {
  bool failStop = false;
  @override
  Future<void> stop() async {
    if (failStop) throw StateError('stop failed');
    await super.stop();
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 180));

class FakeBookService implements BookService {
  FakeBookService(this.result, {this.error});
  final BookLookup result;
  final Object? error;
  int calls = 0;
  BookPositionKey? requested;
  @override
  Future<BookLookup> query({
    required Uri endpoint,
    required BookPositionKey position,
  }) async {
    calls++;
    if (error != null) throw error!;
    requested = position;
    return result;
  }
}

void main() {
  late BoardSession session;
  late FakeEngine fake;
  late EngineSessionController engine;
  setUp(() {
    session = BoardSession();
    fake = FakeEngine();
    engine = EngineSessionController(session, () => Future.value(fake));
  });
  tearDown(() {
    engine.dispose();
    session.dispose();
  });
  test(
    'AI responds legally, locks its turn and undo returns to the human turn',
    () async {
      await engine.setAiSide(Side.black, true);
      expect(fake.requests, isEmpty);
      session.playMove(Move.parse('h2e2'));
      await tick();
      expect(session.inputLocked, isTrue);
      session.tap(Square.parse('b9'));
      expect(session.selected, isNull);
      expect(fake.requests.single.moveTimeMs, 1000);
      fake.results.last.complete(Move.parse('b9c7'));
      await Future<void>.delayed(Duration.zero);
      expect(session.moves.map((m) => m.toString()), ['h2e2', 'b9c7']);
      expect(session.inputLocked, isFalse);
      await engine.undoForPlay();
      expect(session.moves, isEmpty);
      expect(session.tree.nodeCount, 3);
      expect(engine.aiSides, {Side.black});
    },
  );
  test(
    'analysis AI walk applies one fresh legal move with its own time limit',
    () async {
      final walking = engine.walkOneMove();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fake.requests.single.moveTimeMs, 1000);
      expect(fake.requests.single.depth, isNull);
      expect(engine.aiWalking, isTrue);
      expect(session.inputLocked, isTrue);

      fake.results.single.complete(Move.parse('h2e2'));
      await walking;
      expect(session.moves, [Move.parse('h2e2')]);
      expect(engine.aiWalking, isFalse);
      expect(engine.playing, isFalse);
      expect(session.inputLocked, isFalse);
      expect(engine.status, 'AI 已走一着');
    },
  );
  test(
    'unlimited AI walk uses configured depth and local strength budget',
    () async {
      final walking = engine.walkOneMove(
        moveTimeMs: 0,
        difficulty: 7,
        maxDepth: 42,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fake.requests.single.moveTimeMs, isNull);
      expect(fake.requests.single.depth, 42);
      expect(fake.requests.single.nodeLimit, 80000);
      fake.results.single.complete(Move.parse('h2e2'));
      await walking;
    },
  );
  test(
    'AI walk validates and applies a self-hosted book move before search',
    () async {
      final book = FakeBookService(
        const BookLookup(
          hit: true,
          candidates: [BookMoveCandidate(uci: 'h2e2', scoreCp: 12, weight: 4)],
          datasetId: 'local-test',
          license: 'CC0',
          attribution: 'fixture',
        ),
      );
      engine.dispose();
      engine = EngineSessionController(
        session,
        () => Future.value(fake),
        bookService: book,
      );
      engine.configureBookPolicy(
        endpoint: 'http://localhost:8080',
        openingMode: OpeningBookMode.best,
        endgameEnabled: true,
        leaveBookMoves: 10,
      );
      final initialFen = session.position.toFen();

      await engine.walkOneMove();

      expect(book.requested?.kind, BookKind.opening);
      expect(book.requested?.fen, initialFen);
      expect(session.moves, [Move.parse('h2e2')]);
      expect(fake.requests, isEmpty);
      expect(engine.status, 'AI 已走一着');
    },
  );

  test('illegal cloud candidates fall back to the local engine', () async {
    final book = FakeBookService(
      const BookLookup(
        hit: true,
        candidates: [BookMoveCandidate(uci: 'a0a0', scoreCp: 100, weight: 1)],
        datasetId: 'local-test',
        license: 'CC0',
        attribution: 'fixture',
      ),
    );
    engine.dispose();
    engine = EngineSessionController(
      session,
      () => Future.value(fake),
      bookService: book,
    );
    engine.configureBookPolicy(
      endpoint: 'http://localhost:8080',
      openingMode: OpeningBookMode.best,
      endgameEnabled: true,
      leaveBookMoves: 10,
    );

    final walking = engine.walkOneMove();
    await tick();
    expect(fake.requests, hasLength(1));
    fake.results.single.complete(Move.parse('h2e2'));
    await walking;

    expect(session.moves, [Move.parse('h2e2')]);
    expect(engine.status, '云库着法无效，AI 已走一着');
  });
  test('cloud service failure falls back to the local engine', () async {
    final book = FakeBookService(
      const BookLookup(
        hit: false,
        candidates: [],
        datasetId: 'local-test',
        license: 'CC0',
        attribution: 'fixture',
      ),
      error: const BookServiceUnavailable(),
    );
    engine.dispose();
    engine = EngineSessionController(
      session,
      () => Future.value(fake),
      bookService: book,
    );
    engine.configureBookPolicy(
      endpoint: 'https://books.example.org',
      openingMode: OpeningBookMode.best,
      endgameEnabled: true,
      leaveBookMoves: 10,
    );

    final walking = engine.walkOneMove();
    await tick();
    expect(book.calls, 1);
    expect(fake.requests, hasLength(1));
    fake.results.single.complete(Move.parse('h2e2'));
    await walking;
    expect(engine.status, '云库不可用，AI 已走一着');
  });

  test('empty service address never calls the book service', () async {
    final book = FakeBookService(
      const BookLookup(
        hit: true,
        candidates: [BookMoveCandidate(uci: 'h2e2', scoreCp: 0, weight: 1)],
        datasetId: 'local-test',
        license: 'CC0',
        attribution: 'fixture',
      ),
    );
    engine.dispose();
    engine = EngineSessionController(
      session,
      () => Future.value(fake),
      bookService: book,
    );
    engine.configureBookPolicy(
      endpoint: '',
      openingMode: OpeningBookMode.best,
      endgameEnabled: true,
      leaveBookMoves: 10,
    );

    final walking = engine.walkOneMove();
    await tick();
    expect(book.calls, 0);
    expect(fake.requests, hasLength(1));
    fake.results.single.complete(Move.parse('h2e2'));
    await walking;
  });
  test('analysis resumes on the new position after one AI walk', () async {
    await engine.enable();
    expect(fake.requests.single.moveTimeMs, isNull);
    final walking = engine.walkOneMove(moveTimeMs: 3000);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(fake.requests.last.moveTimeMs, 3000);
    fake.results.last.complete(Move.parse('h2e2'));
    await walking;
    expect(session.moves, [Move.parse('h2e2')]);
    expect(engine.enabled, isTrue);
    await tick();
    expect(fake.requests.last.moveTimeMs, isNull);
    expect(engine.status, '本地分析中');
  });
  test(
    'cancelling analysis AI walk does not apply a stale best move',
    () async {
      fake.stopMove = Move.parse('h2e2');
      final walking = engine.walkOneMove();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(engine.aiWalking, isTrue);
      await engine.cancelAiWalk();
      await walking;
      expect(session.moves, isEmpty);
      expect(engine.aiWalking, isFalse);
      expect(session.inputLocked, isFalse);
      expect(engine.status, 'AI 走棋已取消');
    },
  );
  test('navigating to another position cancels the pending AI walk', () async {
    session.playMove(Move.parse('h2e2'));
    final walking = engine.walkOneMove();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(engine.aiWalking, isTrue);
    await engine.navigateToNode('n0');
    await walking;
    expect(session.tree.cursorId, 'n0');
    expect(engine.aiWalking, isFalse);
    expect(session.inputLocked, isFalse);
    expect(fake.requests.length, 1);
  });
  test('failed stop blocks a second search during AI walk', () async {
    final failedStop = FailedStopFake();
    engine.dispose();
    fake = failedStop;
    engine = EngineSessionController(session, () => Future.value(failedStop));
    await engine.enable();
    expect(failedStop.requests.length, 1);
    failedStop.failStop = true;
    await engine.walkOneMove();
    expect(failedStop.requests.length, 1);
    expect(engine.aiWalking, isFalse);
    expect(engine.enabled, isFalse);
    expect(session.inputLocked, isFalse);
  });
  test(
    'stopping discards the bestmove returned by stop, while immediate move adopts it',
    () async {
      fake.stopMove = Move.parse('h2e2');
      await engine.setAiSide(Side.red, true);
      await engine.disable();
      expect(session.moves, isEmpty);
      expect(session.inputLocked, isFalse);
      await engine.setAiSide(Side.red, true);
      await engine.immediateMove();
      await Future<void>.delayed(Duration.zero);
      expect(session.moves.single, Move.parse('h2e2'));
    },
  );
  test(
    'alternative excludes the last move and preserves it as a variation',
    () async {
      await engine.setAiSide(Side.black, true);
      session.playMove(Move.parse('h2e2'));
      await tick();
      final old = Move.parse('b9c7');
      fake.results.last.complete(old);
      await Future<void>.delayed(Duration.zero);
      expect(engine.canAlternative, isTrue);
      await engine.alternative();
      final request = fake.requests.last;
      expect(request.moves.map((m) => m.toString()), ['h2e2']);
      expect(request.searchMoves, isNot(contains(old)));
      final next = request.searchMoves!.first;
      fake.results.last.complete(next);
      await Future<void>.delayed(Duration.zero);
      expect(session.moves.last, next);
      expect(session.tree.node('n1').children.length, 2);
      expect(session.tree.node('n1').children.first, session.tree.cursorId);
    },
  );
  test(
    'analysis and AI are exclusive and switching cannot adopt an old result',
    () async {
      fake.stopMove = Move.parse('h2e2');
      await engine.setAiSide(Side.red, true);
      await engine.enable();
      expect(engine.playing, isFalse);
      expect(engine.enabled, isTrue);
      expect(session.moves, isEmpty);
      expect(fake.requests.last.moveTimeMs, isNull);
      await engine.setAiSide(Side.black, true);
      expect(engine.enabled, isFalse);
      expect(engine.playing, isTrue);
    },
  );
  test(
    'dual AI chains turns and stopping cancels the next scheduled move',
    () async {
      await engine.setAiSide(Side.red, true);
      await engine.setAiSide(Side.black, true);
      fake.results.last.complete(Move.parse('h2e2'));
      await tick();
      expect(fake.requests.last.position.turn, Side.black);
      fake.results.last.complete(Move.parse('b9c7'));
      await Future<void>.delayed(Duration.zero);
      final count = fake.requests.length;
      await engine.disable();
      await tick();
      expect(fake.requests.length, count);
      expect(session.moves.length, 2);
      expect(engine.aiSides, isEmpty);
      expect(session.inputLocked, isFalse);
    },
  );
  test(
    'undo during AI thinking discards the response returned by stop',
    () async {
      await engine.setAiSide(Side.black, true);
      session.playMove(Move.parse('h2e2'));
      await tick();
      fake.stopMove = Move.parse('b9c7');
      await engine.undoForPlay();
      await Future<void>.delayed(Duration.zero);
      expect(session.moves, isEmpty);
      expect(session.tree.nodeCount, 2);
      expect(session.inputLocked, isFalse);
    },
  );
  test(
    'reading a historical node stops AI and discards its late best move',
    () async {
      await engine.setAiSide(Side.black, true);
      session.playMove(Move.parse('h2e2'));
      await tick();
      fake.stopMove = Move.parse('b9c7');
      await engine.navigateToNode('n0');
      expect(engine.aiSides, isEmpty);
      expect(session.tree.cursorId, 'n0');
      expect(session.tree.nodeCount, 2);
      expect(session.inputLocked, isFalse);
      expect(session.tree.currentLine.map((node) => node.id), ['n0', 'n1']);
    },
  );
  test('a delayed stop cannot navigate over a newer human move', () async {
    final delayed = DelayedStopFake();
    fake = delayed;
    await engine.setAiSide(Side.black, true);
    session.playMove(Move.parse('h2e2'));
    await tick();
    final gate = Completer<void>();
    delayed.stopGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final reading = engine.navigateToNode('n0');
    expect(session.inputLocked, isFalse);
    expect(session.playMove(Move.parse('b9c7')), isTrue);
    gate.complete();
    await reading;
    expect(session.tree.cursorId, 'n2');
    expect(session.moves.map((move) => move.toString()), ['h2e2', 'b9c7']);
    expect(engine.aiSides, isEmpty);
  });
}
