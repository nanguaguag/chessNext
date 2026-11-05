import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../ports/release_service.dart';

const _maxReleaseResponseBytes = 2 * 1024 * 1024;
const _releaseVersionPattern = r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$';

/// Bounded GET adapter for the optional self-hosted release metadata endpoint.
final class HttpReleaseService implements ReleaseService {
  HttpReleaseService({
    HttpClient? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;

  void close() => _client.close(force: true);

  @override
  Future<ReleaseMetadata> fetchLatest({required Uri endpoint}) async {
    if (!_validEndpoint(endpoint)) {
      throw const ReleaseServiceInvalidResponse();
    }
    final uri = endpoint.replace(
      path:
          '${endpoint.path.replaceFirst(RegExp(r'/+$'), '')}/v1/releases/latest',
      query: null,
      fragment: null,
    );
    try {
      final request = await _client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw ReleaseServiceRejected(response.statusCode);
      }
      if (response.contentLength > _maxReleaseResponseBytes) {
        await response.drain<void>();
        throw const ReleaseServiceInvalidResponse();
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        if (bytes.length + chunk.length > _maxReleaseResponseBytes) {
          throw const ReleaseServiceInvalidResponse();
        }
        bytes.addAll(chunk);
      }
      return _decode(utf8.decode(bytes));
    } on ReleaseServiceException {
      rethrow;
    } on TimeoutException {
      throw const ReleaseServiceUnavailable();
    } on SocketException {
      throw const ReleaseServiceUnavailable();
    } on HttpException {
      throw const ReleaseServiceUnavailable();
    } on FormatException {
      throw const ReleaseServiceInvalidResponse();
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

  static ReleaseMetadata _decode(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic> ||
        json.keys.toSet().difference({
          'schema',
          'current',
          'history',
        }).isNotEmpty ||
        json['schema'] != 1 ||
        json['current'] is! Map<String, dynamic> ||
        json['history'] is! List ||
        (json['history'] as List).isEmpty ||
        (json['history'] as List).length > 100) {
      throw const FormatException('Invalid release response');
    }
    final history = (json['history'] as List)
        .map(_decodeEntry)
        .toList(growable: false);
    final current = _decodeEntry(json['current']);
    if (!_sameRelease(current, history.first)) {
      throw const FormatException('Release current entry mismatch');
    }
    final identities = <String>{};
    for (var index = 0; index < history.length; index++) {
      final entry = history[index];
      if (!identities.add('${entry.version}+${entry.build}') ||
          (index > 0 &&
              !history[index - 1].publishedAt.isAfter(entry.publishedAt))) {
        throw const FormatException('Invalid release ordering');
      }
    }
    return ReleaseMetadata(history: history);
  }

  static ReleaseEntry _decodeEntry(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw.keys.toSet().difference({
          'version',
          'build',
          'publishedAt',
          'notes',
        }).isNotEmpty ||
        raw['version'] is! String ||
        !RegExp(_releaseVersionPattern).hasMatch(raw['version'] as String) ||
        raw['build'] is! int ||
        (raw['build'] as int) < 1 ||
        raw['publishedAt'] is! String ||
        raw['notes'] is! String ||
        (raw['notes'] as String).length > 4000 ||
        (raw['notes'] as String).contains(
          RegExp(r'[\u0000-\u0008\u000b\u000c\u000e-\u001f]'),
        )) {
      throw const FormatException('Invalid release entry');
    }
    final date = DateTime.tryParse(raw['publishedAt'] as String);
    if (date == null || !date.isUtc) {
      throw const FormatException('Invalid release date');
    }
    return ReleaseEntry(
      version: raw['version'] as String,
      build: raw['build'] as int,
      publishedAt: date,
      notes: raw['notes'] as String,
    );
  }

  static bool _sameRelease(ReleaseEntry left, ReleaseEntry right) =>
      left.version == right.version &&
      left.build == right.build &&
      left.publishedAt == right.publishedAt &&
      left.notes == right.notes;
}
