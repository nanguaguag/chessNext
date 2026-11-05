import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../ports/feedback_service.dart';

typedef FeedbackAttachmentChooser =
    Future<List<XFile>?> Function(List<XTypeGroup> types);

final class FileSelectorFeedbackAttachmentPicker
    implements FeedbackAttachmentPicker {
  FileSelectorFeedbackAttachmentPicker({FeedbackAttachmentChooser? chooser})
    : _chooser = chooser ?? _choose;

  final FeedbackAttachmentChooser _chooser;

  static Future<List<XFile>?> _choose(List<XTypeGroup> types) =>
      openFiles(acceptedTypeGroups: types);

  @override
  Future<List<FeedbackAttachment>?> pickAttachments({
    required int remaining,
  }) async {
    if (remaining <= 0) throw const FeedbackAttachmentPickerException.limit();
    try {
      final files = await _chooser([
        const XTypeGroup(
          label: 'PNG/JPEG 图片',
          extensions: ['png', 'jpg', 'jpeg'],
        ),
      ]);
      if (files == null) return null;
      if (files.isEmpty) return const [];
      if (files.length > remaining) {
        throw const FeedbackAttachmentPickerException.limit();
      }
      final selected = <FeedbackAttachment>[];
      var total = 0;
      for (final file in files) {
        final extension = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : '';
        final mimeType = switch (extension) {
          'png' => 'image/png',
          'jpg' || 'jpeg' => 'image/jpeg',
          _ => throw const FeedbackAttachmentPickerException.format(),
        };
        final length = await file.length();
        if (length <= 0 || length > FeedbackAttachment.maxBytes) {
          throw const FeedbackAttachmentPickerException.size();
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in file.openRead()) {
          if (builder.length + chunk.length > FeedbackAttachment.maxBytes) {
            throw const FeedbackAttachmentPickerException.size();
          }
          builder.add(chunk);
        }
        final bytes = builder.takeBytes();
        if (bytes.length != length) {
          throw const FeedbackAttachmentPickerException.read();
        }
        total += bytes.length;
        if (total > FeedbackAttachment.maxTotalBytes) {
          throw const FeedbackAttachmentPickerException.size();
        }
        selected.add(
          FeedbackAttachment(
            name: _basename(file.name),
            mimeType: mimeType,
            bytes: Uint8List.fromList(bytes),
          ),
        );
      }
      return List.unmodifiable(selected);
    } on FeedbackAttachmentPickerException {
      rethrow;
    } on MissingPluginException {
      throw const FeedbackAttachmentPickerException.unavailable();
    } on UnsupportedError {
      throw const FeedbackAttachmentPickerException.unavailable();
    } on ArgumentError {
      throw const FeedbackAttachmentPickerException.format();
    } catch (_) {
      throw const FeedbackAttachmentPickerException.read();
    }
  }

  static String _basename(String name) => name.split(RegExp(r'[/\\]')).last;
}
