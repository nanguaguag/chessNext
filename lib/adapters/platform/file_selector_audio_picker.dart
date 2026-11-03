import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../ports/audio_library.dart';

typedef AudioFileChooser = Future<XFile?> Function(List<XTypeGroup> types);

class FileSelectorAudioPicker implements AudioFilePicker {
  FileSelectorAudioPicker({AudioFileChooser? chooser})
    : _chooser = chooser ?? _choose;

  final AudioFileChooser _chooser;

  static Future<XFile?> _choose(List<XTypeGroup> types) =>
      openFile(acceptedTypeGroups: types);

  @override
  Future<SelectedAudioFile?> pickAudio() async {
    try {
      final file = await _chooser([
        const XTypeGroup(label: '音效文件', extensions: ['wav', 'mp3']),
      ]);
      if (file == null) return null;
      final extension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : '';
      final length = await file.length();
      if (length > AudioLibraryLimits.maxBytes) {
        throw const AudioLibraryException(AudioLibraryFailure.tooLarge);
      }
      final builder = BytesBuilder(copy: false);
      final iterator = StreamIterator(file.openRead());
      try {
        while (await iterator.moveNext()) {
          final chunk = iterator.current;
          if (builder.length + chunk.length > AudioLibraryLimits.maxBytes) {
            throw const AudioLibraryException(AudioLibraryFailure.tooLarge);
          }
          builder.add(chunk);
        }
      } finally {
        try {
          await iterator.cancel();
        } catch (_) {
          // The selected handle is not reused.
        }
      }
      return SelectedAudioFile(
        extension,
        Uint8List.fromList(builder.takeBytes()),
      );
    } on AudioLibraryException {
      rethrow;
    } on MissingPluginException {
      throw const AudioLibraryException(AudioLibraryFailure.unavailable);
    } on UnsupportedError {
      throw const AudioLibraryException(AudioLibraryFailure.unavailable);
    } catch (_) {
      throw const AudioLibraryException(AudioLibraryFailure.read);
    }
  }
}
