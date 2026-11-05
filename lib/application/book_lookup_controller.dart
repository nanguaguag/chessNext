import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

import '../ports/book_service.dart';
import 'board_session.dart';

enum BookLookupStatus {
  idle,
  loading,
  hit,
  miss,
  stale,
  unavailable,
  rejected,
  invalid,
}

/// Explicit, read-only lookup for the current game-tree cursor.
///
/// A query sends only the selected position and its move history to the
/// operator-configured BookService. Navigation invalidates in-flight results.
final class BookLookupController extends ChangeNotifier {
  BookLookupController(this.session, this.service) {
    session.addListener(_sessionChanged);
  }

  final BoardSession session;
  final BookService service;
  BookLookupStatus status = BookLookupStatus.idle;
  BookKind kind = BookKind.opening;
  List<BookMoveCandidate> candidates = const [];
  String? datasetId;
  String? license;
  String? attribution;
  String? message;
  int _generation = 0;
  int _lastEpoch = 0;
  int _lastPositionRevision = 0;

  void setKind(BookKind value) {
    if (kind == value) return;
    kind = value;
    ++_generation;
    _clear(BookLookupStatus.idle);
  }

  Future<void> query(String configuredEndpoint) async {
    final endpointValue = configuredEndpoint.trim();
    final endpoint = Uri.tryParse(endpointValue);
    if (endpointValue.isEmpty || endpoint == null) {
      _clear(BookLookupStatus.unavailable, '请先在应用设置中配置自建云库服务地址。');
      return;
    }
    final tree = session.tree;
    final epoch = session.epoch;
    final revision = session.positionRevision;
    final path = tree.path;
    if (path.length > 513) {
      _clear(BookLookupStatus.invalid, '当前线路超过云库查询支持的512步上限。');
      return;
    }

    final generation = ++_generation;
    _lastEpoch = epoch;
    _lastPositionRevision = revision;
    candidates = const [];
    datasetId = null;
    license = null;
    attribution = null;
    message = '正在向已配置的自建云库发送当前局面与着法历史…';
    status = BookLookupStatus.loading;
    notifyListeners();
    bool current() =>
        generation == _generation &&
        session.epoch == epoch &&
        session.positionRevision == revision &&
        identical(session.tree, tree);

    try {
      final result = await service.query(
        endpoint: endpoint,
        position: BookPositionKey(
          kind: kind,
          fen: tree.current.position.toFen(),
          history: path.skip(1).map((node) => node.move.toString()).toList(),
        ),
      );
      if (!current()) return;
      final legal = result.candidates
          .where((candidate) {
            try {
              return session.isLegalMove(Move.parse(candidate.uci));
            } on FormatException {
              return false;
            }
          })
          .toList(growable: false);
      if (result.hit && legal.isEmpty) {
        _clear(BookLookupStatus.invalid, '云库返回的着法在当前局面均不合法，已隐藏。');
        return;
      }
      candidates = legal;
      datasetId = result.datasetId;
      license = result.license;
      attribution = result.attribution;
      status = result.hit ? BookLookupStatus.hit : BookLookupStatus.miss;
      message = result.hit
          ? '已找到 ${legal.length} 个合法候选；查询不会自动走棋。'
          : '云库未收录此局面。';
      notifyListeners();
    } on BookServiceUnavailable {
      if (current()) {
        _clear(BookLookupStatus.unavailable, '无法连接云库。请检查网络、地址和服务状态。');
      }
    } on BookServiceRejected catch (error) {
      if (current()) {
        _clear(
          BookLookupStatus.rejected,
          '自建云库拒绝请求（HTTP ${error.statusCode}）。',
        );
      }
    } on BookServiceInvalidResponse {
      if (current()) {
        _clear(BookLookupStatus.invalid, '云库返回的数据格式无效，未显示候选着法。');
      }
    } catch (_) {
      if (current()) {
        _clear(BookLookupStatus.invalid, '云库查询失败，棋局未受影响。');
      }
    }
  }

  void _sessionChanged() {
    if (session.epoch == _lastEpoch &&
        session.positionRevision == _lastPositionRevision) {
      return;
    }
    if (status == BookLookupStatus.loading ||
        status == BookLookupStatus.hit ||
        status == BookLookupStatus.miss) {
      ++_generation;
      _clear(BookLookupStatus.stale, '局面已变化；旧查询结果已清除，请重新查询。');
    }
    _lastEpoch = session.epoch;
    _lastPositionRevision = session.positionRevision;
  }

  void _clear(BookLookupStatus next, [String? detail]) {
    candidates = const [];
    datasetId = null;
    license = null;
    attribution = null;
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
