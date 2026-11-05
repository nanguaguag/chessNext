final class ReleaseEntry {
  const ReleaseEntry({
    required this.version,
    required this.build,
    required this.publishedAt,
    required this.notes,
  });

  final String version;
  final int build;
  final DateTime publishedAt;
  final String notes;
}

final class ReleaseMetadata {
  ReleaseMetadata({required List<ReleaseEntry> history})
    : history = List.unmodifiable(history) {
    if (this.history.isEmpty || this.history.length > 100) {
      throw ArgumentError.value(history, 'history');
    }
  }

  final List<ReleaseEntry> history;
  ReleaseEntry get current => history.first;
}

abstract interface class ReleaseService {
  Future<ReleaseMetadata> fetchLatest({required Uri endpoint});
}

sealed class ReleaseServiceException implements Exception {
  const ReleaseServiceException();
}

final class ReleaseServiceUnavailable extends ReleaseServiceException {
  const ReleaseServiceUnavailable();
}

final class ReleaseServiceInvalidResponse extends ReleaseServiceException {
  const ReleaseServiceInvalidResponse();
}

final class ReleaseServiceRejected extends ReleaseServiceException {
  const ReleaseServiceRejected(this.statusCode);
  final int statusCode;
}
