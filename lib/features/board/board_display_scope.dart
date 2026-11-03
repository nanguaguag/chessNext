import 'package:flutter/widgets.dart';
import '../../application/board_appearance.dart';
import '../../application/app_preferences.dart';

/// Read-only presentation data above Navigator; no controller, IO or document.
class BoardDisplayScope extends InheritedWidget {
  const BoardDisplayScope({
    super.key,
    required this.showCoordinates,
    this.rotateOppositePieces = false,
    this.pieceSizePercent = 100,
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
  final int pieceSizePercent;
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
  @override
  bool updateShouldNotify(BoardDisplayScope oldWidget) =>
      showMoveGrades != oldWidget.showMoveGrades ||
      selectionStyle != oldWidget.selectionStyle ||
      lastMoveMarker != oldWidget.lastMoveMarker ||
      animationSpeed != oldWidget.animationSpeed ||
      showCoordinates != oldWidget.showCoordinates ||
      rotateOppositePieces != oldWidget.rotateOppositePieces ||
      showAnalysisArrows != oldWidget.showAnalysisArrows ||
      showVariationArrows != oldWidget.showVariationArrows ||
      arrowHead != oldWidget.arrowHead ||
      pieceSizePercent != oldWidget.pieceSizePercent;
}
