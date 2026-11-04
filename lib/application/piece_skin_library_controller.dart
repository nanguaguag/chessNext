import 'dart:math';
import 'package:flutter/foundation.dart';
import '../ports/piece_images.dart';
import '../ports/piece_skin_library.dart';
import '../ports/piece_skin_shadow.dart';
import 'piece_skin_package_codec.dart';
import 'piece_image_library_controller.dart';
import 'preferences_controller.dart';

class PieceSkinLibraryController extends ChangeNotifier {
  PieceSkinLibraryController(this.repository, this.images, this.preferences);
  final PieceSkinLibraryRepository repository;
  final PieceImageLibraryController images;
  final PreferencesController preferences;
  List<PieceSkinDefinition> profiles = const [];
  bool loading = false;
  String? error;
  bool _disposed = false;

  Future<void> initialize() async {
    if (loading || _disposed) return;
    loading = true;
    notifyListeners();
    try {
      profiles = List.unmodifiable(await repository.load());
      if (!PieceSkin.values.any(
            (skin) => skin.name == preferences.value.selectedPieceSkinId,
          ) &&
          !profiles.any(
            (profile) => profile.id == preferences.value.selectedPieceSkinId,
          )) {
        await preferences.setPieceSkin(PieceSkin.roundSeal);
      }
    } catch (_) {
      error = '本机棋子皮肤目录读取失败。';
      if (!PieceSkin.values.any(
        (skin) => skin.name == preferences.value.selectedPieceSkinId,
      )) {
        await preferences.setPieceSkin(preferences.value.pieceSkin);
      }
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  String get selectedName {
    final id = preferences.value.selectedPieceSkinId;
    if (id == PieceSkin.roundSeal.name) return '传统圆章';
    if (id == PieceSkin.squareInk.name) return '方章墨韵';
    for (final item in profiles) {
      if (item.id == id) return item.name;
    }
    return id;
  }

  PieceSkinDefinition? definitionFor(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  Future<void> select(String id) async {
    if (loading) return;
    final builtIn = PieceSkin.values
        .where((skin) => skin.name == id)
        .firstOrNull;
    if (builtIn != null) {
      await preferences.selectPieceSkin(builtIn, builtIn.name);
      return;
    }
    final profile = definitionFor(id);
    if (profile != null) {
      await preferences.selectPieceSkin(profile.baseSkin, id);
    }
  }

  Future<bool> updateAppearance(
    String id, {
    int? scalePercent,
    int? offsetXPercent,
    int? offsetYPercent,
    PieceSkinShadow? shadow,
    bool clearShadow = false,
  }) {
    final profile = definitionFor(id);
    if (profile == null || loading) return Future.value(false);
    final updated = profile.copyWith(
      scalePercent: scalePercent,
      offsetXPercent: offsetXPercent,
      offsetYPercent: offsetYPercent,
      shadow: shadow,
      clearShadow: clearShadow,
    );
    return _save(
      profiles.map((item) => item.id == id ? updated : item).toList(),
    );
  }

  Future<bool> create({required String name}) async {
    final normalized = name.trim();
    if (loading ||
        profiles.length >= 64 ||
        normalized.isEmpty ||
        normalized.runes.length > PieceSkinDefinition.maxNameRunes ||
        normalized.runes.any((rune) => rune < 32 || rune == 127) ||
        profiles.any((p) => p.name.toLowerCase() == normalized.toLowerCase())) {
      error = '名称不能为空或重复，皮肤数量最多64套。';
      notifyListeners();
      return false;
    }
    loading = true;
    error = null;
    notifyListeners();
    final id = _newId();
    final base = preferences.value.pieceSkin;
    try {
      if (!await images.cloneSkinImages(
        preferences.value.selectedPieceSkinId,
        id,
      )) {
        throw StateError('clone failed');
      }
      final active = definitionFor(preferences.value.selectedPieceSkinId);
      final scalePercent =
          active?.scalePercent ??
          (base == PieceSkin.roundSeal
              ? preferences.value.roundSealPieceScalePercent
              : preferences.value.squareInkPieceScalePercent);
      final offsetXPercent =
          active?.offsetXPercent ??
          (base == PieceSkin.roundSeal
              ? preferences.value.roundSealPieceOffsetX
              : preferences.value.squareInkPieceOffsetX);
      final offsetYPercent =
          active?.offsetYPercent ??
          (base == PieceSkin.roundSeal
              ? preferences.value.roundSealPieceOffsetY
              : preferences.value.squareInkPieceOffsetY);
      final shadow =
          active?.shadow ?? preferences.value.pieceSkinShadows[base]!;
      final license = active?.license ?? '';
      final attribution = active?.attribution ?? '';
      final next = [
        ...profiles,
        PieceSkinDefinition(
          id: id,
          name: normalized,
          baseSkin: base,
          scalePercent: scalePercent,
          offsetXPercent: offsetXPercent,
          offsetYPercent: offsetYPercent,
          shadow: shadow,
          license: license,
          attribution: attribution,
        ),
      ];
      await repository.save(next);
      profiles = List.unmodifiable(next);
      await preferences.selectPieceSkin(base, id);
      return true;
    } catch (_) {
      await images.removeSkin(id);
      error = '创建皮肤失败，原皮肤保持不变。';
      return false;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> importPackage(
    PieceSkinPackage package, {
    String license = '',
    String attribution = '',
  }) async {
    final profile = package.profile;
    if (loading ||
        profiles.length >= 64 ||
        profiles.any(
          (item) => item.name.toLowerCase() == profile.name.toLowerCase(),
        )) {
      error = '皮肤名称重复或本机皮肤数量已达上限。';
      notifyListeners();
      return false;
    }
    loading = true;
    error = null;
    notifyListeners();
    final id = _newId();
    final imported = PieceSkinDefinition(
      id: id,
      name: profile.name,
      baseSkin: profile.baseSkin,
      scalePercent: profile.scalePercent,
      offsetXPercent: profile.offsetXPercent,
      offsetYPercent: profile.offsetYPercent,
      shadow: profile.shadow,
      license: license.isEmpty ? profile.license : license,
      attribution: attribution.isEmpty ? profile.attribution : attribution,
    );
    try {
      if (!await images.installPackageImages(id, package.images)) {
        throw StateError('package images could not be installed');
      }
      final next = [...profiles, imported];
      await repository.save(next);
      profiles = List.unmodifiable(next);
      try {
        await preferences.selectPieceSkin(imported.baseSkin, imported.id);
      } catch (_) {
        error = '皮肤已导入，但自动选用失败。';
      }
      return true;
    } catch (_) {
      try {
        await images.discardInstalledSkin(id);
      } catch (_) {}
      error = '导入失败，当前皮肤库保持不变。';
      return false;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  String _newId() =>
      'custom-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(1 << 24).toRadixString(36)}';

  Future<bool> rename(String id, String name) async {
    final normalized = name.trim();
    if (loading ||
        normalized.isEmpty ||
        profiles.any(
          (p) => p.id != id && p.name.toLowerCase() == normalized.toLowerCase(),
        ) ||
        normalized.runes.length > PieceSkinDefinition.maxNameRunes) {
      return false;
    }
    final next = profiles
        .map((p) => p.id == id ? p.copyWith(name: normalized) : p)
        .toList();
    return _save(next);
  }

  Future<bool> delete(String id) async {
    final profile = profiles.where((p) => p.id == id).firstOrNull;
    if (loading || profile == null) return false;
    if (preferences.value.selectedPieceSkinId == id) {
      await preferences.setPieceSkin(profile.baseSkin);
    }
    final next = profiles.where((p) => p.id != id).toList();
    if (!await _save(next)) return false;
    if (!await images.removeSkin(id)) {
      await _save([...profiles, profile]);
      if (preferences.value.selectedPieceSkinId != id) {
        await preferences.selectPieceSkin(profile.baseSkin, id);
      }
      error = '删除皮肤图片失败。';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> _save(List<PieceSkinDefinition> next) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.save(next);
      profiles = List.unmodifiable(next);
      return true;
    } catch (_) {
      error = '皮肤目录保存失败，请重试。';
      return false;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MemoryPieceSkinLibraryRepository implements PieceSkinLibraryRepository {
  List<PieceSkinDefinition> _profiles = const [];
  @override
  Future<List<PieceSkinDefinition>> load() async => List.of(_profiles);
  @override
  Future<void> save(List<PieceSkinDefinition> definitions) async {
    _profiles = List.unmodifiable(definitions);
  }
}
