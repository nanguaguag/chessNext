import 'dart:typed_data';

import 'package:xiangqi_core/xiangqi_core.dart';
import 'app_preferences.dart';
import 'board_appearance.dart';
import 'board_session.dart';
import 'current_move_arrows.dart';
import 'review_report.dart';
import '../ports/piece_images.dart';

/// Only immutable values cross the modal boundary; no live session is retained.
class BoardImageSnapshot {
  BoardImageSnapshot({
    required this.position,
    required this.showCoordinates,
    required this.pieceSizePercent,
    required this.lastMoveStyle,
    required this.arrowHead,
    this.lastMove,
    this.assessment,
    this.recommendation,
    this.reply,
    this.flipped = false,
    this.mirrored = false,
    this.rotateOppositePieces = false,
    this.boardSkin = BoardSkin.parchment,
    this.pieceSkin = PieceSkin.roundSeal,
    Map<PieceImageSlot, Uint8List> pieceImages = const {},
    Iterable<VariationArrow> variations = const [],
  }) : pieceImages = Map.unmodifiable({
         for (final entry in pieceImages.entries)
           entry.key: Uint8List.fromList(entry.value).asUnmodifiableView(),
       }),
       variations = List.unmodifiable(
         variations.take(CurrentMoveArrows.maxVisible),
       ) {
    if (pieceSizePercent < 10 ||
        pieceSizePercent > 200 ||
        pieceSizePercent % 5 != 0) {
      throw ArgumentError.value(pieceSizePercent, 'pieceSizePercent');
    }
  }
  factory BoardImageSnapshot.capture(
    BoardSession session,
    AppPreferences prefs, {
    MoveAssessment? assessment,
    Move? recommendation,
    Move? reply,
    Map<PieceImageSlot, Uint8List> pieceImages = const {},
  }) => BoardImageSnapshot(
    position: session.position,
    lastMove: session.tree.current.move,
    assessment: prefs.showMoveGrades ? assessment : null,
    recommendation: prefs.showAnalysisArrows ? recommendation : null,
    reply: prefs.showAnalysisArrows ? reply : null,
    variations: prefs.showVariationArrows && session.showCurrentVariationArrows
        ? session.currentMoveArrows.visible
        : const [],
    flipped: session.flipped,
    mirrored: session.mirrored,
    rotateOppositePieces: prefs.rotateOppositePieces,
    boardSkin: prefs.boardSkin,
    pieceSkin: prefs.pieceSkin,
    pieceImages: pieceImages,
    showCoordinates: prefs.showCoordinates,
    pieceSizePercent: prefs.pieceSizePercent,
    lastMoveStyle: prefs.lastMoveMarker,
    arrowHead: prefs.arrowHead,
  );
  final Position position;
  final Move? lastMove, recommendation, reply;
  final MoveAssessment? assessment;
  final List<VariationArrow> variations;
  final bool flipped, mirrored, showCoordinates, rotateOppositePieces;
  final BoardSkin boardSkin;
  final PieceSkin pieceSkin;
  final Map<PieceImageSlot, Uint8List> pieceImages;
  final int pieceSizePercent;
  final LastMoveMarkerStyle lastMoveStyle;
  final ArrowHeadStyle arrowHead;
}
