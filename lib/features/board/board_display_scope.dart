import 'package:flutter/widgets.dart';

/// Read-only presentation data above Navigator; no controller, IO or document.
class BoardDisplayScope extends InheritedWidget {
  const BoardDisplayScope({
    super.key,
    required this.showCoordinates,
    this.pieceSizePercent = 100,
    required super.child,
  }) : assert(
         pieceSizePercent >= 10 &&
             pieceSizePercent <= 200 &&
             pieceSizePercent % 5 == 0,
       );
  final bool showCoordinates;
  final int pieceSizePercent;
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
      pieceSizePercent != oldWidget.pieceSizePercent;
}
