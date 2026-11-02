import 'dart:async';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/pv_preview.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/analysis/pv_history_dialog.dart';
import 'package:chess_next/features/analysis/pv_preview_dialog.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/pv_history_entry.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  final moves = 'h2e2 b9c7 b0c2 h9g7'.split(' ').map(Move.parse).toList();
  final entry = previewEntry(moves);
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

  Widget host(WidgetBuilder builder) => MaterialApp(
    home: Builder(
      builder: (context) => FilledButton(
        onPressed: () => showDialog<void>(context: context, builder: builder),
        child: const Text('打开预览'),
      ),
    ),
  );
  String progress(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('pv-preview-progress')))
      .data!;
  testWidgets(
    'real worker preview from history remains read-only while live analysis continues',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine();
      await tester.pumpWidget(
        ChessNextApp(engineFactory: () => Future.value(fake)),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      final token = fake.requests.last.token;
      fake.emit(token, pv: moves.join(' '));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree,
          revision = session.revision,
          requests = fake.requests.length,
          stops = fake.stops;
      await tap(tester, find.byKey(const ValueKey('pv-history-open')));
      await tester.tap(find.text('预览').first);
      await tester.pump();
      await pumpUntil(
        tester,
        () => find
            .byKey(const ValueKey('pv-preview-progress'))
            .evaluate()
            .isNotEmpty,
      );
      expect(progress(tester), '1 / 4');
      fake.emit(token, score: 99);
      await tester.pump(const Duration(milliseconds: 150));
      await tap(tester, find.byTooltip('下一步'));
      expect(progress(tester), '2 / 4');
      expect(
        tester
            .widget<BoardSurface>(
              find.descendant(
                of: find.byType(PvPreviewDialog),
                matching: find.byType(BoardSurface),
              ),
            )
            .enabled,
        isFalse,
      );
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.dirty, isFalse);
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PvPreviewDialog), findsNothing);
      expect(find.byType(PvHistoryDialog), findsOneWidget);
      await tap(tester, find.text('关闭'));
      expect(
        tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis
            .enabled,
        isTrue,
      );
    },
  );
  testWidgets(
    'stepping, keyboard, timed playback, pause and last-step restart obey boundaries',
    (tester) async {
      desktop(tester);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(
        host(
          (_) => PvPreviewDialog(
            entry: entry,
            loader: (e) => Future.value(PvPreview.prepare(e)),
          ),
        ),
      );
      await tap(tester, find.text('打开预览'));
      expect(progress(tester), '1 / 4');
      await tap(tester, find.byTooltip('回到原局面'));
      expect(progress(tester), '0 / 4');
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == '上一步',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('播放'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 799));
      expect(progress(tester), '0 / 4');
      await tester.pump(const Duration(milliseconds: 1));
      expect(progress(tester), '1 / 4');
      await tester.pump(const Duration(milliseconds: 800));
      expect(progress(tester), '2 / 4');
      await tester.tap(find.byTooltip('暂停'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(progress(tester), '2 / 4');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(progress(tester), '1 / 4');
      await tap(tester, find.byTooltip('到预览末尾'));
      expect(progress(tester), '4 / 4');
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == '下一步',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('播放'));
      await tester.pump();
      expect(progress(tester), '0 / 4');
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pumpAndSettle();
      expect(progress(tester), '4 / 4');
      expect(find.byTooltip('暂停'), findsNothing);
      await tap(tester, find.text('1. 炮二平五'));
      expect(progress(tester), '1 / 4');
      await tester.tap(find.byTooltip('播放'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.byTooltip('暂停'), findsNothing);
      final frozen = progress(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(progress(tester), frozen);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.byTooltip('播放'));
      await tester.pump();
      await tester.tap(find.text('关闭预览'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancelled pending worker cannot replace or close a later preview route',
    (tester) async {
      desktop(tester);
      final pending = Completer<PvPreview>();
      var opened = 0;
      final shorter = previewEntry(moves.take(2).toList());
      await tester.pumpWidget(
        host((_) {
          opened++;
          return PvPreviewDialog(
            entry: opened == 1 ? entry : shorter,
            loader: opened == 1
                ? (_) => pending.future
                : (e) => Future.value(PvPreview.prepare(e)),
          );
        }),
      );
      await tester.tap(find.text('打开预览'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('关闭预览'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('打开预览'));
      await tester.pumpAndSettle();
      expect(progress(tester), '1 / 2');
      pending.complete(PvPreview.prepare(entry));
      await tester.pumpAndSettle();
      expect(progress(tester), '1 / 2');
      expect(find.byType(PvPreviewDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PvPreviewDialog), findsNothing);
    },
  );
  testWidgets(
    'preparation error can retry without exposing internal errors or mutating a board',
    (tester) async {
      desktop(tester);
      var attempts = 0;
      await tester.pumpWidget(
        host(
          (_) => PvPreviewDialog(
            entry: entry,
            loader: (e) async {
              if (attempts++ == 0) throw StateError('/private/native/path');
              return PvPreview.prepareInWorker(e);
            },
          ),
        ),
      );
      await tap(tester, find.text('打开预览'));
      expect(find.text('无法准备此PV，请重试'), findsOneWidget);
      expect(find.textContaining('/private'), findsNothing);
      await tester.tap(find.text('重试'));
      await tester.pump();
      await pumpUntil(
        tester,
        () => find
            .byKey(const ValueKey('pv-preview-progress'))
            .evaluate()
            .isNotEmpty,
      );
      expect(progress(tester), '1 / 4');
      await tap(tester, find.text('关闭预览'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow 200 percent preview keeps the read-only board and last virtualized move accessible',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        final cycle = 'b0c2 b9c7 c2b0 c7b9'.split(' ').map(Move.parse).toList();
        final long = previewEntry(List.generate(140, (i) => cycle[i % 4]));
        await tester.pumpWidget(
          host(
            (_) => PvPreviewDialog(
              entry: long,
              flipped: true,
              loader: (e) => Future.value(PvPreview.prepare(e)),
            ),
          ),
        );
        await tap(tester, find.text('打开预览'));
        expect(find.textContaining('原PV共140步'), findsOneWidget);
        expect(find.byKey(const ValueKey('pv-preview-step-128')), findsNothing);
        await tap(tester, find.byTooltip('到预览末尾'));
        expect(progress(tester), '128 / 128');
        expect(
          find.byKey(const ValueKey('pv-preview-step-128')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('第128步只读局面'), findsOneWidget);
        final board = tester.widget<BoardSurface>(find.byType(BoardSurface));
        expect(board.flipped, isTrue);
        expect(board.lastMove, long.info.pv.last);
        expect(board.selected, isNull);
        expect(board.enabled, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
