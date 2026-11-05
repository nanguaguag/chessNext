import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/board_skin_image_library_controller.dart';
import 'package:chess_next/application/board_skin_library_controller.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/features/settings/board_skin_library_dialog.dart';
import 'package:chess_next/l10n/app_localizations.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Picker implements PieceImagePicker {
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
}

void main() {
  testWidgets('board skin library labels use the selected locale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final engine = EngineSessionController(BoardSession(), null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    await preferences.initialize();
    final images = BoardSkinImageLibraryController(
      _Picker(),
      MemoryBoardSkinImageRepository(),
    );
    await images.initialize();
    final library = BoardSkinLibraryController(
      MemoryBoardSkinLibraryRepository(),
      images,
      preferences,
    );
    await library.initialize();
    addTearDown(library.dispose);
    addTearDown(images.dispose);
    addTearDown(preferences.dispose);
    addTearDown(engine.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BoardSkinLibraryDialog(library: library)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Built-in skins'), findsOneWidget);
    expect(find.text('My boards'), findsOneWidget);
    expect(find.text('Save only'), findsOneWidget);
    expect(find.text('Create and use'), findsOneWidget);
    expect(find.text('Parchment wood'), findsOneWidget);
    expect(find.text('Jade green'), findsOneWidget);
    expect(find.textContaining('还没有本机棋盘皮肤'), findsNothing);
  });
}
