import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

void main() {
  test(
    'mirror and rotation compose without changing selection or any document identity',
    () {
      final session = BoardSession();
      try {
        session.playMove(Move.parse('h2e2'));
        session.first();
        session.tap(Square.parse('h2'));
        final tree = session.tree,
            revision = session.revision,
            position = session.positionRevision,
            epoch = session.epoch;
        final selected = session.selected,
            targets = session.targets,
            dirty = session.dirty;
        session.mirror();
        expect(session.mirrored, isTrue);
        expect(session.flipped, isFalse);
        session.flip();
        expect(session.mirrored, isTrue);
        expect(session.flipped, isTrue);
        session.mirror();
        expect(session.mirrored, isFalse);
        expect(session.flipped, isTrue);
        session.flip();
        expect(session.flipped, isFalse);
        expect(session.tree, same(tree));
        expect(session.revision, revision);
        expect(session.positionRevision, position);
        expect(session.epoch, epoch);
        expect(session.selected, selected);
        expect(session.targets, targets);
        expect(session.dirty, dirty);
        session.mirror();
        session.flip();
        session.newGame();
        expect(session.mirrored, isTrue);
        expect(session.flipped, isTrue);
        session.replaceTree(tree);
        expect(session.mirrored, isTrue);
        expect(session.flipped, isTrue);
      } finally {
        session.dispose();
      }
    },
  );
  test(
    'view changes keep an active analysis token and a thinking AI applies logical moves',
    () async {
      final session = BoardSession(), fake = FakeEngine();
      final engine = EngineSessionController(session, () async => fake);
      Future<void> tick() =>
          Future<void>.delayed(const Duration(milliseconds: 20));
      try {
        await engine.enable();
        await tick();
        final request = fake.requests.single;
        session.mirror();
        session.flip();
        session.flip();
        fake.emit(request.token);
        await Future<void>.delayed(const Duration(milliseconds: 180));
        expect(fake.requests.length, 1);
        expect(engine.infos.single.token, request.token);
        expect(engine.recommended, Move.parse('h2e2'));
        await engine.disable();
        await engine.setAiSide(Side.red, true);
        await tick();
        final count = fake.requests.length;
        session.mirror();
        session.flip();
        expect(session.inputLocked, isTrue);
        expect(fake.requests.length, count);
        fake.results.last.complete(Move.parse('h2e2'));
        await tick();
        expect(session.moves, [Move.parse('h2e2')]);
        expect(
          session.position.toFen(),
          Position.initial().play(Move.parse('h2e2')).toFen(),
        );
        expect(session.mirrored, isFalse);
        expect(session.flipped, isTrue);
        expect(session.inputLocked, isFalse);
        expect(engine.error, isNull);
        expect(fake.requests.length, count);
      } finally {
        engine.dispose();
        session.dispose();
      }
    },
  );
}
