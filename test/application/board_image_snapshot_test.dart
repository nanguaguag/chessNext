import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_image_snapshot.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/current_move_arrows.dart';
import 'package:chess_next/application/review_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test('capture freezes board, directions and enabled presentation values', () {
    final session = BoardSession();
    addTearDown(session.dispose);
    final move = Move.parse('h2e2');
    expect(session.playMove(move), isTrue);
    session.flip();
    session.mirror();
    final assessment = MoveAssessment(
      nodeId: session.tree.cursorId,
      mover: Side.red,
      grade: MoveGrade.good,
      lossUnits: 40,
    );
    final recommendation = session.position.legalMoves.first;
    final prefs = AppPreferences(
      showCoordinates: false,
      boardSkin: BoardSkin.jade,
      pieceSkin: PieceSkin.squareInk,
      pieceSizePercent: 135,
      arrowHead: ArrowHeadStyle.wide,
      lastMoveMarker: LastMoveMarkerStyle.box,
    );
    final snapshot = BoardImageSnapshot.capture(
      session,
      prefs,
      assessment: assessment,
      recommendation: recommendation,
    );

    expect(snapshot.position, same(session.position));
    expect(snapshot.lastMove, move);
    expect(snapshot.assessment, same(assessment));
    expect(snapshot.recommendation, recommendation);
    expect(snapshot.flipped, isTrue);
    expect(snapshot.mirrored, isTrue);
    expect(snapshot.showCoordinates, isFalse);
    expect(snapshot.boardSkin, BoardSkin.jade);
    expect(snapshot.pieceSkin, PieceSkin.squareInk);
    expect(snapshot.pieceSizePercent, 135);
    expect(snapshot.arrowHead, ArrowHeadStyle.wide);
    expect(snapshot.lastMoveStyle, LastMoveMarkerStyle.box);

    session.undo();
    session.flip();
    session.mirror();
    expect(snapshot.position.toFen(), isNot(session.position.toFen()));
    expect(snapshot.flipped, isTrue);
    expect(snapshot.mirrored, isTrue);
  });

  test('disabled analysis and grade settings remove those captured layers', () {
    final session = BoardSession();
    addTearDown(session.dispose);
    expect(session.playMove(Move.parse('h2e2')), isTrue);
    final snapshot = BoardImageSnapshot.capture(
      session,
      AppPreferences(
        showAnalysisArrows: false,
        showVariationArrows: false,
        showMoveGrades: false,
      ),
      assessment: MoveAssessment(
        nodeId: session.tree.cursorId,
        mover: Side.red,
        grade: MoveGrade.best,
        lossUnits: 0,
      ),
      recommendation: session.position.legalMoves.first,
      reply: session.position.legalMoves.last,
    );
    expect(snapshot.assessment, isNull);
    expect(snapshot.recommendation, isNull);
    expect(snapshot.reply, isNull);
    expect(snapshot.variations, isEmpty);
  });

  test('direct snapshot validates size and owns a bounded variation list', () {
    final arrows = List.generate(
      CurrentMoveArrows.maxVisible + 3,
      (index) => VariationArrow(
        nodeId: 'n$index',
        move: Move.parse('h2e2'),
        number: index + 1,
        selected: false,
        notation: '自制着法',
      ),
    );
    final snapshot = BoardImageSnapshot(
      position: Position.initial(),
      showCoordinates: true,
      pieceSizePercent: 100,
      lastMoveStyle: LastMoveMarkerStyle.halo,
      arrowHead: ArrowHeadStyle.standard,
      variations: arrows,
    );
    arrows.clear();
    expect(snapshot.variations, hasLength(CurrentMoveArrows.maxVisible));
    expect(() => snapshot.variations.clear(), throwsUnsupportedError);
    expect(
      () => BoardImageSnapshot(
        position: Position.initial(),
        showCoordinates: true,
        pieceSizePercent: 101,
        lastMoveStyle: LastMoveMarkerStyle.halo,
        arrowHead: ArrowHeadStyle.standard,
      ),
      throwsArgumentError,
    );
  });
}
