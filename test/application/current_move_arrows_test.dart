import 'dart:async';
import 'package:chess_next/application/current_move_arrows.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/branched_record.dart';

class DelayedVariationPreferences extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'projection uses current-move siblings in parent order, never the next choices',
    () {
      final tree = branchedRecord();
      final projection = CurrentMoveArrows.fromTree(tree);
      expect(projection.total, 2);
      expect(projection.visible.map((a) => a.move.toString()), [
        'b0c2',
        'h2h4',
      ]);
      expect(projection.visible.map((a) => a.notation), ['马八进七', '炮二进二']);
      expect(projection.visible.map((a) => a.number), [1, 2]);
      expect(projection.visible.map((a) => a.selected), [false, true]);
      expect(
        CurrentMoveArrows.fromTree(
          tree.goTo('n2'),
        ).visible.single.move.toString(),
        'b9c7',
      );
      expect(CurrentMoveArrows.fromTree(tree.goTo('n0')).visible, isEmpty);
    },
  );
  test(
    'promotion and deletion update numbering without mutating the snapshot',
    () {
      final tree = branchedRecord();
      final original = CurrentMoveArrows.fromTree(tree);
      final promoted = tree.promote(tree.cursorId);
      final changed = CurrentMoveArrows.fromTree(promoted);
      expect(changed.visible.first.nodeId, tree.cursorId);
      expect(changed.visible.first.number, 1);
      final remaining = CurrentMoveArrows.fromTree(promoted.deleteBranch('n3'));
      expect(remaining.visible.single.move.toString(), 'h2h4');
      expect(original.visible.first.number, 1);
      expect(original.visible.first.nodeId, 'n3');
    },
  );
  test(
    'local display state is not document content and clears at root or document replacement',
    () {
      final session = BoardSession();
      addTearDown(session.dispose);
      session.replaceTree(branchedRecord());
      final tree = session.tree;
      final revision = session.revision,
          positionRevision = session.positionRevision;
      final projection = session.currentMoveArrows;
      session.setCurrentVariationArrows(true);
      expect(session.currentMoveArrows, same(projection));
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.positionRevision, positionRevision);
      expect(session.dirty, isFalse);
      session.navigate('n2');
      expect(session.showCurrentVariationArrows, isTrue);
      session.first();
      expect(session.showCurrentVariationArrows, isFalse);
      session.setCurrentVariationArrows(true);
      expect(session.showCurrentVariationArrows, isFalse);
      session.replaceTree(tree);
      session.setCurrentVariationArrows(true);
      session.replaceTree(tree);
      expect(session.showCurrentVariationArrows, isFalse);
    },
  );
  test(
    'large legal sibling collection stays bounded while keeping current original number',
    () {
      final position = Position.fromFen(
        '4k4/9/9/9/4P4/2P1P1P2/9/1C5C1/R7R/1N2K2N1 w - - 0 1',
      );
      final moves = position.legalMoves.toList();
      expect(moves.length, greaterThan(CurrentMoveArrows.maxVisible));
      var tree = GameTree(initial: position);
      for (final move in moves) {
        tree = tree.goTo(tree.root.id).play(move);
      }
      final projection = CurrentMoveArrows.fromTree(tree);
      expect(projection.visible.length, 64);
      expect(projection.total, moves.length);
      expect(projection.truncated, isTrue);
      expect(projection.visible.last.nodeId, tree.cursorId);
      expect(projection.visible.last.number, moves.length);
      expect(
        projection.visible.map((a) => a.number).take(63),
        List.generate(63, (i) => i + 1),
      );
    },
  );
  test(
    'global variation preference is optional, strict and merges late independently',
    () async {
      final old = AppPreferences().toJson();
      expect(old.containsKey('showVariationArrows'), isFalse);
      expect(AppPreferences.fromJson(old).showVariationArrows, isTrue);
      for (final bad in [null, 'false', 0]) {
        expect(
          () => AppPreferences.fromJson({...old, 'showVariationArrows': bad}),
          throwsFormatException,
        );
      }
      final session = BoardSession(), store = DelayedVariationPreferences();
      store.value = AppPreferences(pieceSizePercent: 125);
      final engine = EngineSessionController(session, null);
      final current = PreferencesController(engine, store);
      try {
        final loading = current.initialize();
        final edit = current.setVariationArrows(false);
        store.gate.complete();
        await loading;
        await edit;
        await current.flush();
        expect(current.value.showVariationArrows, isFalse);
        expect(current.value.pieceSizePercent, 125);
        expect(AppPreferences.fromJson(store.value!.toJson()), store.value);
      } finally {
        current.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
