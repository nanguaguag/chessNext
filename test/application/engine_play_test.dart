import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/chess_next.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 180));
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
}
