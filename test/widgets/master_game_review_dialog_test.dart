import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

import 'package:chess_next/features/workspace/master_game_review_dialog.dart';
import 'package:chess_next/ports/master_games_service.dart';

void main() {
  testWidgets('navigates the copied PGN without applying it elsewhere', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final record = PgnRecord(
      tree: GameTree().play(Move.parse('h2e2')),
      tags: {'Red': '红方', 'Black': '黑方', 'Event': '邀请赛'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => MasterGameReviewDialog(
                  record: const MasterGameRecord(
                    id: 'licensed-game',
                    category: MasterGameCategory.game,
                    red: '红方',
                    black: '黑方',
                    event: '邀请赛',
                    year: 2024,
                    result: MasterGameResult.redWin,
                    hasRecord: true,
                  ),
                  pgn: record,
                  datasetId: 'sample',
                  license: 'CC0',
                  attribution: 'operator',
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('进度 0/1'), findsOneWidget);
    await tester.tap(find.byTooltip('下一着'));
    await tester.pumpAndSettle();
    expect(find.text('进度 1/1'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('打开'), findsOneWidget);
  });
}
