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
}
