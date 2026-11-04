import 'package:flutter/material.dart';
import '../../application/app_preferences.dart';
import '../../application/preferences_controller.dart';

class RecordPlaybackSettingsDialog extends StatelessWidget {
  const RecordPlaybackSettingsDialog({super.key, required this.preferences});
  final PreferencesController preferences;

  static const presets = [500, 1000, 2000, 3000];
  static String seconds(int milliseconds) =>
      '${(milliseconds / 1000).toStringAsFixed(milliseconds % 1000 == 0 ? 0 : 1)}秒';

  static String actionLabel(BoardContextAction action) => switch (action) {
    BoardContextAction.copyFen => '复制当前局面（FEN）',
    BoardContextAction.copyRecord => '复制当前线路着法',
    BoardContextAction.importText => '从文字或剪贴板导入',
    BoardContextAction.exportText => '导出或复制文字',
    BoardContextAction.saveRecord => '保存到本地棋谱库',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final value = preferences.value.recordPlaybackIntervalMs;
      final isPreset = presets.contains(value);
      return AlertDialog(
        title: const Text('棋谱与操作'),
        content: SizedBox(
          width: 420,
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('自动播放时，两步之间的等待时间。'),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  emptySelectionAllowed: true,
                  segments: presets
                      .map(
                        (milliseconds) => ButtonSegment<int>(
                          value: milliseconds,
                          label: Text(seconds(milliseconds)),
                        ),
                      )
                      .toList(),
                  selected: isPreset ? {value} : const {},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      preferences.setRecordPlaybackInterval(selected.single);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text('自定义：${seconds(value)}'),
                Slider(
                  key: const ValueKey('record-playback-interval'),
                  min: 500,
                  max: 30000,
                  divisions: 295,
                  value: value.toDouble(),
                  label: seconds(value),
                  onChanged: (next) => preferences.setRecordPlaybackInterval(
                    (next / 100).round() * 100,
                  ),
                ),
                const Text('项目自定义范围为0.5–30秒，步进0.1秒。'),
                const Divider(height: 24),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('显示棋谱栏'),
                  value: preferences.value.showMoveList,
                  onChanged: preferences.setShowMoveList,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('显示播放按钮'),
                  value: preferences.value.showRecordPlaybackButton,
                  onChanged: preferences.setShowRecordPlaybackButton,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('显示面板切换栏'),
                  value: preferences.value.showPanelSwitchBar,
                  onChanged: preferences.setShowPanelSwitchBar,
                ),
                const Divider(height: 24),
                const Text('棋盘长按/右键快捷操作'),
                for (final action in BoardContextAction.values)
                  CheckboxListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(actionLabel(action)),
                    value: preferences.value.boardContextActions.contains(
                      action,
                    ),
                    onChanged: (enabled) {
                      final actions = [
                        ...preferences.value.boardContextActions,
                      ];
                      if (enabled == true) {
                        actions.add(action);
                      } else {
                        actions.remove(action);
                      }
                      preferences.setBoardContextActions(actions);
                    },
                  ),
                if (preferences.error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    },
  );
}
