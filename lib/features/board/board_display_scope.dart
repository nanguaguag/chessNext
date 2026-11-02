import 'package:flutter/widgets.dart';
import '../../application/board_appearance.dart';

/// Read-only presentation data above Navigator; no controller, IO or document.
class BoardDisplayScope extends InheritedWidget {
  const BoardDisplayScope({
    super.key,
    required this.showCoordinates,
    this.pieceSizePercent = 100,
    this.showAnalysisArrows = true,
    this.arrowHead = ArrowHeadStyle.standard,
    required super.child,
  }) : assert(
         pieceSizePercent >= 10 &&
             pieceSizePercent <= 200 &&
             pieceSizePercent % 5 == 0,
       );
  final bool showCoordinates;
  final int pieceSizePercent;
  final bool showAnalysisArrows;
  final ArrowHeadStyle arrowHead;
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
      showCoordinates != oldWidget.showCoordinates ||
      showAnalysisArrows != oldWidget.showAnalysisArrows ||
      arrowHead != oldWidget.arrowHead ||
      pieceSizePercent != oldWidget.pieceSizePercent;
}
