import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ports/piece_images.dart';
import 'piece_image_validator.dart';

class PieceImageLibraryController extends ChangeNotifier {
  PieceImageLibraryController(this.picker, this.repository);

  final PieceImagePicker picker;
  final PieceImageRepository repository;
  Map<PieceSkin, Map<PieceImageSlot, Uint8List>> _images = const {};
  bool loading = false;
  PieceImageSlot? busySlot;
  PieceImageSlot? errorSlot;
  String? error;
  bool _disposed = false;

  Uint8List? imageFor(PieceSkin skin, PieceImageSlot slot) =>
      _images[skin]?[slot];

  Map<PieceImageSlot, Uint8List> imagesFor(PieceSkin skin) =>
      _images[skin] ?? const {};

  Map<PieceSkin, Map<PieceImageSlot, Uint8List>> get snapshot =>
      Map.unmodifiable({
        for (final entry in _images.entries)
          entry.key: Map<PieceImageSlot, Uint8List>.unmodifiable(entry.value),
      });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_disposed || loading) return;
    loading = true;
    _notify();
    try {
      final loaded = await repository.load();
      if (_disposed) return;
      _images = Map.unmodifiable({
        for (final entry in loaded.entries)
          entry.key: Map<PieceImageSlot, Uint8List>.unmodifiable({
            for (final image in entry.value.entries)
              image.key: Uint8List.fromList(image.value).asUnmodifiableView(),
          }),
      });
    } catch (_) {
      error = '棋子图片读取失败，原图片文件仍保留。';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> replace(PieceSkin skin, PieceImageSlot slot) async {
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
      error = '棋子图片未能保存，请检查本机空间后重试。';
      return false;
    } finally {
      busySlot = null;
      _notify();
    }
  }

  Future<bool> reset(PieceSkin skin, PieceImageSlot slot) async {
    if (_disposed || loading || busySlot != null) return false;
    busySlot = slot;
    errorSlot = null;
    error = null;
    _notify();
    try {
      await repository.remove(skin, slot);
      if (_disposed) return false;
      final next = Map<PieceSkin, Map<PieceImageSlot, Uint8List>>.from(_images);
      final skinImages = Map<PieceImageSlot, Uint8List>.from(
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
      error = '默认棋子图片未能恢复，请重试。';
      return false;
    } finally {
      busySlot = null;
      _notify();
    }
  }

  void _setImage(PieceSkin skin, PieceImageSlot slot, Uint8List bytes) {
    final next = Map<PieceSkin, Map<PieceImageSlot, Uint8List>>.from(_images);
    next[skin] = Map<PieceImageSlot, Uint8List>.from(next[skin] ?? const {})
      ..[slot] = Uint8List.fromList(bytes).asUnmodifiableView();
    _images = Map.unmodifiable({
      ...next,
      skin: Map<PieceImageSlot, Uint8List>.unmodifiable(next[skin]!),
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MemoryPieceImageRepository implements PieceImageRepository {
  Map<PieceSkin, Map<PieceImageSlot, Uint8List>> _values = {};

  @override
  Future<Map<PieceSkin, Map<PieceImageSlot, Uint8List>>> load() async => {
    for (final entry in _values.entries)
      entry.key: {
        for (final image in entry.value.entries)
          image.key: Uint8List.fromList(image.value),
      },
  };

  @override
  Future<void> save(
    PieceSkin skin,
    PieceImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    final next = Map<PieceSkin, Map<PieceImageSlot, Uint8List>>.from(_values);
    next[skin] = Map<PieceImageSlot, Uint8List>.from(next[skin] ?? const {})
      ..[slot] = Uint8List.fromList(bytes);
    _values = next;
  }

  @override
  Future<void> remove(PieceSkin skin, PieceImageSlot slot) async {
    final next = Map<PieceSkin, Map<PieceImageSlot, Uint8List>>.from(_values);
    final skinImages = Map<PieceImageSlot, Uint8List>.from(
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

class CancelPieceImagePicker implements PieceImagePicker {
  const CancelPieceImagePicker();
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
}
