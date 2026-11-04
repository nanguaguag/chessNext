import 'package:chess_next/app.dart';
import 'package:chess_next/application/board_skin_library_controller.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create, rename, select, and delete a local board skin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = MemoryPreferencesRepository();
    final skins = MemoryBoardSkinLibraryRepository();
    await tester.pumpWidget(
      ChessNextApp(
        preferencesRepository: preferences,
        boardSkinLibraryRepository: skins,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('棋盘显示'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('管理棋盘皮肤库'));
    await tester.tap(find.text('管理棋盘皮肤库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建并使用'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '我的棋盘');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();

    var profile = (await skins.load()).single;
    expect(preferences.value!.selectedBoardSkinId, profile.id);
    expect(find.text('我的棋盘'), findsWidgets);
    expect(
      tester
          .widget<BoardDisplayScope>(find.byType(BoardDisplayScope))
          .boardSkin,
      profile.baseSkin,
    );

    await tester.tap(find.text('关闭').last);
    await tester.pumpAndSettle();
    final leftMargin = tester.widget<Slider>(
      find.byKey(ValueKey('board-geometry-${profile.id}-左边距')),
    );
    leftMargin.onChanged!(12);
    await tester.pumpAndSettle();
    profile = (await skins.load()).single;
    expect(profile.geometry.leftPercent, 12);
    expect(
      tester
          .widget<BoardDisplayScope>(find.byType(BoardDisplayScope))
          .geometry
          .leftPercent,
      12,
    );
    await tester.ensureVisible(find.text('管理棋盘皮肤库'));
    await tester.tap(find.text('管理棋盘皮肤库'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('重命名我的棋盘'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '夜间木色');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    profile = (await skins.load()).single;
    expect(profile.name, '夜间木色');

    await tester.tap(find.byTooltip('删除夜间木色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(await skins.load(), isEmpty);
    expect(preferences.value!.selectedBoardSkinId, 'parchment');
    expect(
      tester
          .widget<BoardDisplayScope>(find.byType(BoardDisplayScope))
          .boardSkin,
      BoardSkin.parchment,
    );
  });
}
