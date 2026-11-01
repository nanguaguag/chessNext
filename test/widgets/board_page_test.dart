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
    expect(find.text('1. 炮二平五'), findsOneWidget);
    await tester.tap(find.text('翻转'));
    await tester.pump();
    expect(find.text('黑方行棋'), findsOneWidget);
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('1. 炮二平五'), findsOneWidget);
    await tester.tap(find.text('悔棋'));
    await tester.pump();
    expect(find.text('红方行棋'), findsOneWidget);
    expect(find.text('1. 炮二平五'), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(const ValueKey('move-n0'))).selected,
      isTrue,
    );
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
  testWidgets('comments and continuations survive cursor navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChessNextApp());
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('comment-n1')));
    await tester.enterText(find.byKey(const ValueKey('comment-n1')), '中炮注释');
    await tester.pump();
    await tester.tap(find.byTooltip('回到开始'));
    await tester.pump();
    expect(find.text('继续 炮二平五'), findsOneWidget);
    await tester.tap(find.byTooltip('下一着'));
    await tester.pump();
    expect(find.text('中炮注释'), findsOneWidget);
  });
  testWidgets(
    'save and open restore the current document without discarding it',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ChessNextApp());
      await tester.tap(find.byKey(const ValueKey('square-h2')));
      await tester.tap(find.byKey(const ValueKey('square-e2')));
      await tester.pump();
      await tester.tap(find.text('保存棋谱'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('record-name')), '我的中炮');
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();
      expect(find.text('已保存到本地 · 我的中炮'), findsOneWidget);
      await tester.tap(find.text('新局'));
      await tester.pumpAndSettle();
      expect(find.text('1. 炮二平五'), findsNothing);
      await tester.tap(find.text('棋谱库'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('我的中炮'));
      await tester.pumpAndSettle();
      expect(find.text('1. 炮二平五'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
