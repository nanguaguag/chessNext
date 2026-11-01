/// Immutable, bounded record information, independent from position and file IO.
/// FEN/Format are retained as opaque tags; notation codecs interpret them.
class GameMetadata {
  const GameMetadata._(this.tags);
  static const empty = GameMetadata._({});
  static const maxTags = 64, maxValueLength = 4096;
  static const resultSymbols = {'*', '1-0', '0-1', '1/2-1/2'};
  static final _name = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}$');
  static final _controls = RegExp(r'[\x00-\x1f\x7f]');
  factory GameMetadata(Map<String, String> tags) {
    if (tags.isEmpty) return empty;
    if (tags.length > maxTags) throw ArgumentError('棋谱资料超过64项');
    for (final entry in tags.entries) {
      if (!_name.hasMatch(entry.key) ||
          entry.value.length > maxValueLength ||
          _controls.hasMatch(entry.value)) {
        throw ArgumentError('棋谱资料名称或内容无效：${entry.key}');
      }
    }
    if (tags['Game'] != null && tags['Game'] != 'Chinese Chess') {
      throw ArgumentError('棋谱游戏类型应为Chinese Chess');
    }
    if (tags['Result'] != null && !resultSymbols.contains(tags['Result'])) {
      throw ArgumentError('棋谱记录结果无效');
    }
    return GameMetadata._(Map.unmodifiable(tags));
  }
  final Map<String, String> tags;
  bool get isEmpty => tags.isEmpty;
  String get result => tags['Result'] ?? '*';
  GameMetadata copyWith(Map<String, String?> edits) {
    final next = Map<String, String>.of(tags);
    for (final entry in edits.entries) {
      if (entry.value == null) {
        next.remove(entry.key);
      } else {
        next[entry.key] = entry.value!;
      }
    }
    return GameMetadata(next);
  }

  Map<String, String> toJson() => tags;
  factory GameMetadata.fromJson(Object? raw) {
    if (raw is! Map ||
        raw.length > maxTags ||
        raw.keys.any((k) => k is! String) ||
        raw.values.any((v) => v is! String)) {
      throw const FormatException('棋谱资料格式无效');
    }
    try {
      return GameMetadata(Map<String, String>.from(raw));
    } on ArgumentError {
      throw const FormatException('棋谱资料内容无效');
    }
  }
  @override
  bool operator ==(Object other) =>
      other is GameMetadata &&
      tags.length == other.tags.length &&
      tags.entries.every((e) => other.tags[e.key] == e.value);
  @override
  int get hashCode => Object.hashAllUnordered(
    tags.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
