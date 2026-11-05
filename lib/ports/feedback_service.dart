import 'dart:convert';

enum FeedbackKind { problem, suggestion }

final class FeedbackSubmission {
  FeedbackSubmission({
    required this.kind,
    required this.message,
    this.contact = '',
  }) {
    if (message.trim().isEmpty ||
        message.length > 2000 ||
        contact.length > 200 ||
        utf8.encode(message).length > 10000 ||
        utf8.encode(contact).length > 1000) {
      throw ArgumentError('Invalid feedback submission');
    }
  }

  final FeedbackKind kind;
  final String message;
  final String contact;
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
