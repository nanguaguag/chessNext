import 'package:chess_next/features/settings/board_skin_geometry_draft_dialog.dart';
import 'package:chess_next/l10n/app_localizations.dart';
import 'package:chess_next/ports/board_skin_images.dart';
import 'package:chess_next/ports/board_skin_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved board geometry draft resolves labels and save errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = BoardSkinDefinition(
      id: 'custom-abcdefgh',
      name: 'Wood grain',
      baseSkin: BoardSkin.parchment,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BoardSkinGeometryDraftDialog(
                  profile: profile,
                  onSave: (_) async => false,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Wood grain'), findsOneWidget);
    expect(find.text('Grid and margins'), findsOneWidget);
    expect(find.textContaining('Left margin'), findsOneWidget);
    expect(find.text('Piece scale 100%'), findsOneWidget);
    expect(find.text('Rotate the landing marker image'), findsOneWidget);
    expect(find.text('Reset geometry'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This board skin could not be saved on this device. Try again.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
