import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/board_appearance.dart';
import '../../application/preferences_controller.dart';

class AnalysisMarkersDialog extends StatelessWidget {
  const AnalysisMarkersDialog({super.key, required this.preferences});
  final PreferencesController preferences;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) => AlertDialog(
      title: const Text('分析标记'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('推荐箭头'),
                subtitle: const Text('蓝色为本步推荐，紫色为预计应着'),
                value: preferences.value.showAnalysisArrows,
                onChanged: preferences.loading
                    ? null
                    : (value) =>
                          unawaited(preferences.setAnalysisArrows(value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('变着箭头'),
                subtitle: const Text('还需在本步变着中开启“棋盘箭头”'),
                value: preferences.value.showVariationArrows,
                onChanged: preferences.loading
                    ? null
                    : (value) =>
                          unawaited(preferences.setVariationArrows(value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('局势条'),
                subtitle: const Text('本机WDL预期得分；缺失模型时显示问号'),
                value: preferences.value.showEvaluationBar,
                onChanged: preferences.loading
                    ? null
                    : (value) => unawaited(preferences.setEvaluationBar(value)),
              ),
              DropdownButtonFormField<ArrowHeadStyle>(
                key: ValueKey(preferences.value.arrowHead),
                initialValue: preferences.value.arrowHead,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '箭头头部样式'),
                items: const [
                  DropdownMenuItem(
                    value: ArrowHeadStyle.sharp,
                    child: Text('尖'),
                  ),
                  DropdownMenuItem(
                    value: ArrowHeadStyle.standard,
                    child: Text('标准'),
                  ),
                  DropdownMenuItem(
                    value: ArrowHeadStyle.wide,
                    child: Text('宽'),
                  ),
                ],
                onChanged: preferences.loading
                    ? null
                    : (value) {
                        if (value != null) {
                          unawaited(preferences.setArrowHead(value));
                        }
                      },
              ),
              const SizedBox(height: 12),
              const Text('实时生效并保存在本机。隐藏箭头时分析继续，结果仍可在分析面板阅读。'),
              if (preferences.loading || preferences.saving)
                const LinearProgressIndicator(),
              if (preferences.error != null) ...[
                Text(
                  preferences.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    ),
  );
}
