import 'package:chess_next/features/workspace/resizable_workspace.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop board page uses the four-pane workspace when wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChessNextApp(preferencesRepository: MemoryPreferencesRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ResizableWorkspace), findsOneWidget);
    expect(find.byKey(const ValueKey('调整左栏宽度')), findsOneWidget);
    expect(find.byKey(const ValueKey('调整棋盘宽度')), findsOneWidget);
    expect(find.byKey(const ValueKey('调整左侧上下分区')), findsOneWidget);
    expect(find.byKey(const ValueKey('调整右侧引擎与云库上下分区')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four splitters resize their real panes and reset to defaults', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResizableWorkspace(
            leftTop: const Text('左侧操作区'),
            leftBottom: const Text('左侧记录区'),
            board: const Text('棋盘区域'),
            rightTop: const Text('右侧引擎区'),
            rightBottom: const Text('右侧云库区'),
            rightHeader: const Text('侧栏选择'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    final dividerLabels = ['调整左栏宽度', '调整棋盘宽度', '调整左侧上下分区', '调整右侧引擎与云库上下分区'];
    for (final label in dividerLabels) {
      expect(find.byKey(ValueKey(label)), findsOneWidget);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }

    final initialBoardWidth = tester
        .getSize(find.byKey(const ValueKey('workspace-board-pane')))
        .width;
    await tester.drag(
      find.byKey(const ValueKey('调整左栏宽度')),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('workspace-board-pane'))).width,
      lessThan(initialBoardWidth),
    );

    final initialRightTopHeight = tester
        .getSize(find.byKey(const ValueKey('workspace-right-top')))
        .height;
    await tester.drag(
      find.byKey(const ValueKey('调整右侧引擎与云库上下分区')),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('workspace-right-top'))).height,
      greaterThan(initialRightTopHeight),
    );

    await tester.tap(find.byKey(const ValueKey('reset-workspace-layout')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('workspace-board-pane'))).width,
      initialBoardWidth,
    );

    final leftSplitter = tester.getSemantics(find.bySemanticsLabel('调整左栏宽度'));
    final splitterData = leftSplitter.getSemanticsData();
    expect(splitterData.hasAction(SemanticsAction.increase), isTrue);
    expect(splitterData.hasAction(SemanticsAction.decrease), isTrue);
    semantics.dispose();
  });

  testWidgets('board-left preset puts board, record and side panels in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryPreferencesRepository()
      ..value = AppPreferences(
        boardLayoutPreset: BoardLayoutPreset.boardOnLeft,
      );

    await tester.pumpWidget(ChessNextApp(preferencesRepository: repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workspace-board-pane')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-middle-pane')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-right-pane')), findsOneWidget);
    final boardLeft = tester
        .getTopLeft(find.byKey(const ValueKey('workspace-board-pane')))
        .dx;
    final recordLeft = tester
        .getTopLeft(find.byKey(const ValueKey('workspace-middle-pane')))
        .dx;
    final panelsLeft = tester
        .getTopLeft(find.byKey(const ValueKey('workspace-right-pane')))
        .dx;
    expect(boardLeft, lessThan(recordLeft));
    expect(recordLeft, lessThan(panelsLeft));
    expect(find.byKey(const ValueKey('调整左栏宽度')), findsNothing);
    expect(find.byKey(const ValueKey('调整棋盘宽度')), findsOneWidget);
    final semantics = tester.ensureSemantics();
    final splitter = tester.getSemantics(find.bySemanticsLabel('调整棋盘宽度'));
    expect(
      splitter.getSemanticsData().hasAction(SemanticsAction.increase),
      isTrue,
    );
    final initialBoardWidth = tester
        .getSize(find.byKey(const ValueKey('workspace-board-pane')))
        .width;
    await tester.drag(
      find.byKey(const ValueKey('调整棋盘宽度')),
      const Offset(40, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('workspace-board-pane'))).width,
      greaterThan(initialBoardWidth),
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings apply and persist board layout preset', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryPreferencesRepository();

    await tester.pumpWidget(ChessNextApp(preferencesRepository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board-layout-preset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('棋盘靠左').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '应用设置'));
    await tester.pumpAndSettle();

    expect(repository.value?.boardLayoutPreset, BoardLayoutPreset.boardOnLeft);
    expect(find.byKey(const ValueKey('workspace-middle-pane')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
