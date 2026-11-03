import 'package:flutter/material.dart';
import '../../application/preferences_controller.dart';

class RecordPlaybackSettingsDialog extends StatelessWidget {
  const RecordPlaybackSettingsDialog({super.key, required this.preferences});
  final PreferencesController preferences;

  static const presets = [500, 1000, 2000, 3000];
  static String seconds(int milliseconds) =>
      '${(milliseconds / 1000).toStringAsFixed(milliseconds % 1000 == 0 ? 0 : 1)}秒';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final value = preferences.value.recordPlaybackIntervalMs;
      final isPreset = presets.contains(value);
      return AlertDialog(
        title: const Text('棋谱播放'),
        content: SizedBox(
          width: 420,
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
