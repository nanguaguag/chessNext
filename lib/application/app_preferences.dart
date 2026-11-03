import 'board_appearance.dart';
import 'review_models.dart';

enum ThemePreference { system, light, dark }

/// Project timing choices; the reference site does not expose numeric durations.
enum AnimationSpeed { off, fast, standard, slow }

extension AnimationSpeedTiming on AnimationSpeed {
  Duration get duration => switch (this) {
    AnimationSpeed.off => Duration.zero,
    AnimationSpeed.fast => const Duration(milliseconds: 300),
    AnimationSpeed.standard => const Duration(milliseconds: 600),
    AnimationSpeed.slow => const Duration(milliseconds: 1200),
  };
}

enum TextSizePreference { system, standard, large, extraLarge }

extension TextSizeScale on TextSizePreference {
  double? get manualScale => switch (this) {
    TextSizePreference.system => null,
    TextSizePreference.standard => 1,
    TextSizePreference.large => 1.15,
    TextSizePreference.extraLarge => 1.3,
  };
}

/// Versioned, platform-neutral settings. AI roles and active searches are excluded.
final class AppPreferences {
  AppPreferences({
    this.theme = ThemePreference.system,
    this.animationSpeed = AnimationSpeed.standard,
    this.playMoveSound = true,
    this.playSelectionSound = true,
    this.playCaptureSound = true,
    this.playCheckSound = true,
    this.playMateSound = true,
    this.reviewMode = ReviewMode.best,
    this.textSize = TextSizePreference.system,
    this.showCoordinates = true,
    this.pieceSizePercent = 100,
    this.showAnalysisArrows = true,
    this.showVariationArrows = true,
    this.showEvaluationBar = true,
    this.showMoveGrades = true,
    this.arrowHead = ArrowHeadStyle.standard,
    this.lastMoveMarker = LastMoveMarkerStyle.halo,
    this.selectionStyle = SelectionStyle.lift,
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
    this.thinkTimeMs = 1000,
    this.guideVersion = 0,
  }) {
    if (pieceSizePercent < 10 ||
        pieceSizePercent > 200 ||
        pieceSizePercent % 5 != 0 ||
        threads < 1 ||
        threads > 1024 ||
        hashMb < 1 ||
        hashMb > 1024 ||
        multiPv < 1 ||
        multiPv > 256 ||
        thinkTimeMs < 50 ||
        thinkTimeMs > 600000 ||
        guideVersion < 0 ||
        guideVersion > 1000000) {
      throw ArgumentError('Invalid preferences');
    }
  }
  final ThemePreference theme;
  final AnimationSpeed animationSpeed;
  final bool playMoveSound;
  final bool playSelectionSound;
  final bool playCaptureSound;
  final bool playCheckSound;
  final bool playMateSound;
  final ReviewMode reviewMode;
  final TextSizePreference textSize;
  final bool showCoordinates;
  final int pieceSizePercent;
  final bool showAnalysisArrows;
  final bool showVariationArrows;
  final bool showEvaluationBar;
  final bool showMoveGrades;
  final ArrowHeadStyle arrowHead;
  final LastMoveMarkerStyle lastMoveMarker;
  final SelectionStyle selectionStyle;
  static const currentGuideVersion = 1;
  final int threads, hashMb, multiPv, thinkTimeMs, guideVersion;
  AppPreferences copyWith({
    ThemePreference? theme,
    AnimationSpeed? animationSpeed,
    bool? playMoveSound,
    bool? playSelectionSound,
    bool? playCaptureSound,
    bool? playCheckSound,
    bool? playMateSound,
    ReviewMode? reviewMode,
    TextSizePreference? textSize,
    bool? showCoordinates,
    int? pieceSizePercent,
    bool? showAnalysisArrows,
    bool? showVariationArrows,
    bool? showEvaluationBar,
    bool? showMoveGrades,
    ArrowHeadStyle? arrowHead,
    LastMoveMarkerStyle? lastMoveMarker,
    SelectionStyle? selectionStyle,
    int? threads,
    int? hashMb,
    int? multiPv,
    int? thinkTimeMs,
    int? guideVersion,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    animationSpeed: animationSpeed ?? this.animationSpeed,
    playMoveSound: playMoveSound ?? this.playMoveSound,
    playSelectionSound: playSelectionSound ?? this.playSelectionSound,
    playCaptureSound: playCaptureSound ?? this.playCaptureSound,
    playCheckSound: playCheckSound ?? this.playCheckSound,
    playMateSound: playMateSound ?? this.playMateSound,
    reviewMode: reviewMode ?? this.reviewMode,
    textSize: textSize ?? this.textSize,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    pieceSizePercent: pieceSizePercent ?? this.pieceSizePercent,
    showAnalysisArrows: showAnalysisArrows ?? this.showAnalysisArrows,
    showVariationArrows: showVariationArrows ?? this.showVariationArrows,
    showEvaluationBar: showEvaluationBar ?? this.showEvaluationBar,
    showMoveGrades: showMoveGrades ?? this.showMoveGrades,
    arrowHead: arrowHead ?? this.arrowHead,
    lastMoveMarker: lastMoveMarker ?? this.lastMoveMarker,
    selectionStyle: selectionStyle ?? this.selectionStyle,
    threads: threads ?? this.threads,
    hashMb: hashMb ?? this.hashMb,
    multiPv: multiPv ?? this.multiPv,
    thinkTimeMs: thinkTimeMs ?? this.thinkTimeMs,
    guideVersion: guideVersion ?? this.guideVersion,
  );
  Map<String, Object> toJson() => {
    'schema': 1,
    if (reviewMode != ReviewMode.best) 'reviewMode': reviewMode.name,
    if (selectionStyle != SelectionStyle.lift)
      'selectionStyle': selectionStyle.name,
    if (lastMoveMarker != LastMoveMarkerStyle.halo)
      'lastMoveMarker': lastMoveMarker.name,
    'theme': theme.name,
    if (animationSpeed != AnimationSpeed.standard)
      'animationSpeed': animationSpeed.name,
    if (!playMoveSound) 'playMoveSound': false,
    if (!playSelectionSound) 'playSelectionSound': false,
    if (!playCaptureSound) 'playCaptureSound': false,
    if (!playCheckSound) 'playCheckSound': false,
    if (!playMateSound) 'playMateSound': false,
    if (textSize != TextSizePreference.system) 'textSize': textSize.name,
    if (!showCoordinates) 'showCoordinates': false,
    if (pieceSizePercent != 100) 'pieceSizePercent': pieceSizePercent,
    if (!showAnalysisArrows) 'showAnalysisArrows': false,
    if (!showVariationArrows) 'showVariationArrows': false,
    if (!showEvaluationBar) 'showEvaluationBar': false,
    if (!showMoveGrades) 'showMoveGrades': false,
    if (arrowHead != ArrowHeadStyle.standard) 'arrowHead': arrowHead.name,
    'threads': threads,
    'hashMb': hashMb,
    'multiPv': multiPv,
    'thinkTimeMs': thinkTimeMs,
    if (guideVersion != 0) 'guideVersion': guideVersion,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        (json.containsKey('reviewMode') && json['reviewMode'] is! String) ||
        (json.containsKey('selectionStyle') &&
            json['selectionStyle'] is! String) ||
        (json.containsKey('lastMoveMarker') &&
            json['lastMoveMarker'] is! String) ||
        (json.containsKey('showMoveGrades') &&
            json['showMoveGrades'] is! bool) ||
        (json.containsKey('showEvaluationBar') &&
            json['showEvaluationBar'] is! bool) ||
        (json.containsKey('showVariationArrows') &&
            json['showVariationArrows'] is! bool) ||
        (json.containsKey('showAnalysisArrows') &&
            json['showAnalysisArrows'] is! bool) ||
        (json.containsKey('arrowHead') && json['arrowHead'] is! String) ||
        json['theme'] is! String ||
        (json.containsKey('textSize') && json['textSize'] is! String) ||
        (json.containsKey('animationSpeed') &&
            json['animationSpeed'] is! String) ||
        (json.containsKey('playMoveSound') && json['playMoveSound'] is! bool) ||
        (json.containsKey('playSelectionSound') &&
            json['playSelectionSound'] is! bool) ||
        (json.containsKey('playCaptureSound') &&
            json['playCaptureSound'] is! bool) ||
        (json.containsKey('playCheckSound') &&
            json['playCheckSound'] is! bool) ||
        (json.containsKey('playMateSound') && json['playMateSound'] is! bool) ||
        (json.containsKey('showCoordinates') &&
            json['showCoordinates'] is! bool) ||
        (json.containsKey('guideVersion') && json['guideVersion'] is! int) ||
        (json.containsKey('pieceSizePercent') &&
            json['pieceSizePercent'] is! int) ||
        ![
          'threads',
          'hashMb',
          'multiPv',
          'thinkTimeMs',
        ].every((key) => json[key] is int)) {
      throw const FormatException('Unsupported preferences schema');
    }
    try {
      return AppPreferences(
        reviewMode: ReviewMode.values.byName(
          json['reviewMode'] as String? ?? 'best',
        ),
        selectionStyle: SelectionStyle.values.byName(
          json['selectionStyle'] as String? ?? 'lift',
        ),
        lastMoveMarker: LastMoveMarkerStyle.values.byName(
          json['lastMoveMarker'] as String? ?? 'halo',
        ),
        showEvaluationBar: json['showEvaluationBar'] as bool? ?? true,
        showMoveGrades: json['showMoveGrades'] as bool? ?? true,
        showVariationArrows: json['showVariationArrows'] as bool? ?? true,
        showAnalysisArrows: json['showAnalysisArrows'] as bool? ?? true,
        arrowHead: ArrowHeadStyle.values.byName(
          json['arrowHead'] as String? ?? 'standard',
        ),
        theme: ThemePreference.values.byName(json['theme'] as String),
        animationSpeed: AnimationSpeed.values.byName(
          json['animationSpeed'] as String? ?? 'standard',
        ),
        playMoveSound: json['playMoveSound'] as bool? ?? true,
        playSelectionSound: json['playSelectionSound'] as bool? ?? true,
        playCaptureSound: json['playCaptureSound'] as bool? ?? true,
        playCheckSound: json['playCheckSound'] as bool? ?? true,
        playMateSound: json['playMateSound'] as bool? ?? true,
        textSize: TextSizePreference.values.byName(
          json['textSize'] as String? ?? 'system',
        ),
        threads: json['threads'] as int,
        showCoordinates: json['showCoordinates'] as bool? ?? true,
        pieceSizePercent: json['pieceSizePercent'] as int? ?? 100,
        hashMb: json['hashMb'] as int,
        multiPv: json['multiPv'] as int,
        thinkTimeMs: json['thinkTimeMs'] as int,
        guideVersion: json['guideVersion'] as int? ?? 0,
      );
    } on ArgumentError {
      throw const FormatException('Invalid preference value');
    }
  }
  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      reviewMode == other.reviewMode &&
      selectionStyle == other.selectionStyle &&
      lastMoveMarker == other.lastMoveMarker &&
      showEvaluationBar == other.showEvaluationBar &&
      showMoveGrades == other.showMoveGrades &&
      showVariationArrows == other.showVariationArrows &&
      showAnalysisArrows == other.showAnalysisArrows &&
      arrowHead == other.arrowHead &&
      theme == other.theme &&
      animationSpeed == other.animationSpeed &&
      playMoveSound == other.playMoveSound &&
      playSelectionSound == other.playSelectionSound &&
      playCaptureSound == other.playCaptureSound &&
      playCheckSound == other.playCheckSound &&
      playMateSound == other.playMateSound &&
      textSize == other.textSize &&
      showCoordinates == other.showCoordinates &&
      pieceSizePercent == other.pieceSizePercent &&
      threads == other.threads &&
      hashMb == other.hashMb &&
      multiPv == other.multiPv &&
      thinkTimeMs == other.thinkTimeMs &&
      guideVersion == other.guideVersion;
  @override
  int get hashCode => Object.hashAll([
    reviewMode,
    selectionStyle,
    lastMoveMarker,
    showEvaluationBar,
    showMoveGrades,
    showVariationArrows,
    showAnalysisArrows,
    arrowHead,
    theme,
    animationSpeed,
    playMoveSound,
    playSelectionSound,
    playCaptureSound,
    playCheckSound,
    playMateSound,
    textSize,
    showCoordinates,
    pieceSizePercent,
    threads,
    hashMb,
    multiPv,
    thinkTimeMs,
    guideVersion,
  ]);
}
