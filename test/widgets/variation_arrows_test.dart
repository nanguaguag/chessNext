import 'dart:ui' as ui;
import 'package:chess_next/app.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:chess_next/features/board/variation_arrows_painter.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/features/settings/preferences_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/branched_record.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder painter() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is VariationArrowsPainter,
  );
  VariationArrowsPainter painted(WidgetTester tester) =>
      tester.widget<CustomPaint>(painter()).painter! as VariationArrowsPainter;
  final toggle = find.byKey(const ValueKey('current-variation-arrows'));

  testWidgets(
    'global gate and local switch are independent; opening settings resets local only',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(branchedRecord());
      await tester.pumpAndSettle();
      expect(painter(), findsNothing);
      final tree = session.tree, revision = session.revision;
      await tap(tester, toggle);
      expect(painted(tester).arrows.map((a) => a.number), [1, 2]);
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.dirty, isFalse);
      await tap(tester, find.byTooltip('应用设置'));
      expect(session.showCurrentVariationArrows, isFalse);
      await tap(tester, find.text('分析标记'));
      await tap(tester, find.text('变着箭头'));
      expect(store.value!.showVariationArrows, isFalse);
      await tap(tester, find.text('关闭'));
      await tap(tester, find.text('取消'));
      await tap(tester, toggle);
      expect(session.showCurrentVariationArrows, isTrue);
      expect(painter(), findsNothing);
      expect(find.text('变着箭头已在分析标记设置中关闭。'), findsOneWidget);
      session.first();
      await tester.pumpAndSettle();
      expect(session.showCurrentVariationArrows, isFalse);
      expect(toggle, findsNothing);
    },
  );
  testWidgets(
    'promotion, deletion and new document never retain old numbered targets',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(branchedRecord());
      await tester.pumpAndSettle();
      await tap(tester, toggle);
      final stale = tester.widget<Switch>(toggle).onChanged!;
      session.promote(session.tree.cursorId);
      await tester.pumpAndSettle();
      expect(painted(tester).arrows.first.move.toString(), 'h2h4');
      expect(painted(tester).arrows.first.number, 1);
      session.deleteBranch('n3');
      await tester.pumpAndSettle();
      expect(painted(tester).arrows.single.move.toString(), 'h2h4');
      session.replaceTree(branchedRecord());
      await tester.pumpAndSettle();
      stale(true);
      await tester.pumpAndSettle();
      expect(session.showCurrentVariationArrows, isFalse);
      expect(painter(), findsNothing);
    },
  );
  testWidgets(
    'running analysis keeps its search, document and cell interaction with both visual layers',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine();
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(branchedRecord());
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('应用设置'));
      final prefs = tester
          .widget<PreferencesDialog>(find.byType(PreferencesDialog))
          .preferences;
      await tap(tester, find.text('取消'));
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      fake.emit(fake.requests.last.token, pv: 'h9g7 h0g2');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      final requests = fake.requests.length,
          stops = fake.stops,
          revision = session.revision;
      await tap(tester, toggle);
      expect(painter(), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is BoardArrowsPainter,
        ),
        findsOneWidget,
      );
      await prefs.setAnalysisArrows(false);
      await tester.pumpAndSettle();
      expect(painter(), findsOneWidget);
      await prefs.setVariationArrows(false);
      await tester.pumpAndSettle();
      expect(painter(), findsNothing);
      expect(session.showCurrentVariationArrows, isTrue);
      await prefs.setVariationArrows(true);
      await tester.pumpAndSettle();
      expect(painter(), findsOneWidget);
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      expect(session.revision, revision);
      await tap(tester, find.byKey(const ValueKey('square-a6')));
      expect(session.selected.toString(), 'a6');
    },
  );
  testWidgets(
    'narrow 200 percent view exposes numbered semantics and clears local at root',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const ChessNextApp());
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        session.replaceTree(branchedRecord());
        await tester.pumpAndSettle();
        await tap(tester, toggle);
        await tester.ensureVisible(find.byType(XiangqiBoard));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('上一局面的本步变着：1 马八进七；2 炮二进二')),
          findsOneWidget,
        );
        session.flip();
        await tester.pumpAndSettle();
        expect(painted(tester).flipped, isTrue);
        session.first();
        await tester.pumpAndSettle();
        expect(painter(), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  test(
    'green arrows and bright numbered badges are actually rasterized',
    () async {
      final session = BoardSession()..replaceTree(branchedRecord());
      try {
        final recorder = ui.PictureRecorder();
        VariationArrowsPainter(
          arrows: session.currentMoveArrows.visible,
        ).paint(ui.Canvas(recorder), const ui.Size(450, 500));
        final picture = recorder.endRecording();
        final image = await picture.toImage(450, 500);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var green = false, labels = false;
          for (var i = 0; i < bytes.lengthInBytes; i += 4) {
            green |=
                bytes.getUint8(i + 3) > 0 &&
                bytes.getUint8(i + 1) > bytes.getUint8(i) &&
                bytes.getUint8(i + 1) > bytes.getUint8(i + 2);
            labels |=
                bytes.getUint8(i + 3) == 255 &&
                bytes.getUint8(i) > 190 &&
                bytes.getUint8(i + 1) > 190 &&
                bytes.getUint8(i + 2) > 190;
          }
          expect(green, isTrue);
          expect(labels, isTrue);
        } finally {
          image.dispose();
          picture.dispose();
        }
      } finally {
        session.dispose();
      }
    },
  );
}
