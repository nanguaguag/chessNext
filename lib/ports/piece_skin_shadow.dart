enum PieceShadowStyle { none, soft, prominent }

/// Portable shadow settings persisted with a local piece skin definition.
final class PieceSkinShadow {
  factory PieceSkinShadow({
    PieceShadowStyle style = PieceShadowStyle.none,
    int angleDegrees = 138,
    double distancePercent = 6.7,
    double blurPercent = 2.4,
    int opacityPercent = 50,
  }) {
    if (angleDegrees < 0 ||
        angleDegrees >= 360 ||
        distancePercent < 0 ||
        distancePercent > 20 ||
        blurPercent < 0 ||
        blurPercent > 20 ||
        opacityPercent < 0 ||
        opacityPercent > 100) {
      throw ArgumentError('Invalid piece skin shadow');
    }
    return PieceSkinShadow._(
      style: style,
      angleDegrees: angleDegrees,
      distancePercent: distancePercent,
      blurPercent: blurPercent,
      opacityPercent: opacityPercent,
    );
  }

  const PieceSkinShadow._({
    required this.style,
    required this.angleDegrees,
    required this.distancePercent,
    required this.blurPercent,
    required this.opacityPercent,
  });

  const PieceSkinShadow.roundSealDefault()
    : style = PieceShadowStyle.soft,
      angleDegrees = 90,
      distancePercent = 4,
      blurPercent = 6,
      opacityPercent = 15;

  const PieceSkinShadow.standard()
    : style = PieceShadowStyle.none,
      angleDegrees = 138,
      distancePercent = 6.7,
      blurPercent = 2.4,
      opacityPercent = 50;

  final PieceShadowStyle style;
  final int angleDegrees;
  final double distancePercent;
  final double blurPercent;
  final int opacityPercent;

  PieceSkinShadow copyWith({
    PieceShadowStyle? style,
    int? angleDegrees,
    double? distancePercent,
    double? blurPercent,
    int? opacityPercent,
  }) => PieceSkinShadow(
    style: style ?? this.style,
    angleDegrees: angleDegrees ?? this.angleDegrees,
    distancePercent: distancePercent ?? this.distancePercent,
    blurPercent: blurPercent ?? this.blurPercent,
    opacityPercent: opacityPercent ?? this.opacityPercent,
  );

  Map<String, Object> toJson() => {
    'style': style.name,
    'angle': angleDegrees,
    'distance': distancePercent,
    'blur': blurPercent,
    'opacity': opacityPercent,
  };

  factory PieceSkinShadow.fromJson(Map<String, dynamic> json) {
    if (json['style'] is! String ||
        json['angle'] is! int ||
        json['distance'] is! num ||
        json['blur'] is! num ||
        json['opacity'] is! int) {
      throw const FormatException('Invalid piece skin shadow');
    }
    try {
      return PieceSkinShadow(
        style: PieceShadowStyle.values.byName(json['style'] as String),
        angleDegrees: json['angle'] as int,
        distancePercent: (json['distance'] as num).toDouble(),
        blurPercent: (json['blur'] as num).toDouble(),
        opacityPercent: json['opacity'] as int,
      );
    } on ArgumentError {
      throw const FormatException('Invalid piece skin shadow');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PieceSkinShadow &&
      style == other.style &&
      angleDegrees == other.angleDegrees &&
      distancePercent == other.distancePercent &&
      blurPercent == other.blurPercent &&
      opacityPercent == other.opacityPercent;

  @override
  int get hashCode => Object.hash(
    style,
    angleDegrees,
    distancePercent,
    blurPercent,
    opacityPercent,
  );
}
