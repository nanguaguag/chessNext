import 'package:flutter/foundation.dart';

import '../ports/board_skin_images.dart';
import '../ports/piece_images.dart' show PieceImageException, PieceImagePicker;
import 'piece_image_validator.dart';

class BoardSkinImageLibraryController extends ChangeNotifier {
  BoardSkinImageLibraryController(this.picker, this.repository);

  final PieceImagePicker picker;
  final BoardSkinImageRepository repository;
  Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>> _images = const {};
  bool loading = false;
  BoardSkinImageSlot? busySlot;
  BoardSkinImageSlot? errorSlot;
  String? error;
  bool _disposed = false;

  Uint8List? imageFor(BoardSkin skin, BoardSkinImageSlot slot) =>
      _images[skin]?[slot];

  Map<BoardSkinImageSlot, Uint8List> imagesFor(BoardSkin skin) =>
      _images[skin] ?? const {};

  Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>> get snapshot =>
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

  Future<bool> replace(BoardSkin skin, BoardSkinImageSlot slot) async {
    if (_disposed || loading || busySlot != null) return false;
    busySlot = slot;
    errorSlot = null;
    error = null;
    _notify();
    try {
      final selected = await picker.pickImage();
      if (selected == null || _disposed) return false;
      PieceImageValidator.validate(selected);
      await repository.save(skin, slot, selected.extension, selected.bytes);
      if (_disposed) return false;
      _setImage(skin, slot, selected.bytes);
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

  Future<bool> reset(BoardSkin skin, BoardSkinImageSlot slot) async {
    if (_disposed || loading || busySlot != null) return false;
    busySlot = slot;
    errorSlot = null;
    error = null;
    _notify();
    try {
      await repository.remove(skin, slot);
      if (_disposed) return false;
      final next = Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>>.from(
        _images,
      );
      final skinImages = Map<BoardSkinImageSlot, Uint8List>.from(
        next[skin] ?? const {},
      )..remove(slot);
      if (skinImages.isEmpty) {
        next.remove(skin);
      } else {
        next[skin] = skinImages;
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

  void _setImage(BoardSkin skin, BoardSkinImageSlot slot, Uint8List bytes) {
    final next = Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>>.from(
      _images,
    );
    next[skin] = Map<BoardSkinImageSlot, Uint8List>.from(next[skin] ?? const {})
      ..[slot] = Uint8List.fromList(bytes).asUnmodifiableView();
    _images = Map.unmodifiable({
      ...next,
      skin: Map<BoardSkinImageSlot, Uint8List>.unmodifiable(next[skin]!),
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MemoryBoardSkinImageRepository implements BoardSkinImageRepository {
  Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>> _values = {};

  @override
  Future<Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>>> load() async => {
    for (final entry in _values.entries)
      entry.key: {
        for (final image in entry.value.entries)
          image.key: Uint8List.fromList(image.value),
      },
  };

  @override
  Future<void> save(
    BoardSkin skin,
    BoardSkinImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    final next = Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>>.from(
      _values,
    );
    next[skin] = Map<BoardSkinImageSlot, Uint8List>.from(next[skin] ?? const {})
      ..[slot] = Uint8List.fromList(bytes);
    _values = next;
  }

  @override
  Future<void> remove(BoardSkin skin, BoardSkinImageSlot slot) async {
    final next = Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>>.from(
      _values,
    );
    final skinImages = Map<BoardSkinImageSlot, Uint8List>.from(
      next[skin] ?? const {},
    )..remove(slot);
    if (skinImages.isEmpty) {
      next.remove(skin);
    } else {
      next[skin] = skinImages;
    }
    _values = next;
  }
}
