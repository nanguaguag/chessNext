import 'package:chess_next/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('local play, flip, undo and destructive new-game cancellation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChessNextApp());
    expect(find.text('红方行棋'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pump();
    expect(find.text('黑方行棋'), findsOneWidget);
    expect(find.text('1. h2e2'), findsOneWidget);
    await tester.tap(find.text('翻转'));
    await tester.pump();
    expect(find.text('黑方行棋'), findsOneWidget);
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('1. h2e2'), findsOneWidget);
    await tester.tap(find.text('悔棋'));
    await tester.pump();
    expect(find.text('红方行棋'), findsOneWidget);
    expect(find.text('1. h2e2'), findsNothing);
  });
  testWidgets('keyboard selection and narrow layout at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChessNextApp());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '红方帅 e0' &&
            w.properties.selected == true,
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '红方帅 e0' &&
            w.properties.selected == true,
      ),
      findsNothing,
    );

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('红方帅 e0')), findsOneWidget);
    semantics.dispose();
  });
}
