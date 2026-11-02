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
    this.arrowHead = ArrowHeadStyle.standard,
    this.lastMoveMarker = LastMoveMarkerStyle.halo,
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
  static bool variationArrowsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.showVariationArrows ??
      true;
  final ArrowHeadStyle arrowHead;
  final LastMoveMarkerStyle lastMoveMarker;
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
      lastMoveMarker != oldWidget.lastMoveMarker ||
      showCoordinates != oldWidget.showCoordinates ||
      showAnalysisArrows != oldWidget.showAnalysisArrows ||
      showVariationArrows != oldWidget.showVariationArrows ||
      arrowHead != oldWidget.arrowHead ||
      pieceSizePercent != oldWidget.pieceSizePercent;
}
