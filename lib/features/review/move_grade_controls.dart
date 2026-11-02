import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/preferences_controller.dart';
import '../../application/review_report.dart';
import '../board/move_grade_badge.dart';

class MoveGradeControls extends StatelessWidget {
  const MoveGradeControls({
    super.key,
    required this.preferences,
    this.assessment,
    this.showPersistenceErrors = false,
  });
  final PreferencesController preferences;
  final MoveAssessment? assessment;
  final bool showPersistenceErrors;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('show-move-grades'),
          contentPadding: EdgeInsets.zero,
          title: const Text('着法标记'),
          subtitle: const Text('复盘后显示当前着的本机评级徽标'),
          value: preferences.value.showMoveGrades,
          onChanged: preferences.loading
              ? null
              : (v) => unawaited(preferences.setMoveGrades(v)),
        ),
        if (assessment != null) Text(moveGradeDescription(assessment!)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.info_outline),
            label: const Text('标记说明'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const MoveGradeLegend(),
            ),
          ),
        ),
        if (showPersistenceErrors && preferences.error != null) ...[
          Text(
            preferences.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: preferences.loading || preferences.saving
                ? null
                : () => unawaited(preferences.retryPersistence()),
            child: const Text('重试保存设置'),
          ),
        ],
      ],
    ),
  );
}

class MoveGradeLegend extends StatelessWidget {
  const MoveGradeLegend({super.key});
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('本机着法标记说明'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('根据原生WDL预期得分损失（和棋计半分），采用走子方视角；百分比点表示预期得分的差。此为本项目模型。'),
          for (final entry in const {
            MoveGrade.best: '引擎首选且预期损失为0',
            MoveGrade.excellent: '预期损失 <2 个百分点（不含最佳）',
            MoveGrade.good: '预期损失 ≥2 且 <5 个百分点',
            MoveGrade.inaccuracy: '预期损失 ≥5 且 <10 个百分点',
            MoveGrade.mistake: '预期损失 ≥10 且 <20 个百分点',
            MoveGrade.blunder: '预期损失 ≥20 个百分点',
          }.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    moveGradeIcon(entry.key),
                    color: moveGradeColor(entry.key),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${entry.key.label}：${entry.value}')),
                ],
              ),
            ),
          const Text('缺失WDL、上下界和预测杀棋不画普通评级。分析未完整时，仅展示已有充分数据的着法；修改棋谱后旧评级失效。'),
          const Text('模型版本：${ReviewReport.algorithmVersion}'),
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
}
