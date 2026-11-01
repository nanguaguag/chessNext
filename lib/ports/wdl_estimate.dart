/// Native engine model output, in per mille, from the side-to-move perspective.
/// Winning probability and expected score (draw = half point) are distinct.
class WdlEstimate {
  WdlEstimate({required this.wins, required this.draws, required this.losses}) {
    if ([wins, draws, losses].any((v) => v < 0 || v > 1000) ||
        wins + draws + losses != 1000) {
      throw ArgumentError('Invalid WDL estimate');
    }
  }
  final int wins, draws, losses;
  double get expectedScore => (wins + draws / 2) / 1000;
  WdlEstimate flipped() =>
      WdlEstimate(wins: losses, draws: draws, losses: wins);
  List<int> toJson() => [wins, draws, losses];
  factory WdlEstimate.fromJson(Object? raw) {
    if (raw is! List || raw.length != 3 || raw.any((v) => v is! int)) {
      throw const FormatException('Invalid WDL data');
    }
    try {
      return WdlEstimate(
        wins: raw[0] as int,
        draws: raw[1] as int,
        losses: raw[2] as int,
      );
    } on ArgumentError {
      throw const FormatException('Invalid WDL values');
    }
  }
}
