import 'dart:math' as math;
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/analysis/pv_history_dialog.dart';
import 'package:chess_next/features/analysis/pv_preview_dialog.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:chess_next/features/board/last_move_markers.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/editor/editor_page.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

void main() {
  void desktop(WidgetTester t) {
    t.view.physicalSize = const Size(1120, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets(
    'main control maps four orientations to logical taps at 200 percent with small and oversized faces',
    (t) async {
      desktop(t);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = t.ensureSemantics();
      try {
        for (final percent in [10, 200]) {
          await t.pumpWidget(
            ChessNextApp(
              key: UniqueKey(),
              preferencesRepository: MemoryPreferencesRepository()
                ..value = AppPreferences(pieceSizePercent: percent),
            ),
          );
          await t.pumpAndSettle();
          final session = t
              .widget<XiangqiBoard>(find.byType(XiangqiBoard))
              .session;
          for (final flipped in [false, true]) {
            for (final mirrored in [false, true]) {
              session.newGame();
              if (session.flipped != flipped) session.flip();
              if (session.mirrored != mirrored) await tap(t, find.text('左右翻转'));
              await t.pumpAndSettle();
              final a = t.getCenter(find.byKey(const ValueKey('square-a9'))),
                  z = t.getCenter(find.byKey(const ValueKey('square-i0')));
              final step = t
                  .getSize(find.byKey(const ValueKey('square-h2')))
                  .width;
              final origin = Offset(
                math.min(a.dx, z.dx) - step / 2,
                math.min(a.dy, z.dy) - step / 2,
              );
              final size = Size(step * 9, step * 10);
              Offset point(String s) =>
                  origin +
                  boardSquarePoint(
                    Square.parse(s),
                    size,
                    flipped: flipped,
                    mirrored: mirrored,
                  );
              await t.ensureVisible(find.byType(XiangqiBoard));
              await t.pumpAndSettle();
              // Recompute origin after scrolling into view.
              final delta =
                  t.getCenter(find.byKey(const ValueKey('square-a9'))) - a;
              await t.tapAt(point('h2') + delta);
              await t.pumpAndSettle();
              expect(session.selected, Square.parse('h2'));
              await t.tapAt(point('e2') + delta);
              await t.pumpAndSettle();
              expect(session.moves, [Move.parse('h2e2')]);
              final painter =
                  t
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('last-move-markers')),
                          )
                          .painter!
                      as LastMoveMarkersPainter;
              expect(painter.flipped, flipped);
              expect(painter.mirrored, mirrored);
              expect(find.bySemanticsLabel('最后一步：h2至e2'), findsOneWidget);
              expect(t.takeException(), isNull);
            }
          }
        }
      } finally {
        semantics.dispose();
      }
      // Keyboard left follows visible direction in the composed geometry.
      for (final flipped in [false, true]) {
        for (final mirrored in [false, true]) {
          final taps = <Square>[];
          await t.pumpWidget(
            MaterialApp(
              home: Material(
                child: BoardSurface(
                  at: Position.initial().at,
                  onTap: taps.add,
                  flipped: flipped,
                  mirrored: mirrored,
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('square-h2')));
          await t.pumpAndSettle();
          await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await t.sendKeyEvent(LogicalKeyboardKey.enter);
          await t.pumpAndSettle();
          expect(taps, [
            Square.parse('h2'),
            Square.parse(flipped != mirrored ? 'i2' : 'g2'),
          ]);
        }
      }
    },
  );
  testWidgets(
    'history and real-worker preview capture both view directions without tracking later main changes',
    (t) async {
      desktop(t);
      final fake = FakeEngine();
      await t.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await t.pumpAndSettle();
      final engine = t
          .widget<AnalysisPanel>(find.byType(AnalysisPanel))
          .analysis;
      await tap(t, find.text('开始分析'));
      await pumpUntil(t, () => fake.requests.isNotEmpty);
      fake.emit(fake.requests.last.token);
      await t.pump(const Duration(milliseconds: 150));
      await tap(t, find.text('左右翻转'));
      await tap(t, find.text('翻转'));
      final tree = engine.session.tree, token = fake.requests.last.token;
      await tap(t, find.byKey(const ValueKey('pv-history-open')));
      final history = t.widget<PvHistoryDialog>(find.byType(PvHistoryDialog));
      expect(history.mirrored, isTrue);
      expect(history.side, Side.black);
      engine.session.mirror();
      engine.session.flip();
      await t.pumpAndSettle();
      expect(
        t.widget<PvHistoryDialog>(find.byType(PvHistoryDialog)).mirrored,
        isTrue,
      );
      final previewButton = find.byKey(
        ValueKey('pv-history-preview-${history.entries.first.id}'),
      );
      await t.ensureVisible(previewButton);
      await t.pumpAndSettle();
      await t.tap(previewButton);
      await t.pump();
      await pumpUntil(
        t,
        () => find
            .byKey(const ValueKey('pv-preview-progress'))
            .evaluate()
            .isNotEmpty,
      );
      final preview = t.widget<PvPreviewDialog>(find.byType(PvPreviewDialog));
      expect(preview.flipped, isTrue);
      expect(preview.mirrored, isTrue);
      final surface = t.widget<BoardSurface>(
        find.descendant(
          of: find.byType(PvPreviewDialog),
          matching: find.byType(BoardSurface),
        ),
      );
      expect(surface.flipped, isTrue);
      expect(surface.mirrored, isTrue);
      await tap(
        t,
        find.descendant(
          of: find.byType(PvPreviewDialog),
          matching: find.text('关闭预览'),
        ),
      );
      await tap(t, find.text('关闭'));
      expect(engine.session.tree, same(tree));
      expect(fake.requests.length, 1);
      expect(engine.infos.single.token, token);
      await engine.disable();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'main mirror does not alter editor setup and stays a session-only view',
    (t) async {
      desktop(t);
      await t.pumpWidget(ChessNextApp(key: UniqueKey()));
      await t.pumpAndSettle();
      final session = t.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session;
      await tap(t, find.text('左右翻转'));
      final tree = session.tree;
      await tap(t, find.text('编辑局面'));
      final editor = t.widget<BoardSurface>(
        find.descendant(
          of: find.byType(EditorPage),
          matching: find.byType(BoardSurface),
        ),
      );
      expect(editor.mirrored, isFalse);
      for (var file = 0; file < 9; file++) {
        for (var rank = 0; rank < 10; rank++) {
          final square = Square(file, rank);
          final actual = editor.at(square),
              expected = Position.initial().at(square);
          expect(
            (actual?.side, actual?.type),
            (expected?.side, expected?.type),
          );
        }
      }
      await tap(t, find.byTooltip('取消编辑'));
      expect(session.tree, same(tree));
      expect(session.mirrored, isTrue);
      expect(session.dirty, isFalse);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(ChessNextApp(key: UniqueKey()));
      await t.pumpAndSettle();
      expect(
        t.widget<XiangqiBoard>(find.byType(XiangqiBoard)).session.mirrored,
        isFalse,
      );
      expect(t.takeException(), isNull);
    },
  );
}
