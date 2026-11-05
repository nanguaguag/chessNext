import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'side_panel_order_dialog.dart';
import 'record_playback_settings_dialog.dart';
import '../../application/app_preferences.dart';
import '../../application/preferences_controller.dart';
import 'text_size_dialog.dart';
import 'board_display_dialog.dart';
import 'analysis_markers_dialog.dart';
import '../../application/audio_library_controller.dart';
import '../../application/piece_image_library_controller.dart';
import '../../application/board_skin_image_library_controller.dart';
import '../../application/board_skin_library_controller.dart';
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/piece_skin_folder_picker.dart';
import '../../ports/piece_skin_catalog.dart';
import '../../ports/release_service.dart';
import 'about_support_dialog.dart';

class PreferencesDialog extends StatefulWidget {
  const PreferencesDialog({
    super.key,
    required this.preferences,
    this.audioLibrary,
    required this.pieceImages,
    required this.boardSkinImages,
    required this.boardSkins,
    this.pieceSkins,
    this.pieceSkinPackageExporter,
    this.pieceSkinPackagePicker,
    this.pieceSkinFolderPicker,
    this.pieceSkinCatalog,
    this.boardSkinCatalog,
    required this.releaseService,
  });
  final PreferencesController preferences;
  final AudioLibraryController? audioLibrary;
  final PieceImageLibraryController pieceImages;
  final BoardSkinImageLibraryController boardSkinImages;
  final BoardSkinLibraryController boardSkins;
  final PieceSkinLibraryController? pieceSkins;
  final PieceSkinPackageExporter? pieceSkinPackageExporter;
  final PieceSkinPackagePicker? pieceSkinPackagePicker;
  final PieceSkinFolderPicker? pieceSkinFolderPicker;
  final PieceSkinCatalog? pieceSkinCatalog;
  final BoardSkinCatalog? boardSkinCatalog;
  final ReleaseService releaseService;
  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController aiWalkTimeController;
  late final TextEditingController bookServiceUrlController;
  late final TextEditingController releaseServiceUrlController;
  late ThemePreference theme;
  late BoardLayoutPreset boardLayoutPreset;
  late int threads, hash, pv;
  late bool autoHash;
  late double seconds;
  late double aiWalkSeconds;
  late int aiWalkDifficulty, aiWalkMaxDepth;
  late OpeningBookMode openingBookMode;
  late bool endgameBookEnabled;
  late int leaveBookMoves;
  @override
  void initState() {
    super.initState();
    final value = widget.preferences.value;
    theme = value.theme;
    boardLayoutPreset = value.boardLayoutPreset;
    threads = value.threads;
    autoHash = value.autoHash;
    hash = value.hashMb;
    pv = value.multiPv;
    seconds = value.thinkTimeMs / 1000;
    aiWalkSeconds = value.aiWalkTimeMs / 1000;
    aiWalkTimeController = TextEditingController(text: '$aiWalkSeconds');
    aiWalkDifficulty = value.aiWalkDifficulty;
    aiWalkMaxDepth = value.aiWalkMaxDepth;
    openingBookMode = value.openingBookMode;
    endgameBookEnabled = value.endgameBookEnabled;
    leaveBookMoves = value.leaveBookMoves;
    bookServiceUrlController = TextEditingController(
      text: value.bookServiceBaseUrl,
    );
    releaseServiceUrlController = TextEditingController(
      text: value.releaseServiceBaseUrl,
    );
  }

  @override
  void dispose() {
    aiWalkTimeController.dispose();
    bookServiceUrlController.dispose();
    releaseServiceUrlController.dispose();
    super.dispose();
  }

