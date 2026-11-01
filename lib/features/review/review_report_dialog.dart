import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/review_report.dart';
import '../../application/review_models.dart';

class ReviewReportDialog extends StatefulWidget {
  const ReviewReportDialog({
    super.key,
    required this.report,
    required this.onNavigate,
  });
  final ReviewReport report;
  final Future<bool> Function(String id) onNavigate;
  @override
  State<ReviewReportDialog> createState() => _ReviewReportDialogState();
}

class _ReviewReportDialogState extends State<ReviewReportDialog> {
  Side? side;
  bool problemsOnly = true;
  String? notice;
  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final rows = report.rows
        .where(
          (r) =>
              (side == null || r.mover == side) &&
              (!problemsOnly || r.isProblem),
        )
        .toList();
    final extent = math.max(
      104.0,
      MediaQuery.textScalerOf(context).scale(16) * 4 + 24,
    );
    Widget summary(String name, SideReviewSummary value) => Text(
      '$name：${value.rated}/${value.total} 着已评级 · 问题 ${value.problems} · 未评级 ${value.unrated}\n平均预期损失 ${value.averageLossPercent == null ? '暂无数据' : '${value.averageLossPercent!.toStringAsFixed(2)}%'}',
    );
    return AlertDialog(
      scrollable: true,
      title: const Text('模型着法评级'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('依据原生胜和负的预期得分损失（和棋计半分）；本报告为打开时的分析快照。'),
            Text(
              report.run.scope == ReviewScope.tree
                  ? '范围：整棵棋树（含分支着法）'
                  : '范围：所选线路',
            ),
            if (report.partial) const Text('分析尚未完整，缺失数据不算正确着法。'),
            summary('红方', report.red),
            summary('黑方', report.black),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: side == null,
                  onSelected: (_) => setState(() => side = null),
                ),
                ChoiceChip(
                  label: const Text('红方'),
                  selected: side == Side.red,
                  onSelected: (_) => setState(() => side = Side.red),
                ),
                ChoiceChip(
                  label: const Text('黑方'),
                  selected: side == Side.black,
                  onSelected: (_) => setState(() => side = Side.black),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('只看问题着法'),
              value: problemsOnly,
              onChanged: (value) => setState(() => problemsOnly = value),
            ),
            if (notice != null)
              Text(
                notice!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (rows.isEmpty)
              Text(problemsOnly ? '没有已评级的问题着法。未评级不等于正确。' : '此范围没有着法。'),
            if (rows.isNotEmpty)
              SizedBox(
                height: math.min(
                  400.0,
                  math.min(
                    rows.length * extent,
                    MediaQuery.sizeOf(context).height * .35,
                  ),
                ),
                child: ListView.builder(
                  primary: false,
                  itemExtent: extent,
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final node = report.run.tree.node(row.nodeId);
                    final parent = report.run.tree.node(node.parentId!);
                    final ply = report.run.tree.goTo(node.id).path.length - 1;
                    final source = switch (row.source) {
                      LossSource.candidate => '同一父局面的实际着候选',
                      LossSource.followingPosition => '落子后局面（已换算走子方视角）',
                      LossSource.terminal => '规则终局结果',
                      null => row.reason ?? '未评级',
                    };
                    return Tooltip(
                      message: row.rated
                          ? '$source\n落子前预期 ${(row.beforeUnits! / 20).toStringAsFixed(2)}% · 实际着预期 ${(row.actualUnits! / 20).toStringAsFixed(2)}%'
                          : source,
                      child: ListTile(
                        key: ValueKey('assessment-${node.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '$ply. ${ChineseNotation.format(parent.position, node.move!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${row.grade.label} · ${row.lossPercent == null ? row.reason : '预期损失 ${row.lossPercent!.toStringAsFixed(2)}%'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final applied = await widget.onNavigate(row.nodeId);
                          if (!context.mounted) return;
                          if (applied) {
                            Navigator.pop(context);
                          } else {
                            setState(() => notice = '棋谱已变化，本次未跳转。');
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              '评级：最佳为零损失且命中引擎首选；优秀 <2%，好着 [2,5%)，不精确 [5,10%)，错误 [10,20%)，败着 ≥20%。杀棋与上下界不作普通概率评级。',
            ),
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
}
