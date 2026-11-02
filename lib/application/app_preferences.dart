import 'board_appearance.dart';

enum ThemePreference { system, light, dark }

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
    this.textSize = TextSizePreference.system,
    this.showCoordinates = true,
    this.pieceSizePercent = 100,
    this.showAnalysisArrows = true,
    this.showVariationArrows = true,
    this.showEvaluationBar = true,
    this.arrowHead = ArrowHeadStyle.standard,
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
  final TextSizePreference textSize;
  final bool showCoordinates;
  final int pieceSizePercent;
  final bool showAnalysisArrows;
  final bool showVariationArrows;
  final bool showEvaluationBar;
  final ArrowHeadStyle arrowHead;
  static const currentGuideVersion = 1;
  final int threads, hashMb, multiPv, thinkTimeMs, guideVersion;
  AppPreferences copyWith({
    ThemePreference? theme,
    TextSizePreference? textSize,
    bool? showCoordinates,
    int? pieceSizePercent,
    bool? showAnalysisArrows,
    bool? showVariationArrows,
    bool? showEvaluationBar,
    ArrowHeadStyle? arrowHead,
    int? threads,
    int? hashMb,
    int? multiPv,
    int? thinkTimeMs,
    int? guideVersion,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    textSize: textSize ?? this.textSize,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    pieceSizePercent: pieceSizePercent ?? this.pieceSizePercent,
    showAnalysisArrows: showAnalysisArrows ?? this.showAnalysisArrows,
    showVariationArrows: showVariationArrows ?? this.showVariationArrows,
    showEvaluationBar: showEvaluationBar ?? this.showEvaluationBar,
    arrowHead: arrowHead ?? this.arrowHead,
    threads: threads ?? this.threads,
    hashMb: hashMb ?? this.hashMb,
    multiPv: multiPv ?? this.multiPv,
    thinkTimeMs: thinkTimeMs ?? this.thinkTimeMs,
    guideVersion: guideVersion ?? this.guideVersion,
  );
  Map<String, Object> toJson() => {
    'schema': 1,
    'theme': theme.name,
    if (textSize != TextSizePreference.system) 'textSize': textSize.name,
    if (!showCoordinates) 'showCoordinates': false,
    if (pieceSizePercent != 100) 'pieceSizePercent': pieceSizePercent,
    if (!showAnalysisArrows) 'showAnalysisArrows': false,
    if (!showVariationArrows) 'showVariationArrows': false,
    if (!showEvaluationBar) 'showEvaluationBar': false,
    if (arrowHead != ArrowHeadStyle.standard) 'arrowHead': arrowHead.name,
    'threads': threads,
    'hashMb': hashMb,
    'multiPv': multiPv,
    'thinkTimeMs': thinkTimeMs,
    if (guideVersion != 0) 'guideVersion': guideVersion,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        (json.containsKey('showEvaluationBar') &&
            json['showEvaluationBar'] is! bool) ||
        (json.containsKey('showVariationArrows') &&
            json['showVariationArrows'] is! bool) ||
        (json.containsKey('showAnalysisArrows') &&
            json['showAnalysisArrows'] is! bool) ||
        (json.containsKey('arrowHead') && json['arrowHead'] is! String) ||
        json['theme'] is! String ||
        (json.containsKey('textSize') && json['textSize'] is! String) ||
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
        showEvaluationBar: json['showEvaluationBar'] as bool? ?? true,
        showVariationArrows: json['showVariationArrows'] as bool? ?? true,
        showAnalysisArrows: json['showAnalysisArrows'] as bool? ?? true,
        arrowHead: ArrowHeadStyle.values.byName(
          json['arrowHead'] as String? ?? 'standard',
        ),
        theme: ThemePreference.values.byName(json['theme'] as String),
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
      showEvaluationBar == other.showEvaluationBar &&
      showVariationArrows == other.showVariationArrows &&
      showAnalysisArrows == other.showAnalysisArrows &&
      arrowHead == other.arrowHead &&
      theme == other.theme &&
      textSize == other.textSize &&
      showCoordinates == other.showCoordinates &&
      pieceSizePercent == other.pieceSizePercent &&
      threads == other.threads &&
      hashMb == other.hashMb &&
      multiPv == other.multiPv &&
      thinkTimeMs == other.thinkTimeMs &&
      guideVersion == other.guideVersion;
  @override
  int get hashCode => Object.hash(
    showEvaluationBar,
    showVariationArrows,
    showAnalysisArrows,
    arrowHead,
    theme,
    textSize,
    showCoordinates,
    pieceSizePercent,
    threads,
    hashMb,
    multiPv,
    thinkTimeMs,
    guideVersion,
  );
}
