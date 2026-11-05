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

  @override
  String get boardGeometryHeading => '格点与边距';

  @override
  String get boardGeometryHelp => '按画布百分比调整格网四边；所有棋子、标记和交点点击共用此几何。';

  @override
  String get boardGeometryCalibrate => '拖动格点校准';

  @override
  String get boardGeometryCalibrateTitle => '拖动格点校准';

  @override
  String get done => '完成';

  @override
  String get leftMargin => '左边距';

  @override
  String get rightMargin => '右边距';

  @override
  String get topMargin => '上边距';

  @override
  String get bottomMargin => '下边距';

  @override
  String boardSkinPieceScale(int percent) {
    return '棋子缩放 $percent%';
  }

  @override
  String get boardSkinPieceScaleHelp =>
      '棋子只改变面容尺寸，不改变格线间距或交点命中；与全局棋子尺寸、棋子样式比例相乘。';

  @override
  String get landingMarkerRotation => '落点标记图片旋转';

  @override
  String get landingMarkerRotationHelp => '每次换步时转一周后静止；系统减少动画或关闭动画速度时静止。';

  @override
  String get resetBoardGrid => '格网恢复默认';

  @override
  String get boardGridPreview => '棋盘格点预览，九列十行';

  @override
  String get topLeftGridPoint => '左上格点';

  @override
  String get bottomRightGridPoint => '右下格点';

  @override
  String topLeftGridPointValue(String left, String top) {
    return '左 $left%，上 $top%';
  }

  @override
  String bottomRightGridPointValue(String right, String bottom) {
    return '右 $right%，下 $bottom%';
  }

  @override
  String get gridPointMoveHint => '拖动或聚焦后使用方向键，每次移动1%；读屏可用方向操作调整';

  @override
  String get gridPointMoveLeft => '格点左移1%';

  @override
  String get gridPointMoveRight => '格点右移1%';

  @override
  String get gridPointMoveUp => '格点上移1%';

  @override
  String get gridPointMoveDown => '格点下移1%';

  @override
  String pieceSkinScaleCurrent(int percent) {
    return '当前棋子样式大小：$percent%';
  }

  @override
  String get pieceSkinScaleHelp =>
      '大小只对当前棋子样式生效，并与下方全局棋子大小相乘；默认100%，范围80%–120%。';

  @override
  String pieceSkinPositionCurrent(int x, int y) {
    return '当前棋子样式位置：横向$x%，纵向$y%';
  }

  @override
  String get skinPieceMoveUp => '棋子上移1%';

  @override
  String get skinPieceMoveDown => '棋子下移1%';

  @override
  String get skinPieceMoveLeft => '棋子左移1%';

  @override
  String get skinPieceMoveRight => '棋子右移1%';

  @override
  String get skinPieceAutoAlign => '棋子自动对正';

  @override
  String get pieceSkinPositionHelp => '每次移动当前棋子样式1%格宽，最多±8%；位置仅影响棋子绘制。';

  @override
  String get pieceShadowLabel => '棋子阴影';

  @override
  String get pieceShadowNone => '无';

  @override
  String get pieceShadowSoft => '柔和';

  @override
  String get pieceShadowProminent => '明显';

  @override
  String get pieceShadowDirection => '方向';

  @override
  String get pieceShadowDistance => '距离';

  @override
  String get pieceShadowBlur => '模糊';

  @override
  String get pieceShadowOpacity => '浓淡';

  @override
  String get pieceShadowHelp => '方向0°向右，90°向下；距离、模糊按棋格宽计算，值域为本机设计。';
}
