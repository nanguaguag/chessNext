import 'package:flutter/foundation.dart';

import '../ports/board_skin_images.dart';
import '../ports/piece_images.dart' show PieceImageException, PieceImagePicker;
import 'piece_image_validator.dart';

class BoardSkinImageLibraryController extends ChangeNotifier {
  BoardSkinImageLibraryController(this.picker, this.repository);

  final PieceImagePicker picker;
  final BoardSkinImageRepository repository;
  Map<String, Map<BoardSkinImageSlot, Uint8List>> _images = const {};
  bool loading = false;
  BoardSkinImageSlot? busySlot;
  BoardSkinImageSlot? errorSlot;
  String? error;
  bool _disposed = false;

  Uint8List? imageFor(String skinId, BoardSkinImageSlot slot) =>
      _images[skinId]?[slot];

  Map<BoardSkinImageSlot, Uint8List> imagesFor(String skinId) =>
      _images[skinId] ?? const {};

  Future<void> cloneSkin(String sourceId, String destinationId) async {
    await repository.cloneSkin(sourceId, destinationId);
    if (_disposed) return;
    final source = _images[sourceId];
    if (source != null) {
      _images = Map.unmodifiable({
        ..._images,
        destinationId: Map<BoardSkinImageSlot, Uint8List>.unmodifiable({
          for (final entry in source.entries)
            entry.key: Uint8List.fromList(entry.value).asUnmodifiableView(),
        }),
      });
      _notify();
    }
  }

  Future<void> removeSkin(String skinId) async {
    await repository.removeSkin(skinId);
    if (_disposed) return;
    final next = Map<String, Map<BoardSkinImageSlot, Uint8List>>.from(_images)
      ..remove(skinId);
    _images = Map.unmodifiable(next);
    _notify();
  }

  Map<String, Map<BoardSkinImageSlot, Uint8List>> get snapshot =>
      Map.unmodifiable({
        for (final entry in _images.entries)
          entry.key: Map<BoardSkinImageSlot, Uint8List>.unmodifiable(
            entry.value,
          ),
      });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_disposed || loading) return;
    loading = true;
    error = null;
    _notify();
    try {
      final loaded = await repository.load();
      if (_disposed) return;
      _images = Map.unmodifiable({
        for (final entry in loaded.entries)
          entry.key: Map<BoardSkinImageSlot, Uint8List>.unmodifiable({
            for (final image in entry.value.entries)
              image.key: Uint8List.fromList(image.value).asUnmodifiableView(),
          }),
      });
    } catch (_) {
      error = '棋盘皮肤图片读取失败，原文件仍保留。';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> replace(String skinId, BoardSkinImageSlot slot) async {
    if (_disposed || loading || busySlot != null) return false;
    busySlot = slot;
    errorSlot = null;
    error = null;
    _notify();
    try {
      final selected = await picker.pickImage();
      if (selected == null || _disposed) return false;
      PieceImageValidator.validate(selected);
      await repository.save(skinId, slot, selected.extension, selected.bytes);
      if (_disposed) return false;
      _setImage(skinId, slot, selected.bytes);
      return true;
    } on PieceImageException catch (exception) {
      errorSlot = slot;
      error = exception.message;
      return false;
    } catch (_) {
      errorSlot = slot;
      error = '棋盘皮肤图片未能保存，请检查本机空间后重试。';
      return false;
    } finally {
      busySlot = null;
      _notify();
    }
  }

  Future<bool> reset(String skinId, BoardSkinImageSlot slot) async {
    if (_disposed || loading || busySlot != null) return false;
    busySlot = slot;
    errorSlot = null;
    error = null;
    _notify();
    try {
      await repository.remove(skinId, slot);
      if (_disposed) return false;
      final next = Map<String, Map<BoardSkinImageSlot, Uint8List>>.from(
        _images,
      );
      final skinImages = Map<BoardSkinImageSlot, Uint8List>.from(
        next[skinId] ?? const {},
      )..remove(slot);
      if (skinImages.isEmpty) {
        next.remove(skinId);
      } else {
        next[skinId] = skinImages;
      }
      _images = Map.unmodifiable(next);
      return true;
    } catch (_) {
      errorSlot = slot;
      error = '默认棋盘图片未能恢复，请重试。';
      return false;
    } finally {
      busySlot = null;
      _notify();
    }
  }

  void _setImage(String skinId, BoardSkinImageSlot slot, Uint8List bytes) {
    final next = Map<String, Map<BoardSkinImageSlot, Uint8List>>.from(_images);
    next[skinId] = Map<BoardSkinImageSlot, Uint8List>.from(
      next[skinId] ?? const {},
    )..[slot] = Uint8List.fromList(bytes).asUnmodifiableView();
    _images = Map.unmodifiable({
      ...next,
      skinId: Map<BoardSkinImageSlot, Uint8List>.unmodifiable(next[skinId]!),
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MemoryBoardSkinImageRepository implements BoardSkinImageRepository {
  Map<String, Map<BoardSkinImageSlot, Uint8List>> _values = {};

  @override
  Future<Map<String, Map<BoardSkinImageSlot, Uint8List>>> load() async => {
    for (final entry in _values.entries)
      entry.key: {
        for (final image in entry.value.entries)
          image.key: Uint8List.fromList(image.value),
      },
  };

  @override
  Future<void> save(
    String skinId,
    BoardSkinImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    final next = Map<String, Map<BoardSkinImageSlot, Uint8List>>.from(_values);
    next[skinId] = Map<BoardSkinImageSlot, Uint8List>.from(
      next[skinId] ?? const {},
    )..[slot] = Uint8List.fromList(bytes);
    _values = next;
  }

  @override
  Future<void> remove(String skinId, BoardSkinImageSlot slot) async {
    final next = Map<String, Map<BoardSkinImageSlot, Uint8List>>.from(_values);
    final skinImages = Map<BoardSkinImageSlot, Uint8List>.from(
      next[skinId] ?? const {},
    )..remove(slot);
    if (skinImages.isEmpty) {
      next.remove(skinId);
    } else {
      next[skinId] = skinImages;
    }
    _values = next;
  }

  @override
  Future<void> removeSkin(String skinId) async {
    final next = Map<String, Map<BoardSkinImageSlot, Uint8List>>.from(_values)
      ..remove(skinId);
    _values = next;
  }

  @override
  Future<void> cloneSkin(String sourceId, String destinationId) async {
    final source = _values[sourceId];
    if (source == null) return;
    _values = {
      ..._values,
      destinationId: {
        for (final entry in source.entries)
          entry.key: Uint8List.fromList(entry.value),
      },
    };
  }
}
