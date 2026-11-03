import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ports/piece_images.dart';
import 'piece_image_validator.dart';

class PieceImageLibraryController extends ChangeNotifier {
  PieceImageLibraryController(this.picker, this.repository);

  final PieceImagePicker picker;
  final PieceImageRepository repository;
  Map<String, Map<PieceImageSlot, Uint8List>> _images = const {};
  bool loading = false;
  PieceImageSlot? busySlot;
  bool batchBusy = false;
  int batchImportedCount = 0;
  final Set<PieceImageSlot> batchImportedSlots = {};
  PieceImageSlot? errorSlot;
  String? error;
  bool _disposed = false;

  static String _skinId(Object skin) =>
      skin is PieceSkin ? skin.name : skin as String;
  Uint8List? imageFor(Object skin, PieceImageSlot slot) =>
      _images[_skinId(skin)]?[slot];

  Map<PieceImageSlot, Uint8List> imagesFor(Object skin) =>
      _images[_skinId(skin)] ?? const {};

  Map<String, Map<PieceImageSlot, Uint8List>> get snapshot => Map.unmodifiable({
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

  Future<bool> replace(Object skin, PieceImageSlot slot) async {
    final skinId = _skinId(skin);
    if (_disposed || loading || busySlot != null || batchBusy) return false;
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
      error = '棋子图片未能保存，请检查本机空间后重试。';
      return false;
    } finally {
      busySlot = null;
      _notify();
    }
  }

  Future<bool> reset(Object skin, PieceImageSlot slot) async {
    final skinId = _skinId(skin);
    if (_disposed || loading || busySlot != null || batchBusy) return false;
    busySlot = slot;
    errorSlot = null;
    error = null;
    _notify();
    try {
      await repository.remove(skinId, slot);
      if (_disposed) return false;
      final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_images);
      final skinImages = Map<PieceImageSlot, Uint8List>.from(
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
      error = '默认棋子图片未能恢复，请重试。';
      return false;
    } finally {
      busySlot = null;
      _notify();
    }
  }

  Future<List<NamedPieceImage>?> pickBatchImages() async {
    if (_disposed || loading || busySlot != null || batchBusy) return null;
    if (picker is! PieceImageBatchPicker) {
      error = '当前平台不支持多选棋子图片。';
      errorSlot = null;
      _notify();
      return null;
    }
    final batchPicker = picker as PieceImageBatchPicker;
    batchBusy = true;
    batchImportedCount = 0;
    batchImportedSlots.clear();
    error = null;
    errorSlot = null;
    _notify();
    try {
      final selected = await batchPicker.pickImages();
      if (_disposed || selected == null) return selected;
      if (selected.isEmpty) {
        error = '请选择至少一张 PNG/JPEG 图片。';
        return null;
      }
      for (final file in selected) {
        PieceImageValidator.validate(file.image);
      }
      return selected;
    } on PieceImageException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = '读取图片失败，请确认所选文件仍可用。';
      return null;
    } finally {
      batchBusy = false;
      _notify();
    }
  }

  Future<int> importBatch(
    Object skin,
    Map<PieceImageSlot, SelectedPieceImage> images,
  ) async {
    final skinId = _skinId(skin);
    if (_disposed ||
        loading ||
        busySlot != null ||
        batchBusy ||
        images.isEmpty) {
      return 0;
    }
    for (final image in images.values) {
      try {
        PieceImageValidator.validate(image);
      } on PieceImageException catch (exception) {
        error = exception.message;
        errorSlot = null;
        _notify();
        return 0;
      }
    }
    batchBusy = true;
    error = null;
    errorSlot = null;
    _notify();
    try {
      for (final entry in images.entries) {
        if (batchImportedSlots.contains(entry.key)) continue;
        if (_disposed) break;
        busySlot = entry.key;
        _notify();
        final file = entry.value;
        await repository.save(skinId, entry.key, file.extension, file.bytes);
        if (_disposed) break;
        _setImage(skinId, entry.key, file.bytes);
        batchImportedSlots.add(entry.key);
        batchImportedCount++;
      }
    } catch (_) {
      error = batchImportedSlots.isEmpty
          ? '批量导入失败，未写入图片。'
          : '已导入$batchImportedCount张；其余图片保存失败，可重试未完成项。';
    } finally {
      busySlot = null;
      batchBusy = false;
      _notify();
    }
    return batchImportedSlots.length;
  }

