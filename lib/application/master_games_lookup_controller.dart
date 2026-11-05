import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

import '../ports/master_games_service.dart';
import 'board_session.dart';

enum MasterGamesStatus {
  idle,
  loading,
  hit,
  miss,
  stale,
  unavailable,
  rejected,
  invalid,
}

/// Explicit, read-only index search. Navigation invalidates results and requests.
final class MasterGamesLookupController extends ChangeNotifier {
  MasterGamesLookupController(this.session, this.service) {
    session.addListener(_sessionChanged);
    _epoch = session.epoch;
    _revision = session.positionRevision;
  }

  final BoardSession session;
  final MasterGamesService service;
  MasterGamesStatus status = MasterGamesStatus.idle;
  List<MasterGameRecord> records = const [];
  int total = 0;
  int page = 1;
  int pageSize = 24;
  String? datasetId, license, attribution, message;
  MasterGameCategory? category;
  String text = '';
  int? fromYear, toYear;
  Set<MasterGameResult> results = const {};
  int _generation = 0, _epoch = 0, _revision = 0;
  bool _invalidFilters = false;

  Future<PgnRecord?> readRecord(
    MasterGameRecord record,
    String configuredEndpoint,
  ) async {
    if (!record.hasRecord ||
        status != MasterGamesStatus.hit ||
        !records.any((item) => item.id == record.id)) {
      return null;
    }
    final generation = _generation;
    final epoch = session.epoch;
    final revision = session.positionRevision;
    final tree = session.tree;
    final detail = await service.readRecord(
      endpoint: Uri.parse(configuredEndpoint.trim()),
      id: record.id,
    );
    if (generation != _generation ||
        epoch != session.epoch ||
        revision != session.positionRevision ||
        !identical(tree, session.tree) ||
        !records.any((item) => item.id == record.id)) {
      return null;
    }
    if (detail.datasetId != datasetId ||
        detail.license != license ||
        detail.attribution != attribution) {
      throw const FormatException('棋谱来源与当前索引结果不一致。');
    }
    final expectedHistory = tree.path
        .skip(1)
        .map((node) => node.move.toString())
        .toList(growable: false);
    if (detail.fen != tree.current.position.toFen() ||
        !listEquals(detail.history, expectedHistory)) {
      throw const FormatException('棋谱索引局面与查询位置不一致。');
    }
    final parsed = PgnCodec.parse(detail.pgn);
    for (final pair in [
      ('Red', record.red),
      ('Black', record.black),
      ('Event', record.event),
    ]) {
      final declared = parsed.tags[pair.$1];
      if (declared != null && declared != pair.$2) {
        throw const FormatException('棋谱资料与索引元数据不一致。');
      }
    }
    final line = parsed.tree.currentLine;
    final historyLength = expectedHistory.length;
    final hasPosition = line.asMap().entries.any((entry) {
      final end = entry.key;
      final start = end - historyLength;
      if (start < 0 ||
          line[start].position.toFen() != tree.root.position.toFen() ||
          entry.value.position.toFen() != detail.fen) {
        return false;
      }
      final moves = line
          .skip(start + 1)
          .take(historyLength)
          .map((node) => node.move.toString());
      return listEquals(moves.toList(growable: false), expectedHistory);
    });
    if (!hasPosition) {
      throw const FormatException('整局棋谱不包含本次查询的局面与历史。');
    }
    return parsed;
  }

  void setFilters({
    MasterGameCategory? category,
    bool clearCategory = false,
    String? text,
    int? fromYear,
    bool clearFromYear = false,
    int? toYear,
    bool clearToYear = false,
    Set<MasterGameResult>? results,
  }) {
    final nextCategory = clearCategory ? null : category ?? this.category;
    final nextText = text ?? this.text;
    final nextFrom = clearFromYear ? null : fromYear ?? this.fromYear;
    final nextTo = clearToYear ? null : toYear ?? this.toYear;
    final nextResults = results ?? this.results;
    this.category = nextCategory;
    this.text = nextText;
    this.fromYear = nextFrom;
    this.toYear = nextTo;
    this.results = Set.unmodifiable(nextResults);
    if (nextFrom != null && nextTo != null && nextFrom > nextTo) {
      _invalidFilters = true;
      message = '起始年份不能晚于截止年份。';
      _generation++;
      records = const [];
      total = 0;
      datasetId = license = attribution = null;
      status = MasterGamesStatus.invalid;
      notifyListeners();
      return;
    }
    _invalidFilters = false;
    page = 1;
    _invalidateResults();
  }

