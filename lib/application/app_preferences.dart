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
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
    this.thinkTimeMs = 1000,
    this.guideVersion = 0,
  }) {
    if (threads < 1 ||
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
  static const currentGuideVersion = 1;
  final int threads, hashMb, multiPv, thinkTimeMs, guideVersion;
  AppPreferences copyWith({
    ThemePreference? theme,
    TextSizePreference? textSize,
    bool? showCoordinates,
    int? threads,
    int? hashMb,
    int? multiPv,
    int? thinkTimeMs,
    int? guideVersion,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    textSize: textSize ?? this.textSize,
    showCoordinates: showCoordinates ?? this.showCoordinates,
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
    'threads': threads,
    'hashMb': hashMb,
    'multiPv': multiPv,
    'thinkTimeMs': thinkTimeMs,
    if (guideVersion != 0) 'guideVersion': guideVersion,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        json['theme'] is! String ||
        (json.containsKey('textSize') && json['textSize'] is! String) ||
        (json.containsKey('showCoordinates') &&
            json['showCoordinates'] is! bool) ||
        (json.containsKey('guideVersion') && json['guideVersion'] is! int) ||
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
        theme: ThemePreference.values.byName(json['theme'] as String),
        textSize: TextSizePreference.values.byName(
          json['textSize'] as String? ?? 'system',
        ),
        threads: json['threads'] as int,
        showCoordinates: json['showCoordinates'] as bool? ?? true,
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
      theme == other.theme &&
      textSize == other.textSize &&
      showCoordinates == other.showCoordinates &&
      threads == other.threads &&
      hashMb == other.hashMb &&
      multiPv == other.multiPv &&
      thinkTimeMs == other.thinkTimeMs &&
      guideVersion == other.guideVersion;
  @override
  int get hashCode => Object.hash(
    theme,
    textSize,
    showCoordinates,
    threads,
    hashMb,
    multiPv,
    thinkTimeMs,
    guideVersion,
  );
}
