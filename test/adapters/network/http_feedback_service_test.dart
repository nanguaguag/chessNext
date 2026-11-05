import 'dart:convert';
import 'dart:io';

import 'package:chess_next/adapters/network/http_feedback_service.dart';
import 'package:chess_next/ports/feedback_service.dart';
import 'package:chess_next/ports/copyright_complaint_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late HttpFeedbackService service;
  var statusCode = HttpStatus.created;
  var responseBody = '{"schema":1,"accepted":true}';
  var requestPath = '';
  Map<String, dynamic>? requestBody;
  var requestCount = 0;

  setUp(() async {
    statusCode = HttpStatus.created;
    responseBody = '{"schema":1,"accepted":true}';
    requestPath = '';
    requestBody = null;
    requestCount = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestCount++;
      requestPath = request.uri.path;
      requestBody =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      request.response
        ..statusCode = statusCode
        ..headers.contentType = ContentType.json
        ..write(responseBody);
      await request.response.close();
    });
    service = HttpFeedbackService();
  });

  tearDown(() async {
    service.close();
    await server.close(force: true);
  });

  test('sends only the user-authored fields to configured endpoint', () async {
    await service.submit(
      endpoint: Uri.parse('http://localhost:${server.port}/prefix/'),
      feedback: FeedbackSubmission(
        kind: FeedbackKind.problem,
        message: '按钮无响应',
        contact: 'user@example.test',
      ),
    );
    expect(requestPath, '/prefix/v1/feedback');
    expect(requestBody, {
      'schema': 1,
      'kind': 'problem',
      'message': '按钮无响应',
      'contact': 'user@example.test',
    });
    expect(requestCount, 1);
  });

  test('posts bounded complaint fields to dedicated route', () async {
    await service.submitCopyrightComplaint(
      endpoint: Uri.parse('http://localhost:${server.port}'),
      complaint: CopyrightComplaintSubmission(
        complainant: 'Test Person',
        email: 'person@example.test',
        work: 'Test work',
        ownership: 'Created by complainant',
        content: 'https://example.test/item',
        details: 'No attachment',
      ),
    );
    expect(requestPath, '/v1/copyright/complaints');
    expect(requestBody, {
      'schema': 1,
      'complainant': 'Test Person',
      'email': 'person@example.test',
      'work': 'Test work',
      'ownership': 'Created by complainant',
      'content': 'https://example.test/item',
      'details': 'No attachment',
    });
    expect(requestCount, 1);
  });

  test('rejects public insecure endpoint without network access', () async {
    await expectLater(
      service.submit(
        endpoint: Uri.parse('http://example.org'),
        feedback: FeedbackSubmission(
          kind: FeedbackKind.suggestion,
          message: 'x',
        ),
      ),
      throwsA(isA<FeedbackServiceInvalidResponse>()),
    );
    expect(requestCount, 0);
  });

  test(
    'distinguishes rejected submission from invalid acknowledgement',
    () async {
      statusCode = HttpStatus.serviceUnavailable;
      await expectLater(
        service.submit(
          endpoint: Uri.parse('http://localhost:${server.port}'),
          feedback: FeedbackSubmission(
            kind: FeedbackKind.problem,
            message: 'x',
          ),
        ),
        throwsA(isA<FeedbackServiceRejected>()),
      );
      statusCode = HttpStatus.created;
      responseBody = '{"schema":2,"accepted":true}';
      await expectLater(
        service.submit(
          endpoint: Uri.parse('http://localhost:${server.port}'),
          feedback: FeedbackSubmission(
            kind: FeedbackKind.problem,
            message: 'x',
          ),
        ),
        throwsA(isA<FeedbackServiceInvalidResponse>()),
      );
    },
  );
}
