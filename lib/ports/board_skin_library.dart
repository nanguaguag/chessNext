import '../application/board_skin_geometry.dart';
import 'board_skin_images.dart';

/// A user-owned board appearance cloned from one of the built-in palettes.
final class BoardSkinDefinition {
  factory BoardSkinDefinition({
    required String id,
    required String name,
    required BoardSkin baseSkin,
    BoardSkinGeometry geometry = const BoardSkinGeometry.standard(),
    String license = '',
    String attribution = '',
  }) {
    final normalized = name.trim();
    if (!isValidId(id) ||
        normalized.isEmpty ||
        normalized.runes.length > maxNameRunes ||
        normalized.runes.any((rune) => rune < 32 || rune == 127)) {
      throw ArgumentError('Invalid board skin definition');
    }
    if (license.runes.length > 120 || attribution.runes.length > 500) {
      throw ArgumentError('Invalid board skin license metadata');
    }
    if (license.runes.any((rune) => rune < 32 && rune != 9 && rune != 10) ||
        attribution.runes.any((rune) => rune < 32 && rune != 9 && rune != 10)) {
      throw ArgumentError('Invalid board skin license metadata');
    }
    return BoardSkinDefinition._(
      id: id,
      name: normalized,
      baseSkin: baseSkin,
      geometry: geometry,
      license: license.trim(),
      attribution: attribution.trim(),
    );
  }

  const BoardSkinDefinition._({
    required this.id,
    required this.name,
    required this.baseSkin,
    required this.geometry,
    this.license = '',
    this.attribution = '',
  });

  static const maxNameRunes = 32;
  static bool isValidId(String value) =>
      RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(value);

  final String id;
  final String name;
  final BoardSkin baseSkin;
  final BoardSkinGeometry geometry;
  final String license;
  final String attribution;

  BoardSkinDefinition copyWith({
    String? name,
    BoardSkinGeometry? geometry,
    String? license,
    String? attribution,
  }) => BoardSkinDefinition(
    id: id,
    name: name ?? this.name,
    baseSkin: baseSkin,
    geometry: geometry ?? this.geometry,
    license: license ?? this.license,
    attribution: attribution ?? this.attribution,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'baseSkin': baseSkin.name,
    'geometry': geometry.toJson(),
    'license': license,
    'attribution': attribution,
  };

  factory BoardSkinDefinition.fromJson(Map<String, dynamic> json) {
    if (json.keys.toSet().difference({
          'id',
          'name',
          'baseSkin',
          'geometry',
          'license',
          'attribution',
        }).isNotEmpty ||
        json['id'] is! String ||
        json['name'] is! String ||
        json['baseSkin'] is! String ||
        json['geometry'] is! Map ||
        (json.containsKey('license') && json['license'] is! String) ||
        (json.containsKey('attribution') && json['attribution'] is! String)) {
      throw const FormatException('Invalid board skin definition');
    }
    try {
      return BoardSkinDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        baseSkin: BoardSkin.values.byName(json['baseSkin'] as String),
        geometry: BoardSkinGeometry.fromJson(
          Map<String, dynamic>.from(json['geometry'] as Map),
        ),
        license: json['license'] as String? ?? '',
        attribution: json['attribution'] as String? ?? '',
      );
    } on ArgumentError {
      throw const FormatException('Invalid board skin definition');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BoardSkinDefinition &&
      id == other.id &&
      name == other.name &&
      baseSkin == other.baseSkin &&
      geometry == other.geometry &&
      license == other.license &&
      attribution == other.attribution;

  @override
  int get hashCode =>
      Object.hash(id, name, baseSkin, geometry, license, attribution);
}

abstract interface class BoardSkinLibraryRepository {
  Future<List<BoardSkinDefinition>> load();
  Future<void> save(List<BoardSkinDefinition> profiles);
}
