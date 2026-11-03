import 'package:flutter/widgets.dart';
import '../../application/board_appearance.dart';
import '../../application/app_preferences.dart';
import '../../ports/piece_images.dart';
import '../../ports/board_skin_images.dart';
import 'dart:typed_data';
import '../../application/board_skin_geometry.dart';

/// Read-only presentation data above Navigator; no controller, IO or document.
class BoardDisplayScope extends InheritedWidget {
  const BoardDisplayScope({
    super.key,
    required this.showCoordinates,
    this.rotateOppositePieces = false,
    this.boardSkin = BoardSkin.parchment,
    this.geometry = const BoardSkinGeometry.standard(),
    this.pieceSkin = PieceSkin.roundSeal,
    this.pieceSkinShadow,
    this.pieceImages = const {},
    this.boardSkinImages = const {},
    this.pieceSizePercent = 100,
    this.pieceSkinSizePercent = 100,
    this.pieceSkinOffsetXPercent = 0,
    this.pieceSkinOffsetYPercent = 0,
    this.showAnalysisArrows = true,
    this.showVariationArrows = true,
    this.showMoveGrades = true,
    this.arrowHead = ArrowHeadStyle.standard,
    this.lastMoveMarker = LastMoveMarkerStyle.halo,
    this.animationSpeed = AnimationSpeed.standard,
    this.selectionStyle = SelectionStyle.lift,
    required super.child,
  }) : assert(
         pieceSizePercent >= 10 &&
             pieceSizePercent <= 200 &&
             pieceSizePercent % 5 == 0,
       );
  final bool showCoordinates;
  final bool rotateOppositePieces;
  final BoardSkin boardSkin;
  final BoardSkinGeometry geometry;
  final PieceSkin pieceSkin;
  final PieceSkinShadow? pieceSkinShadow;
  final Map<PieceImageSlot, Uint8List> pieceImages;
  final Map<BoardSkinImageSlot, Uint8List> boardSkinImages;
  final int pieceSizePercent;
  final int pieceSkinSizePercent;
  final int pieceSkinOffsetXPercent, pieceSkinOffsetYPercent;
  final bool showAnalysisArrows;
  final bool showVariationArrows;
  final bool showMoveGrades;
  static bool moveGradesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.showMoveGrades ??
      true;
  static bool variationArrowsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.showVariationArrows ??
      true;
  final ArrowHeadStyle arrowHead;
  final LastMoveMarkerStyle lastMoveMarker;
  final AnimationSpeed animationSpeed;
  static AnimationSpeed animationSpeedOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.animationSpeed ??
      AnimationSpeed.standard;
  final SelectionStyle selectionStyle;
  static SelectionStyle selectionStyleOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.selectionStyle ??
      SelectionStyle.lift;
  static LastMoveMarkerStyle lastMoveMarkerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.lastMoveMarker ??
      LastMoveMarkerStyle.halo;
  static bool analysisArrowsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.showAnalysisArrows ??
      true;
  static ArrowHeadStyle arrowHeadOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.arrowHead ??
      ArrowHeadStyle.standard;
  static int pieceSizeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.pieceSizePercent ??
      100;
  static int pieceSkinSizeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.pieceSkinSizePercent ??
      100;
  static int pieceSkinOffsetXOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.pieceSkinOffsetXPercent ??
      0;
  static int pieceSkinOffsetYOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.pieceSkinOffsetYPercent ??
      0;
  static bool coordinatesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.showCoordinates ??
      false;
  static bool rotateOppositePiecesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.rotateOppositePieces ??
      false;
  static BoardSkin boardSkinOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.boardSkin ??
      BoardSkin.parchment;
  static BoardSkinGeometry geometryOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.geometry ??
      const BoardSkinGeometry.standard();
  static PieceSkin pieceSkinOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.pieceSkin ??
      PieceSkin.roundSeal;
  static PieceSkinShadow? pieceSkinShadowOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
      ?.pieceSkinShadow;
  static Map<PieceImageSlot, Uint8List> pieceImagesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.pieceImages ??
      const {};
  static Map<BoardSkinImageSlot, Uint8List> boardSkinImagesOf(
    BuildContext context,
  ) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.boardSkinImages ??
      const {};
  @override
  bool updateShouldNotify(BoardDisplayScope oldWidget) =>
      showMoveGrades != oldWidget.showMoveGrades ||
      selectionStyle != oldWidget.selectionStyle ||
      lastMoveMarker != oldWidget.lastMoveMarker ||
      animationSpeed != oldWidget.animationSpeed ||
      showCoordinates != oldWidget.showCoordinates ||
      rotateOppositePieces != oldWidget.rotateOppositePieces ||
      boardSkin != oldWidget.boardSkin ||
      geometry != oldWidget.geometry ||
      pieceSkin != oldWidget.pieceSkin ||
      pieceSkinShadow != oldWidget.pieceSkinShadow ||
      !identical(pieceImages, oldWidget.pieceImages) ||
      showAnalysisArrows != oldWidget.showAnalysisArrows ||
      showVariationArrows != oldWidget.showVariationArrows ||
      arrowHead != oldWidget.arrowHead ||
      pieceSizePercent != oldWidget.pieceSizePercent ||
      pieceSkinSizePercent != oldWidget.pieceSkinSizePercent ||
      pieceSkinOffsetXPercent != oldWidget.pieceSkinOffsetXPercent ||
      pieceSkinOffsetYPercent != oldWidget.pieceSkinOffsetYPercent ||
      !identical(boardSkinImages, oldWidget.boardSkinImages);
}
