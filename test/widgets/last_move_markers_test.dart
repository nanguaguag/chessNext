import 'dart:ui' as ui;
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/board/board_arrows_painter.dart';
import 'package:chess_next/features/board/last_move_markers.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/settings/board_display_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/ports/audio_feedback.dart';
import 'package:chess_next/ports/audio_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';
import '../support/branched_record.dart';

class MarkerStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences value) async {
    if (fail) throw StateError('disk');
    await super.save(value);
  }
}

class MarkerAudio implements AudioFeedbackPort {
  final events = <AudioFeedbackKind>[];
  @override
  Future<void> play(
    AudioFeedbackKind kind, {
    MoveSoundChoice moveChoice = MoveSoundChoice.sound1,
  }) async => events.add(kind);
  @override
  Future<void> dispose() async {}
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

  LastMoveMarkersPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byKey(const ValueKey('last-move-markers')),
              )
              .painter!
          as LastMoveMarkersPainter;
  Future<void> settings(WidgetTester tester) async {
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('棋盘显示'));
  }

  Future<void> choose(WidgetTester tester, String label) async {
    await tap(
      tester,
      find.byType(DropdownButtonFormField<LastMoveMarkerStyle>),
    );
    await tap(tester, find.text(label).last);
  }

  testWidgets(
    'root has no marker; moves, navigation, flip and replacement use current document only',
    (tester) async {
      desktop(tester);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const ChessNextApp());
        await tester.pumpAndSettle();
        expect(find.byType(LastMoveMarkers), findsNothing);
        await tap(tester, find.byKey(const ValueKey('square-h2')));
        await tester.tap(find.byKey(const ValueKey('square-e2')));
        await tester.pump();
        expect(painter(tester).phase, 0);
        await tester.pump(const Duration(milliseconds: 150));
        expect(painter(tester).phase, closeTo(.25, .02));
        await tester.pumpAndSettle();
        final session = tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session;
        session.replaceTree(branchedRecord());
        await tester.pumpAndSettle();
        expect(painter(tester).move, Move.parse('h2h4'));
        expect(find.bySemanticsLabel('最后一步：h2至h4'), findsOneWidget);
        final tree = session.tree;
        await tap(tester, find.text('翻转'));
        expect(painter(tester).flipped, isTrue);
        expect(painter(tester).move, Move.parse('h2h4'));
        expect(session.tree, same(tree));
        session.navigate('n2');
        await tester.pumpAndSettle();
        expect(painter(tester).move, Move.parse('b9c7'));
        session.first();
        await tester.pumpAndSettle();
        expect(find.byType(LastMoveMarkers), findsNothing);
        session.newGame();
        await tester.pumpAndSettle();
        expect(find.byType(LastMoveMarkers), findsNothing);
        await tap(tester, find.text('编辑局面'));
        expect(find.byType(LastMoveMarkers), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('animation speed controls next move and persists locally', (
    tester,
  ) async {
    desktop(tester);
    final store = MarkerStore();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    await settings(tester);
    final off = find.descendant(
      of: find.byKey(const ValueKey('animation-speed')),
      matching: find.text('关'),
    );
    await tap(tester, off);
    expect(store.value?.animationSpeed, AnimationSpeed.off);
    await tap(tester, find.text('关闭'));
    await tap(tester, find.text('取消'));
    await tap(tester, find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pump();
    expect(painter(tester).phase, 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter(tester).phase, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('app routes offline selection and move feedback to its port', (
    tester,
  ) async {
    desktop(tester);
    final store = MarkerStore();
    final audio = MarkerAudio();
    await tester.pumpWidget(
      ChessNextApp(preferencesRepository: store, audioFeedback: audio),
    );
    await tester.pumpAndSettle();
    final session = tester
        .widget<XiangqiBoard>(find.byType(XiangqiBoard))
        .session;
    final move = session.legalMoves.first;
    session.tap(move.from);
    await tester.pump();
    expect(audio.events, [AudioFeedbackKind.select]);
    session.tap(move.to);
    await tester.pump();
    await tester.pump(Duration.zero);
    expect(audio.events, [AudioFeedbackKind.select, AudioFeedbackKind.move]);
    expect(session.tree.current.move, move);

    await settings(tester);
    await tap(tester, find.widgetWithText(SwitchListTile, '选子音效'));
    expect(store.value?.playSelectionSound, isFalse);
    await tap(tester, find.widgetWithText(SwitchListTile, '吃子音效'));
    await tap(tester, find.widgetWithText(SwitchListTile, '将军音效'));
    await tap(tester, find.widgetWithText(SwitchListTile, '绝杀音效'));
    await tap(tester, find.widgetWithText(SwitchListTile, '着法朗读'));
    expect(store.value?.playCaptureSound, isFalse);
    expect(store.value?.playCheckSound, isFalse);
    expect(store.value?.playMateSound, isFalse);
    expect(store.value?.speakMoves, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'halo completes a finite turn, orientation does not restart it, reduced motion stops immediately',
    (tester) async {
      Move move = Move.parse('h2e2');
      Object identity = 1;
      bool reduced = false, flipped = false;
      Widget view() => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: SizedBox(
            width: 450,
            height: 500,
            child: LastMoveMarkers(
              move: move,
              identity: identity,
              style: LastMoveMarkerStyle.halo,
              flipped: flipped,
            ),
          ),
        ),
      );
      await tester.pumpWidget(view());
      expect(painter(tester).phase, 1);
      move = Move.parse('b9c7');
      identity = 2;
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 150));
      expect(painter(tester).phase, closeTo(.25, .02));
      flipped = true;
      await tester.pumpWidget(view());
      expect(painter(tester).phase, closeTo(.25, .02));
      await tester.pump(const Duration(milliseconds: 450));
      expect(painter(tester).phase, 1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
      identity = 3;
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter(tester).phase, lessThan(1));
      reduced = true;
      await tester.pumpWidget(view());
      await tester.pump();
      expect(painter(tester).phase, 1);
      identity = 4;
      await tester.pumpWidget(view());
      expect(painter(tester).phase, 1);
      reduced = false;
      identity = 5;
      await tester.pumpWidget(view());
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'live style switch persists and retries without changing engine or document',
    (tester) async {
      desktop(tester);
      final fake = FakeEngine(), store = MarkerStore();
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        engineFactory: () async => fake,
        preferencesRepository: store,
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(branchedRecord());
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      fake.emit(fake.requests.last.token);
      await tester.pump(const Duration(milliseconds: 150));
      final requests = fake.requests.length, stops = fake.stops;
      final tree = session.tree,
          revision = session.revision,
          positionRevision = session.positionRevision;
      await settings(tester);
      store.fail = true;
      await choose(tester, '方框');
      expect(painter(tester).style, LastMoveMarkerStyle.box);
      expect(
        find.descendant(
          of: find.byType(BoardDisplayDialog),
          matching: find.textContaining('设置保存失败'),
        ),
        findsOneWidget,
      );
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.positionRevision, positionRevision);
      expect(session.dirty, isFalse);
      store.fail = false;
      await tap(
        tester,
        find.descendant(
          of: find.byType(BoardDisplayDialog),
          matching: find.text('重试'),
        ),
      );
      await pumpUntil(
        tester,
        () => store.value?.lastMoveMarker == LastMoveMarkerStyle.box,
      );
      await tap(tester, find.text('关闭'));
      await tap(tester, find.text('取消'));
      await tester
          .widget<AnalysisPanel>(find.byType(AnalysisPanel))
          .analysis
          .disable();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await settings(tester);
      expect(
        tester
            .widget<DropdownButtonFormField<LastMoveMarkerStyle>>(
              find.byType(DropdownButtonFormField<LastMoveMarkerStyle>),
            )
            .initialValue,
        LastMoveMarkerStyle.box,
      );
      expect(find.text('重试'), findsNothing);
    },
  );
  testWidgets(
    '200 percent text and large pieces keep markers at intersections and allow tapping through',
    (tester) async {
      final position = Position.initial().play(Move.parse('h2e2'));
      final taps = <Square>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Material(
              child: Center(
                child: SizedBox(
                  width: 450,
                  child: BoardSurface(
                    at: position.at,
                    onTap: taps.add,
                    lastMove: Move.parse('h2e2'),
                    lastMoveMarkerStyle: LastMoveMarkerStyle.box,
                    pieceSizePercent: 200,
                    flipped: true,
                    mirrored: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cell = find.byKey(const ValueKey('square-e2'));
      expect(tester.getSize(cell).width, 50);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(taps, [Square.parse('e2')]);
      expect(painter(tester).flipped, isTrue);
      expect(painter(tester).mirrored, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'actual pixels mark both logical endpoints in four directions with distinct destination styles',
    () async {
      final move = Move.parse('h2e2');
      for (final flipped in [false, true]) {
        for (final mirrored in [false, true]) {
          final samples = <LastMoveMarkerStyle, int>{};
          for (final style in LastMoveMarkerStyle.values) {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            LastMoveMarkersPainter(
              move: move,
              style: style,
              flipped: flipped,
              mirrored: mirrored,
            ).paint(canvas, const Size(450, 500));
            final picture = recorder.endRecording();
            final image = await picture.toImage(450, 500);
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            int alphaAt(Offset point) => data.getUint8(
              (point.dy.round() * 450 + point.dx.round()) * 4 + 3,
            );
            final from = boardSquarePoint(
              move.from,
              const Size(450, 500),
              flipped: flipped,
              mirrored: mirrored,
            );
            final to = boardSquarePoint(
              move.to,
              const Size(450, 500),
              flipped: flipped,
              mirrored: mirrored,
            );
            expect(alphaAt(from + const Offset(7, 0)), greaterThan(0));
            expect(alphaAt(to), 0);
            var count = 0;
            for (var y = to.dy.toInt() - 25; y < to.dy.toInt() + 25; y++) {
              for (var x = to.dx.toInt() - 25; x < to.dx.toInt() + 25; x++) {
                if (data.getUint8((y * 450 + x) * 4 + 3) > 0) count++;
              }
            }
            expect(count, greaterThan(150));
            samples[style] = count;
            image.dispose();
            picture.dispose();
          }
          expect(
            samples[LastMoveMarkerStyle.halo],
            isNot(samples[LastMoveMarkerStyle.box]),
          );
        }
      }
    },
  );
}
