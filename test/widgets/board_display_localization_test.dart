import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/features/settings/board_display_dialog.dart';
import 'package:chess_next/l10n/app_localizations.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'board appearance basics resolve labels from the selected locale',
    (tester) async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      await preferences.initialize();
      addTearDown(preferences.dispose);
      addTearDown(engine.dispose);
      addTearDown(session.dispose);

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
                  builder: (_) => BoardDisplayDialog(preferences: preferences),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Board display'), findsOneWidget);
      expect(find.text('Board skin'), findsOneWidget);
      expect(find.text('Piece skin'), findsOneWidget);
      expect(find.text('Show coordinates'), findsOneWidget);
      expect(find.text('Rotate the opponent\'s pieces'), findsOneWidget);
      expect(find.text('Reset size'), findsOneWidget);
      expect(find.textContaining('Piece size: 100%'), findsOneWidget);
      expect(
        find.textContaining('Size only affects appearance'),
        findsOneWidget,
      );
      expect(find.text('Grid and margins'), findsOneWidget);
      expect(find.text('Left margin'), findsNWidgets(2));
      expect(find.text('Rotate the landing marker image'), findsOneWidget);
      expect(find.text('Piece shadow'), findsOneWidget);
      expect(find.text('Edit piece images'), findsOneWidget);
      expect(find.text('Last-move marker'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Slow'), findsOneWidget);
      expect(find.text('Move sound'), findsOneWidget);
      expect(find.text('Capture sound'), findsOneWidget);
      expect(find.text('Check sound'), findsOneWidget);
      expect(find.text('Checkmate sound'), findsOneWidget);
      expect(find.text('Selection sound'), findsOneWidget);
      expect(find.text('Piece selection style'), findsOneWidget);
      expect(find.text('Read moves aloud'), findsOneWidget);
      expect(
        find.textContaining('Current piece style size: 100%'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Current piece style position: horizontal 0%'),
        findsOneWidget,
      );
      expect(find.byTooltip('Align pieces automatically'), findsOneWidget);
      final shadowStyle = find.byType(
        DropdownButtonFormField<PieceShadowStyle>,
      );
      await tester.ensureVisible(shadowStyle);
      await tester.tap(shadowStyle);
      await tester.pumpAndSettle();
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Soft'), findsNWidgets(2));
      expect(find.text('Strong'), findsOneWidget);
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();
      final calibrateButton = find.byKey(
        ValueKey(
          'board-grid-editor-open-${preferences.value.selectedBoardSkinId}',
        ),
      );
      await tester.ensureVisible(calibrateButton);
      await tester.tap(calibrateButton);
      await tester.pumpAndSettle();
      expect(find.text('Calibrate by dragging grid points'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.bySemanticsLabel('Top-left grid point'), findsOneWidget);
      expect(find.bySemanticsLabel('Bottom-right grid point'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
