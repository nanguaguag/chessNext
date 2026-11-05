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

  @override
  String get boardGeometryHeading => 'Grid and margins';

  @override
  String get boardGeometryHelp =>
      'Adjust the four grid edges as a percentage of the canvas. Pieces, markers and intersection taps share this geometry.';

  @override
  String get boardGeometryCalibrate => 'Drag grid points to calibrate';

  @override
  String get boardGeometryCalibrateTitle => 'Calibrate by dragging grid points';

  @override
  String get done => 'Done';

  @override
  String get leftMargin => 'Left margin';

  @override
  String get rightMargin => 'Right margin';

  @override
  String get topMargin => 'Top margin';

  @override
  String get bottomMargin => 'Bottom margin';

  @override
  String boardSkinPieceScale(int percent) {
    return 'Piece scale $percent%';
  }

  @override
  String get boardSkinPieceScaleHelp =>
      'Piece size changes appearance only, not grid spacing or intersection targets. It multiplies with global piece size and the piece style scale.';

  @override
  String get landingMarkerRotation => 'Rotate the landing marker image';

  @override
  String get landingMarkerRotationHelp =>
      'On each move, rotate it once and stop. It stays still when reduced motion is enabled or animation speed is off.';

  @override
  String get resetBoardGrid => 'Reset grid';

  @override
  String get boardGridPreview =>
      'Board grid preview, nine columns and ten rows';

  @override
  String get topLeftGridPoint => 'Top-left grid point';

  @override
  String get bottomRightGridPoint => 'Bottom-right grid point';

  @override
  String topLeftGridPointValue(String left, String top) {
    return 'Left $left%, top $top%';
  }

  @override
  String bottomRightGridPointValue(String right, String bottom) {
    return 'Right $right%, bottom $bottom%';
  }

  @override
  String get gridPointMoveHint =>
      'Drag or focus the point and use the arrow keys to move by 1%. Screen reader users can use directional actions.';

  @override
  String get gridPointMoveLeft => 'Move grid point left by 1%';

  @override
  String get gridPointMoveRight => 'Move grid point right by 1%';

  @override
  String get gridPointMoveUp => 'Move grid point up by 1%';

  @override
  String get gridPointMoveDown => 'Move grid point down by 1%';

  @override
  String pieceSkinScaleCurrent(int percent) {
    return 'Current piece style size: $percent%';
  }

  @override
  String get pieceSkinScaleHelp =>
      'Applies to this piece style and multiplies with the global piece size. Default is 100%; range 80–120%.';

  @override
  String pieceSkinPositionCurrent(int x, int y) {
    return 'Current piece style position: horizontal $x%, vertical $y%';
  }

  @override
  String get skinPieceMoveUp => 'Move pieces up by 1%';

  @override
  String get skinPieceMoveDown => 'Move pieces down by 1%';

  @override
  String get skinPieceMoveLeft => 'Move pieces left by 1%';

  @override
  String get skinPieceMoveRight => 'Move pieces right by 1%';

  @override
  String get skinPieceAutoAlign => 'Align pieces automatically';

  @override
  String get pieceSkinPositionHelp =>
      'Each step moves this piece style by 1% of the grid width, up to ±8%. Position affects drawing only.';

  @override
  String get pieceShadowLabel => 'Piece shadow';

  @override
  String get pieceShadowNone => 'None';

  @override
  String get pieceShadowSoft => 'Soft';

  @override
  String get pieceShadowProminent => 'Strong';

  @override
  String get pieceShadowDirection => 'Direction';

  @override
  String get pieceShadowDistance => 'Distance';

  @override
  String get pieceShadowBlur => 'Blur';

  @override
  String get pieceShadowOpacity => 'Opacity';

  @override
  String get pieceShadowHelp =>
      '0° points right and 90° down. Distance and blur use grid width; range is defined by this app.';

  @override
  String get roundSealPieceSkin => 'Traditional round seal';

  @override
  String get squareInkPieceSkin => 'Square ink';

  @override
  String get pieceStyleMoveSoundHelp =>
      'The piece style also determines the sound used when following the piece skin.';

  @override
  String get editPieceImages => 'Edit piece images';

  @override
  String get lastMoveMarker => 'Last-move marker';

  @override
  String get lastMoveHalo => 'Rotating halo';

  @override
  String get lastMoveBox => 'Box';

  @override
  String get lastMoveAnimationHelp =>
      'Animation speed controls piece movement and custom markers. They stay still when reduced motion is enabled.';

  @override
  String get animationOff => 'Off';

  @override
  String get animationFast => 'Fast';

  @override
  String get animationStandard => 'Standard';

  @override
  String get animationSlow => 'Slow';

  @override
  String get animationDurationHelp =>
      'Controls one rotation of the landing halo: off, 300, 600 or 1200 ms. Reduced motion always stops it.';

  @override
  String get moveSound => 'Move sound';

  @override
  String get moveSoundHelp =>
      'Play an offline sound on this device after a move.';

  @override
  String get captureSound => 'Capture sound';

  @override
  String get captureSoundHelp =>
      'Play an offline sound on this device when a piece is captured.';

  @override
  String get checkSound => 'Check sound';

  @override
  String get checkSoundHelp => 'Play on check; checkmate sound takes priority.';

  @override
  String get mateSound => 'Checkmate sound';

  @override
  String get mateSoundHelp =>
      'Play on checkmate; mutually exclusive with the ordinary move sound.';

  @override
  String get selectionSound => 'Selection sound';

  @override
  String get selectionSoundHelp =>
      'Play an offline sound on this device when selecting one of your pieces.';

  @override
  String replaceSound(String kind) {
    return 'Change $kind sound';
  }

  @override
  String get selectionStyle => 'Piece selection style';

  @override
  String get selectionLift => 'Lift';

  @override
  String get selectionFrame => 'Selection frame';

  @override
  String get selectionStyleHelp =>
      'Changes only how the selected piece looks. Click targets remain at intersections.';

  @override
  String get speakMoves => 'Read moves aloud';

  @override
  String get speakMovesHelp =>
      'Uses an installed system voice in Chinese, independently of move sounds. Silent if no offline Chinese voice is installed.';

  @override
  String editPieceSkinImages(String skin) {
    return 'Edit $skin piece images';
  }

  @override
  String get pieceImagesHelp =>
      'Only the selected pieces are replaced. PNG/JPEG, up to 512 KiB and 1024 pixels on the longest side. Files stay on this device.';

  @override
  String get batchImportImages => 'Import images in batch';

  @override
  String importedPieceImages(int count) {
    return 'Imported $count piece images.';
  }

  @override
  String editBoardSkinImages(String skin) {
    return 'Edit $skin board images';
  }

  @override
  String get boardImagesHelp =>
      'Files stay on this device. PNG/JPEG, up to 512 KiB per image.';

  @override
  String get boardImageBackground => 'Board background';

  @override
  String get boardImageStartMarker => 'Starting-square marker';

  @override
  String get boardImageLandingMarker => 'Landing-square marker';

  @override
  String get boardImageSelectionFrame => 'Selection frame';

  @override
  String get defaultBoardBackground =>
      'Use the board color as the default background';

  @override
  String defaultBoardImageSlot(String slot) {
    return 'Use the default $slot';
  }

  @override
  String get selectImage => 'Choose image';

  @override
  String get replaceBoardImage => 'Replace image';

  @override
  String get replaceImage => 'Replace image';

  @override
  String get resetImage => 'Reset to default';

  @override
  String get pieceImageRedRook => 'Red rook';

  @override
  String get pieceImageRedHorse => 'Red horse';

  @override
  String get pieceImageRedElephant => 'Red elephant';

  @override
  String get pieceImageRedAdvisor => 'Red advisor';

  @override
  String get pieceImageRedGeneral => 'Red general';

  @override
  String get pieceImageRedCannon => 'Red cannon';

  @override
  String get pieceImageRedPawn => 'Red pawn';

  @override
  String get pieceImageBlackRook => 'Black rook';

  @override
  String get pieceImageBlackHorse => 'Black horse';

  @override
  String get pieceImageBlackElephant => 'Black elephant';

  @override
  String get pieceImageBlackAdvisor => 'Black advisor';

  @override
  String get pieceImageBlackGeneral => 'Black general';

  @override
  String get pieceImageBlackCannon => 'Black cannon';

  @override
  String get pieceImageBlackPawn => 'Black pawn';

  @override
  String get batchImportPieceImagesTitle => 'Batch import piece images';

  @override
  String batchImportPieceImagesHelp(int count) {
    return 'Selected $count images. Choose a target piece for each. Unmapped or duplicate slots cannot be imported.';
  }

  @override
  String get chooseTargetPiece => 'Choose a target piece';

  @override
  String get cancel => 'Cancel';

  @override
  String get importImages => 'Import images';

  @override
  String get boardSkinParchment => 'Parchment wood';

  @override
  String get boardSkinJade => 'Jade green';

  @override
  String get manageBoardSkins => 'Manage board skins';

  @override
  String get skinPackageHelp =>
      'Board and piece skins support this app\'s ZIP format for import and export. Site ZIP and folder formats are unverified.';

  @override
  String get editBoardImages => 'Edit board images';

  @override
  String get managePieceSkins => 'Manage piece skins';

  @override
  String editBoardSkinGeometry(String name) {
    return 'Edit $name';
  }

  @override
  String get resetBoardGeometry => 'Reset geometry';

  @override
  String get save => 'Save';

  @override
  String get boardSkinGeometrySaveError =>
      'This board skin could not be saved on this device. Try again.';

  @override
  String get onlineBoardCatalog => 'Self-hosted board catalog';

  @override
  String get catalogServiceAddress => 'Catalog service address';

  @override
  String get catalogEndpointHelp =>
      'Remote services require HTTPS; localhost is allowed for local deployment.';

  @override
  String get saveAddressConnect => 'Save address and connect';

  @override
  String get searchBoardSkins => 'Search board skins';

  @override
  String get onlineSort => 'Online sort';

  @override
  String get sortDefault => 'Default order';

  @override
  String get sortLikes => 'Likes';

  @override
  String get sortName => 'Name';

  @override
  String get sortAuthor => 'Author';

  @override
  String get sortRecent => 'Recently created';

  @override
  String offlineCacheAt(String time) {
    return 'Offline cache · $time';
  }

  @override
  String get unknownTime => 'time unknown';

  @override
  String get catalogEmpty => 'The catalog has no board skins.';

  @override
  String get catalogUnavailable =>
      'Could not connect to the self-hosted board catalog. Check the network and service.';

  @override
  String catalogHttpRejected(int status) {
    return 'The catalog returned HTTP $status.';
  }

  @override
  String get catalogInvalidResponse =>
      'The catalog response is invalid. Remote board skins were not shown.';

  @override
  String get catalogRequestFailed =>
      'The catalog request failed. Check the service address.';

  @override
  String get catalogNotConfigured =>
      'Enter and connect to your self-hosted catalog first.';

  @override
  String skinDetailsAuthor(String value) {
    return 'Author: $value';
  }

  @override
  String skinDetailsLikes(int value) {
    return 'Likes: $value';
  }

  @override
  String skinDetailsCreated(String value) {
    return 'Created: $value';
  }

  @override
  String skinDetailsLicense(String value) {
    return 'License: $value';
  }

  @override
  String skinDetailsAttribution(String value) {
    return 'Attribution: $value';
  }

  @override
  String get noExtraAttribution => 'No additional attribution';

  @override
  String get downloadConfirmImport => 'Download and review import';

  @override
  String confirmBoardSkinImport(String name) {
    return 'Import $name?';
  }

  @override
  String boardSkinLicenseReview(String license, String attribution) {
    return 'The package passed SHA-256 and this app\'s board skin ZIP checks.\n\nLicense: $license\nAttribution: $attribution\n\nImport adds and selects a local board skin. You are responsible for following the license.';
  }

  @override
  String get acceptLicenseImport => 'Accept license and import';

  @override
  String boardSkinImported(String name) {
    return 'Validated and imported $name.';
  }

  @override
  String get boardSkinImportFailed => 'Import failed.';

  @override
  String get remoteDownloadFailed =>
      'Download failed. Check the network; local board skins were not changed.';

  @override
  String get remotePackageRejected =>
      'Package validation failed or the service rejected the request; local board skins were not changed.';

  @override
  String get invalidBoardSkinPackage =>
      'The board skin package is invalid; local data was not changed.';

  @override
  String get remoteBoardSkinImportFailed =>
      'Could not import this remote board skin; local data was not changed.';

  @override
  String get boardSkinExported => 'Board skin package exported.';

  @override
  String get boardSkinExportFailed =>
      'Could not export the board skin. Check local storage and try again.';

  @override
  String get importBoardSkinPackage => 'Import board skin package';

  @override
  String boardSkinPackageSummary(String name, int count) {
    return 'Project-format package: $name\nContains $count custom images and independent grid settings. Import adds and selects it without replacing existing skins.';
  }

  @override
  String get importAndUse => 'Import and use';

  @override
  String get invalidBoardSkinPackageSize =>
      'The board skin package is invalid or exceeds the size limit; local skins were not changed.';

  @override
  String get readBoardSkinPackageFailed =>
      'Could not read the board skin package; local skins were not changed.';

  @override
  String get newBoardSkin => 'New board skin';

  @override
  String get renameBoardSkin => 'Rename board skin';

  @override
  String get deleteBoardSkin => 'Delete board skin';

  @override
  String confirmDeleteBoardSkin(String name) {
    return 'Delete “$name”? This cannot be undone.';
  }

  @override
  String get builtInSkins => 'Built-in skins';

  @override
  String get builtInPalette => 'Built-in palette';

  @override
  String get use => 'Use';

  @override
  String get myBoards => 'My boards';

  @override
  String get saveOnly => 'Save only';

  @override
  String get createAndUse => 'Create and use';

  @override
  String get noLocalBoardSkins =>
      'No local board skins yet. Creating one copies the current board colors, grid, and images.';

  @override
  String basedOnSkin(String skin) {
    return 'Based on $skin';
  }

  @override
  String editNamedBoardSkin(String name) {
    return 'Edit $name';
  }

  @override
  String renameNamedBoardSkin(String name) {
    return 'Rename $name';
  }

  @override
  String deleteNamedBoardSkin(String name) {
    return 'Delete $name';
  }

  @override
  String exportNamedBoardSkin(String name) {
    return 'Export $name';
  }

  @override
  String get boardSkinName => 'Name';

  @override
  String get delete => 'Delete';

  @override
  String get loadMore => 'Load more board skins';

  @override
  String get invalidCatalogAddress =>
      'Invalid service address. Remote services must use HTTPS.';

  @override
  String get catalogAddressSaveFailed =>
      'Could not save the service address. Try again.';

  @override
  String audioSettingsTitle(String name) {
    return '$name sound';
  }

  @override
  String get audioCurrentCustom => 'Current: custom sound';

  @override
  String audioCurrentChoice(String choice, String skin) {
    return 'Current: $choice$skin';
  }

  @override
  String get audioCurrentDefault => 'Current: default sound';

  @override
  String audioReplaceHelp(String name) {
    return 'Only replaces the $name sound. Files stay on this device and are not uploaded.';
  }

  @override
  String get audioFileLimits => 'WAV or MP3, up to 512 KiB and 5 seconds.';

  @override
  String get audioPlan => 'Sound plan';

  @override
  String get audioResetToChoosePlan =>
      'Restore the default sound to choose a built-in plan.';

  @override
  String get audioSkinChoice => 'Follow piece skin';

  @override
  String get audioSoundChoice1 => 'Sound 1';

  @override
  String get audioSoundChoice2 => 'Sound 2';

  @override
  String get audioFollowSkin => 'Follow piece skin';

  @override
  String audioPreviewChoice(String choice) {
    return 'Preview $choice';
  }

  @override
  String get audioPreviewCurrent => 'Preview current sound';

  @override
  String get audioImportCustom => 'Import custom sound';

  @override
  String get audioRestoreDefault => 'Restore default sound';

  @override
  String get audioRoundSealSkin => 'Traditional seal';

  @override
  String get audioSquareInkSkin => 'Square ink style';
}
