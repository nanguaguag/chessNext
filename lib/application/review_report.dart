import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';
import 'review_models.dart';

enum MoveGrade { best, excellent, good, inaccuracy, mistake, blunder, unrated }

enum LossSource { candidate, followingPosition, terminal }

extension MoveGradeLabel on MoveGrade {
  String get label => switch (this) {
    MoveGrade.best => '最佳',
    MoveGrade.excellent => '优秀',
    MoveGrade.good => '好着',
    MoveGrade.inaccuracy => '不精确',
    MoveGrade.mistake => '错误',
    MoveGrade.blunder => '败着',
    MoveGrade.unrated => '未评级',
  };
}

class MoveAssessment {
  const MoveAssessment({
    required this.nodeId,
    required this.mover,
    required this.grade,
    this.lossUnits,
    this.beforeUnits,
    this.actualUnits,
    this.source,
    this.reason,
  });
  final String nodeId;
  final Side mover;
  final MoveGrade grade;

  /// One unit = 0.05 percentage points (two times native per-mille score).
  final int? lossUnits, beforeUnits, actualUnits;
  final LossSource? source;
  final String? reason;
  bool get rated => grade != MoveGrade.unrated;
  bool get isProblem => {
    MoveGrade.inaccuracy,
    MoveGrade.mistake,
    MoveGrade.blunder,
  }.contains(grade);
  double? get lossPercent => lossUnits == null ? null : lossUnits! / 20;
}

class SideReviewSummary {
  SideReviewSummary(Iterable<MoveAssessment> rows, Side side) {
    final own = rows.where((r) => r.mover == side).toList();
    total = own.length;
    rated = own.where((r) => r.rated).length;
    problems = own.where((r) => r.isProblem).length;
    final sum = own.fold<int>(0, (n, r) => n + (r.lossUnits ?? 0));
    averageLossPercent = rated == 0 ? null : sum / (20 * rated);
  }
  late final int total, rated, problems;
  late final double? averageLossPercent;
  int get unrated => total - rated;
}

/// A report is calculated once from the immutable snapshot opened by the user.
/// This is a versioned expected-score regret model, not reference-site accuracy.
class ReviewReport {
  ReviewReport.fromRun(this.run) : rows = List.unmodifiable(_build(run)) {
    red = SideReviewSummary(rows, Side.red);
    black = SideReviewSummary(rows, Side.black);
  }
  static const algorithmVersion = 'native-wdl-loss-v1';
  final ReviewRun run;
  final List<MoveAssessment> rows;
  late final SideReviewSummary red, black;
  bool get partial => run.phase != ReviewPhase.completed;
  static MoveGrade grade(int lossUnits, {bool engineChoice = false}) {
    if (lossUnits < 0 || lossUnits > 2000) throw ArgumentError('Invalid loss');
    if (lossUnits == 0 && engineChoice) return MoveGrade.best;
    if (lossUnits < 40) return MoveGrade.excellent;
    if (lossUnits < 100) return MoveGrade.good;
    if (lossUnits < 200) return MoveGrade.inaccuracy;
    if (lossUnits < 400) return MoveGrade.mistake;
    return MoveGrade.blunder;
  }

  static Iterable<MoveAssessment> _build(ReviewRun run) sync* {
    for (final id in run.nodeIds.reversed) {
      final node = run.tree.node(id);
      if (node.parentId == null) continue;
      final parent = run.tree.node(node.parentId!);
      final mover = parent.position.turn;
      MoveAssessment missing(String reason) => MoveAssessment(
        nodeId: id,
        mover: mover,
        grade: MoveGrade.unrated,
        reason: reason,
      );
      final before = run.results[parent.id];
      final after = run.results[id];
      if (before == null || after == null) {
        yield missing('相关局面尚未完成分析');
        continue;
      }
      if (before.turn != mover || after.turn != node.position.turn) {
        yield missing('评分视角与局面不匹配');
        continue;
      }
      final best = before.info;
      if (best == null ||
          before.status != ReviewScoreStatus.scored ||
          best.wdl == null) {
        yield missing('缺少原生胜和负估计');
        continue;
      }
      if (best.bound != null) {
        yield missing('起始评分只有上下界');
        continue;
      }
      if (best.isMate || after.info?.isMate == true) {
        yield missing('杀棋变化需单独评估');
        continue;
      }
      final beforeUnits = _units(best.wdl!);
      int actual;
      LossSource source;
      if (after.status == ReviewScoreStatus.terminal) {
        final outcome = node.position.boardOutcome();
        if (!outcome.isTerminal) {
          yield missing('终局状态与棋谱不匹配');
          continue;
        }
        actual = outcome.winner == mover ? 2000 : 0;
        source = LossSource.terminal;
      } else {
        EngineInfo? specific;
        final set = run.candidateResults[parent.id];
        if (set?.complete == true) {
          for (final entry in set!.entries) {
            if (entry.move == node.move) {
              specific = entry.info;
              break;
            }
          }
        }
        if (specific != null &&
            specific.wdl != null &&
            specific.bound == null &&
            !specific.isMate) {
          actual = _units(specific.wdl!);
          source = LossSource.candidate;
        } else {
          if (specific?.isMate == true) {
            yield missing('候选包含杀棋变化');
            continue;
          }
          final next = after.info;
          if (next == null ||
              next.wdl == null ||
              after.status != ReviewScoreStatus.scored) {
            yield missing('缺少落子后的原生估计');
            continue;
          }
          if (next.bound != null) {
            yield missing('落子后评分只有上下界');
            continue;
          }
          // A legal move changes the side to move; normalize to the mover.
          actual = node.position.turn == mover
              ? _units(next.wdl!)
              : 2000 - _units(next.wdl!);
          source = LossSource.followingPosition;
        }
      }
      final loss = (beforeUnits - actual).clamp(0, 2000);
      yield MoveAssessment(
        nodeId: id,
        mover: mover,
        lossUnits: loss,
        beforeUnits: beforeUnits,
        actualUnits: actual,
        source: source,
        grade: grade(loss, engineChoice: best.pv.firstOrNull == node.move),
      );
    }
  }

  static int _units(WdlEstimate estimate) => estimate.wins * 2 + estimate.draws;
}
