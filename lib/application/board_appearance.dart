import '../ports/piece_images.dart' show PieceSkin;
import '../ports/board_skin_images.dart' show BoardSkin;

export '../ports/piece_images.dart' show PieceSkin;
export '../ports/board_skin_images.dart' show BoardSkin;

/// Stable storage values. Drawing geometry belongs to the presentation layer.
enum ArrowHeadStyle { sharp, standard, wide }

enum LastMoveMarkerStyle { halo, box }

enum SelectionStyle { lift, frame }

extension BoardSkinPalette on BoardSkin {
  int get boardColor => switch (this) {
    BoardSkin.parchment => 0xfff1dfbf,
    BoardSkin.jade => 0xffe5eee4,
  };
  int get gridColor => switch (this) {
    BoardSkin.parchment => 0xff947c57,
    BoardSkin.jade => 0xff668270,
  };
  int get labelColor => switch (this) {
    BoardSkin.parchment => 0xff806b4d,
    BoardSkin.jade => 0xff587261,
  };
  int get pieceColor => switch (this) {
    BoardSkin.parchment => 0xfffff4da,
    BoardSkin.jade => 0xfff2f6ef,
  };
  int get pieceBorderColor => switch (this) {
    BoardSkin.parchment => 0xffbda177,
    BoardSkin.jade => 0xff9bb3a0,
  };
}

extension PieceSkinPalette on PieceSkin {
  int get faceColor => switch (this) {
    PieceSkin.roundSeal => 0xfffff4da,
    PieceSkin.squareInk => 0xfff2eddf,
  };
  int get borderColor => switch (this) {
    PieceSkin.roundSeal => 0xffbda177,
    PieceSkin.squareInk => 0xff756a58,
  };
}

enum PieceShadowStyle { none, soft, prominent }

/// Per-piece-skin shadow controls; values are platform-neutral preferences.
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
