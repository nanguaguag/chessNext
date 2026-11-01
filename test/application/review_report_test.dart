import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/application/review_report.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

EngineInfo score(
  String pv,
  WdlEstimate? wdl, {
  String? bound,
  bool mate = false,
}) => EngineInfo(
  token: 1,
  depth: 4,
  multiPv: 1,
  score: 777,
  isMate: mate,
  bound: bound,
  wdl: wdl,
  pv: [Move.parse(pv)],
);
GameTree sampleTree() =>
    GameTree().play(Move.parse('h2e2')).play(Move.parse('b9c7'));
ReviewRun sampleRun({
  Map<String, ReviewedPosition>? results,
  Map<String, ReviewedCandidates> candidates = const {},
  ReviewPhase phase = ReviewPhase.completed,
}) {
  final tree = sampleTree();
  return ReviewRun(
    epoch: 1,
    revision: 2,
    tree: tree,
    scope: ReviewScope.line,
    limits: ReviewLimits(depth: 4, moveTimeMs: null),
    nodeIds: ['n2', 'n1', 'n0'],
    phase: phase,
    candidateResults: candidates,
    results:
        results ??
        {
          'n0': ReviewedPosition(
            nodeId: 'n0',
            turn: Side.red,
            status: ReviewScoreStatus.scored,
            info: score('b2e2', WdlEstimate(wins: 800, draws: 200, losses: 0)),
          ),
          'n1': ReviewedPosition(
            nodeId: 'n1',
            turn: Side.black,
            status: ReviewScoreStatus.scored,
            info: score(
              'h9g7',
              WdlEstimate(wins: 300, draws: 400, losses: 300),
            ),
          ),
          'n2': ReviewedPosition(
            nodeId: 'n2',
            turn: Side.red,
            status: ReviewScoreStatus.scored,
            info: score('b2e2', WdlEstimate(wins: 900, draws: 100, losses: 0)),
          ),
        },
  );
}