  void setInvalidFilter(String message) {
    _invalidFilters = true;
    _generation++;
    records = const [];
    total = 0;
    datasetId = license = attribution = null;
    status = MasterGamesStatus.invalid;
    this.message = message;
    notifyListeners();
  }

  Future<void> query(String configuredEndpoint, {int requestedPage = 1}) async {
    final value = configuredEndpoint.trim();
    final endpoint = Uri.tryParse(value);
    if (value.isEmpty || endpoint == null) {
      _clear(MasterGamesStatus.unavailable, '请先配置自建大师谱服务地址；当前不会联网。');
      return;
    }
    if (_invalidFilters ||
        requestedPage < 1 ||
        requestedPage > 100000 ||
        (fromYear != null && toYear != null && fromYear! > toYear!)) {
      _clear(MasterGamesStatus.invalid, '筛选条件或页码无效。');
      return;
    }
    final tree = session.tree;
    final epoch = session.epoch;
    final revision = session.positionRevision;
    final path = tree.path;
    if (path.length > 513) {
      _clear(MasterGamesStatus.invalid, '当前线路超过512步查询上限。');
      return;
    }
    final generation = ++_generation;
    _epoch = epoch;
    _revision = revision;
    page = requestedPage;
    records = const [];
    datasetId = license = attribution = null;
    status = MasterGamesStatus.loading;
    message = '查询会向已配置的自建服务发送当前局面、完整着法历史与筛选条件…';
    notifyListeners();
    bool current() =>
        generation == _generation &&
        session.epoch == epoch &&
        session.positionRevision == revision &&
        identical(session.tree, tree);
    try {
      final response = await service.query(
        endpoint: endpoint,
        query: MasterGamesQuery(
          fen: tree.current.position.toFen(),
          history: path.skip(1).map((node) => node.move.toString()).toList(),
          category: category,
          text: text,
          fromYear: fromYear,
          toYear: toYear,
          results: results,
          page: requestedPage,
          pageSize: pageSize,
        ),
      );
      if (!current()) return;
      records = response.records;
      total = response.total;
      datasetId = response.datasetId;
      license = response.license;
      attribution = response.attribution;
      status = records.isEmpty ? MasterGamesStatus.miss : MasterGamesStatus.hit;
      message = records.isEmpty ? '没有符合筛选条件的记录。' : '找到 $total 条记录。';
      notifyListeners();
    } on MasterGamesUnavailable {
      if (current()) _clear(MasterGamesStatus.unavailable, '无法连接自建大师谱服务。');
    } on MasterGamesRejected catch (error) {
      if (current()) {
        _clear(MasterGamesStatus.rejected, '服务拒绝请求（HTTP ${error.statusCode}）。');
      }
    } on MasterGamesInvalidResponse {
      if (current()) _clear(MasterGamesStatus.invalid, '服务返回的数据无效，未显示结果。');
    } catch (_) {
      if (current()) _clear(MasterGamesStatus.invalid, '查询失败；棋局没有变化。');
    }
  }

  void nextPage(String endpoint) {
    if (status == MasterGamesStatus.loading || (page * pageSize) >= total) {
      return;
    }
    unawaited(query(endpoint, requestedPage: page + 1));
  }

  void previousPage(String endpoint) {
    if (status == MasterGamesStatus.loading || page <= 1) return;
    unawaited(query(endpoint, requestedPage: page - 1));
  }

  void _sessionChanged() {
    if (session.epoch == _epoch && session.positionRevision == _revision) {
      return;
    }
    if (status == MasterGamesStatus.loading ||
        status == MasterGamesStatus.hit ||
        status == MasterGamesStatus.miss) {
      ++_generation;
      _clear(MasterGamesStatus.stale, '局面已变化，旧查询已清除。');
    }
    _epoch = session.epoch;
    _revision = session.positionRevision;
  }

  void _invalidateResults() {
    ++_generation;
    records = const [];
    total = 0;
    datasetId = license = attribution = null;
    status = MasterGamesStatus.idle;
    message = null;
    notifyListeners();
  }

  void _clear(MasterGamesStatus next, String detail) {
    records = const [];
    total = 0;
    datasetId = license = attribution = null;
    status = next;
    message = detail;
    notifyListeners();
  }

  @override
  void dispose() {
    session.removeListener(_sessionChanged);
    ++_generation;
    super.dispose();
  }
}
