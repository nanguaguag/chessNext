import 'dart:async';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/pv_prefix_action.dart';
import 'package:chess_next/application/pv_preview.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/analysis/pv_history_dialog.dart';
import 'package:chess_next/features/analysis/pv_preview_dialog.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';
import '../support/pv_history_entry.dart';

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

  final apply = find.byKey(const ValueKey('pv-apply-prefix'));
  Future<FakeEngine> livePreview(WidgetTester tester) async {
    final fake = FakeEngine();
    await tester.pumpWidget(
      ChessNextApp(engineFactory: () => Future.value(fake)),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('开始分析'));
    await pumpUntil(tester, () => fake.requests.isNotEmpty);
    fake.emit(fake.requests.last.token, pv: moves.join(' '));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
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
    return fake;
  }

  testWidgets(
    'selected prefix stops analysis, writes once and returns through both routes to the board',
    (tester) async {
      desktop(tester);
      final fake = await livePreview(tester);
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final revision = session.revision,
          positionRevision = session.positionRevision,
          epoch = session.epoch,
          requests = fake.requests.length;
      await tap(tester, find.byTooltip('回到原局面'));
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      await tap(tester, find.byTooltip('下一步'));
      await tap(tester, find.byTooltip('下一步'));
      await tester.tap(apply);
      await tester.pump();
      await pumpUntil(
        tester,
        () => find.byType(PvPreviewDialog).evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.byType(PvHistoryDialog), findsNothing);
      expect(session.moves, moves.take(2));
      expect(session.tree.nodeCount, 3);
      expect(session.revision, revision + 1);
      expect(session.positionRevision, positionRevision + 1);
      expect(session.epoch, epoch);
      expect(session.dirty, isTrue);
      expect(fake.requests.length, requests);
      expect(fake.stops, 1);
      expect(
        tester
            .widget<AnalysisPanel>(find.byType(AnalysisPanel))
            .analysis
            .enabled,
        isFalse,
      );
    },
  );
  testWidgets(
    'changed source metadata immediately disables apply and retains the new document content',
    (tester) async {
      desktop(tester);
      final fake = await livePreview(tester);
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree, stops = fake.stops;
      session.updateMetadata(GameMetadata({'Event': '不能覆盖'}));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pv-apply-stale')), findsOneWidget);
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      expect(session.tree, same(tree));
      expect(fake.stops, stops);
      await tap(tester, find.text('关闭预览'));
      await tap(tester, find.text('关闭'));
      expect(session.metadata.tags['Event'], '不能覆盖');
    },
  );
  testWidgets(
    'closing a pending apply cancels before commit and late success cannot close a newer route',
    (tester) async {
      desktop(tester);
      final done = Completer<PvApplyResult>();
      PvApplyCancellation? token;
      var opened = 0, plies = 0;
      final action = PvPrefixAction(
        isCurrent: () => true,
        perform: (count, cancel) {
          plies = count;
          token = cancel;
          return done.future;
        },
      );
      final shorter = previewEntry(moves.take(2).toList());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                opened++;
                final view = PvPreviewDialog(
                  entry: opened == 1 ? entry : shorter,
                  action: opened == 1 ? action : null,
                  loader: (e) => Future.value(PvPreview.prepare(e)),
                );
                showDialog<PvPreviewExit>(
                  context: context,
                  builder: (_) => view,
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      await tester.tap(apply);
      await tester.pump();
      expect(plies, 1);
      expect(token!.cancelled, isFalse);
      expect(find.text('正在处理…'), findsOneWidget);
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      await tester.tap(find.text('关闭预览'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(token!.cancelled, isTrue);
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('pv-preview-progress')))
            .data,
        '1 / 2',
      );
      done.complete(PvApplyResult.applied);
      await tester.pumpAndSettle();
      expect(find.byType(PvPreviewDialog), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('pv-preview-progress')))
            .data,
        '1 / 2',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    '200 percent apply failure remains readable and can retry without leaving preview',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var attempts = 0;
      final action = PvPrefixAction(
        isCurrent: () => true,
        perform: (_, _) async =>
            attempts++ == 0 ? PvApplyResult.capacity : PvApplyResult.stopFailed,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<PvPreviewExit>(
                context: context,
                builder: (_) => PvPreviewDialog(
                  entry: entry,
                  action: action,
                  loader: (e) => Future.value(PvPreview.prepare(e)),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tap(tester, find.text('打开'));
      await tap(tester, apply);
      expect(find.text('应用后超过2000节点限制，棋谱未改变'), findsOneWidget);
      expect(find.byType(PvPreviewDialog), findsOneWidget);
      await tap(tester, apply);
      expect(find.text('停止引擎失败，棋谱未改变，请重试'), findsOneWidget);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('关闭预览'));
    },
  );
}
