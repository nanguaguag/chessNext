import 'piece_images.dart' show PieceSkin;
import 'piece_skin_shadow.dart';

final class PieceSkinDefinition {
  factory PieceSkinDefinition({
    required String id,
    required String name,
    required PieceSkin baseSkin,
    int scalePercent = 100,
    int offsetXPercent = 0,
    int offsetYPercent = 0,
    PieceSkinShadow? shadow,
    String license = '',
    String attribution = '',
  }) {
    final normalizedName = name.trim();
    if (!isValidId(id) ||
        normalizedName.isEmpty ||
        normalizedName.runes.length > maxNameRunes ||
        normalizedName.runes.any((rune) => rune < 32 || rune == 127) ||
        scalePercent < 80 ||
        scalePercent > 120 ||
        offsetXPercent < -8 ||
        offsetXPercent > 8 ||
        offsetYPercent < -8 ||
        offsetYPercent > 8 ||
        license.runes.length > 120 ||
        attribution.runes.length > 500 ||
        license.runes.any((rune) => rune < 32 && rune != 9) ||
        attribution.runes.any((rune) => rune < 32 && rune != 9)) {
      throw ArgumentError('Invalid piece skin definition');
    }
    return PieceSkinDefinition._(
      id: id,
      name: normalizedName,
      baseSkin: baseSkin,
      scalePercent: scalePercent,
      offsetXPercent: offsetXPercent,
      offsetYPercent: offsetYPercent,
      shadow: shadow,
      license: license.trim(),
      attribution: attribution.trim(),
    );
  }

  const PieceSkinDefinition._({
    required this.id,
    required this.name,
    required this.baseSkin,
    required this.scalePercent,
    required this.offsetXPercent,
    required this.offsetYPercent,
    required this.shadow,
    required this.license,
    required this.attribution,
  });

  static const maxNameRunes = 32;
  static bool isValidId(String value) =>
      RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(value);

  final String id;
  final String name;
  final PieceSkin baseSkin;
  final int scalePercent;
  final int offsetXPercent;
  final int offsetYPercent;
  final PieceSkinShadow? shadow;
  final String license;
  final String attribution;

  PieceSkinDefinition copyWith({
    String? name,
    int? scalePercent,
    int? offsetXPercent,
    int? offsetYPercent,
    PieceSkinShadow? shadow,
    bool clearShadow = false,
    String? license,
    String? attribution,
  }) => PieceSkinDefinition(
    id: id,
    name: name ?? this.name,
    baseSkin: baseSkin,
    scalePercent: scalePercent ?? this.scalePercent,
    offsetXPercent: offsetXPercent ?? this.offsetXPercent,
    offsetYPercent: offsetYPercent ?? this.offsetYPercent,
    shadow: clearShadow ? null : shadow ?? this.shadow,
    license: license ?? this.license,
    attribution: attribution ?? this.attribution,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'baseSkin': baseSkin.name,
    if (scalePercent != 100) 'scalePercent': scalePercent,
    if (offsetXPercent != 0) 'offsetXPercent': offsetXPercent,
    if (offsetYPercent != 0) 'offsetYPercent': offsetYPercent,
    if (shadow != null) 'shadow': shadow!.toJson(),
    if (license.isNotEmpty) 'license': license,
    if (attribution.isNotEmpty) 'attribution': attribution,
  };

  factory PieceSkinDefinition.fromJson(Map<String, dynamic> json) {
    if (json.keys.toSet().difference({
          'id',
          'name',
          'baseSkin',
          'scalePercent',
          'offsetXPercent',
          'offsetYPercent',
          'shadow',
          'license',
          'attribution',
        }).isNotEmpty ||
        json['id'] is! String ||
        json['name'] is! String ||
        json['baseSkin'] is! String ||
        (json.containsKey('scalePercent') && json['scalePercent'] is! int) ||
        (json.containsKey('offsetXPercent') &&
            json['offsetXPercent'] is! int) ||
        (json.containsKey('offsetYPercent') &&
            json['offsetYPercent'] is! int) ||
        (json.containsKey('shadow') && json['shadow'] is! Map) ||
        (json.containsKey('license') && json['license'] is! String) ||
        (json.containsKey('attribution') && json['attribution'] is! String)) {
      throw const FormatException('Invalid piece skin definition');
    }
    try {
      return PieceSkinDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        baseSkin: PieceSkin.values.byName(json['baseSkin'] as String),
        scalePercent: json['scalePercent'] as int? ?? 100,
        offsetXPercent: json['offsetXPercent'] as int? ?? 0,
        offsetYPercent: json['offsetYPercent'] as int? ?? 0,
        shadow: json['shadow'] == null
            ? null
            : PieceSkinShadow.fromJson(
                Map<String, dynamic>.from(json['shadow'] as Map),
              ),
        license: json['license'] as String? ?? '',
        attribution: json['attribution'] as String? ?? '',
      );
    } on ArgumentError {
      throw const FormatException('Invalid piece skin definition');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PieceSkinDefinition &&
      id == other.id &&
      name == other.name &&
      baseSkin == other.baseSkin &&
      scalePercent == other.scalePercent &&
      offsetXPercent == other.offsetXPercent &&
      offsetYPercent == other.offsetYPercent &&
      shadow == other.shadow &&
      license == other.license &&
      attribution == other.attribution;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseSkin,
    scalePercent,
    offsetXPercent,
    offsetYPercent,
    shadow,
    license,
    attribution,
  );
}

abstract interface class PieceSkinLibraryRepository {
  Future<List<PieceSkinDefinition>> load();
  Future<void> save(List<PieceSkinDefinition> definitions);
}
