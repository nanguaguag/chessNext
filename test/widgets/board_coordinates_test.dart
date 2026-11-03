import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/board_file_coordinates.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/editor/editor_page.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class BoardPreferenceStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences next) async {
    if (fail) throw StateError('disk full');
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

  String rail(WidgetTester tester, String edge) => [
    for (var i = 0; i < 9; i++)
      tester.widget<Text>(find.byKey(ValueKey('coordinate-$edge-$i'))).data!,
  ].join();

  testWidgets(
    'local board skin applies immediately and survives a new app instance',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      await open(tester);
      final dropdown = find.byType(DropdownButtonFormField<BoardSkin>);
      await tap(tester, dropdown);
      await tap(tester, find.text('松石青').last);
      expect(store.value!.boardSkin, BoardSkin.jade);
      final background = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('board-skin-background')),
      );
      expect(
        (background.decoration as BoxDecoration).color,
        Color(BoardSkin.jade.boardColor),
      );
      final pieceDropdown = find.byType(DropdownButtonFormField<PieceSkin>);
      await tap(tester, pieceDropdown);
      await tap(tester, find.text('方章墨韵').last);
      expect(store.value!.pieceSkin, PieceSkin.squareInk);
      final inkFace = find.descendant(
        of: find.byKey(const ValueKey('square-a9')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).borderRadius != null,
        ),
      );
      expect(inkFace, findsOneWidget);
      expect(
        (tester.widget<Container>(inkFace).decoration as BoxDecoration).shape,
        BoxShape.rectangle,
      );
      await tap(tester, find.text('关闭'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      final restored = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('board-skin-background')),
      );
      expect(
        (restored.decoration as BoxDecoration).color,
        Color(BoardSkin.jade.boardColor),
      );
      expect(store.value!.pieceSkin, PieceSkin.squareInk);
    },
  );
  testWidgets(
    'all four orientations label logical files and align with grid columns',
    (tester) async {
      final position = Position.initial();
      final taps = <Square>[];
      for (final (flipped, mirrored, top, bottom) in [
        (false, false, '123456789', '九八七六五四三二一'),
        (true, false, '一二三四五六七八九', '987654321'),
        (false, true, '987654321', '一二三四五六七八九'),
        (true, true, '九八七六五四三二一', '123456789'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Center(
                child: SizedBox(
                  width: 450,
                  child: BoardSurface(
                    at: position.at,
                    onTap: taps.add,
                    showCoordinates: true,
                    flipped: flipped,
                    mirrored: mirrored,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(rail(tester, 'top'), top);
        expect(rail(tester, 'bottom'), bottom);
        final file = flipped != mirrored ? 8 : 0;
        final square = Square(file, flipped ? 0 : 9);
        final label = find.byKey(const ValueKey('coordinate-top-0'));
        expect(
          tester.getCenter(label).dx,
          closeTo(
            tester.getCenter(find.byKey(ValueKey('square-$square'))).dx,
            .01,
          ),
        );
        final before = taps.length;
        await tester.tap(label);
        expect(
          taps.length,
          before,
          reason: 'labels are outside grid hit areas',
        );
        await tap(tester, find.byKey(const ValueKey('square-h2')));
        expect(taps.last, Square.parse('h2'));
      }
    },
  );
  testWidgets(
    'global toggle preserves game, old form apply, editor state and new App preference',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(
          textSize: TextSizePreference.large,
          guideVersion: 99,
        );
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      await tap(tester, find.byKey(const ValueKey('square-h2')));
      await tap(tester, find.byKey(const ValueKey('square-e2')));
      final tree = session.tree;
      final revision = session.revision;
      await open(tester);
      await tap(tester, find.text('显示坐标'));
      expect(find.byType(BoardFileCoordinates), findsNothing);
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      await tap(tester, find.text('关闭'));
      await tap(tester, find.widgetWithText(FilledButton, '应用设置'));
      expect(store.value!.showCoordinates, isFalse);
      expect(store.value!.textSize, TextSizePreference.large);
      expect(store.value!.guideVersion, 99);
      await tap(tester, find.text('编辑局面'));
      await tap(tester, find.text('继续编辑'));
      expect(find.byType(BoardFileCoordinates), findsNothing);
      await tap(tester, find.byTooltip('取消编辑'));
      expect(session.tree, same(tree));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ChessNextApp(key: UniqueKey(), preferencesRepository: store),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BoardFileCoordinates), findsNothing);
      await open(tester);
      await tap(tester, find.text('显示坐标'));
      expect(find.byType(BoardFileCoordinates), findsOneWidget);
    },
  );
  testWidgets(
    'editor rotates and mirrors coordinate rails while drag targets keep logical squares',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      await tap(tester, find.text('编辑局面'));
      expect(find.byType(EditorPage), findsOneWidget);
      expect(rail(tester, 'top'), '123456789');
      await tap(tester, find.text('旋转棋盘'));
      expect(rail(tester, 'top'), '一二三四五六七八九');
      await tap(tester, find.text('左右翻转'));
      expect(rail(tester, 'top'), '九八七六五四三二一');
      await tap(tester, find.text('清空'));
      final from = tester.getCenter(
        find.byKey(const ValueKey('palette-red-pawn')),
      );
      final to = tester.getCenter(find.byKey(const ValueKey('square-a3')));
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BoardSurface>(find.byType(BoardSurface))
            .at(Square.parse('a3'))
            ?.type,
        PieceType.pawn,
      );
    },
  );
  testWidgets(
    'standalone board defaults hidden and explicit override wins over scope',
    (tester) async {
      for (final (scope, override, shown) in [
        (false, null, false),
        (true, false, false),
        (false, true, true),
        (true, null, true),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: BoardDisplayScope(
                showCoordinates: scope,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    child: BoardSurface(
                      at: Position.initial().at,
                      onTap: (_) {},
                      showCoordinates: override,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          find.byType(BoardFileCoordinates),
          shown ? findsOneWidget : findsNothing,
        );
      }
    },
  );
  testWidgets(
    'coordinate save failure keeps current display and retry preserves exact choice',
    (tester) async {
      desktop(tester);
      final store = BoardPreferenceStore();
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();
      await open(tester);
      store.fail = true;
      await tap(tester, find.text('显示坐标'));
      expect(find.byType(BoardFileCoordinates), findsNothing);
      expect(find.text('设置保存失败，当前设置仍生效，请重试').last, findsOneWidget);
      store.fail = false;
      await tap(tester, find.text('重试'));
      expect(store.value!.showCoordinates, isFalse);
      expect(find.text('设置保存失败，当前设置仍生效，请重试'), findsNothing);
    },
  );
  testWidgets(
    'small board at 200 percent keeps geometry and exposes readable coordinate semantics',
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
        expect(find.bySemanticsLabel(RegExp('顶部黑方路数')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('底部红方路数')), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('square-h2')));
        await tap(tester, find.byKey(const ValueKey('square-e2')));
        expect(find.text('黑方行棋'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
