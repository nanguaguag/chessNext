import 'package:flutter/widgets.dart';

/// Read-only presentation data above Navigator; no controller, IO or document.
class BoardDisplayScope extends InheritedWidget {
  const BoardDisplayScope({
    super.key,
    required this.showCoordinates,
    required super.child,
  });
  final bool showCoordinates;
  static bool coordinatesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardDisplayScope>()
          ?.showCoordinates ??
      false;
  @override
  bool updateShouldNotify(BoardDisplayScope oldWidget) =>
      showCoordinates != oldWidget.showCoordinates;
}
