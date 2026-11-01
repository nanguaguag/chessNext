import 'dart:convert';

/// Verified artifact provenance. A UCI display name alone is not a cache key.
class EngineIdentity {
  EngineIdentity({
    required this.release,
    required this.commit,
    required this.sourceBinarySha256,
    required this.binarySha256,
    required this.networkSha256,
    required this.target,
  }) {
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(commit) ||
        [
          sourceBinarySha256,
          binarySha256,
          networkSha256,
        ].any((hash) => !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) ||
        [release, target].any(
          (s) =>
              s.isEmpty ||
              s.length > 128 ||
              RegExp(r'[\x00-\x1f\x7f]').hasMatch(s),
        )) {
      throw const FormatException('Invalid engine provenance');
    }
  }
  final String release;
  final String commit;

  /// Original upstream executable, before local code signing.
  final String sourceBinarySha256;

  /// Actual executable bytes, after signing, verified before spawning.
  final String binarySha256;
  final String networkSha256;
  final String target;
  Map<String, Object> toJson() => {
    'schema': 1,
    'release': release,
    'commit': commit,
    'sourceBinarySha256': sourceBinarySha256,
    'binarySha256': binarySha256,
    'networkSha256': networkSha256,
    'target': target,
  };
  factory EngineIdentity.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported engine provenance');
    }
    final fields = [
      'release',
      'commit',
      'sourceBinarySha256',
      'binarySha256',
      'networkSha256',
      'target',
    ];
    if (fields.any((field) => json[field] is! String)) {
      throw const FormatException('Invalid engine provenance');
    }
    return EngineIdentity(
      release: json['release'] as String,
      commit: json['commit'] as String,
      sourceBinarySha256: json['sourceBinarySha256'] as String,
      binarySha256: json['binarySha256'] as String,
      networkSha256: json['networkSha256'] as String,
      target: json['target'] as String,
    );
  }

  /// Fixed order, independent of input JSON property order.
  String get cacheIdentity => jsonEncode(toJson());
}
