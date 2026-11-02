import 'package:xiangqi_core/xiangqi_core.dart';
import '../ports/engine_gateway.dart';

enum EvaluationKind { unavailable, model, bound, mate, terminal }

class BoardEvaluation {
  const BoardEvaluation._(this.kind, this.description, this.redUnits);
  final EvaluationKind kind;
  final String description;

  /// Model expectation in half per mille, or actual terminal result.
  final int? redUnits;
  double? get redRatio => redUnits == null ? null : redUnits! / 2000;
  factory BoardEvaluation.fromInfo({
    required Side turn,
    required BoardOutcome outcome,
    EngineInfo? info,
    bool frozen = false,
  }) {
    String side(Side value) => value == Side.red ? '红方' : '黑方';
    if (outcome.isTerminal) {
      return BoardEvaluation._(
        EvaluationKind.terminal,
        '${side(outcome.winner!)}已获胜（${outcome.status == BoardStatus.checkmate ? '将死' : '困毙'}）',
        outcome.winner == Side.red ? 2000 : 0,
      );
    }
    if (info == null || info.multiPv != 1) {
      return const BoardEvaluation._(
        EvaluationKind.unavailable,
        '暂无有效模型估计',
        null,
      );
    }
    final prefix = frozen ? '保留的当前局面结果：' : '';
    if (info.bound != null) {
      return BoardEvaluation._(
        EvaluationKind.bound,
        '$prefix当前评分只有边界，未显示模型比例',
        null,
      );
    }
    if (info.isMate) {
      return BoardEvaluation._(
        EvaluationKind.mate,
        info.score == 0
            ? '$prefix杀棋评分为0，未由此判定胜方'
            : '$prefix预计${side(info.score > 0 ? turn : turn.opponent)}${info.score.abs()}步杀；不是模型概率',
        null,
      );
    }
    final wdl = turn == Side.red ? info.wdl : info.wdl?.flipped();
    if (wdl == null) {
      return BoardEvaluation._(
        EvaluationKind.unavailable,
        '$prefix引擎未提供胜和负模型',
        null,
      );
    }
    final units = wdl.wins * 2 + wdl.draws;
    return BoardEvaluation._(
      EvaluationKind.model,
      '$prefix红方预期得分${(units / 20).toStringAsFixed(1)}%，黑方${((2000 - units) / 20).toStringAsFixed(1)}%；本机WDL模型（胜加半和），不是实战胜率',
      units,
    );
  }
}
