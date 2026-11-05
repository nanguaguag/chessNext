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

  /// No description provided for @roundSealPieceSkin.
  ///
  /// In zh, this message translates to:
  /// **'传统圆章'**
  String get roundSealPieceSkin;

  /// No description provided for @squareInkPieceSkin.
  ///
  /// In zh, this message translates to:
  /// **'方章墨韵'**
  String get squareInkPieceSkin;

  /// No description provided for @pieceStyleMoveSoundHelp.
  ///
  /// In zh, this message translates to:
  /// **'棋子样式会同步决定“随棋子皮肤”的走棋音效。'**
  String get pieceStyleMoveSoundHelp;

  /// No description provided for @editPieceImages.
  ///
  /// In zh, this message translates to:
  /// **'编辑棋子图片'**
  String get editPieceImages;

  /// No description provided for @lastMoveMarker.
  ///
  /// In zh, this message translates to:
  /// **'落子标记'**
  String get lastMoveMarker;

  /// No description provided for @lastMoveHalo.
  ///
  /// In zh, this message translates to:
  /// **'旋转光圈'**
  String get lastMoveHalo;

  /// No description provided for @lastMoveBox.
  ///
  /// In zh, this message translates to:
  /// **'方框'**
  String get lastMoveBox;

  /// No description provided for @lastMoveAnimationHelp.
  ///
  /// In zh, this message translates to:
  /// **'动画速度控制棋子走动和自定义标记；系统减少动态效果时静止。'**
  String get lastMoveAnimationHelp;

  /// No description provided for @animationOff.
  ///
  /// In zh, this message translates to:
  /// **'关'**
  String get animationOff;

  /// No description provided for @animationFast.
  ///
  /// In zh, this message translates to:
  /// **'快'**
  String get animationFast;

  /// No description provided for @animationStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get animationStandard;

  /// No description provided for @animationSlow.
  ///
  /// In zh, this message translates to:
  /// **'慢'**
  String get animationSlow;

  /// No description provided for @animationDurationHelp.
  ///
  /// In zh, this message translates to:
  /// **'控制落子光圈旋转一周的时长：关、300毫秒、600毫秒或1200毫秒。系统减少动画时始终静止。'**
  String get animationDurationHelp;

  /// No description provided for @moveSound.
  ///
  /// In zh, this message translates to:
  /// **'走棋音效'**
  String get moveSound;

  /// No description provided for @moveSoundHelp.
  ///
  /// In zh, this message translates to:
  /// **'落子后播放本机离线音效'**
  String get moveSoundHelp;

  /// No description provided for @captureSound.
  ///
  /// In zh, this message translates to:
  /// **'吃子音效'**
  String get captureSound;

  /// No description provided for @captureSoundHelp.
  ///
  /// In zh, this message translates to:
  /// **'吃掉对方棋子时播放本机离线音效'**
  String get captureSoundHelp;

  /// No description provided for @checkSound.
  ///
  /// In zh, this message translates to:
  /// **'将军音效'**
  String get checkSound;

  /// No description provided for @checkSoundHelp.
  ///
  /// In zh, this message translates to:
  /// **'将军时播放；将死提示优先'**
  String get checkSoundHelp;

  /// No description provided for @mateSound.
  ///
  /// In zh, this message translates to:
  /// **'绝杀音效'**
  String get mateSound;

  /// No description provided for @mateSoundHelp.
  ///
  /// In zh, this message translates to:
  /// **'将死时播放；与普通走棋音效互斥'**
  String get mateSoundHelp;

  /// No description provided for @selectionSound.
  ///
  /// In zh, this message translates to:
  /// **'选子音效'**
  String get selectionSound;

  /// No description provided for @selectionSoundHelp.
  ///
  /// In zh, this message translates to:
  /// **'选中己方棋子时播放本机离线音效'**
  String get selectionSoundHelp;

  /// No description provided for @replaceSound.
  ///
  /// In zh, this message translates to:
  /// **'更换{kind}音效'**
  String replaceSound(String kind);

  /// No description provided for @selectionStyle.
  ///
  /// In zh, this message translates to:
  /// **'选子样式'**
  String get selectionStyle;

  /// No description provided for @selectionLift.
  ///
  /// In zh, this message translates to:
  /// **'抬起'**
  String get selectionLift;

  /// No description provided for @selectionFrame.
  ///
  /// In zh, this message translates to:
  /// **'选择框'**
  String get selectionFrame;

  /// No description provided for @selectionStyleHelp.
  ///
  /// In zh, this message translates to:
  /// **'只改变选中棋子的显示，点击区域保持在交点。'**
  String get selectionStyleHelp;

  /// No description provided for @speakMoves.
  ///
  /// In zh, this message translates to:
  /// **'着法朗读'**
  String get speakMoves;

  /// No description provided for @speakMovesHelp.
  ///
  /// In zh, this message translates to:
  /// **'使用本机已安装的中文系统语音，独立于走棋音效；无离线中文语音时不朗读'**
  String get speakMovesHelp;

  /// No description provided for @editPieceSkinImages.
  ///
  /// In zh, this message translates to:
  /// **'编辑{skin}图片'**
  String editPieceSkinImages(String skin);

  /// No description provided for @pieceImagesHelp.
  ///
  /// In zh, this message translates to:
  /// **'仅替换选中的棋子，PNG/JPEG、512 KiB以内、最长边1024像素；文件保存在本机。'**
  String get pieceImagesHelp;

  /// No description provided for @batchImportImages.
  ///
  /// In zh, this message translates to:
  /// **'批量导入图片'**
  String get batchImportImages;

  /// No description provided for @importedPieceImages.
  ///
  /// In zh, this message translates to:
  /// **'已导入{count}张棋子图片。'**
  String importedPieceImages(int count);

  /// No description provided for @editBoardSkinImages.
  ///
  /// In zh, this message translates to:
  /// **'编辑{skin}棋盘图片'**
  String editBoardSkinImages(String skin);

  /// No description provided for @boardImagesHelp.
  ///
  /// In zh, this message translates to:
  /// **'仅保存在本机；支持 PNG/JPEG，单张不超过512 KiB。'**
  String get boardImagesHelp;

  /// No description provided for @boardImageBackground.
  ///
  /// In zh, this message translates to:
  /// **'棋盘背景'**
  String get boardImageBackground;

  /// No description provided for @boardImageStartMarker.
  ///
  /// In zh, this message translates to:
  /// **'起点标记'**
  String get boardImageStartMarker;

  /// No description provided for @boardImageLandingMarker.
  ///
  /// In zh, this message translates to:
  /// **'落点标记'**
  String get boardImageLandingMarker;

  /// No description provided for @boardImageSelectionFrame.
  ///
  /// In zh, this message translates to:
  /// **'选中框'**
  String get boardImageSelectionFrame;

  /// No description provided for @defaultBoardBackground.
  ///
  /// In zh, this message translates to:
  /// **'使用棋盘配色默认背景'**
  String get defaultBoardBackground;

  /// No description provided for @defaultBoardImageSlot.
  ///
  /// In zh, this message translates to:
  /// **'使用默认{slot}'**
  String defaultBoardImageSlot(String slot);

  /// No description provided for @selectImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get selectImage;

  /// No description provided for @replaceBoardImage.
  ///
  /// In zh, this message translates to:
  /// **'替换图片'**
  String get replaceBoardImage;

  /// No description provided for @replaceImage.
  ///
  /// In zh, this message translates to:
  /// **'替换'**
  String get replaceImage;

  /// No description provided for @resetImage.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get resetImage;

  /// No description provided for @pieceImageRedRook.
  ///
  /// In zh, this message translates to:
  /// **'红车'**
  String get pieceImageRedRook;

  /// No description provided for @pieceImageRedHorse.
  ///
  /// In zh, this message translates to:
  /// **'红马'**
  String get pieceImageRedHorse;

  /// No description provided for @pieceImageRedElephant.
  ///
  /// In zh, this message translates to:
  /// **'红相'**
  String get pieceImageRedElephant;

  /// No description provided for @pieceImageRedAdvisor.
  ///
  /// In zh, this message translates to:
  /// **'红仕'**
  String get pieceImageRedAdvisor;

  /// No description provided for @pieceImageRedGeneral.
  ///
  /// In zh, this message translates to:
  /// **'红帅'**
  String get pieceImageRedGeneral;

  /// No description provided for @pieceImageRedCannon.
  ///
  /// In zh, this message translates to:
  /// **'红炮'**
  String get pieceImageRedCannon;

  /// No description provided for @pieceImageRedPawn.
  ///
  /// In zh, this message translates to:
  /// **'红兵'**
  String get pieceImageRedPawn;

  /// No description provided for @pieceImageBlackRook.
  ///
  /// In zh, this message translates to:
  /// **'黑车'**
  String get pieceImageBlackRook;

  /// No description provided for @pieceImageBlackHorse.
  ///
  /// In zh, this message translates to:
  /// **'黑马'**
  String get pieceImageBlackHorse;

  /// No description provided for @pieceImageBlackElephant.
  ///
  /// In zh, this message translates to:
  /// **'黑象'**
  String get pieceImageBlackElephant;

  /// No description provided for @pieceImageBlackAdvisor.
  ///
  /// In zh, this message translates to:
  /// **'黑士'**
  String get pieceImageBlackAdvisor;

  /// No description provided for @pieceImageBlackGeneral.
  ///
  /// In zh, this message translates to:
  /// **'黑将'**
  String get pieceImageBlackGeneral;

  /// No description provided for @pieceImageBlackCannon.
  ///
  /// In zh, this message translates to:
  /// **'黑炮'**
  String get pieceImageBlackCannon;

  /// No description provided for @pieceImageBlackPawn.
  ///
  /// In zh, this message translates to:
  /// **'黑卒'**
  String get pieceImageBlackPawn;

  /// No description provided for @batchImportPieceImagesTitle.
  ///
  /// In zh, this message translates to:
  /// **'批量导入棋子图片'**
  String get batchImportPieceImagesTitle;

  /// No description provided for @batchImportPieceImagesHelp.
  ///
  /// In zh, this message translates to:
  /// **'已选{count}张。为每张图片选择目标棋子；未映射或重复槽位不能导入。'**
  String batchImportPieceImagesHelp(int count);

  /// No description provided for @chooseTargetPiece.
  ///
  /// In zh, this message translates to:
  /// **'请选择目标棋子'**
  String get chooseTargetPiece;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @importImages.
  ///
  /// In zh, this message translates to:
  /// **'导入图片'**
  String get importImages;

  /// No description provided for @boardSkinParchment.
  ///
  /// In zh, this message translates to:
  /// **'宣纸木色'**
  String get boardSkinParchment;

  /// No description provided for @boardSkinJade.
  ///
  /// In zh, this message translates to:
  /// **'松石青'**
  String get boardSkinJade;

  /// No description provided for @manageBoardSkins.
  ///
  /// In zh, this message translates to:
  /// **'管理棋盘皮肤库'**
  String get manageBoardSkins;

  /// No description provided for @skinPackageHelp.
  ///
  /// In zh, this message translates to:
  /// **'棋盘与棋子皮肤均支持项目格式的ZIP导入/导出；站点皮肤ZIP及文件夹格式未确认。'**
  String get skinPackageHelp;

  /// No description provided for @editBoardImages.
  ///
  /// In zh, this message translates to:
  /// **'编辑棋盘图片'**
  String get editBoardImages;

  /// No description provided for @managePieceSkins.
  ///
  /// In zh, this message translates to:
  /// **'管理皮肤库'**
  String get managePieceSkins;

  /// No description provided for @editBoardSkinGeometry.
  ///
  /// In zh, this message translates to:
  /// **'编辑{name}'**
  String editBoardSkinGeometry(String name);

  /// No description provided for @resetBoardGeometry.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认几何'**
  String get resetBoardGeometry;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @boardSkinGeometrySaveError.
  ///
  /// In zh, this message translates to:
  /// **'棋盘皮肤未能保存在本机，请重试。'**
  String get boardSkinGeometrySaveError;

  /// No description provided for @onlineBoardCatalog.
  ///
  /// In zh, this message translates to:
  /// **'自建在线棋盘目录'**
  String get onlineBoardCatalog;

  /// No description provided for @catalogServiceAddress.
  ///
  /// In zh, this message translates to:
  /// **'自建目录服务地址'**
  String get catalogServiceAddress;

  /// No description provided for @catalogEndpointHelp.
  ///
  /// In zh, this message translates to:
  /// **'远程需HTTPS；localhost可用于本机部署。'**
  String get catalogEndpointHelp;

  /// No description provided for @saveAddressConnect.
  ///
  /// In zh, this message translates to:
  /// **'保存服务地址并连接'**
  String get saveAddressConnect;

  /// No description provided for @searchBoardSkins.
  ///
  /// In zh, this message translates to:
  /// **'搜索棋盘皮肤'**
  String get searchBoardSkins;

  /// No description provided for @onlineSort.
  ///
  /// In zh, this message translates to:
  /// **'在线排序'**
  String get onlineSort;

  /// No description provided for @sortDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认排序'**
  String get sortDefault;

  /// No description provided for @sortLikes.
  ///
  /// In zh, this message translates to:
  /// **'点赞'**
  String get sortLikes;

  /// No description provided for @sortName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get sortName;

  /// No description provided for @sortAuthor.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get sortAuthor;

  /// No description provided for @sortRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近创建'**
  String get sortRecent;

  /// No description provided for @offlineCacheAt.
  ///
  /// In zh, this message translates to:
  /// **'离线缓存 · {time}'**
  String offlineCacheAt(String time);

  /// No description provided for @unknownTime.
  ///
  /// In zh, this message translates to:
  /// **'时间未知'**
  String get unknownTime;

  /// No description provided for @catalogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'目录当前没有棋盘皮肤。'**
  String get catalogEmpty;

  /// No description provided for @catalogUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法连接自建棋盘目录，请检查网络和服务状态。'**
  String get catalogUnavailable;

  /// No description provided for @catalogHttpRejected.
  ///
  /// In zh, this message translates to:
  /// **'目录服务返回HTTP {status}。'**
  String catalogHttpRejected(int status);

  /// No description provided for @catalogInvalidResponse.
  ///
  /// In zh, this message translates to:
  /// **'目录响应无效，未显示远程棋盘皮肤。'**
  String get catalogInvalidResponse;

  /// No description provided for @catalogRequestFailed.
  ///
  /// In zh, this message translates to:
  /// **'目录请求失败，请检查服务地址。'**
  String get catalogRequestFailed;

  /// No description provided for @catalogNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'请先填写并连接自建目录服务。'**
  String get catalogNotConfigured;

  /// No description provided for @skinDetailsAuthor.
  ///
  /// In zh, this message translates to:
  /// **'作者：{value}'**
  String skinDetailsAuthor(String value);

  /// No description provided for @skinDetailsLikes.
  ///
  /// In zh, this message translates to:
  /// **'点赞：{value}'**
  String skinDetailsLikes(int value);

  /// No description provided for @skinDetailsCreated.
  ///
  /// In zh, this message translates to:
  /// **'创建：{value}'**
  String skinDetailsCreated(String value);

  /// No description provided for @skinDetailsLicense.
  ///
  /// In zh, this message translates to:
  /// **'许可证：{value}'**
  String skinDetailsLicense(String value);

  /// No description provided for @skinDetailsAttribution.
  ///
  /// In zh, this message translates to:
  /// **'署名：{value}'**
  String skinDetailsAttribution(String value);

  /// No description provided for @noExtraAttribution.
  ///
  /// In zh, this message translates to:
  /// **'无额外署名'**
  String get noExtraAttribution;

  /// No description provided for @downloadConfirmImport.
  ///
  /// In zh, this message translates to:
  /// **'下载并确认导入'**
  String get downloadConfirmImport;

  /// No description provided for @confirmBoardSkinImport.
  ///
  /// In zh, this message translates to:
  /// **'确认导入{name}？'**
  String confirmBoardSkinImport(String name);

  /// No description provided for @boardSkinLicenseReview.
  ///
  /// In zh, this message translates to:
  /// **'下载包已通过SHA-256与本机棋盘皮肤ZIP格式校验。\n\n许可证：{license}\n署名：{attribution}\n\n导入将新增并立即使用一套本机棋盘皮肤；许可义务由你自行遵守。'**
  String boardSkinLicenseReview(String license, String attribution);

  /// No description provided for @acceptLicenseImport.
  ///
  /// In zh, this message translates to:
  /// **'接受许可并导入'**
  String get acceptLicenseImport;

  /// No description provided for @boardSkinImported.
  ///
  /// In zh, this message translates to:
  /// **'已校验并导入{name}。'**
  String boardSkinImported(String name);

  /// No description provided for @boardSkinImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败。'**
  String get boardSkinImportFailed;

  /// No description provided for @remoteDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败，请检查网络；本机棋盘皮肤未更改。'**
  String get remoteDownloadFailed;

  /// No description provided for @remotePackageRejected.
  ///
  /// In zh, this message translates to:
  /// **'下载包校验失败或服务拒绝请求；本机棋盘皮肤未更改。'**
  String get remotePackageRejected;

  /// No description provided for @invalidBoardSkinPackage.
  ///
  /// In zh, this message translates to:
  /// **'棋盘皮肤包格式无效；本机数据未更改。'**
  String get invalidBoardSkinPackage;

  /// No description provided for @remoteBoardSkinImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法导入该远程棋盘皮肤；本机数据未更改。'**
  String get remoteBoardSkinImportFailed;

  /// No description provided for @boardSkinExported.
  ///
  /// In zh, this message translates to:
  /// **'棋盘皮肤包已导出。'**
  String get boardSkinExported;

  /// No description provided for @boardSkinExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'棋盘皮肤导出失败，请检查本机存储后重试。'**
  String get boardSkinExportFailed;

  /// No description provided for @importBoardSkinPackage.
  ///
  /// In zh, this message translates to:
  /// **'导入棋盘皮肤包'**
  String get importBoardSkinPackage;

  /// No description provided for @boardSkinPackageSummary.
  ///
  /// In zh, this message translates to:
  /// **'项目格式皮肤包：{name}\n包含{count}张自定义图片和独立格网设置。导入后会新增并立即使用，不覆盖现有皮肤。'**
  String boardSkinPackageSummary(String name, int count);

  /// No description provided for @importAndUse.
  ///
  /// In zh, this message translates to:
  /// **'导入并使用'**
  String get importAndUse;

  /// No description provided for @invalidBoardSkinPackageSize.
  ///
  /// In zh, this message translates to:
  /// **'棋盘皮肤包无效或超过大小限制，本机皮肤未更改。'**
  String get invalidBoardSkinPackageSize;

  /// No description provided for @readBoardSkinPackageFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取棋盘皮肤包，本机皮肤未更改。'**
  String get readBoardSkinPackageFailed;

  /// No description provided for @newBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'新建棋盘皮肤'**
  String get newBoardSkin;

  /// No description provided for @renameBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'重命名棋盘皮肤'**
  String get renameBoardSkin;

  /// No description provided for @deleteBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'删除棋盘皮肤'**
  String get deleteBoardSkin;

  /// No description provided for @confirmDeleteBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'确定删除「{name}」？此操作无法撤销。'**
  String confirmDeleteBoardSkin(String name);

  /// No description provided for @builtInSkins.
  ///
  /// In zh, this message translates to:
  /// **'内置皮肤'**
  String get builtInSkins;

  /// No description provided for @builtInPalette.
  ///
  /// In zh, this message translates to:
  /// **'内置配色'**
  String get builtInPalette;

  /// No description provided for @use.
  ///
  /// In zh, this message translates to:
  /// **'使用'**
  String get use;

  /// No description provided for @myBoards.
  ///
  /// In zh, this message translates to:
  /// **'我的棋盘'**
  String get myBoards;

  /// No description provided for @saveOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅保存'**
  String get saveOnly;

  /// No description provided for @createAndUse.
  ///
  /// In zh, this message translates to:
  /// **'新建并使用'**
  String get createAndUse;

  /// No description provided for @noLocalBoardSkins.
  ///
  /// In zh, this message translates to:
  /// **'还没有本机棋盘皮肤。新建时会复制当前棋盘的配色、格网和图片。'**
  String get noLocalBoardSkins;

  /// No description provided for @basedOnSkin.
  ///
  /// In zh, this message translates to:
  /// **'基于{skin}'**
  String basedOnSkin(String skin);

  /// No description provided for @editNamedBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'编辑{name}'**
  String editNamedBoardSkin(String name);

  /// No description provided for @renameNamedBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'重命名{name}'**
  String renameNamedBoardSkin(String name);

  /// No description provided for @deleteNamedBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'删除{name}'**
  String deleteNamedBoardSkin(String name);

  /// No description provided for @exportNamedBoardSkin.
  ///
  /// In zh, this message translates to:
  /// **'导出{name}'**
  String exportNamedBoardSkin(String name);

  /// No description provided for @boardSkinName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get boardSkinName;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @loadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多棋盘皮肤'**
  String get loadMore;

  /// No description provided for @invalidCatalogAddress.
  ///
  /// In zh, this message translates to:
  /// **'服务地址无效：远程地址必须使用HTTPS。'**
  String get invalidCatalogAddress;

  /// No description provided for @catalogAddressSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'服务地址保存失败，可重试。'**
  String get catalogAddressSaveFailed;

  /// No description provided for @audioSettingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name}音效'**
  String audioSettingsTitle(String name);

  /// No description provided for @audioCurrentCustom.
  ///
  /// In zh, this message translates to:
  /// **'当前：自定义音效'**
  String get audioCurrentCustom;

  /// No description provided for @audioCurrentChoice.
  ///
  /// In zh, this message translates to:
  /// **'当前：{choice}{skin}'**
  String audioCurrentChoice(String choice, String skin);

  /// No description provided for @audioCurrentDefault.
  ///
  /// In zh, this message translates to:
  /// **'当前：默认音效'**
  String get audioCurrentDefault;

  /// No description provided for @audioReplaceHelp.
  ///
  /// In zh, this message translates to:
  /// **'只替换{name}音效。文件仅保存在本机，不上传。'**
  String audioReplaceHelp(String name);

  /// No description provided for @audioFileLimits.
  ///
  /// In zh, this message translates to:
  /// **'支持 WAV / MP3，最多512 KiB、5秒。'**
  String get audioFileLimits;

  /// No description provided for @audioPlan.
  ///
  /// In zh, this message translates to:
  /// **'音效方案'**
  String get audioPlan;

  /// No description provided for @audioResetToChoosePlan.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认音效后可选择内置方案。'**
  String get audioResetToChoosePlan;

  /// No description provided for @audioSkinChoice.
  ///
  /// In zh, this message translates to:
  /// **'随棋子皮肤'**
  String get audioSkinChoice;

  /// No description provided for @audioSoundChoice1.
  ///
  /// In zh, this message translates to:
  /// **'音效1'**
  String get audioSoundChoice1;

  /// No description provided for @audioSoundChoice2.
  ///
  /// In zh, this message translates to:
  /// **'音效2'**
  String get audioSoundChoice2;

  /// No description provided for @audioFollowSkin.
  ///
  /// In zh, this message translates to:
  /// **'随棋子皮肤'**
  String get audioFollowSkin;

  /// No description provided for @audioPreviewChoice.
  ///
  /// In zh, this message translates to:
  /// **'试听{choice}'**
  String audioPreviewChoice(String choice);

  /// No description provided for @audioPreviewCurrent.
  ///
  /// In zh, this message translates to:
  /// **'试听当前音效'**
  String get audioPreviewCurrent;

  /// No description provided for @audioImportCustom.
  ///
  /// In zh, this message translates to:
  /// **'导入自定义音效'**
  String get audioImportCustom;

  /// No description provided for @audioRestoreDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认音效'**
  String get audioRestoreDefault;

  /// No description provided for @audioRoundSealSkin.
  ///
  /// In zh, this message translates to:
  /// **'传统圆章'**
  String get audioRoundSealSkin;

  /// No description provided for @audioSquareInkSkin.
  ///
  /// In zh, this message translates to:
  /// **'方章墨韵'**
  String get audioSquareInkSkin;
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
