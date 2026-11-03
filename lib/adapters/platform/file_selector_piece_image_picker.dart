import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../ports/piece_images.dart';

typedef PieceImageChooser = Future<XFile?> Function(List<XTypeGroup> types);

class FileSelectorPieceImagePicker implements PieceImagePicker {
  FileSelectorPieceImagePicker({PieceImageChooser? chooser})
    : _chooser = chooser ?? _choose;

  final PieceImageChooser _chooser;

  static Future<XFile?> _choose(List<XTypeGroup> types) =>
      openFile(acceptedTypeGroups: types);

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
      return SelectedPieceImage(
        extension,
        Uint8List.fromList(builder.takeBytes()),
      );
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
}
