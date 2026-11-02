import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

class MarkerStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences value) async {
    if (fail) throw StateError('full');
    await super.save(value);
  }
}

void main() {
  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder getArrows() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is BoardArrowsPainter,
  );
  BoardArrowsPainter arrows(WidgetTester tester) =>
      tester.widget<CustomPaint>(getArrows()).painter! as BoardArrowsPainter;
  Future<void> open(WidgetTester tester) async {
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('分析标记'));
  }

  Future<void> style(WidgetTester tester, String label) async {
    await tap(tester, find.byType(DropdownButtonFormField<ArrowHeadStyle>));
    await tap(tester, find.text(label).last);
  }

  testWidgets(
    'master hides both arrows, keeps running analysis and displays its latest PV on reopening',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine(), store = MarkerStore();
      await tester.pumpWidget(
        ChessNextApp(
          engineFactory: () async => fake,
          preferencesRepository: store,
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      fake.emit(fake.requests.last.token);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(arrows(tester).recommendation.toString(), 'h2e2');
      expect(arrows(tester).reply.toString(), 'b9c7');
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree;
      final requests = fake.requests.length, stops = fake.stops;
      await open(tester);
      await tap(tester, find.text('推荐箭头'));
      expect(getArrows(), findsNothing);
      expect(find.byKey(const ValueKey('pv-1')), findsOneWidget);
      fake.emit(fake.requests.last.token, pv: 'b2e2 b9c7');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await style(tester, '宽');
      await tap(tester, find.text('推荐箭头'));
      expect(arrows(tester).recommendation.toString(), 'b2e2');
      expect(arrows(tester).reply.toString(), 'b9c7');
      expect(arrows(tester).headStyle, ArrowHeadStyle.wide);
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      await tap(tester, find.text('关闭'));
      await tap(tester, find.text('取消'));
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      expect(
        session.selected.toString(),
        'h2',
        reason: 'visual layer must not intercept cells',
      );
    },
  );
  testWidgets(
    'style and visibility survive old form apply and a new app instance',
    (tester) async {
      desktop(tester);
      final store = MarkerStore()
        ..value = AppPreferences(
          showCoordinates: false,
          pieceSizePercent: 125,
          guideVersion: 55,
        );
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      await open(tester);
      await style(tester, '尖');
      await tap(tester, find.text('推荐箭头'));
      await tap(tester, find.text('关闭'));
      await tap(tester, find.widgetWithText(FilledButton, '应用设置'));
      expect(store.value!.arrowHead, ArrowHeadStyle.sharp);
      expect(store.value!.showAnalysisArrows, isFalse);
      expect(store.value!.showCoordinates, isFalse);
      expect(store.value!.pieceSizePercent, 125);
      expect(store.value!.guideVersion, 55);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      await open(tester);
      expect(
        tester
            .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, '推荐箭头'))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<ArrowHeadStyle>>(
              find.byType(DropdownButtonFormField<ArrowHeadStyle>),
            )
            .initialValue,
        ArrowHeadStyle.sharp,
      );
    },
  );
  testWidgets(
    'failed marker persistence is actionable and retries the visible choice',
    (tester) async {
      desktop(tester);
      final store = MarkerStore();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await open(tester);
      store.fail = true;
      await style(tester, '宽');
      expect(find.text('设置保存失败，当前设置仍生效，请重试').last, findsOneWidget);
      store.fail = false;
      await tap(tester, find.text('重试'));
      expect(store.value!.arrowHead, ArrowHeadStyle.wide);
    },
  );
  testWidgets(
    'narrow 200 percent dialog scrolls, keyboard dismisses and arrows expose read-only semantics',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fake = FakeEngine();
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(ChessNextApp(engineFactory: () async => fake));
        await tester.pumpAndSettle();
        await tap(tester, find.text('开始分析'));
        await pumpUntil(tester, () => fake.requests.isNotEmpty);
        fake.emit(fake.requests.last.token);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('引擎推荐：h2至e2；预计应着：b9至c7')),
          findsOneWidget,
        );
        await open(tester);
        await style(tester, '宽');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(arrows(tester).headStyle, ArrowHeadStyle.wide);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
