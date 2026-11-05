import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../ports/copyright_complaint_service.dart';
import '../../ports/feedback_service.dart';

const _maxFeedbackResponseBytes = 4096;

final class HttpFeedbackService
    implements FeedbackService, CopyrightComplaintService {
  HttpFeedbackService({
    HttpClient? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;

  void close() => _client.close(force: true);

  @override
  Future<void> submit({
    required Uri endpoint,
    required FeedbackSubmission feedback,
  }) async {
    await _post(
      endpoint: endpoint,
      path: '/v1/feedback',
      body: <String, Object>{
        'schema': 1,
        'kind': feedback.kind.name,
        'message': feedback.message,
        if (feedback.contact.trim().isNotEmpty)
          'contact': feedback.contact.trim(),
        if (feedback.attachments.isNotEmpty)
          'attachments': [
            for (final attachment in feedback.attachments)
              {
                'name': attachment.name,
                'mimeType': attachment.mimeType,
                'data': base64Encode(attachment.bytes),
              },
          ],
      },
      maxRequestBytes: 786432,
    );
  }

  Future<void> _post({
    required Uri endpoint,
    required String path,
    required Map<String, Object> body,
    int maxRequestBytes = 16384,
  }) async {
    if (!_validEndpoint(endpoint)) throw const FeedbackServiceInvalidResponse();
    final uri = endpoint.replace(
      path: '${endpoint.path.replaceFirst(RegExp(r'/+$'), '')}$path',
      query: null,
      fragment: null,
    );
    final encodedBody = utf8.encode(jsonEncode(body));
    if (encodedBody.length > maxRequestBytes) {
      throw const FeedbackServiceInvalidResponse();
    }
    try {
      final request = await _client.postUrl(uri).timeout(timeout);
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, 'application/json');
      request.followRedirects = false;
      request.add(encodedBody);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.created) {
        await response.drain<void>();
        throw FeedbackServiceRejected(response.statusCode);
      }
      if (response.contentLength > _maxFeedbackResponseBytes) {
        await response.drain<void>();
        throw const FeedbackServiceInvalidResponse();
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        if (bytes.length + chunk.length > _maxFeedbackResponseBytes) {
          throw const FeedbackServiceInvalidResponse();
        }
        bytes.addAll(chunk);
      }
      final result = jsonDecode(utf8.decode(bytes));
      if (result is! Map<String, dynamic> ||
          result['schema'] != 1 ||
          result['accepted'] != true ||
          result.keys.toSet().difference({'schema', 'accepted'}).isNotEmpty) {
        throw const FeedbackServiceInvalidResponse();
      }
    } on FeedbackServiceException {
      rethrow;
    } on TimeoutException {
      throw const FeedbackServiceUnavailable();
    } on SocketException {
      throw const FeedbackServiceUnavailable();
    } on HttpException {
      throw const FeedbackServiceUnavailable();
    } on FormatException {
      throw const FeedbackServiceInvalidResponse();
    }
  }

  @override
  Future<void> submitCopyrightComplaint({
    required Uri endpoint,
    required CopyrightComplaintSubmission complaint,
  }) async {
    await _post(
      endpoint: endpoint,
      path: '/v1/copyright/complaints',
      body: <String, Object>{
        'schema': 1,
        'complainant': complaint.complainant.trim(),
        'email': complaint.email.trim(),
        'work': complaint.work.trim(),
        'ownership': complaint.ownership.trim(),
        'content': complaint.content.trim(),
        if (complaint.details.trim().isNotEmpty)
          'details': complaint.details.trim(),
        if (complaint.attachments.isNotEmpty)
          'attachments': [
            for (final attachment in complaint.attachments)
              {
                'name': attachment.name,
                'mimeType': attachment.mimeType,
                'data': base64Encode(attachment.bytes),
              },
          ],
      },
      maxRequestBytes: 786432,
    );
  }

  static bool _validEndpoint(Uri uri) {
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return false;
    }
    if (uri.scheme == 'https') return uri.host.isNotEmpty;
    return uri.scheme == 'http' &&
        {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
  }
}
