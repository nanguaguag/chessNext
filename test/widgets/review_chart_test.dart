import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/features/review/review_chart.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

ReviewedPosition score(
  String id,
  int value, {
  Side turn = Side.red,
  bool mate = false,
  String? bound,
}) => ReviewedPosition(
  nodeId: id,
  turn: turn,
  status: ReviewScoreStatus.scored,
  info: EngineInfo(
    token: 1,
    depth: 10,
    multiPv: 1,
    score: value,
    isMate: mate,
    bound: bound,
    pv: const [],
  ),
);
void main() {
  test(
    'plot uses red cp, preserves missing samples and never treats mate as cp',
    () {
      expect(ReviewChartPainter.ordinate(score('n0', 500)), .5);
      expect(
        ReviewChartPainter.ordinate(score('n1', 1500, turn: Side.black)),
        -1,
      );
      expect(ReviewChartPainter.ordinate(score('n2', -2, mate: true)), -1);
      expect(ReviewChartPainter.ordinate(score('n2', 2, mate: true)), 1);
      expect(ReviewChartPainter.ordinate(score('n2', 0, mate: true)), isNull);
      expect(ReviewChartPainter.ordinate(null), isNull);
      expect(
        ReviewChartPainter.ordinate(
          const ReviewedPosition(
            nodeId: 'n3',
            turn: Side.red,
            status: ReviewScoreStatus.terminal,
          ),
        ),
        isNull,
      );
    },
  );
  testWidgets(
    'chart clicks, keyboard and slider navigate the actual selected line',
    (tester) async {
      final session = BoardSession();
      addTearDown(session.dispose);
      session.playMove(Move.parse('h2e2'));
      session.playMove(Move.parse('b9c7'));
      session.first();
      final results = {
        'n0': score('n0', 150),
        'n1': score('n1', 200, turn: Side.black, bound: 'lower'),
        'n2': score('n2', 3, mate: true),
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: session,
              builder: (_, _) => SizedBox(
                width: 326,
                child: ReviewChart(
                  line: session.tree.currentLine,
                  results: results,
                  cursorId: session.tree.cursorId,
                  onNavigate: session.navigate,
                ),
              ),
            ),
          ),
        ),
      );
      final chart = find.byKey(const ValueKey('review-chart'));
      final bounds = tester.getRect(chart);
      await tester.tapAt(Offset(bounds.right - 13, bounds.center.dy));
      await tester.pump();
      expect(session.tree.cursorId, 'n2');
      expect(find.text('2. 马２进３，红方 杀棋 3'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(session.tree.cursorId, 'n1');
      expect(find.text('1. 炮二平五，红方 ≤-2.00'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(session.tree.cursorId, 'n0');
      tester.widget<Slider>(find.byType(Slider)).onChanged!(1);
      await tester.pump();
      expect(session.tree.cursorId, 'n1');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(session.tree.cursorId, 'n2');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'single missing point works at large text and exposes a readable selection',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 240,
                child: ReviewChart(
                  line: GameTree().currentLine,
                  results: const {},
                  cursorId: 'n0',
                  onNavigate: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('开始，未分析'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
      await tester.tap(find.byKey(const ValueKey('review-chart')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
