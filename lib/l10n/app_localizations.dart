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

  /// No description provided for @boardGeometryHeading.
  ///
  /// In zh, this message translates to:
  /// **'格点与边距'**
  String get boardGeometryHeading;

  /// No description provided for @boardGeometryHelp.
  ///
  /// In zh, this message translates to:
  /// **'按画布百分比调整格网四边；所有棋子、标记和交点点击共用此几何。'**
  String get boardGeometryHelp;

  /// No description provided for @boardGeometryCalibrate.
  ///
  /// In zh, this message translates to:
  /// **'拖动格点校准'**
  String get boardGeometryCalibrate;

  /// No description provided for @boardGeometryCalibrateTitle.
  ///
  /// In zh, this message translates to:
  /// **'拖动格点校准'**
  String get boardGeometryCalibrateTitle;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @leftMargin.
  ///
  /// In zh, this message translates to:
  /// **'左边距'**
  String get leftMargin;

  /// No description provided for @rightMargin.
  ///
  /// In zh, this message translates to:
  /// **'右边距'**
  String get rightMargin;

  /// No description provided for @topMargin.
  ///
  /// In zh, this message translates to:
  /// **'上边距'**
  String get topMargin;

  /// No description provided for @bottomMargin.
  ///
  /// In zh, this message translates to:
  /// **'下边距'**
  String get bottomMargin;

  /// No description provided for @boardSkinPieceScale.
  ///
  /// In zh, this message translates to:
  /// **'棋子缩放 {percent}%'**
  String boardSkinPieceScale(int percent);

  /// No description provided for @boardSkinPieceScaleHelp.
  ///
  /// In zh, this message translates to:
  /// **'棋子只改变面容尺寸，不改变格线间距或交点命中；与全局棋子尺寸、棋子样式比例相乘。'**
  String get boardSkinPieceScaleHelp;

  /// No description provided for @landingMarkerRotation.
  ///
  /// In zh, this message translates to:
  /// **'落点标记图片旋转'**
  String get landingMarkerRotation;

  /// No description provided for @landingMarkerRotationHelp.
  ///
  /// In zh, this message translates to:
  /// **'每次换步时转一周后静止；系统减少动画或关闭动画速度时静止。'**
  String get landingMarkerRotationHelp;

  /// No description provided for @resetBoardGrid.
  ///
  /// In zh, this message translates to:
  /// **'格网恢复默认'**
  String get resetBoardGrid;

  /// No description provided for @boardGridPreview.
  ///
  /// In zh, this message translates to:
  /// **'棋盘格点预览，九列十行'**
  String get boardGridPreview;

  /// No description provided for @topLeftGridPoint.
  ///
  /// In zh, this message translates to:
  /// **'左上格点'**
  String get topLeftGridPoint;

  /// No description provided for @bottomRightGridPoint.
  ///
  /// In zh, this message translates to:
  /// **'右下格点'**
  String get bottomRightGridPoint;

  /// No description provided for @topLeftGridPointValue.
  ///
  /// In zh, this message translates to:
  /// **'左 {left}%，上 {top}%'**
  String topLeftGridPointValue(String left, String top);

  /// No description provided for @bottomRightGridPointValue.
  ///
  /// In zh, this message translates to:
  /// **'右 {right}%，下 {bottom}%'**
  String bottomRightGridPointValue(String right, String bottom);

  /// No description provided for @gridPointMoveHint.
  ///
  /// In zh, this message translates to:
  /// **'拖动或聚焦后使用方向键，每次移动1%；读屏可用方向操作调整'**
  String get gridPointMoveHint;

  /// No description provided for @gridPointMoveLeft.
  ///
  /// In zh, this message translates to:
  /// **'格点左移1%'**
  String get gridPointMoveLeft;

  /// No description provided for @gridPointMoveRight.
  ///
  /// In zh, this message translates to:
  /// **'格点右移1%'**
  String get gridPointMoveRight;

  /// No description provided for @gridPointMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'格点上移1%'**
  String get gridPointMoveUp;

  /// No description provided for @gridPointMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'格点下移1%'**
  String get gridPointMoveDown;

  /// No description provided for @pieceSkinScaleCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前棋子样式大小：{percent}%'**
  String pieceSkinScaleCurrent(int percent);

  /// No description provided for @pieceSkinScaleHelp.
  ///
  /// In zh, this message translates to:
  /// **'大小只对当前棋子样式生效，并与下方全局棋子大小相乘；默认100%，范围80%–120%。'**
  String get pieceSkinScaleHelp;

  /// No description provided for @pieceSkinPositionCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前棋子样式位置：横向{x}%，纵向{y}%'**
  String pieceSkinPositionCurrent(int x, int y);

  /// No description provided for @skinPieceMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'棋子上移1%'**
  String get skinPieceMoveUp;

  /// No description provided for @skinPieceMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'棋子下移1%'**
  String get skinPieceMoveDown;

  /// No description provided for @skinPieceMoveLeft.
  ///
  /// In zh, this message translates to:
  /// **'棋子左移1%'**
  String get skinPieceMoveLeft;

  /// No description provided for @skinPieceMoveRight.
  ///
  /// In zh, this message translates to:
  /// **'棋子右移1%'**
  String get skinPieceMoveRight;

  /// No description provided for @skinPieceAutoAlign.
  ///
  /// In zh, this message translates to:
  /// **'棋子自动对正'**
  String get skinPieceAutoAlign;

  /// No description provided for @pieceSkinPositionHelp.
  ///
  /// In zh, this message translates to:
  /// **'每次移动当前棋子样式1%格宽，最多±8%；位置仅影响棋子绘制。'**
  String get pieceSkinPositionHelp;

  /// No description provided for @pieceShadowLabel.
  ///
  /// In zh, this message translates to:
  /// **'棋子阴影'**
  String get pieceShadowLabel;

  /// No description provided for @pieceShadowNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get pieceShadowNone;

  /// No description provided for @pieceShadowSoft.
  ///
  /// In zh, this message translates to:
  /// **'柔和'**
  String get pieceShadowSoft;

  /// No description provided for @pieceShadowProminent.
  ///
  /// In zh, this message translates to:
  /// **'明显'**
  String get pieceShadowProminent;

  /// No description provided for @pieceShadowDirection.
  ///
  /// In zh, this message translates to:
  /// **'方向'**
  String get pieceShadowDirection;

  /// No description provided for @pieceShadowDistance.
  ///
  /// In zh, this message translates to:
  /// **'距离'**
  String get pieceShadowDistance;

  /// No description provided for @pieceShadowBlur.
  ///
  /// In zh, this message translates to:
  /// **'模糊'**
  String get pieceShadowBlur;

  /// No description provided for @pieceShadowOpacity.
  ///
  /// In zh, this message translates to:
  /// **'浓淡'**
  String get pieceShadowOpacity;

  /// No description provided for @pieceShadowHelp.
  ///
  /// In zh, this message translates to:
  /// **'方向0°向右，90°向下；距离、模糊按棋格宽计算，值域为本机设计。'**
  String get pieceShadowHelp;
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
