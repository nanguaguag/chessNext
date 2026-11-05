/// Categories offered by the operator supplied master-games index.
enum MasterGameCategory { game, chessbook }

enum MasterGameResult { redWin, draw, blackWin }

final class MasterGamesQuery {
  MasterGamesQuery({
    required this.fen,
    required List<String> history,
    this.category,
    this.text = '',
    this.fromYear,
    this.toYear,
    Set<MasterGameResult> results = const {},
    this.page = 1,
    this.pageSize = 24,
  }) : history = List.unmodifiable(history),
       results = Set.unmodifiable(results) {
    final start = fromYear;
    final end = toYear;
    if (fen.trim().isEmpty ||
        fen.length > 256 ||
        history.length > 512 ||
        history.any((move) => !_move.hasMatch(move)) ||
        text.runes.length > 120 ||
        (start != null && (start < 1 || start > 9999)) ||
        (end != null && (end < 1 || end > 9999)) ||
        (start != null && end != null && start > end) ||
        page < 1 ||
        page > 100000 ||
        pageSize < 1 ||
        pageSize > 50) {
      throw ArgumentError('Invalid master games query');
    }
  }

  static final _move = RegExp(r'^[a-i][0-9][a-i][0-9]$');
  final String fen;
  final List<String> history;
  final MasterGameCategory? category;
  final String text;
  final int? fromYear;
  final int? toYear;
  final Set<MasterGameResult> results;
  final int page;
  final int pageSize;
}

final class MasterGameRecord {
  const MasterGameRecord({
    required this.id,
    required this.category,
    required this.red,
    required this.black,
    required this.event,
    required this.year,
    required this.result,
    this.hasRecord = false,
  });

  final String id;
  final MasterGameCategory category;
  final String red;
  final String black;
  final String event;
  final int year;
  final MasterGameResult result;
  final bool hasRecord;
}

final class MasterGameDetail {
  const MasterGameDetail({
    required this.id,
    required this.pgn,
    required this.fen,
    required this.history,
    required this.datasetId,
    required this.license,
    required this.attribution,
  });

  final String id;
  final String pgn;
  final String fen;
  final List<String> history;
  final String datasetId;
  final String license;
  final String attribution;
}

final class MasterGamesPage {
  const MasterGamesPage({
    required this.datasetId,
    required this.license,
    required this.attribution,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.records,
  });

  final String datasetId;
  final String license;
  final String attribution;
  final int page;
  final int pageSize;
  final int total;
  final List<MasterGameRecord> records;
}

abstract interface class MasterGamesService {
  Future<MasterGamesPage> query({
    required Uri endpoint,
    required MasterGamesQuery query,
  });

  Future<MasterGameDetail> readRecord({
    required Uri endpoint,
    required String id,
  });
}

sealed class MasterGamesServiceException implements Exception {
  const MasterGamesServiceException();
}

final class MasterGamesUnavailable extends MasterGamesServiceException {
  const MasterGamesUnavailable();
}

final class MasterGamesInvalidResponse extends MasterGamesServiceException {
  const MasterGamesInvalidResponse();
}

final class MasterGamesRejected extends MasterGamesServiceException {
  const MasterGamesRejected(this.statusCode);
  final int statusCode;
}
