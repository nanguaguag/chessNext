import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/application/review_report.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/move_grade_badge.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/review/move_grade_controls.dart';
import 'package:chess_next/features/settings/analysis_markers_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

class GradeStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences v) async {
    if (fail) throw StateError('disk');
    return super.save(v);
  }
}

void main() {
  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets(
    'logical corner geometry, size independence, semantics and pointer passthrough',
    (t) async {
      final semantics = t.ensureSemantics();
      try {
        for (final flipped in [false, true]) {
          for (final mirrored in [false, true]) {
            for (final percent in [10, 200]) {
              final taps = <Square>[];
              final move = Move.parse('a0a1');
              await t.pumpWidget(
                MaterialApp(
                  home: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(2),
                    ),
                    child: Material(
                      child: Center(
                        child: SizedBox(
                          width: 450,
                          child: BoardSurface(
                            at: Position.initial().at,
                            onTap: taps.add,
                            lastMove: move,
                            pieceSizePercent: percent,
                            flipped: flipped,
                            mirrored: mirrored,
                            assessment: const MoveAssessment(
                              nodeId: 'n1',
                              mover: Side.red,
                              grade: MoveGrade.good,
                              lossUnits: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await t.pumpAndSettle();
              final board = find.byType(MoveGradeBadge);
              final point = boardSquarePoint(
                move.to,
                t.getSize(board),
                flipped: flipped,
                mirrored: mirrored,
              );
              final center = t.getCenter(
                find.byKey(const ValueKey('move-grade-glyph')),
              );
              expect(
                center,
                t.getTopLeft(board) + point + const Offset(14, -14),
              );
              expect(
                t.getSize(find.byKey(const ValueKey('move-grade-glyph'))),
                const Size(17, 17),
              );
              await t.tapAt(center);
              await t.pumpAndSettle();
              expect(taps, [move.to]);
              expect(
                find.bySemanticsLabel(RegExp('a1；本机模型评级：好着，预期损失 2.00')),
                findsOneWidget,
              );
              expect(t.takeException(), isNull);
            }
          }
        }
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'global hide removes only badge; editor-style board and unrated never draw',
    (t) async {
      bool show = true;
      final move = Move.parse('h2e2');
      MoveAssessment? row = const MoveAssessment(
        nodeId: 'n1',
        mover: Side.red,
        grade: MoveGrade.best,
        lossUnits: 0,
      );
      Widget view() => MaterialApp(
        home: BoardDisplayScope(
          showCoordinates: false,
          showMoveGrades: show,
          child: Material(
            child: BoardSurface(
              at: Position.initial().at,
              onTap: (_) {},
              lastMove: move,
              assessment: row,
            ),
          ),
        ),
      );
      await t.pumpWidget(view());
      expect(find.byType(MoveGradeBadge), findsOneWidget);
      show = false;
      await t.pumpWidget(view());
      expect(find.byType(MoveGradeBadge), findsNothing);
      expect(find.byKey(const ValueKey('last-move-markers')), findsOneWidget);
      show = true;
      row = const MoveAssessment(
        nodeId: 'n1',
        mover: Side.red,
        grade: MoveGrade.unrated,
      );
      await t.pumpWidget(view());
      expect(find.byType(MoveGradeBadge), findsNothing);
      await t.pumpWidget(
        MaterialApp(
          home: Material(
            child: BoardSurface(at: Position.initial().at, onTap: (_) {}),
          ),
        ),
      );
      expect(find.byType(MoveGradeBadge), findsNothing);
    },
  );
  testWidgets(
    'review and settings share live flag; failed writes retry, persist, leave search and document alone',
    (t) async {
      t.view.physicalSize = const Size(1120, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final fake = FakeEngine(), store = GradeStore();
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        engineFactory: () async => fake,
        preferencesRepository: store,
      );
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      final engine = t
          .widget<AnalysisPanel>(find.byType(AnalysisPanel))
          .analysis;
      final session = engine.session;
      session.playMove(Move.parse('h2e2'));
      await t.pumpAndSettle();
      var completed = false;
      final job = engine
          .startReview(limits: ReviewLimits(depth: 2))
          .whenComplete(() => completed = true);
      await pumpUntil(t, () => fake.requests.isNotEmpty);
      var seen = 0;
      for (var i = 0; i < 20 && !completed; i++) {
        if (fake.requests.length > seen) {
          seen = fake.requests.length;
          final r = fake.requests.last;
          fake.emit(
            r.token,
            pv: r.position.legalMoves.first.toString(),
            wdl: WdlEstimate(wins: 300, draws: 400, losses: 300),
          );
          await t.pump();
          fake.results.last.complete(r.position.legalMoves.first);
        }
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await t.pump(const Duration(milliseconds: 10));
      }
      expect(completed, isTrue);
      await job;
      await t.pumpAndSettle();
      expect(find.byType(MoveGradeBadge), findsOneWidget);
      final row = engine.currentMoveAssessment!, tree = session.tree;
      await tap(t, find.text('开始分析'));
      await pumpUntil(t, () => engine.enabled && fake.requests.length > seen);
      final requests = fake.requests.length, stops = fake.stops;
      store.fail = true;
      await tap(t, find.byKey(const ValueKey('show-move-grades')));
      expect(find.byType(MoveGradeBadge), findsNothing);
      expect(find.textContaining('本机模型评级：${row.grade.label}'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MoveGradeControls),
          matching: find.textContaining('设置保存失败'),
        ),
        findsOneWidget,
      );
      store.fail = false;
      await tap(
        t,
        find.descendant(
          of: find.byType(MoveGradeControls),
          matching: find.text('重试保存设置'),
        ),
      );
      await tap(t, find.byTooltip('应用设置'));
      await tap(t, find.text('分析标记'));
      final flag = find.descendant(
        of: find.byType(AnalysisMarkersDialog),
        matching: find.byKey(const ValueKey('show-move-grades')),
      );
      expect(t.widget<SwitchListTile>(flag).value, isFalse);
      await tap(t, flag);
      expect(find.byType(MoveGradeBadge), findsOneWidget);
      await tap(
        t,
        find.descendant(
          of: find.byType(AnalysisMarkersDialog),
          matching: find.text('标记说明'),
        ),
      );
      expect(find.byType(MoveGradeLegend), findsOneWidget);
      await tap(
        t,
        find.descendant(
          of: find.byType(MoveGradeLegend),
          matching: find.text('关闭'),
        ),
      );
      await tap(t, flag);
      await tap(t, find.text('关闭'));
      await tap(t, find.text('取消'));
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      expect(session.tree, same(tree));
      expect(engine.currentMoveAssessment, same(row));
      await engine.disable();
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      expect(
        t
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('show-move-grades')),
            )
            .value,
        isFalse,
      );
      expect(store.value!.showMoveGrades, isFalse);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('legend remains scrollable at 200 percent in a narrow window', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(2),
                    ),
                    child: const MoveGradeLegend(),
                  ),
                ),
                child: const Text('说明'),
              ),
            ),
          ),
        ),
      ),
    );
    await tap(t, find.text('说明'));
    await t.ensureVisible(find.text('模型版本：native-wdl-loss-v1'));
    await t.pumpAndSettle();
    expect(find.text('模型版本：native-wdl-loss-v1').hitTestable(), findsOneWidget);
    await tap(t, find.text('关闭'));
    expect(t.takeException(), isNull);
  });
}
