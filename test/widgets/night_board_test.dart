import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_gif_snapshot.dart';
import 'package:chess_next/application/board_image_snapshot.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  testWidgets('night board only darkens the default parchment in dark mode', (
    tester,
  ) async {
    Widget app({
      required Brightness brightness,
      required bool enabled,
      String selectedId = 'parchment',
      BoardSkin skin = BoardSkin.parchment,
    }) => MaterialApp(
      key: ValueKey('$brightness-$enabled-$selectedId-$skin'),
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 450,
            child: BoardDisplayScope(
              showCoordinates: false,
              boardSkin: skin,
              selectedBoardSkinId: selectedId,
              nightBoardInDarkMode: enabled,
              child: BoardSurface(at: Position.initial().at, onTap: (_) {}),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(brightness: Brightness.dark, enabled: true));
    var board = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('board-skin-background')),
    );
    expect(
      (board.decoration as BoxDecoration).color,
      Color(BoardSkin.parchment.nightBoardColor),
    );

    await tester.pumpWidget(app(brightness: Brightness.dark, enabled: false));
    board = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('board-skin-background')),
    );
    expect(
      (board.decoration as BoxDecoration).color,
      Color(BoardSkin.parchment.boardColor),
    );

    await tester.pumpWidget(app(brightness: Brightness.light, enabled: true));
    board = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('board-skin-background')),
    );
    expect(
      (board.decoration as BoxDecoration).color,
      Color(BoardSkin.parchment.boardColor),
    );

    await tester.pumpWidget(
      app(
        brightness: Brightness.dark,
        enabled: true,
        selectedId: 'custom-abcdefgh',
      ),
    );
    board = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('board-skin-background')),
    );
    expect(
      (board.decoration as BoxDecoration).color,
      Color(BoardSkin.parchment.boardColor),
    );
  });

  test('image and GIF captures retain the night-board preference', () {
    final session = BoardSession();
    addTearDown(session.dispose);
    final prefs = AppPreferences(nightBoardInDarkMode: false);
    final png = BoardImageSnapshot.capture(session, prefs);
    final gif = BoardGifSnapshot.capture(session, prefs);
    expect(
      BoardSkin.parchment.nightBoardColor,
      isNot(BoardSkin.parchment.boardColor),
    );
    expect(png.nightBoardInDarkMode, isFalse);
    expect(gif.nightBoardInDarkMode, isFalse);
  });
}
