import 'package:chess_next/application/board_skin_image_library_controller.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/features/settings/board_skin_images_dialog.dart';
import 'package:chess_next/features/settings/piece_skin_batch_import_dialog.dart';
import 'package:chess_next/features/settings/piece_skin_images_dialog.dart';
import 'package:chess_next/l10n/app_localizations.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ImagePicker implements PieceImagePicker {
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
}

void main() {
  testWidgets('piece and board image dialogs resolve labels in English', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pieceImages = PieceImageLibraryController(
      _ImagePicker(),
      MemoryPieceImageRepository(),
    );
    final boardImages = BoardSkinImageLibraryController(
      _ImagePicker(),
      MemoryBoardSkinImageRepository(),
    );
    await pieceImages.initialize();
    await boardImages.initialize();
    addTearDown(pieceImages.dispose);
    addTearDown(boardImages.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => PieceSkinImagesDialog(
                      skinId: 'roundSeal',
                      skinLabel: 'Traditional round seal',
                      library: pieceImages,
                    ),
                  ),
                  child: const Text('Open pieces'),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => BoardSkinImagesDialog(
                      skinId: BoardSkin.parchment.name,
                      skinLabel: 'Parchment wood',
                      library: boardImages,
                    ),
                  ),
                  child: const Text('Open board images'),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => PieceSkinBatchImportDialog(
                      skin: 'roundSeal',
                      images: const <NamedPieceImage>[],
                      library: pieceImages,
                    ),
                  ),
                  child: const Text('Open batch import'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open pieces'));
    await tester.pumpAndSettle();
    expect(
      find.text('Edit Traditional round seal piece images'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Only the selected pieces are replaced'),
      findsOneWidget,
    );
    expect(find.text('Red rook'), findsOneWidget);
    expect(find.text('Import images in batch'), findsOneWidget);
    expect(find.text('Replace image'), findsWidgets);
    expect(find.text('Reset to default'), findsWidgets);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open board images'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Parchment wood board images'), findsOneWidget);
    expect(find.text('Board background'), findsOneWidget);
    expect(find.text('Starting-square marker'), findsOneWidget);
    expect(find.text('Landing-square marker'), findsOneWidget);
    expect(
      find.text('Use the board color as the default background'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Selection frame'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Selection frame'), findsOneWidget);
    expect(find.text('Choose image'), findsWidgets);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open batch import'));
    await tester.pumpAndSettle();
    expect(find.text('Batch import piece images'), findsOneWidget);
    expect(
      find.textContaining('Selected 0 images. Choose a target piece for each.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Import images'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
