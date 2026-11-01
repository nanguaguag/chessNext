import 'package:flutter/material.dart';

enum GuideExit { skipped, completed }

const _steps = [
  (
    Icons.grid_on,
    '从棋盘开始',
    '点选己方棋子，再选择可走的交点。着法列表可回看过去和未来，切换变着不会删除其他线路。\n\n'
        '读谱前后沿当前线路移动；翻转只改变观看方向。键盘在棋盘获得焦点后可用方向键、Enter 或空格操作。',
  ),
  (
    Icons.smart_toy_outlined,
    '选择对弈或分析',
    '本地分析会持续给出当前局面的评分与推荐着法。与 AI 下棋时，选择引擎执红或执黑，并设置每步思考用时。\n\n'
        '立即出招可结束当前思考，变招可尝试其他合法着法。本引导只介绍操作，不会自动开启引擎或改变你的棋局。',
  ),
  (
    Icons.insights,
    '复盘与探索变化',
    '整谱复盘可计算所选线路或全部分支，支持取消与复用已有结果；点击曲线或结果可回到对应着法。\n\n'
        '单步候选在当前着的父局面计算，点击试走才创建或切换同级变着。模型评级中的未评级不代表正确，杀棋与上下界会单独处理。',
  ),
  (
    Icons.save_outlined,
    '把棋谱留在本机',
    '保存棋谱可保留完整棋树和注释，在本地棋谱库按名称打开。自动草稿是独立的恢复副本；最近阅读记录已保存棋谱的位置。\n\n'
        '文字导出仅包含根局面到当前着的路径。想再次查看这些说明，可从帮助与按钮说明重放引导；关闭后即可继续当前对局。',
  ),
];

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});
  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int step = 0;
  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = _steps[step];
    return AlertDialog(
      scrollable: true,
      title: const Text('新手引导'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                '${step + 1} / ${_steps.length}',
                semanticsLabel: '第${step + 1}步，共${_steps.length}步',
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (step + 1) / _steps.length),
            const SizedBox(height: 16),
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(body),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, GuideExit.skipped),
          child: const Text('跳过引导'),
        ),
        TextButton(
          onPressed: step == 0 ? null : () => setState(() => step--),
          child: const Text('上一步'),
        ),
        FilledButton(
          onPressed: () {
            if (step == _steps.length - 1) {
              Navigator.pop(context, GuideExit.completed);
            } else {
              setState(() => step++);
            }
          },
          child: Text(step == _steps.length - 1 ? '开始使用' : '下一步'),
        ),
      ],
    );
  }
}
