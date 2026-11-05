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
}
