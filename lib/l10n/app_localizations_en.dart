// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get textSizeDialogTitle => 'Interface text size';

  @override
  String get followSystemTextSize => 'Follow system text size';

  @override
  String systemTextSizePreview(int percent) {
    return 'System text size preview: $percent%';
  }

  @override
  String get currentTextSizeFollowing => 'Current size: Follow system';

  @override
  String currentTextSizeManual(String sizeLabel) {
    return 'Current size: $sizeLabel';
  }

  @override
  String get standardTextSize => 'Standard 100%';

  @override
  String get largeTextSize => 'Large 115%';

  @override
  String get extraLargeTextSize => 'Extra large 130%';

  @override
  String get textSizePreviewLine => 'Red to move · Local records and analysis';

  @override
  String get textSizePersistenceHelp =>
      'Changes apply immediately and are saved on this device. Manual adjustment turns off system following; turning it off again returns to standard size.';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get boardDisplayTitle => 'Board display';

  @override
  String get boardSkinLabel => 'Board skin';

  @override
  String get pieceSkinLabel => 'Piece skin';

  @override
  String pieceScalePercent(int percent) {
    return 'Piece size: $percent%';
  }

  @override
  String get resetPieceSize => 'Reset size';

  @override
  String get pieceSizeHelp =>
      'Size only affects appearance; clicks still target intersections. Larger values may overlap pieces.';

  @override
  String get showCoordinates => 'Show coordinates';

  @override
  String get showCoordinatesHelp =>
      'Red and black move numbers along the top and bottom edges of the board.';

  @override
  String get rotateOppositePieces => 'Rotate the opponent\'s pieces';

  @override
  String get rotateOppositePiecesHelp =>
      'Rotate the pieces on the far side by 180° for face-to-face play.';

  @override
  String get boardDisplayPersistenceHelp =>
      'Applies to the main board and position editor, and is saved on this device. Coordinates follow board rotation and mirroring.';
}
