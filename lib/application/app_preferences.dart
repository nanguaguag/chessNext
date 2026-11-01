enum ThemePreference { system, light, dark }

/// Versioned, platform-neutral settings. AI roles and active searches are excluded.
final class AppPreferences {
  AppPreferences({
    this.theme = ThemePreference.system,
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
    this.thinkTimeMs = 1000,
  }) {
    if (threads < 1 ||
        threads > 1024 ||
        hashMb < 1 ||
        hashMb > 1024 ||
        multiPv < 1 ||
        multiPv > 256 ||
        thinkTimeMs < 50 ||
        thinkTimeMs > 600000) {
      throw ArgumentError('Invalid preferences');
    }
  }
  final ThemePreference theme;
  final int threads, hashMb, multiPv, thinkTimeMs;
  AppPreferences copyWith({
    ThemePreference? theme,
    int? threads,
    int? hashMb,
    int? multiPv,
    int? thinkTimeMs,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    threads: threads ?? this.threads,
    hashMb: hashMb ?? this.hashMb,
    multiPv: multiPv ?? this.multiPv,
    thinkTimeMs: thinkTimeMs ?? this.thinkTimeMs,
  );
  Map<String, Object> toJson() => {
    'schema': 1,
    'theme': theme.name,
    'threads': threads,
    'hashMb': hashMb,
    'multiPv': multiPv,
    'thinkTimeMs': thinkTimeMs,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        json['theme'] is! String ||
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
        threads: json['threads'] as int,
        hashMb: json['hashMb'] as int,
        multiPv: json['multiPv'] as int,
        thinkTimeMs: json['thinkTimeMs'] as int,
      );
    } on ArgumentError {
      throw const FormatException('Invalid preference value');
    }
  }
  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      theme == other.theme &&
      threads == other.threads &&
      hashMb == other.hashMb &&
      multiPv == other.multiPv &&
      thinkTimeMs == other.thinkTimeMs;
  @override
  int get hashCode => Object.hash(theme, threads, hashMb, multiPv, thinkTimeMs);
}
