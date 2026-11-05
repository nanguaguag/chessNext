import 'dart:convert';
import 'dart:io';

import 'package:chess_next/adapters/network/http_release_service.dart';
import 'package:chess_next/ports/release_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late HttpReleaseService service;
  var statusCode = HttpStatus.ok;
  var payload = <String, Object?>{};
  var requestCount = 0;

  Map<String, Object?> release(String version, int build, String date) => {
    'version': version,
    'build': build,
    'publishedAt': date,
    'notes': 'notes',
  };

  setUp(() async {
    statusCode = HttpStatus.ok;
    final current = release('1.2.0', 12, '2026-11-05T00:00:00Z');
    payload = {
      'schema': 1,
      'current': current,
      'history': [current, release('1.1.0', 11, '2026-10-01T00:00:00Z')],
    };
    requestCount = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestCount++;
      await request.drain<void>();
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(payload));
      await request.response.close();
    });
    service = HttpReleaseService();
  });

  tearDown(() async {
    service.close();
    await server.close(force: true);
  });

  test(
    'loads bounded release history from configured loopback endpoint',
    () async {
      final result = await service.fetchLatest(
        endpoint: Uri.parse('http://localhost:${server.port}/prefix/'),
      );
      expect(result.current.version, '1.2.0');
      expect(result.current.build, 12);
      expect(result.history, hasLength(2));
      expect(requestCount, 1);
    },
  );

  test('rejects insecure public endpoints before network access', () async {
    await expectLater(
      service.fetchLatest(endpoint: Uri.parse('http://example.org')),
      throwsA(isA<ReleaseServiceInvalidResponse>()),
    );
    expect(requestCount, 0);
  });

  test('rejects mismatch and unordered metadata', () async {
    payload['current'] = release('1.1.0', 11, '2026-10-01T00:00:00Z');
    await expectLater(
      service.fetchLatest(
        endpoint: Uri.parse('http://localhost:${server.port}'),
      ),
      throwsA(isA<ReleaseServiceInvalidResponse>()),
    );

    final sameDate = release('1.1.0', 11, '2026-11-05T00:00:00Z');
    payload = {
      'schema': 1,
      'current': release('1.2.0', 12, '2026-11-05T00:00:00Z'),
      'history': [release('1.2.0', 12, '2026-11-05T00:00:00Z'), sameDate],
    };
    await expectLater(
      service.fetchLatest(
        endpoint: Uri.parse('http://localhost:${server.port}'),
      ),
      throwsA(isA<ReleaseServiceInvalidResponse>()),
    );
  });

  test('distinguishes HTTP rejection from invalid data', () async {
    statusCode = HttpStatus.serviceUnavailable;
    await expectLater(
      service.fetchLatest(
        endpoint: Uri.parse('http://localhost:${server.port}'),
      ),
      throwsA(isA<ReleaseServiceRejected>()),
    );
  });
}