void main() {
  test('integer thresholds, exact equality and engine-choice zero', () {
    final cases = {
      0: MoveGrade.excellent,
      39: MoveGrade.excellent,
      40: MoveGrade.good,
      99: MoveGrade.good,
      100: MoveGrade.inaccuracy,
      199: MoveGrade.inaccuracy,
      200: MoveGrade.mistake,
      399: MoveGrade.mistake,
      400: MoveGrade.blunder,
      2000: MoveGrade.blunder,
    };
    for (final c in cases.entries) {
      expect(ReviewReport.grade(c.key), c.value);
    }
    expect(ReviewReport.grade(0, engineChoice: true), MoveGrade.best);
    expect(() => ReviewReport.grade(-1), throwsArgumentError);
    expect(() => ReviewReport.grade(2001), throwsArgumentError);
  });
  test('normalizes both colors and averages eligible moves only', () {
    final report = ReviewReport.fromRun(sampleRun());
    expect(report.rows.map((r) => r.nodeId), ['n1', 'n2']);
    expect(report.rows.map((r) => r.lossPercent), [40, 45]);
    expect(
      report.rows.every((r) => r.source == LossSource.followingPosition),
      isTrue,
    );
    expect(report.red.averageLossPercent, 40);
    expect(report.black.averageLossPercent, 45);
    expect(report.red.problems, 1);
    expect(report.partial, isFalse);
  });
  test(
    'same-parent completed candidate takes priority over following estimate',
    () {
      final run = sampleRun(
        candidates: {
          'n0': ReviewedCandidates([
            CandidateEvaluation(
              Move.parse('h2e2'),
              score('h2e2', WdlEstimate(wins: 750, draws: 200, losses: 50)),
            ),
          ], complete: true),
        },
      );
      final row = ReviewReport.fromRun(run).rows.first;
      expect(row.lossPercent, 5);
      expect(row.grade, MoveGrade.inaccuracy);
      expect(row.source, LossSource.candidate);
      final incomplete = sampleRun(
        candidates: {
          'n0': ReviewedCandidates(
            run.candidateResults['n0']!.entries,
            complete: false,
          ),
        },
      );
      expect(ReviewReport.fromRun(incomplete).rows.first.lossPercent, 40);
    },
  );
  test(
    'engine choice zero and unfavorable sampling clamp without negative regret',
    () {
      final base = sampleRun();
      final results = Map<String, ReviewedPosition>.of(base.results);
      results['n0'] = ReviewedPosition(
        nodeId: 'n0',
        turn: Side.red,
        status: ReviewScoreStatus.scored,
        info: score('h2e2', WdlEstimate(wins: 0, draws: 1000, losses: 0)),
      );
      results['n1'] = ReviewedPosition(
        nodeId: 'n1',
        turn: Side.black,
        status: ReviewScoreStatus.scored,
        info: score('h9g7', WdlEstimate(wins: 0, draws: 800, losses: 200)),
      );
      expect(
        ReviewReport.fromRun(sampleRun(results: results)).rows.first.grade,
        MoveGrade.best,
      );
    },
  );
  test(
    'partial, no WDL, bounds, mate and perspective mismatch stay unrated',
    () {
      final original = sampleRun();
      final variants = <ReviewedPosition?>[
        null,
        ReviewedPosition(
          nodeId: 'n0',
          turn: Side.red,
          status: ReviewScoreStatus.scored,
          info: score('b2e2', null),
        ),
        ReviewedPosition(
          nodeId: 'n0',
          turn: Side.red,
          status: ReviewScoreStatus.scored,
          info: score(
            'b2e2',
            WdlEstimate(wins: 800, draws: 200, losses: 0),
            bound: 'lower',
          ),
        ),
        ReviewedPosition(
          nodeId: 'n0',
          turn: Side.red,
          status: ReviewScoreStatus.scored,
          info: score(
            'b2e2',
            WdlEstimate(wins: 800, draws: 200, losses: 0),
            mate: true,
          ),
        ),
        ReviewedPosition(
          nodeId: 'n0',
          turn: Side.black,
          status: ReviewScoreStatus.scored,
          info: score('b2e2', WdlEstimate(wins: 800, draws: 200, losses: 0)),
        ),
      ];
      for (final variant in variants) {
        final results = Map<String, ReviewedPosition>.of(original.results)
          ..remove('n0');
        if (variant != null) results['n0'] = variant;
        final report = ReviewReport.fromRun(
          sampleRun(results: results, phase: ReviewPhase.cancelled),
        );
        expect(report.rows.first.grade, MoveGrade.unrated);
        expect(report.red.averageLossPercent, isNull);
        expect(report.red.unrated, 1);
        expect(report.red.problems, 0);
        expect(report.partial, isTrue);
      }
    },
  );
  test(
    'following bound or mate does not become ordinary probability grade',
    () {
      for (final mate in [false, true]) {
        final results = Map<String, ReviewedPosition>.of(sampleRun().results);
        results['n1'] = ReviewedPosition(
          nodeId: 'n1',
          turn: Side.black,
          status: ReviewScoreStatus.scored,
          info: score(
            'h9g7',
            WdlEstimate(wins: 0, draws: 1000, losses: 0),
            mate: mate,
            bound: mate ? null : 'upper',
          ),
        );
        expect(
          ReviewReport.fromRun(sampleRun(results: results)).rows.first.rated,
          isFalse,
        );
      }
    },
  );
  test('verified stalemate is a win for opponent, not a draw', () {
    final tree = GameTree(
      initial: Position.fromFen('4k4/9/9/9/4p4/9/9/3r5/5r3/4K4 b - - 0 1'),
    ).play(Move.parse('d2d1'));
    expect(tree.current.position.boardOutcome().winner, Side.black);
    final run = ReviewRun(
      epoch: 1,
      revision: 0,
      tree: tree,
      scope: ReviewScope.line,
      limits: ReviewLimits(depth: 4),
      nodeIds: ['n1', 'n0'],
      phase: ReviewPhase.completed,
      results: {
        'n0': ReviewedPosition(
          nodeId: 'n0',
          turn: Side.black,
          status: ReviewScoreStatus.scored,
          info: score('f1f2', WdlEstimate(wins: 500, draws: 500, losses: 0)),
        ),
        'n1': const ReviewedPosition(
          nodeId: 'n1',
          turn: Side.red,
          status: ReviewScoreStatus.terminal,
        ),
      },
    );
    final row = ReviewReport.fromRun(run).rows.single;
    expect(row.source, LossSource.terminal);
    expect(row.actualUnits, 2000);
    expect(row.lossPercent, 0);
  });
}
