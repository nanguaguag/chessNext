// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get textSizeDialogTitle => '界面字号';

  @override
  String get followSystemTextSize => '跟随系统字号';

  @override
  String systemTextSizePreview(int percent) {
    return '系统字号预览：$percent%';
  }

  @override
  String get currentTextSizeFollowing => '当前字号：跟随系统';

  @override
  String currentTextSizeManual(String sizeLabel) {
    return '当前字号：$sizeLabel';
  }

  @override
  String get standardTextSize => '标准100%';

  @override
  String get largeTextSize => '大115%';

  @override
  String get extraLargeTextSize => '特大130%';

  @override
  String get textSizePreviewLine => '红方行棋 · 本地棋谱与分析';

  @override
  String get textSizePersistenceHelp => '实时生效并保存在本机。手动调节会关闭跟随系统；重新关闭跟随时回到标准字号。';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get boardDisplayTitle => '棋盘显示';

  @override
  String get boardSkinLabel => '棋盘皮肤';

  @override
  String get pieceSkinLabel => '棋子皮肤';

  @override
  String pieceScalePercent(int percent) {
    return '棋子大小：$percent%';
  }

  @override
  String get resetPieceSize => '恢复默认大小';

  @override
  String get pieceSizeHelp => '大小只影响显示，点击仍按交点。较大值可能使棋子重叠。';

  @override
  String get showCoordinates => '显示坐标';

  @override
  String get showCoordinatesHelp => '棋盘上下边的红黑方路数';

  @override
  String get rotateOppositePieces => '对面一方的棋子倒置';

  @override
  String get rotateOppositePiecesHelp => '上方那一方的棋子转180°，面对面摆棋时更顺眼。';

  @override
  String get boardDisplayPersistenceHelp =>
      '实时应用到主棋盘与局面编辑器并保存在本机。翻转或镜像时，路数随棋盘方向变化。';
}
