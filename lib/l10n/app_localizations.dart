import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @textSizeDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'界面字号'**
  String get textSizeDialogTitle;

  /// No description provided for @followSystemTextSize.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统字号'**
  String get followSystemTextSize;

  /// No description provided for @systemTextSizePreview.
  ///
  /// In zh, this message translates to:
  /// **'系统字号预览：{percent}%'**
  String systemTextSizePreview(int percent);

  /// No description provided for @currentTextSizeFollowing.
  ///
  /// In zh, this message translates to:
  /// **'当前字号：跟随系统'**
  String get currentTextSizeFollowing;

  /// No description provided for @currentTextSizeManual.
  ///
  /// In zh, this message translates to:
  /// **'当前字号：{sizeLabel}'**
  String currentTextSizeManual(String sizeLabel);

  /// No description provided for @standardTextSize.
  ///
  /// In zh, this message translates to:
  /// **'标准100%'**
  String get standardTextSize;

  /// No description provided for @largeTextSize.
  ///
  /// In zh, this message translates to:
  /// **'大115%'**
  String get largeTextSize;

  /// No description provided for @extraLargeTextSize.
  ///
  /// In zh, this message translates to:
  /// **'特大130%'**
  String get extraLargeTextSize;

  /// No description provided for @textSizePreviewLine.
  ///
  /// In zh, this message translates to:
  /// **'红方行棋 · 本地棋谱与分析'**
  String get textSizePreviewLine;

  /// No description provided for @textSizePersistenceHelp.
  ///
  /// In zh, this message translates to:
  /// **'实时生效并保存在本机。手动调节会关闭跟随系统；重新关闭跟随时回到标准字号。'**
  String get textSizePersistenceHelp;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @boardDisplayTitle.
  ///
  /// In zh, this message translates to:
  /// **'棋盘显示'**
  String get boardDisplayTitle;

  /// No description provided for @boardSkinLabel.
  ///
  /// In zh, this message translates to:
  /// **'棋盘皮肤'**
  String get boardSkinLabel;

  /// No description provided for @pieceSkinLabel.
  ///
  /// In zh, this message translates to:
  /// **'棋子皮肤'**
  String get pieceSkinLabel;

  /// No description provided for @pieceScalePercent.
  ///
  /// In zh, this message translates to:
  /// **'棋子大小：{percent}%'**
  String pieceScalePercent(int percent);

  /// No description provided for @resetPieceSize.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认大小'**
  String get resetPieceSize;

  /// No description provided for @pieceSizeHelp.
  ///
  /// In zh, this message translates to:
  /// **'大小只影响显示，点击仍按交点。较大值可能使棋子重叠。'**
  String get pieceSizeHelp;

  /// No description provided for @showCoordinates.
  ///
  /// In zh, this message translates to:
  /// **'显示坐标'**
  String get showCoordinates;

  /// No description provided for @showCoordinatesHelp.
  ///
  /// In zh, this message translates to:
  /// **'棋盘上下边的红黑方路数'**
  String get showCoordinatesHelp;

  /// No description provided for @rotateOppositePieces.
  ///
  /// In zh, this message translates to:
  /// **'对面一方的棋子倒置'**
  String get rotateOppositePieces;

  /// No description provided for @rotateOppositePiecesHelp.
  ///
  /// In zh, this message translates to:
  /// **'上方那一方的棋子转180°，面对面摆棋时更顺眼。'**
  String get rotateOppositePiecesHelp;

  /// No description provided for @boardDisplayPersistenceHelp.
  ///
  /// In zh, this message translates to:
  /// **'实时应用到主棋盘与局面编辑器并保存在本机。翻转或镜像时，路数随棋盘方向变化。'**
  String get boardDisplayPersistenceHelp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
