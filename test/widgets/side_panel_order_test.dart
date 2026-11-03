import 'package:chess_next/app.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/review/review_panel.dart';
import 'package:chess_next/features/review/candidate_panel.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reordering settings changes the real main side panel order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryPreferencesRepository();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(PlayPanel)).dy,
      lessThan(tester.getTopLeft(find.byType(CandidatePanel)).dy),
    );

    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('侧栏顺序'));
    await tester.pumpAndSettle();

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(3, 0);
    await tester.pumpAndSettle();
    expect(store.value?.sidePanelOrder.first.name, 'candidates');

    await tester.tap(find.text('关闭'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(find.byType(CandidatePanel)).dy,
      lessThan(tester.getTopLeft(find.byType(PlayPanel)).dy),
    );
    expect(
      tester.getTopLeft(find.byType(AnalysisPanel)).dy,
      lessThan(tester.getTopLeft(find.byType(ReviewPanel)).dy),
    );
  });
}
