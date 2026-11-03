import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../application/piece_skin_package_codec.dart';
import '../../ports/piece_skin_package_picker.dart';

typedef SkinPackageChooser = Future<XFile?> Function(List<XTypeGroup> types);

class FileSelectorPieceSkinPackagePicker implements PieceSkinPackagePicker {
  FileSelectorPieceSkinPackagePicker({
    SkinPackageChooser? chooser,
    this.readTimeout = const Duration(seconds: 8),
  }) : _chooser = chooser ?? _choose;

  final SkinPackageChooser _chooser;
  final Duration readTimeout;
  static Future<XFile?> _choose(List<XTypeGroup> types) =>
      openFile(acceptedTypeGroups: types);

  @override
  Future<Uint8List?> pickZip() async {
    try {
      final file = await _chooser([
        const XTypeGroup(label: '本机棋子皮肤ZIP', extensions: ['zip']),
      ]);
      if (file == null) return null;
      final length = await file.length().timeout(readTimeout);
      if (length < 22 || length > PieceSkinPackageCodec.maxArchiveBytes) {
        throw const PieceSkinPackageReadException(
          PieceSkinPackageReadFailure.tooLarge,
        );
      }
      final bytes = BytesBuilder(copy: false);
      final stream = StreamIterator(file.openRead());
      final watch = Stopwatch()..start();
      try {
        while (true) {
          final remaining = readTimeout - watch.elapsed;
          if (remaining <= Duration.zero) throw TimeoutException('read');
          if (!await stream.moveNext().timeout(remaining)) break;
          final chunk = stream.current;
          if (bytes.length + chunk.length >
              PieceSkinPackageCodec.maxArchiveBytes) {
            throw const PieceSkinPackageReadException(
              PieceSkinPackageReadFailure.tooLarge,
            );
          }
          bytes.add(chunk);
        }
      } finally {
        try {
          await stream.cancel().timeout(readTimeout);
        } catch (_) {}
      }
      return Uint8List.fromList(bytes.takeBytes());
    } on PieceSkinPackageReadException {
      rethrow;
    } on MissingPluginException {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.unavailable,
      );
    } on UnsupportedError {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.unavailable,
      );
    } on TimeoutException {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.read,
      );
    } catch (_) {
      throw const PieceSkinPackageReadException(
        PieceSkinPackageReadFailure.read,
      );
    }
  }
}
