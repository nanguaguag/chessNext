import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/engine_session_controller.dart';

class PlayPanel extends StatelessWidget {
  const PlayPanel({super.key, required this.engine});
  final EngineSessionController engine;
  Future<void> _time(BuildContext context, int? value) async {
    if (value == null) return;
    if (value > 0) {
      await engine.setThinkTime(value);
      return;
    }
    final form = GlobalKey<FormState>();
    var seconds = engine.thinkTimeMs / 1000;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI每步用时'),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: '$seconds',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '秒',
              helperText: '0.05至600秒',
            ),
            onChanged: (value) => seconds = double.tryParse(value) ?? 0,
            validator: (value) =>
                !seconds.isFinite || seconds < .05 || seconds > 600
                ? '请输入0.05至600之间的秒数'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, (seconds * 1000).round());
              }
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
    if (result != null) await engine.setThinkTime(result);
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('人机对弈', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('引擎执红'),
                selected: engine.aiSides.contains(Side.red),
                onSelected: (value) => engine.setAiSide(Side.red, value),
              ),
              FilterChip(
                label: const Text('引擎执黑'),
                selected: engine.aiSides.contains(Side.black),
                onSelected: (value) => engine.setAiSide(Side.black, value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            key: ValueKey(engine.thinkTimeMs),
            initialValue: const [1000, 3000, 10000].contains(engine.thinkTimeMs)
                ? engine.thinkTimeMs
                : 0,
            decoration: const InputDecoration(labelText: '每步用时'),
            items: [
              const DropdownMenuItem(value: 1000, child: Text('1秒')),
              const DropdownMenuItem(value: 3000, child: Text('3秒')),
              const DropdownMenuItem(value: 10000, child: Text('10秒')),
              DropdownMenuItem(
                value: 0,
                child: Text('自定义（${engine.thinkTimeMs / 1000}秒）'),
              ),
            ],
            onChanged: (value) => _time(context, value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: engine.canImmediate ? engine.immediateMove : null,
                child: const Text('立即出招'),
              ),
              OutlinedButton(
                onPressed: engine.canAlternative ? engine.alternative : null,
                child: const Text('变招'),
              ),
              if (engine.playing)
                TextButton(
                  onPressed: engine.disable,
                  child: const Text('停止对弈'),
                ),
            ],
          ),
          if (engine.thinking) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(engine.playing ? engine.status : '选择AI执方，或同时执红黑自动对弈'),
          if (engine.error != null)
            Text(
              engine.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
