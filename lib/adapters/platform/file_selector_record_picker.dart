import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../ports/record_file_picker.dart';

typedef RecordFileChooser = Future<XFile?> Function(List<XTypeGroup> types);

class FileSelectorRecordPicker implements RecordFilePicker {
  FileSelectorRecordPicker({
    RecordFileChooser? chooser,
    this.readTimeout = const Duration(seconds: 5),
  }) : _chooser = chooser ?? _choose;
  final RecordFileChooser _chooser;
  final Duration readTimeout;
  static const maxBytes = 256000;
  static const maxCharacters = 64000;

  static Future<XFile?> _choose(List<XTypeGroup> types) =>
      openFile(acceptedTypeGroups: types);

  static List<XTypeGroup> typesFor(TargetPlatform platform) => [
    if (platform == TargetPlatform.iOS)
      const XTypeGroup(label: '棋谱文件', uniformTypeIdentifiers: ['public.data'])
    else
      const XTypeGroup(label: '文字棋谱', extensions: ['pgn', 'fen', 'txt']),
  ];

  @override
  Future<PickedRecordText?> openText() async {
    try {
      // A native dialog can wait indefinitely for the user's choice.
      final file = await _chooser(typesFor(defaultTargetPlatform));
      if (file == null) return null;
      final length = await file.length().timeout(readTimeout);
      if (length < 0) {
        throw const RecordFileException(RecordFileFailure.read);
      }
      if (length > maxBytes) {
        throw const RecordFileException(RecordFileFailure.tooLarge);
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
          if (bytes.length + chunk.length > maxBytes) {
            throw const RecordFileException(RecordFileFailure.tooLarge);
          }
          bytes.add(chunk);
        }
      } finally {
        // Bound even cleanup; cancellation failure must not hide read failure.
        try {
          await stream.cancel().timeout(readTimeout);
        } catch (_) {
          // No document has been touched and this handle is never reused.
        }
      }
      String text;
      try {
        text = utf8.decode(bytes.takeBytes(), allowMalformed: false);
      } on FormatException {
        throw const RecordFileException(RecordFileFailure.encoding);
      }
      if (text.length > maxCharacters) {
        throw const RecordFileException(RecordFileFailure.tooLarge);
      }
      final safeName = file.name
          .replaceAll(RegExp(r'[\x00-\x1f\x7f\u202a-\u202e\u2066-\u2069]'), '')
          .replaceAll(RegExp(r'[/\\]'), '_');
      return PickedRecordText(
        displayName: safeName.isEmpty
            ? '所选文件'
            : String.fromCharCodes(safeName.runes.take(160)),
        text: text,
      );
    } on RecordFileException {
      rethrow;
    } on TimeoutException {
      throw const RecordFileException(RecordFileFailure.timeout);
    } on MissingPluginException {
      throw const RecordFileException(RecordFileFailure.unavailable);
    } on UnsupportedError {
      throw const RecordFileException(RecordFileFailure.unavailable);
    } catch (_) {
      throw const RecordFileException(RecordFileFailure.read);
    }
  }
}
