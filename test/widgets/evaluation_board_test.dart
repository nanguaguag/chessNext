import 'dart:ui' as ui;
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_evaluation.dart';
import 'package:chess_next/features/analysis/evaluation_board.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

class BarStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences value) async {
    if (fail) throw StateError('full');
    await super.save(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final estimate = WdlEstimate(wins: 274, draws: 724, losses: 2);
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

  Future<void> emit(
    WidgetTester tester,
    FakeEngine fake, {
    WdlEstimate? wdl,
    String? bound,
  }) async {
    fake.emit(fake.requests.last.token, score: 0, wdl: wdl, bound: bound);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
  }

  BoardEvaluation summary(WidgetTester tester) =>
      tester.widget<EvaluationBoard>(find.byType(EvaluationBoard)).evaluation;

  testWidgets(
    'no data is unknown; native expectation survives stop and flips only its orientation',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine();
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await tester.pumpAndSettle();
      expect(summary(tester).redRatio, isNull);
      expect(find.byKey(const ValueKey('evaluation-fill')), findsNothing);
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.updateMetadata(GameMetadata({'Result': '0-1'}));
      await tester.pumpAndSettle();
      expect(
        summary(tester).kind,
        EvaluationKind.unavailable,
        reason: 'a recorded result does not adjudicate the board',
      );
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      await emit(tester, fake, wdl: estimate);
      expect(summary(tester).redRatio, .636);
      await tap(tester, find.text('停止分析'));
      expect(summary(tester).redRatio, .636);
      expect(summary(tester).description, contains('保留的当前局面结果'));
      await tap(tester, find.text('翻转'));
      final fill =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('evaluation-fill')),
                  )
                  .painter!
              as EvaluationStripPainter;
      expect(fill.flipped, isTrue);
      expect(fill.redRatio, .636);
    },
  );
  testWidgets(
    'visibility reclaims width, persists and never restarts analysis or modifies the game',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine(), store = BarStore();
      await tester.pumpWidget(
        ChessNextApp(
          key: UniqueKey(),
          engineFactory: () async => fake,
          preferencesRepository: store,
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      await emit(tester, fake, wdl: estimate);
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree;
      final revision = session.revision,
          requests = fake.requests.length,
          stops = fake.stops;
      final before = tester.getSize(find.byType(XiangqiBoard)).width;
      await tap(tester, find.byTooltip('应用设置'));
      await tap(tester, find.text('分析标记'));
      await tap(tester, find.text('局势条'));
      expect(find.byKey(const ValueKey('evaluation-strip')), findsNothing);
      expect(
        tester.getSize(find.byType(XiangqiBoard)).width,
        closeTo(before + 28, .01),
      );
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(store.value!.showEvaluationBar, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('evaluation-strip')), findsNothing);
    },
  );
  testWidgets(
    'CP without WDL and bound scores stay unknown; navigation drops the old model',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine();
      await tester.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.playMove(Move.parse('c3c4'));
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      // Legal black-to-move data for this position.
      void event({WdlEstimate? wdl, String? bound}) => fake.emit(
        fake.requests.last.token,
        pv: 'b9c7 h2e2',
        wdl: wdl,
        bound: bound,
      );
      event();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(summary(tester).kind, EvaluationKind.unavailable);
      event(wdl: estimate, bound: 'lower');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(summary(tester).kind, EvaluationKind.bound);
      expect(summary(tester).redRatio, isNull);
      event(wdl: estimate);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(summary(tester).redRatio, .364);
      session.first();
      await tester.pump();
      expect(summary(tester).redRatio, isNull);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(summary(tester).kind, EvaluationKind.unavailable);
    },
  );
  testWidgets(
    'write failure leaves display preference active and can retry without losing it',
    (tester) async {
      desktop(tester);
      final store = BarStore();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('应用设置'));
      await tap(tester, find.text('分析标记'));
      store.fail = true;
      await tap(tester, find.text('局势条'));
      expect(find.byKey(const ValueKey('evaluation-strip')), findsNothing);
      expect(find.text('设置保存失败，当前设置仍生效，请重试').last, findsOneWidget);
      store.fail = false;
      await tap(tester, find.text('重试'));
      expect(store.value!.showEvaluationBar, isFalse);
    },
  );
  testWidgets(
    'narrow system 200 percent retains accessible values, cell targets and keyboard use',
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
        expect(find.bySemanticsLabel('局势条'), findsOneWidget);
        final cell = tester.getSize(find.byKey(const ValueKey('square-h2')));
        expect(cell.width, greaterThanOrEqualTo(48));
        await tap(tester, find.byKey(const ValueKey('square-h2')));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        expect(session.selected, isNull);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  test(
    'actual strip pixels show a stable red fraction with inverted orientation',
    () async {
      for (final flipped in [false, true]) {
        final recorder = ui.PictureRecorder();
        EvaluationStripPainter(
          redRatio: .75,
          flipped: flipped,
        ).paint(ui.Canvas(recorder), const ui.Size(20, 200));
        final picture = recorder.endRecording();
        final image = await picture.toImage(20, 200);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final topRed = bytes.getUint8((10 * 20 + 10) * 4) == 0xab;
          final bottomRed = bytes.getUint8((190 * 20 + 10) * 4) == 0xab;
          expect(topRed, flipped);
          expect(bottomRed, !flipped);
          var red = 0;
          for (var y = 0; y < 200; y++) {
            if (bytes.getUint8((y * 20 + 10) * 4) == 0xab) red++;
          }
          expect(red, 150);
        } finally {
          image.dispose();
          picture.dispose();
        }
      }
    },
  );
}
