import 'dart:typed_data';

import 'package:chess_next/application/board_skin_package_codec.dart';
import 'package:chess_next/ports/board_skin_library.dart';
import 'package:chess_next/ports/piece_skin_catalog.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/board_skin_library_controller.dart';
import 'package:chess_next/application/board_skin_geometry.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';

final class _BoardCatalog implements BoardSkinCatalog {
  _BoardCatalog(this.bytes)
    : item = PublicBoardSkin(
        id: 'authorized-board',
        name: '有许可棋盘',
        author: '棋手甲',
        description: '自制测试外观',
        likes: 2,
        publishedAt: DateTime.utc(2026, 11, 5),
        license: 'CC-BY-4.0',
        attribution: '棋手甲',
        packageSha256: sha256.convert(bytes).toString(),
      );
  final Uint8List bytes;
  final PublicBoardSkin item;
  int searches = 0;

  @override
  Future<BoardSkinCatalogPage> search({
    required Uri endpoint,
    required String query,
    required PublicBoardSkinSort sort,
    int page = 1,
    int pageSize = 24,
  }) async {
    searches++;
    return BoardSkinCatalogPage(items: [item], page: 1, pageSize: 24, total: 1);
  }

  @override
  Future<Uint8List> downloadPackage({
    required Uri endpoint,
    required String id,
    required String expectedSha256,
  }) async => bytes;
}

void main() {
  testWidgets(
    'board catalog verifies package and stores accepted attribution',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = MemoryPreferencesRepository();
      final skins = MemoryBoardSkinLibraryRepository();
      final archive = BoardSkinPackageCodec.encode(
        BoardSkinDefinition(
          id: 'custom-12345678-abcd',
          name: '有许可棋盘',
          baseSkin: BoardSkin.jade,
          geometry: const BoardSkinGeometry.standard(),
        ),
        const {},
      );
      final catalog = _BoardCatalog(archive);
      await tester.pumpWidget(
        ChessNextApp(
          preferencesRepository: preferences,
          boardSkinLibraryRepository: skins,
          boardSkinCatalog: catalog,
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
      await tester.enterText(
        find.widgetWithText(TextField, '自建目录服务地址'),
        'https://skins.example.com',
      );
      await tester.tap(find.byTooltip('保存服务地址并连接'));
      await tester.pumpAndSettle();
      expect(catalog.searches, 1);
      expect(find.text('有许可棋盘'), findsWidgets);
      await tester.tap(find.text('有许可棋盘').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('CC-BY-4.0'), findsWidgets);
      await tester.tap(find.text('下载并确认导入'));
      await tester.pumpAndSettle();
      expect(find.textContaining('本机棋盘皮肤ZIP格式校验'), findsOneWidget);
      await tester.tap(find.text('接受许可并导入'));
      await tester.pumpAndSettle();
      final profile = (await skins.load()).single;
      expect(profile.name, '有许可棋盘');
      expect(profile.license, 'CC-BY-4.0');
      expect(profile.attribution, '棋手甲');
      expect(preferences.value!.selectedBoardSkinId, profile.id);
    },
  );

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
    final leftInput = find.byKey(ValueKey('geometry-value-左边距'));
    await tester.ensureVisible(leftInput);
    await tester.enterText(leftInput, '999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    profile = (await skins.load()).single;
    expect(
      profile.geometry.leftPercent,
      closeTo(
        profile.geometry.rightPercent - BoardSkinGeometry.minSpanPercent,
        .1,
      ),
    );

    await tester.enterText(leftInput, '20.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    profile = (await skins.load()).single;
    expect(profile.geometry.leftPercent, 20.5);
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
