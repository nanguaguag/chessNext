import 'dart:ui' as ui;
import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/selected_piece_frame.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/editor/editor_page.dart';
import 'package:chess_next/features/settings/board_display_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import '../support/pump_until.dart';

class SelectionStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences value) async {
    if (fail) throw StateError('disk');
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

  Future<void> settings(WidgetTester tester) async {
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('棋盘显示'));
  }

  Future<void> choose(WidgetTester tester, String text) async {
    await tap(tester, find.byType(DropdownButtonFormField<SelectionStyle>));
    await tap(tester, find.text(text).last);
  }

  final lifted = find.byKey(const ValueKey('selected-piece-lift'));
  final framed = find.byKey(const ValueKey('selected-piece-frame'));
  testWidgets(
    'both selection styles preserve 90 hit targets at size extremes in every orientation',
    (tester) async {
      final position = Position.initial(), taps = <Square>[];
      final semantics = tester.ensureSemantics();
      try {
        for (final flipped in [false, true]) {
          for (final mirrored in [false, true]) {
            Rect? cell;
            for (final size in [10, 100, 200]) {
              for (final style in SelectionStyle.values) {
                await tester.pumpWidget(
                  MaterialApp(
                    home: Material(
                      child: Center(
                        child: SizedBox(
                          width: 450,
                          child: BoardSurface(
                            at: position.at,
                            onTap: taps.add,
                            selected: Square.parse('h2'),
                            selectionStyle: style,
                            pieceSizePercent: size,
                            flipped: flipped,
                            mirrored: mirrored,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final selected = find.byKey(const ValueKey('square-h2'));
                cell ??= tester.getRect(selected);
                expect(tester.getRect(selected), cell);
                expect(
                  find.byWidgetPredicate(
                    (w) =>
                        w is InkWell &&
                        w.key is ValueKey<String> &&
                        (w.key! as ValueKey<String>).value.startsWith(
                          'square-',
                        ),
                  ),
                  findsNWidgets(90),
                );
                expect(
                  find.byWidgetPredicate(
                    (w) =>
                        w is Semantics &&
                        w.properties.label == '红方炮 h2' &&
                        w.properties.selected == true,
                  ),
                  findsOneWidget,
                );
                if (style == SelectionStyle.lift) {
                  final transform = tester.widget<Transform>(lifted);
                  expect(transform.transform.storage[13], -4);
                  expect(transform.transformHitTests, isFalse);
                  expect(framed, findsNothing);
                } else {
                  expect(lifted, findsNothing);
                  expect(tester.getSize(framed), const Size(50, 50));
                }
                await tester.tap(selected);
                await tester.pumpAndSettle();
                expect(taps.last, Square.parse('h2'));
              }
            }
          }
        }
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'live switching preserves selection and engine and retries the same preference',
    (tester) async {
      desktop(tester);
      final store = SelectionStore(), fake = FakeEngine();
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: store,
        engineFactory: () => Future.value(fake),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap(tester, find.text('开始分析'));
      await pumpUntil(tester, () => fake.requests.isNotEmpty);
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree,
          revision = session.revision,
          positionRevision = session.positionRevision;
      final requests = fake.requests.length, stops = fake.stops;
      expect(lifted, findsOneWidget);
      await settings(tester);
      store.fail = true;
      await choose(tester, '选择框');
      expect(framed, findsOneWidget);
      expect(lifted, findsNothing);
      expect(session.selected, Square.parse('h2'));
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.positionRevision, positionRevision);
      expect(session.dirty, isFalse);
      expect(fake.requests.length, requests);
      expect(fake.stops, stops);
      final dialog = find.byType(BoardDisplayDialog);
      expect(
        find.descendant(of: dialog, matching: find.textContaining('设置保存失败')),
        findsOneWidget,
      );
      store.fail = false;
      await tap(tester, find.descendant(of: dialog, matching: find.text('重试')));
      await pumpUntil(
        tester,
        () => store.value?.selectionStyle == SelectionStyle.frame,
      );
      await tap(tester, find.text('关闭'));
      await tap(tester, find.text('取消'));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(session.selected, isNull);
      expect(framed, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      expect(framed, findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('square-e2')));
      final restored = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      expect(restored.tree.current.move, Move.parse('h2e2'));
      expect(framed, findsNothing);
    },
  );
  testWidgets(
    'editor selection shares style, while drag feedback stays unselected and full size',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: BoardDisplayScope(
            showCoordinates: true,
            pieceSizePercent: 200,
            selectionStyle: SelectionStyle.frame,
            child: EditorPage(initial: Position.initial()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('旋转棋盘'));
      await tap(tester, find.text('左右翻转'));
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      expect(framed, findsOneWidget);
      final from = tester.getCenter(find.byKey(const ValueKey('square-h2'))),
          to = tester.getCenter(find.byKey(const ValueKey('square-h3')));
      final faces = find.byKey(const ValueKey('piece-size')).evaluate().length;
      final gesture = await tester.startGesture(from);
      await gesture.moveTo(to);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('piece-size')),
        findsNWidgets(faces + 1),
      );
      expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('piece-size')).last)
            .transform
            .storage[0],
        2,
      );
      expect(lifted, findsNothing);
      expect(framed, findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(framed, findsNothing);
      final board = tester.widget<BoardSurface>(find.byType(BoardSurface));
      expect(board.at(Square.parse('h3'))?.type, PieceType.cannon);
      expect(board.at(Square.parse('h2')), isNull);
    },
  );
  testWidgets(
    'narrow 200 percent settings remain usable with keyboard selection and escape',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = SelectionStore();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await settings(tester);
      await choose(tester, '选择框');
      expect(store.value!.selectionStyle, SelectionStyle.frame);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tap(tester, find.text('取消'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(framed, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(framed, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'actual frame pixels leave center clear and all four corners identifiable',
    () async {
      final recorder = ui.PictureRecorder();
      const SelectedPieceFramePainter().paint(
        Canvas(recorder),
        const Size(100, 100),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int alpha(int x, int y) => bytes.getUint8((y * 100 + x) * 4 + 3);
      for (final (x, y) in [(5, 5), (95, 5), (5, 95), (95, 95)]) {
        expect(alpha(x, y), greaterThan(0));
      }
      expect(alpha(50, 50), 0);
      expect(alpha(50, 5), 0);
      image.dispose();
      picture.dispose();
    },
  );
}
