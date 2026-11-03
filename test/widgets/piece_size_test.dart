import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/editor/editor_page.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class FailingPieceStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences next) async {
    if (fail) throw StateError('full');
    await super.save(next);
  }
}

void main() {
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

  Future<void> open(WidgetTester tester) async {
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('棋盘显示'));
  }

  Transform face(WidgetTester tester, String square) =>
      tester.widget<Transform>(
        find.descendant(
          of: find.byKey(ValueKey('square-$square')),
          matching: find.byKey(const ValueKey('piece-size')),
        ),
      );

  testWidgets(
    'size endpoints only scale occupied faces while hit cells and logical moves stay fixed',
    (tester) async {
      final position = Position.initial();
      final taps = <Square>[];
      Rect? initial;
      for (final size in [10, 100, 200]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Center(
                child: SizedBox(
                  width: 450,
                  child: BoardDisplayScope(
                    showCoordinates: true,
                    pieceSizePercent: size,
                    child: BoardSurface(at: position.at, onTap: taps.add),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byKey(const ValueKey('square-h2')));
        initial ??= rect;
        expect(rect, initial);
        expect(face(tester, 'h2').transform.storage[0], size / 100);
        expect(face(tester, 'h2').transformHitTests, isFalse);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('square-e2')),
            matching: find.byKey(const ValueKey('piece-size')),
          ),
          findsNothing,
        );
        await tap(tester, find.byKey(const ValueKey('square-h2')));
        expect(taps.last, Square.parse('h2'));
        await tap(tester, find.byKey(const ValueKey('square-g2')));
        expect(
          taps.last,
          Square.parse('g2'),
          reason:
              'a painted overlapping cannon must not capture the neighboring cell',
        );
      }
    },
  );
  testWidgets(
    'live slider, keyboard and reset preserve coordinate/text options and reopen',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(
          showCoordinates: false,
          textSize: TextSizePreference.large,
          guideVersion: 88,
        );
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final tree = session.tree;
      await open(tester);
      final slider = find.byKey(const ValueKey('piece-size-slider'));
      await tap(tester, slider);
      expect(store.value!.pieceSizePercent, 105);
      bool focused() =>
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<Slider>()
              ?.key ==
          const ValueKey('piece-size-slider');
      // The board display dialog now has three additional event sound switches.
      for (var i = 0; i < 16 && !focused(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(focused(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(store.value!.pieceSizePercent, 110);
      expect(face(tester, 'h2').transform.storage[0], 1.1);
      await tap(tester, find.text('恢复默认大小'));
      expect(store.value!.pieceSizePercent, 100);
      expect(store.value!.showCoordinates, isFalse);
      expect(store.value!.textSize, TextSizePreference.large);
      expect(store.value!.guideVersion, 88);
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      await tap(tester, slider);
      await tap(tester, find.text('关闭'));
      await tap(tester, find.widgetWithText(FilledButton, '应用设置'));
      expect(store.value!.pieceSizePercent, 105);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      expect(face(tester, 'h2').transform.storage[0], 1.05);
    },
  );
  testWidgets(
    'large mirrored editor uses the same size for pieces and drag feedback',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(pieceSizePercent: 200);
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await tap(tester, find.text('编辑局面'));
      await tap(tester, find.text('旋转棋盘'));
      await tap(tester, find.text('左右翻转'));
      expect(find.byType(EditorPage), findsOneWidget);
      expect(face(tester, 'h2').transform.storage[0], 2);
      final from = tester.getCenter(find.byKey(const ValueKey('square-h2')));
      final to = tester.getCenter(find.byKey(const ValueKey('square-h3')));
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
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BoardSurface>(find.byType(BoardSurface))
            .at(Square.parse('h3'))
            ?.type,
        PieceType.cannon,
      );
      expect(face(tester, 'h3').transform.storage[0], 2);
    },
  );
  testWidgets('persistence failure leaves visible size active and can retry', (
    tester,
  ) async {
    desktop(tester);
    final store = FailingPieceStore();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    await open(tester);
    store.fail = true;
    await tap(tester, find.byKey(const ValueKey('piece-size-slider')));
    expect(face(tester, 'h2').transform.storage[0], 1.05);
    expect(find.text('设置保存失败，当前设置仍生效，请重试').last, findsOneWidget);
    store.fail = false;
    await tap(tester, find.text('重试'));
    expect(store.value!.pieceSizePercent, 105);
  });
  testWidgets(
    'narrow 200 percent text keeps discrete slider, reset and large-piece hit targets usable',
    (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(pieceSizePercent: 200);
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      await tap(tester, find.byKey(const ValueKey('square-e2')));
      expect(find.text('黑方行棋'), findsOneWidget);
      await open(tester);
      await tap(tester, find.text('恢复默认大小'));
      expect(store.value!.pieceSizePercent, 100);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
