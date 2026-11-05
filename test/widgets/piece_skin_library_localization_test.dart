import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/application/piece_skin_library_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/features/settings/piece_skin_library_dialog.dart';
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
  testWidgets('local piece skin management labels use the selected locale', (
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
    final images = PieceImageLibraryController(
      _Picker(),
      MemoryPieceImageRepository(),
    );
    await images.initialize();
    final library = PieceSkinLibraryController(
      MemoryPieceSkinLibraryRepository(),
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
        home: Scaffold(body: PieceSkinLibraryDialog(library: library)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Piece skin library'), findsOneWidget);
    expect(find.text('Search local skins'), findsOneWidget);
    expect(find.text('Built-in style'), findsNWidgets(2));
    expect(find.text('Traditional round seal'), findsOneWidget);
    expect(find.text('Square ink'), findsOneWidget);
    expect(find.text('Copy current style'), findsOneWidget);
    expect(find.textContaining('搜索本机皮肤'), findsNothing);
    expect(find.textContaining('从当前样式复制'), findsNothing);
  });
}
