/// Normalized positions (percent of the board canvas) of the 9×10 grid edges.
/// This project model is independent of a particular window size or platform.
final class BoardSkinGeometry {
  const BoardSkinGeometry.standard()
    : leftPercent = _defaultLeft,
      topPercent = 5,
      rightPercent = _defaultRight,
      bottomPercent = 95,
      pieceScalePercent = 100,
      rotateLandingMarker = false;

  BoardSkinGeometry({
    this.leftPercent = _defaultLeft,
    this.topPercent = 5,
    this.rightPercent = _defaultRight,
    this.bottomPercent = 95,
    this.pieceScalePercent = 100,
    this.rotateLandingMarker = false,
  }) {
    if (!_valid(leftPercent, topPercent, rightPercent, bottomPercent) ||
        pieceScalePercent < minPieceScalePercent ||
        pieceScalePercent > maxPieceScalePercent) {
      throw ArgumentError('Invalid board skin geometry');
    }
  }

  static const minSpanPercent = 55.0;
  static const minEdgePercent = 1.0;
  static const maxEdgePercent = 99.0;
  static const minPieceScalePercent = 60;
  static const maxPieceScalePercent = 140;
  static const _defaultLeft = 100 * .5 / 9;
  static const _defaultRight = 100 * 8.5 / 9;

  final double leftPercent;
  final double topPercent;
  final double rightPercent;
  final double bottomPercent;
  final int pieceScalePercent;
  final bool rotateLandingMarker;

  static bool _valid(double left, double top, double right, double bottom) =>
      [left, top, right, bottom].every((v) => v.isFinite) &&
      left >= minEdgePercent &&
      top >= minEdgePercent &&
      right <= maxEdgePercent &&
      bottom <= maxEdgePercent &&
      right - left >= minSpanPercent &&
      bottom - top >= minSpanPercent;

  BoardSkinGeometry copyWith({
    double? leftPercent,
    double? topPercent,
    double? rightPercent,
    double? bottomPercent,
    int? pieceScalePercent,
    bool? rotateLandingMarker,
  }) => BoardSkinGeometry(
    leftPercent: leftPercent ?? this.leftPercent,
    topPercent: topPercent ?? this.topPercent,
    rightPercent: rightPercent ?? this.rightPercent,
    bottomPercent: bottomPercent ?? this.bottomPercent,
    pieceScalePercent: pieceScalePercent ?? this.pieceScalePercent,
    rotateLandingMarker: rotateLandingMarker ?? this.rotateLandingMarker,
  );

  Map<String, Object> toJson() => {
    'left': leftPercent,
    'top': topPercent,
    'right': rightPercent,
    'bottom': bottomPercent,
    'pieceScale': pieceScalePercent,
    'rotateLandingMarker': rotateLandingMarker,
  };

  factory BoardSkinGeometry.fromJson(Map<String, dynamic> json) {
    final values = [
      json['left'],
      json['top'],
      json['right'],
      json['bottom'],
      json['pieceScale'],
    ];
    if (values.take(4).any((value) => value is! num) ||
        values[4] is! int ||
        (json.containsKey('rotateLandingMarker') &&
            json['rotateLandingMarker'] is! bool)) {
      throw const FormatException('Invalid board skin geometry');
    }
    try {
      return BoardSkinGeometry(
        leftPercent: (json['left'] as num).toDouble(),
        topPercent: (json['top'] as num).toDouble(),
        rightPercent: (json['right'] as num).toDouble(),
        bottomPercent: (json['bottom'] as num).toDouble(),
        pieceScalePercent: json['pieceScale'] as int,
        rotateLandingMarker: json['rotateLandingMarker'] as bool? ?? false,
      );
    } on ArgumentError {
      throw const FormatException('Invalid board skin geometry');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BoardSkinGeometry &&
      leftPercent == other.leftPercent &&
      topPercent == other.topPercent &&
      rightPercent == other.rightPercent &&
      bottomPercent == other.bottomPercent &&
      pieceScalePercent == other.pieceScalePercent &&
      rotateLandingMarker == other.rotateLandingMarker;

  @override
  int get hashCode => Object.hash(
    leftPercent,
    topPercent,
    rightPercent,
    bottomPercent,
    pieceScalePercent,
    rotateLandingMarker,
  );
}
