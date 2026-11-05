import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../ports/feedback_service.dart';

const _maxFeedbackResponseBytes = 4096;

final class HttpFeedbackService implements FeedbackService {
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
    if (!_validEndpoint(endpoint)) throw const FeedbackServiceInvalidResponse();
    final uri = endpoint.replace(
      path: '${endpoint.path.replaceFirst(RegExp(r'/+$'), '')}/v1/feedback',
      query: null,
      fragment: null,
    );
    final body = utf8.encode(
      jsonEncode({
        'schema': 1,
        'kind': feedback.kind.name,
        'message': feedback.message,
        if (feedback.contact.trim().isNotEmpty)
          'contact': feedback.contact.trim(),
      }),
    );
    try {
      final request = await _client.postUrl(uri).timeout(timeout);
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, 'application/json');
      request.followRedirects = false;
      request.add(body);
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

  static bool _validEndpoint(Uri uri) {
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return false;
    }
    if (uri.scheme == 'https') return uri.host.isNotEmpty;
    return uri.scheme == 'http' &&
        {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
  }
}
