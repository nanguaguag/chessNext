import 'piece_images.dart' show PieceSkin;

final class PieceSkinDefinition {
  factory PieceSkinDefinition({
    required String id,
    required String name,
    required PieceSkin baseSkin,
  }) {
    final normalizedName = name.trim();
    if (!isValidId(id) ||
        normalizedName.isEmpty ||
        normalizedName.runes.length > maxNameRunes ||
        normalizedName.runes.any((rune) => rune < 32 || rune == 127)) {
      throw ArgumentError('Invalid piece skin definition');
    }
    return PieceSkinDefinition._(
      id: id,
      name: normalizedName,
      baseSkin: baseSkin,
    );
  }

  const PieceSkinDefinition._({
    required this.id,
    required this.name,
    required this.baseSkin,
  });

  static const maxNameRunes = 32;
  static bool isValidId(String value) =>
      RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(value);

  final String id;
  final String name;
  final PieceSkin baseSkin;

  PieceSkinDefinition copyWith({String? name}) => PieceSkinDefinition(
    id: id,
    name: name ?? this.name,
    baseSkin: baseSkin,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'baseSkin': baseSkin.name,
  };

  factory PieceSkinDefinition.fromJson(Map<String, dynamic> json) {
    if (json.keys.toSet().difference({'id', 'name', 'baseSkin'}).isNotEmpty ||
        json['id'] is! String ||
        json['name'] is! String ||
        json['baseSkin'] is! String) {
      throw const FormatException('Invalid piece skin definition');
    }
    try {
      return PieceSkinDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        baseSkin: PieceSkin.values.byName(json['baseSkin'] as String),
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
      baseSkin == other.baseSkin;

  @override
  int get hashCode => Object.hash(id, name, baseSkin);
}

abstract interface class PieceSkinLibraryRepository {
  Future<List<PieceSkinDefinition>> load();
  Future<void> save(List<PieceSkinDefinition> definitions);
}