  Future<bool> installPackageImages(
    String skinId,
    Map<PieceImageSlot, Uint8List> packageImages,
  ) async {
    if (_disposed || loading || busySlot != null || batchBusy) {
      return false;
    }
    for (final bytes in packageImages.values) {
      final extension = _imageExtension(bytes);
      if (extension == null) return false;
      try {
        PieceImageValidator.validate(SelectedPieceImage(extension, bytes));
      } on PieceImageException catch (exception) {
        error = exception.message;
        _notify();
        return false;
      }
    }
    batchBusy = true;
    batchImportedCount = 0;
    batchImportedSlots.clear();
    error = null;
    _notify();
    final saved = <PieceImageSlot>[];
    try {
      for (final entry in packageImages.entries) {
        final extension = _imageExtension(entry.value)!;
        await repository.save(skinId, entry.key, extension, entry.value);
        saved.add(entry.key);
        batchImportedSlots.add(entry.key);
        batchImportedCount = saved.length;
        _setImage(skinId, entry.key, entry.value);
      }
      return true;
    } catch (_) {
      try {
        await repository.removeSkin(skinId);
      } catch (_) {
        for (final slot in saved) {
          try {
            await repository.remove(skinId, slot);
          } catch (_) {}
        }
      }
      final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_images)
        ..remove(skinId);
      _images = Map.unmodifiable(next);
      error = '皮肤图片导入失败，未添加该皮肤。';
      return false;
    } finally {
      batchBusy = false;
      _notify();
    }
  }

  Future<void> discardInstalledSkin(String skinId) async {
    try {
      await repository.removeSkin(skinId);
    } finally {
      final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_images)
        ..remove(skinId);
      _images = Map.unmodifiable(next);
      _notify();
    }
  }

  static String? _imageExtension(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return null;
  }

  void _setImage(String skin, PieceImageSlot slot, Uint8List bytes) {
    final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_images);
    next[skin] = Map<PieceImageSlot, Uint8List>.from(next[skin] ?? const {})
      ..[slot] = Uint8List.fromList(bytes).asUnmodifiableView();
    _images = Map.unmodifiable({
      ...next,
      skin: Map<PieceImageSlot, Uint8List>.unmodifiable(next[skin]!),
    });
  }

  Future<bool> cloneSkinImages(String sourceId, String destinationId) async {
    if (_disposed || loading || batchBusy || busySlot != null) return false;
    final source = Map<PieceImageSlot, Uint8List>.from(imagesFor(sourceId));
    try {
      await repository.cloneSkin(sourceId, destinationId);
      _images = Map.unmodifiable({
        ..._images,
        if (source.isNotEmpty) destinationId: source,
      });
      _notify();
      return true;
    } catch (_) {
      try {
        await repository.removeSkin(destinationId);
      } catch (_) {}
      return false;
    }
  }

  Future<bool> removeSkin(String skinId) async {
    if (_disposed || loading || batchBusy || busySlot != null) return false;
    try {
      await repository.removeSkin(skinId);
      final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_images)
        ..remove(skinId);
      _images = Map.unmodifiable(next);
      _notify();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MemoryPieceImageRepository implements PieceImageRepository {
  Map<String, Map<PieceImageSlot, Uint8List>> _values = {};

  @override
  Future<Map<String, Map<PieceImageSlot, Uint8List>>> load() async => {
    for (final entry in _values.entries)
      entry.key: {
        for (final image in entry.value.entries)
          image.key: Uint8List.fromList(image.value),
      },
  };

  @override
  Future<void> save(
    String skin,
    PieceImageSlot slot,
    String extension,
    Uint8List bytes,
  ) async {
    final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_values);
    next[skin] = Map<PieceImageSlot, Uint8List>.from(next[skin] ?? const {})
      ..[slot] = Uint8List.fromList(bytes);
    _values = next;
  }

  @override
  Future<void> remove(String skin, PieceImageSlot slot) async {
    final next = Map<String, Map<PieceImageSlot, Uint8List>>.from(_values);
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

  @override
  Future<void> removeSkin(String skin) async {
    _values.remove(skin);
  }

  @override
  Future<void> cloneSkin(String sourceId, String destinationId) async {
    _values[destinationId] = {
      for (final entry
          in _values[sourceId]?.entries ??
              const <MapEntry<PieceImageSlot, Uint8List>>[])
        entry.key: Uint8List.fromList(entry.value),
    };
  }
}

class CancelPieceImagePicker implements PieceImagePicker {
  const CancelPieceImagePicker();
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
}
