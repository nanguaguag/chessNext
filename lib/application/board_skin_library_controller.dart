import 'dart:math';

import 'package:flutter/foundation.dart';

import '../ports/board_skin_images.dart';
import '../ports/board_skin_library.dart';
import 'board_skin_geometry.dart';
import 'board_skin_image_library_controller.dart';
import 'preferences_controller.dart';

final class BoardSkinLibraryController extends ChangeNotifier {
  BoardSkinLibraryController(this.repository, this.images, this.preferences);

  final BoardSkinLibraryRepository repository;
  final BoardSkinImageLibraryController images;
  final PreferencesController preferences;
  List<BoardSkinDefinition> profiles = const [];
  bool loading = false;
  String? error;
  bool _disposed = false;

  BoardSkinDefinition? definitionFor(String id) =>
      profiles.where((profile) => profile.id == id).firstOrNull;

  BoardSkinGeometry geometryFor(String id) =>
      definitionFor(id)?.geometry ??
      preferences.value.boardGeometries[preferences.value.boardSkin] ??
      const BoardSkinGeometry.standard();

  String get selectedName {
    final id = preferences.value.selectedBoardSkinId;
    final builtIn = BoardSkin.values
        .where((skin) => skin.name == id)
        .firstOrNull;
    if (builtIn != null) return builtIn.label;
    return definitionFor(id)?.name ?? id;
  }

  Future<void> initialize() async {
    if (_disposed || loading) return;
    loading = true;
    _notify();
    try {
      profiles = List.unmodifiable(await repository.load());
      final selectedId = preferences.value.selectedBoardSkinId;
      if (!BoardSkin.values.any((skin) => skin.name == selectedId) &&
          definitionFor(selectedId) == null) {
        await preferences.setBoardSkin(preferences.value.boardSkin);
      }
    } catch (_) {
      error = '本机棋盘皮肤目录读取失败。';
      if (!BoardSkin.values.any(
        (skin) => skin.name == preferences.value.selectedBoardSkinId,
      )) {
        await preferences.setBoardSkin(preferences.value.boardSkin);
      }
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> selectBuiltIn(BoardSkin skin) => preferences.setBoardSkin(skin);

  Future<void> select(String id) async {
    final builtIn = BoardSkin.values
        .where((skin) => skin.name == id)
        .firstOrNull;
    if (builtIn != null) {
      await selectBuiltIn(builtIn);
      return;
    }
    final profile = definitionFor(id);
    if (profile == null || loading) return;
    await preferences.selectBoardSkin(profile.baseSkin, profile.id);
  }

  Future<bool> create({required String name}) async {
    final normalized = name.trim();
    if (loading ||
        profiles.length >= 64 ||
        normalized.isEmpty ||
        normalized.runes.length > BoardSkinDefinition.maxNameRunes ||
        normalized.runes.any((rune) => rune < 32 || rune == 127) ||
        profiles.any((p) => p.name.toLowerCase() == normalized.toLowerCase())) {
      error = '名称不能为空或重复，棋盘皮肤数量最多64套。';
      _notify();
      return false;
    }
    loading = true;
    error = null;
    _notify();
    final id = _newId();
    final currentId = preferences.value.selectedBoardSkinId;
    final currentDefinition = definitionFor(currentId);
    final baseSkin = currentDefinition?.baseSkin ?? preferences.value.boardSkin;
    final geometry =
        currentDefinition?.geometry ??
        preferences.value.boardGeometries[baseSkin] ??
        const BoardSkinGeometry.standard();
    try {
      await images.cloneSkin(currentId, id);
      final next = [
        ...profiles,
        BoardSkinDefinition(
          id: id,
          name: normalized,
          baseSkin: baseSkin,
          geometry: geometry,
        ),
      ];
      await repository.save(next);
      profiles = List.unmodifiable(next);
      await preferences.selectBoardSkin(baseSkin, id);
      return true;
    } catch (_) {
      try {
        await images.removeSkin(id);
      } catch (_) {}
      error = '创建棋盘皮肤失败，当前样式保持不变。';
      return false;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> rename(String id, String name) async {
    final profile = definitionFor(id);
    final normalized = name.trim();
    if (loading ||
        profile == null ||
        normalized.isEmpty ||
        normalized.runes.length > BoardSkinDefinition.maxNameRunes ||
        normalized.runes.any((rune) => rune < 32 || rune == 127) ||
        profiles.any(
          (item) =>
              item.id != id &&
              item.name.toLowerCase() == normalized.toLowerCase(),
        )) {
      error = '名称不能为空或与其他棋盘皮肤重复。';
      _notify();
      return false;
    }
    return _save(
      profiles
          .map((item) => item.id == id ? item.copyWith(name: normalized) : item)
          .toList(),
    );
  }

  Future<bool> updateGeometry(String id, BoardSkinGeometry geometry) async {
    final profile = definitionFor(id);
    if (loading) return false;
    if (profile == null) {
      await preferences.setBoardSkinGeometry(
        preferences.value.boardSkin,
        geometry,
      );
      return true;
    }
    return _save(
      profiles
          .map(
            (item) => item.id == id ? item.copyWith(geometry: geometry) : item,
          )
          .toList(),
    );
  }

  Future<bool> delete(String id) async {
    final profile = definitionFor(id);
    if (loading || profile == null) return false;
    loading = true;
    error = null;
    _notify();
    try {
      if (preferences.value.selectedBoardSkinId == id) {
        await preferences.setBoardSkin(profile.baseSkin);
      }
      final next = profiles.where((item) => item.id != id).toList();
      await repository.save(next);
      profiles = List.unmodifiable(next);
      try {
        await images.removeSkin(id);
      } catch (_) {
        error = '棋盘皮肤已删除，但图片缓存清理失败。';
      }
      return true;
    } catch (_) {
      error = '删除棋盘皮肤失败，请检查本机存储后重试。';
      return false;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> _save(List<BoardSkinDefinition> next) async {
    if (loading) return false;
    loading = true;
    error = null;
    _notify();
    try {
      await repository.save(next);
      profiles = List.unmodifiable(next);
      return true;
    } catch (_) {
      error = '棋盘皮肤未能保存在本机，请重试。';
      return false;
    } finally {
      loading = false;
      _notify();
    }
  }

  String _newId() {
    final random = Random.secure();
    return 'custom-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0')}';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final class MemoryBoardSkinLibraryRepository
    implements BoardSkinLibraryRepository {
  List<BoardSkinDefinition> _profiles = const [];

  @override
  Future<List<BoardSkinDefinition>> load() async =>
      List.unmodifiable(_profiles);

  @override
  Future<void> save(List<BoardSkinDefinition> profiles) async {
    if (profiles.length > 64 ||
        profiles.map((item) => item.id).toSet().length != profiles.length ||
        profiles.map((item) => item.name.toLowerCase()).toSet().length !=
            profiles.length) {
      throw const FormatException('Invalid board skin profiles');
    }
    _profiles = List.unmodifiable(profiles);
  }
}
