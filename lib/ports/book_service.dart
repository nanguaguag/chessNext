/// Book lookup never applies a move. The session validates candidates against
/// its current legal move set before choosing a result.
enum BookKind { opening, endgame }

final class BookPositionKey {
  BookPositionKey({
    required this.kind,
    required this.fen,
    required List<String> history,
  }) : history = List.unmodifiable(history);

  final BookKind kind;
  final String fen;
  final List<String> history;
}

final class BookMoveCandidate {
  const BookMoveCandidate({
    required this.uci,
    required this.scoreCp,
    required this.weight,
  });
  final String uci;
  final int scoreCp;
  final int weight;
}

final class BookLookup {
  const BookLookup({
    required this.hit,
    required this.candidates,
    required this.datasetId,
    required this.license,
    required this.attribution,
  });
  final bool hit;
  final List<BookMoveCandidate> candidates;
  final String? datasetId;
  final String? license;
  final String? attribution;
}

abstract interface class BookService {
  Future<BookLookup> query({
    required Uri endpoint,
    required BookPositionKey position,
  });
}

sealed class BookServiceException implements Exception {
  const BookServiceException();
}

final class BookServiceUnavailable extends BookServiceException {
  const BookServiceUnavailable();
}

final class BookServiceInvalidResponse extends BookServiceException {
  const BookServiceInvalidResponse();
}

final class BookServiceRejected extends BookServiceException {
  const BookServiceRejected(this.statusCode);
  final int statusCode;
}
