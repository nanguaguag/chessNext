import 'dart:convert';
import 'dart:typed_data';

enum FeedbackKind { problem, suggestion }

final class FeedbackAttachment {
  FeedbackAttachment({
    required this.name,
    required this.mimeType,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes) {
    final safeName = name.trim();
    final png =
        mimeType == 'image/png' &&
        this.bytes.length >= 8 &&
        this.bytes.take(8).join(',') == '137,80,78,71,13,10,26,10';
    final jpeg =
        mimeType == 'image/jpeg' &&
        this.bytes.length >= 3 &&
        this.bytes[0] == 0xff &&
        this.bytes[1] == 0xd8 &&
        this.bytes[2] == 0xff;
    if (safeName.isEmpty ||
        safeName.length > 120 ||
        safeName.contains(RegExp(r'[/\\\u0000-\u001f]')) ||
        this.bytes.isEmpty ||
        this.bytes.length > maxBytes ||
        !(png || jpeg)) {
      throw ArgumentError('Invalid feedback attachment');
    }
  }

  static const maxBytes = 256 * 1024;
  static const maxAttachments = 3;
  static const maxTotalBytes = 512 * 1024;
  final String name;
  final String mimeType;
  final Uint8List bytes;
}

abstract interface class FeedbackAttachmentPicker {
  Future<List<FeedbackAttachment>?> pickAttachments({required int remaining});
}

final class FeedbackAttachmentPickerException implements Exception {
  const FeedbackAttachmentPickerException._(this.reason);
  const FeedbackAttachmentPickerException.limit()
    : this._(FeedbackAttachmentPickerFailure.limit);
  const FeedbackAttachmentPickerException.size()
    : this._(FeedbackAttachmentPickerFailure.size);
  const FeedbackAttachmentPickerException.format()
    : this._(FeedbackAttachmentPickerFailure.format);
  const FeedbackAttachmentPickerException.read()
    : this._(FeedbackAttachmentPickerFailure.read);
  const FeedbackAttachmentPickerException.unavailable()
    : this._(FeedbackAttachmentPickerFailure.unavailable);
  final FeedbackAttachmentPickerFailure reason;
}

enum FeedbackAttachmentPickerFailure { limit, size, format, read, unavailable }

final class FeedbackSubmission {
  FeedbackSubmission({
    required this.kind,
    required this.message,
    this.contact = '',
    List<FeedbackAttachment> attachments = const [],
  }) : attachments = List.unmodifiable(attachments) {
    if (message.trim().isEmpty ||
        message.length > 2000 ||
        contact.length > 200 ||
        utf8.encode(message).length > 10000 ||
        utf8.encode(contact).length > 1000 ||
        this.attachments.length > FeedbackAttachment.maxAttachments ||
        this.attachments.fold<int>(0, (sum, item) => sum + item.bytes.length) >
            FeedbackAttachment.maxTotalBytes) {
      throw ArgumentError('Invalid feedback submission');
    }
  }

  final FeedbackKind kind;
  final String message;
  final String contact;
  final List<FeedbackAttachment> attachments;
}

abstract interface class FeedbackService {
  Future<void> submit({
    required Uri endpoint,
    required FeedbackSubmission feedback,
  });
}

sealed class FeedbackServiceException implements Exception {
  const FeedbackServiceException();
}

final class FeedbackServiceUnavailable extends FeedbackServiceException {
  const FeedbackServiceUnavailable();
}

final class FeedbackServiceInvalidResponse extends FeedbackServiceException {
  const FeedbackServiceInvalidResponse();
}

final class FeedbackServiceRejected extends FeedbackServiceException {
  const FeedbackServiceRejected(this.statusCode);
  final int statusCode;
}
