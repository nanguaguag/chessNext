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
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/piece_skin_folder_picker.dart';

class PreferencesDialog extends StatefulWidget {
  const PreferencesDialog({
    super.key,
    required this.preferences,
    this.audioLibrary,
    required this.pieceImages,
    required this.boardSkinImages,
    this.pieceSkins,
    this.pieceSkinPackageExporter,
    this.pieceSkinPackagePicker,
    this.pieceSkinFolderPicker,
  });
  final PreferencesController preferences;
  final AudioLibraryController? audioLibrary;
  final PieceImageLibraryController pieceImages;
  final BoardSkinImageLibraryController boardSkinImages;
  final PieceSkinLibraryController? pieceSkins;
  final PieceSkinPackageExporter? pieceSkinPackageExporter;
  final PieceSkinPackagePicker? pieceSkinPackagePicker;
  final PieceSkinFolderPicker? pieceSkinFolderPicker;
  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  final form = GlobalKey<FormState>();
  late ThemePreference theme;
  late int threads, hash, pv;
  late double seconds;
  @override
  void initState() {
    super.initState();
    final value = widget.preferences.value;
    theme = value.theme;
    threads = value.threads;
    hash = value.hashMb;
    pv = value.multiPv;
    seconds = value.thinkTimeMs / 1000;
  }

  Widget number(
    String label,
    int value,
    int maximum,
    ValueChanged<int> change,
  ) => TextFormField(
    initialValue: '$value',
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, helperText: '1 – $maximum'),
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
                          pieceSkins: widget.pieceSkins,
                          pieceSkinPackageExporter:
                              widget.pieceSkinPackageExporter,
                          pieceSkinPackagePicker: widget.pieceSkinPackagePicker,
                          pieceSkinFolderPicker: widget.pieceSkinFolderPicker,
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
                  ],
                ),
                const SizedBox(height: 12),
                number(
                  '分析线程',
                  threads,
                  widget.preferences.engine.maxThreads,
                  (value) => threads = value,
                ),
                number(
                  '分析内存（MB）',
                  hash,
                  widget.preferences.engine.maxHash,
                  (value) => hash = value,
                ),
                number(
                  '多路变化数',
                  pv,
                  widget.preferences.engine.maxPv,
                  (value) => pv = value,
                ),
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
                      threads: threads,
                      hashMb: hash,
                      multiPv: pv,
                      thinkTimeMs: (seconds * 1000).round(),
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
