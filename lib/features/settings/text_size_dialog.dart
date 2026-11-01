import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/app_preferences.dart';
import '../../application/preferences_controller.dart';
import 'app_text_scaling.dart';

class TextSizeDialog extends StatelessWidget {
  const TextSizeDialog({super.key, required this.preferences});
  final PreferencesController preferences;
  static const manual = [
    TextSizePreference.standard,
    TextSizePreference.large,
    TextSizePreference.extraLarge,
  ];
  static const labels = ['标准100%', '大115%', '特大130%'];
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final size = preferences.value.textSize;
      final system = size == TextSizePreference.system;
      final index = system ? 0 : manual.indexOf(size);
      final systemPercent =
          (AppTextScaling.systemOf(context).scale(16) / 16 * 100).round();
      return AlertDialog(
        title: const Text('界面字号'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('跟随系统字号'),
                  subtitle: Text('系统字号预览：$systemPercent%'),
                  value: system,
                  onChanged: preferences.loading
                      ? null
                      : (value) => unawaited(
                          preferences.setTextSize(
                            value
                                ? TextSizePreference.system
                                : TextSizePreference.standard,
                          ),
                        ),
                ),
                Text(system ? '当前字号：跟随系统' : '当前字号：${labels[index]}'),
                Semantics(
                  label: '界面字号',
                  child: Slider(
                    key: const ValueKey('text-size-slider'),
                    value: index.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    label: labels[index],
                    semanticFormatterCallback: (value) => labels[value.round()],
                    onChanged: preferences.loading
                        ? null
                        : (value) => unawaited(
                            preferences.setTextSize(manual[value.round()]),
                          ),
                  ),
                ),
                const Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [Text('标准100%'), Text('大115%'), Text('特大130%')],
                ),
                const SizedBox(height: 16),
                const Text(
                  '红方行棋 · 本地棋谱与分析',
                  key: ValueKey('text-size-preview'),
                ),
                const SizedBox(height: 12),
                const Text('实时生效并保存在本机。手动调节会关闭跟随系统；重新关闭跟随时回到标准字号。'),
                if (preferences.loading || preferences.saving)
                  const LinearProgressIndicator(),
                if (preferences.error != null) ...[
                  Text(
                    preferences.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: preferences.loading || preferences.saving
                        ? null
                        : () => unawaited(preferences.retryPersistence()),
                    child: const Text('重试'),
                  ),
                ],
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
