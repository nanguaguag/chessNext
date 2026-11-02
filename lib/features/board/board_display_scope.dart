import 'package:flutter/widgets.dart';
import '../../application/board_appearance.dart';

/// Read-only presentation data above Navigator; no controller, IO or document.
class BoardDisplayScope extends InheritedWidget {
  const BoardDisplayScope({
    super.key,
    required this.showCoordinates,
    this.pieceSizePercent = 100,
    this.showAnalysisArrows = true,
    this.showVariationArrows = true,
    this.showMoveGrades = true,
    this.arrowHead = ArrowHeadStyle.standard,
    this.lastMoveMarker = LastMoveMarkerStyle.halo,
    this.selectionStyle = SelectionStyle.lift,
    required super.child,
  }) : assert(
         pieceSizePercent >= 10 &&
             pieceSizePercent <= 200 &&
             pieceSizePercent % 5 == 0,
       );
  final bool showCoordinates;
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
  @override
  bool updateShouldNotify(BoardDisplayScope oldWidget) =>
      showMoveGrades != oldWidget.showMoveGrades ||
      selectionStyle != oldWidget.selectionStyle ||
      lastMoveMarker != oldWidget.lastMoveMarker ||
      showCoordinates != oldWidget.showCoordinates ||
      showAnalysisArrows != oldWidget.showAnalysisArrows ||
      showVariationArrows != oldWidget.showVariationArrows ||
      arrowHead != oldWidget.arrowHead ||
      pieceSizePercent != oldWidget.pieceSizePercent;
}