  Widget number(
    String label,
    int value,
    int maximum,
    ValueChanged<int> change, {
    bool enabled = true,
    String? helperText,
    Key? key,
  }) => TextFormField(
    key: key,
    initialValue: '$value',
    enabled: enabled,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      helperText: helperText ?? '1 – $maximum',
    ),
    onChanged: (text) => change(int.tryParse(text) ?? 0),
    validator: (text) {
      final value = int.tryParse(text ?? '');
      return value == null || value < 1 || value > maximum
          ? '请输入1至$maximum之间的整数'
          : null;
    },
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.preferences,
    builder: (context, _) => AlertDialog(
      title: const Text('应用设置'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ThemePreference>(
                  initialValue: theme,
                  decoration: const InputDecoration(labelText: '外观主题'),
                  items: const [
                    DropdownMenuItem(
                      value: ThemePreference.system,
                      child: Text('跟随系统'),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.light,
                      child: Text('浅色'),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.dark,
                      child: Text('深色'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => theme = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BoardLayoutPreset>(
                  key: const ValueKey('board-layout-preset'),
                  initialValue: boardLayoutPreset,
                  decoration: const InputDecoration(labelText: '棋盘布局'),
                  items: const [
                    DropdownMenuItem(
                      value: BoardLayoutPreset.centered,
                      child: Text('棋盘居中'),
                    ),
                    DropdownMenuItem(
                      value: BoardLayoutPreset.boardOnLeft,
                      child: Text('棋盘靠左'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => boardLayoutPreset = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AnalysisMarkersDialog(
                          preferences: widget.preferences,
                        ),
                      ),
                      icon: const Icon(Icons.north_east),
                      label: const Text('分析标记'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            TextSizeDialog(preferences: widget.preferences),
                      ),
                      icon: const Icon(Icons.format_size),
                      label: const Text('界面字号'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => BoardDisplayDialog(
                          preferences: widget.preferences,
                          audioLibrary: widget.audioLibrary,
                          pieceImages: widget.pieceImages,
                          boardSkinImages: widget.boardSkinImages,
                          boardSkins: widget.boardSkins,
                          pieceSkins: widget.pieceSkins,
                          pieceSkinPackageExporter:
                              widget.pieceSkinPackageExporter,
                          pieceSkinPackagePicker: widget.pieceSkinPackagePicker,
                          pieceSkinFolderPicker: widget.pieceSkinFolderPicker,
                          pieceSkinCatalog: widget.pieceSkinCatalog,
                          boardSkinPackageExporter:
                              widget.pieceSkinPackageExporter,
                          boardSkinPackagePicker: widget.pieceSkinPackagePicker,
                          boardSkinCatalog: widget.boardSkinCatalog,
                        ),
                      ),
                      icon: const Icon(Icons.grid_on),
                      label: const Text('棋盘显示'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => SidePanelOrderDialog(
                          preferences: widget.preferences,
                        ),
                      ),
                      icon: const Icon(Icons.view_sidebar_outlined),
                      label: const Text('侧栏面板'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => RecordPlaybackSettingsDialog(
                          preferences: widget.preferences,
                        ),
                      ),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('棋谱与操作'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('about-support'),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AboutSupportDialog(
                          releaseEndpoint:
                              widget.preferences.value.releaseServiceBaseUrl,
                          releaseService: widget.releaseService,
                        ),
                      ),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('关于与开源许可'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                number(
                  '分析线程',
                  threads,
                  widget.preferences.engine.maxThreads,
                  (value) => setState(() {
                    threads = value;
                    if (autoHash) {
                      hash = (value * 64).clamp(
                        1,
                        widget.preferences.engine.maxHash,
                      );
                    }
                  }),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('按线程自动分配内存'),
                  subtitle: const Text('每个线程64 MB，并受引擎上限约束'),
                  value: autoHash,
                  onChanged: (value) => setState(() {
                    autoHash = value;
                    if (autoHash) {
                      hash = (threads * 64).clamp(
                        1,
                        widget.preferences.engine.maxHash,
                      );
                    }
                  }),
                ),
                number(
                  '分析内存（MB）',
                  hash,
                  widget.preferences.engine.maxHash,
                  (value) => hash = value,
                  enabled: !autoHash,
                  key: ValueKey('analysis-hash-$hash-$autoHash'),
                  helperText: autoHash
                      ? '$threads × 64 MB，受引擎上限约束'
                      : '1 – ${widget.preferences.engine.maxHash}',
                ),
                number(
                  '多路变化数',
                  pv,
                  widget.preferences.engine.maxPv,
                  (value) => pv = value,
                ),
                const Divider(height: 28),
                const Text('分析界面 AI 走棋'),
                Text('难度 $aiWalkDifficulty · 最高 20'),
                const Text('本地按固定节点预算映射；级别与站点棋力算法不等同。'),
                Slider(
                  key: const ValueKey('ai-walk-difficulty'),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  value: aiWalkDifficulty.toDouble(),
                  label: '$aiWalkDifficulty',
                  onChanged: (value) =>
                      setState(() => aiWalkDifficulty = value.round()),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final seconds in [1, 3, 10])
                      ActionChip(
                        label: Text('$seconds 秒'),
                        onPressed: () => setState(() {
                          aiWalkSeconds = seconds.toDouble();
                          aiWalkTimeController.text = '$aiWalkSeconds';
                        }),
                      ),
                    ActionChip(
                      label: const Text('不限时'),
                      onPressed: () => setState(() {
                        aiWalkSeconds = 0;
                        aiWalkTimeController.text = '0';
                      }),
                    ),
                  ],
                ),
                TextFormField(
                  key: const ValueKey('ai-walk-time'),
                  controller: aiWalkTimeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'AI 每步用时（秒）',
                    helperText: '0 为不限时；自定义0.5–600秒，步进0.5秒',
                  ),
                  onChanged: (text) => setState(
                    () => aiWalkSeconds = double.tryParse(text) ?? -1,
                  ),
                  validator: (_) =>
                      !aiWalkSeconds.isFinite ||
                          aiWalkSeconds < 0 ||
                          aiWalkSeconds > 600 ||
                          (aiWalkSeconds != 0 &&
                              aiWalkSeconds * 2 != (aiWalkSeconds * 2).round())
                      ? '请输入0或0.5至600秒的0.5秒倍数'
                      : null,
                ),
                if (aiWalkSeconds == 0)
                  number(
                    '不限时最大深度',
                    aiWalkMaxDepth,
                    255,
                    (value) => aiWalkMaxDepth = value,
                    helperText: '1 – 255；默认60',
                  ),
                const Divider(height: 28),
                const Text('版本更新'),
                TextFormField(
                  key: const ValueKey('release-service-url'),
                  controller: releaseServiceUrlController,
                  keyboardType: TextInputType.url,
                  maxLength: 2048,
                  decoration: const InputDecoration(
                    labelText: '自建版本信息服务地址',
                    helperText:
                        '留空时完全离线；仅在关于页手动检查时请求。公网必须HTTPS，本机可用localhost HTTP',
                  ),
                  validator: (text) {
                    final value = text!.trim().replaceFirst(RegExp(r'/+$'), '');
                    if (value.isEmpty) return null;
                    final uri = Uri.tryParse(value);
                    if (uri == null ||
                        uri.userInfo.isNotEmpty ||
                        uri.hasQuery ||
                        uri.hasFragment) {
                      return '请输入服务根地址';
                    }
                    final local = {
                      'localhost',
                      '127.0.0.1',
                      '::1',
                    }.contains(uri.host);
                    if (uri.host.isEmpty ||
                        (uri.scheme != 'https' &&
                            !(uri.scheme == 'http' && local))) {
                      return '公网必须HTTPS，本机仅允许localhost HTTP';
                    }
                    return null;
                  },
                ),
                const Divider(height: 28),
                const Text('开局与残局云库'),
                TextFormField(
                  key: const ValueKey('book-service-url'),
                  controller: bookServiceUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '自建云库服务地址',
                    helperText:
                        'AI单步会发送当前局面及完整着法历史；留空时完全离线。公网必须HTTPS，本机可用localhost HTTP',
                  ),
                  validator: (text) {
                    final value = text!.trim().replaceFirst(RegExp(r'/+$'), '');
                    if (value.isEmpty) return null;
                    final uri = Uri.tryParse(value);
                    if (uri == null ||
                        uri.userInfo.isNotEmpty ||
                        uri.hasQuery ||
                        uri.hasFragment) {
                      return '请输入服务根地址';
                    }
                    final local = {
                      'localhost',
                      '127.0.0.1',
                      '::1',
                    }.contains(uri.host);
                    if (uri.host.isEmpty ||
                        (uri.scheme != 'https' &&
                            !(uri.scheme == 'http' && local))) {
                      return '公网必须HTTPS，本机仅允许localhost HTTP';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<OpeningBookMode>(
                  key: const ValueKey('opening-book-mode'),
                  initialValue: openingBookMode,
                  decoration: const InputDecoration(labelText: '开局云库策略'),
                  items: const [
                    DropdownMenuItem(
                      value: OpeningBookMode.closed,
                      child: Text('关闭'),
                    ),
                    DropdownMenuItem(
                      value: OpeningBookMode.best,
                      child: Text('最佳着法'),
                    ),
                    DropdownMenuItem(
                      value: OpeningBookMode.randomWithinGap,
                      child: Text('分差内随机'),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) setState(() => openingBookMode = mode);
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用残局云库'),
                  value: endgameBookEnabled,
                  onChanged: (enabled) =>
                      setState(() => endgameBookEnabled = enabled),
                ),
                number(
                  '离开开局云库步数',
                  leaveBookMoves,
                  255,
                  (value) => leaveBookMoves = value,
                  helperText: '1 – 255；站点上界未验证，本机暂定255（P）',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$seconds',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'AI每步用时（秒）',
                    helperText: '0.05 – 600',
                  ),
                  onChanged: (text) => seconds = double.tryParse(text) ?? 0,
                  validator: (_) =>
                      !seconds.isFinite || seconds < .05 || seconds > 600
                      ? '请输入0.05至600之间的秒数'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text('设置保存在本机。启动引擎后会按实际能力调整参数；AI执方需每次手动开启。'),
                if (widget.preferences.error != null)
                  Text(
                    widget.preferences.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: widget.preferences.loading || widget.preferences.saving
              ? null
              : () async {
                  if (!form.currentState!.validate()) return;
                  await widget.preferences.apply(
                    widget.preferences.value.copyWith(
                      theme: theme,
                      boardLayoutPreset: boardLayoutPreset,
                      threads: threads,
                      autoHash: autoHash,
                      hashMb: hash,
                      multiPv: pv,
                      thinkTimeMs: (seconds * 1000).round(),
                      aiWalkDifficulty: aiWalkDifficulty,
                      aiWalkTimeMs: (aiWalkSeconds * 1000).round(),
                      aiWalkMaxDepth: aiWalkMaxDepth,
                      openingBookMode: openingBookMode,
                      endgameBookEnabled: endgameBookEnabled,
                      leaveBookMoves: leaveBookMoves,
                      bookServiceBaseUrl: bookServiceUrlController.text
                          .trim()
                          .replaceFirst(RegExp(r'/+$'), ''),
                      releaseServiceBaseUrl: releaseServiceUrlController.text
                          .trim()
                          .replaceFirst(RegExp(r'/+$'), ''),
                    ),
                  );
                  if (context.mounted && widget.preferences.error == null) {
                    Navigator.pop(context);
                  }
                },
          child: const Text('应用设置'),
        ),
      ],
    ),
  );
}
