import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../ports/piece_images.dart';

typedef PieceImageChooser = Future<XFile?> Function(List<XTypeGroup> types);
typedef PieceImageBatchChooser =
    Future<List<XFile>?> Function(List<XTypeGroup> types);

class FileSelectorPieceImagePicker
    implements PieceImagePicker, PieceImageBatchPicker {
  FileSelectorPieceImagePicker({
    PieceImageChooser? chooser,
    PieceImageBatchChooser? batchChooser,
  }) : _chooser = chooser ?? _choose,
       _batchChooser = batchChooser ?? _chooseMany;

  final PieceImageChooser _chooser;
  final PieceImageBatchChooser _batchChooser;

  static Future<XFile?> _choose(List<XTypeGroup> types) =>
      openFile(acceptedTypeGroups: types);
  static Future<List<XFile>?> _chooseMany(List<XTypeGroup> types) =>
      openFiles(acceptedTypeGroups: types);

  @override
  Future<SelectedPieceImage?> pickImage() async {
    try {
      final file = await _chooser([
        const XTypeGroup(
          label: 'PNG 或 JPEG 图片',
          extensions: ['png', 'jpg', 'jpeg'],
        ),
      ]);
      if (file == null) return null;
      return (await _read(file)).image;
    } on PieceImageException {
      rethrow;
    } on MissingPluginException {
      throw const PieceImageException(PieceImageFailure.unavailable);
    } on UnsupportedError {
      throw const PieceImageException(PieceImageFailure.unavailable);
    } catch (_) {
      throw const PieceImageException(PieceImageFailure.read);
    }
  }

  @override
  Future<List<NamedPieceImage>?> pickImages() async {
    try {
      final files = await _batchChooser([
        const XTypeGroup(
          label: 'PNG 或 JPEG 图片',
          extensions: ['png', 'jpg', 'jpeg'],
        ),
      ]);
      if (files == null) return null;
      if (files.isEmpty) return const [];
      if (files.length > PieceImageLimits.maxBatchFiles) {
        throw const PieceImageException(PieceImageFailure.batchLimit);
      }
      var total = 0;
      final selected = <NamedPieceImage>[];
      for (final file in files) {
        final image = await _read(file);
        total += image.image.bytes.length;
        if (total > PieceImageLimits.maxBatchBytes) {
          throw const PieceImageException(PieceImageFailure.batchLimit);
        }
        selected.add(image);
      }
      return List.unmodifiable(selected);
    } on PieceImageException {
      rethrow;
    } on MissingPluginException {
      throw const PieceImageException(PieceImageFailure.unavailable);
    } on UnsupportedError {
      throw const PieceImageException(PieceImageFailure.unavailable);
    } catch (_) {
      throw const PieceImageException(PieceImageFailure.read);
    }
  }

  Future<NamedPieceImage> _read(XFile file) async {
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    if (!const {'png', 'jpg', 'jpeg'}.contains(extension)) {
      throw const PieceImageException(PieceImageFailure.format);
    }
    if (await file.length() > PieceImageLimits.maxBytes) {
      throw const PieceImageException(PieceImageFailure.tooLarge);
    }
    final builder = BytesBuilder(copy: false);
    final iterator = StreamIterator(file.openRead());
    try {
      while (await iterator.moveNext()) {
        final chunk = iterator.current;
        if (builder.length + chunk.length > PieceImageLimits.maxBytes) {
          throw const PieceImageException(PieceImageFailure.tooLarge);
        }
        builder.add(chunk);
      }
    } finally {
      try {
        await iterator.cancel();
      } catch (_) {
        // A selected handle is not reused.
      }
    }
    return NamedPieceImage(
      name: file.name,
      image: SelectedPieceImage(
        extension,
        Uint8List.fromList(builder.takeBytes()),
      ),
    );
  }
}
