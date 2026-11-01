import 'package:flutter/material.dart';
import '../../application/review_models.dart';
import '../../ports/engine_gateway.dart';

class ReviewConfiguration {
  const ReviewConfiguration(
    this.scope,
    this.limits,
    this.skipExisting, {
    this.mode = ReviewMode.best,
    this.maximum = 1,
  });
  final ReviewMode mode;
  final int maximum;
  final bool skipExisting;
  final ReviewScope scope;
  final ReviewLimits limits;
}

class ReviewOptionsDialog extends StatefulWidget {
  const ReviewOptionsDialog({
    super.key,
    required this.threads,
    required this.hashMb,
  });
  final int threads;
  final int hashMb;
  @override
  State<ReviewOptionsDialog> createState() => _ReviewOptionsDialogState();
}

class _ReviewOptionsDialogState extends State<ReviewOptionsDialog> {
  final depth = TextEditingController(text: '16');
  final seconds = TextEditingController(text: '2');
  final nodes = TextEditingController(text: '0');
  final maximum = TextEditingController(text: '5');
  var mode = ReviewMode.best;
  final form = GlobalKey<FormState>();
  var scope = ReviewScope.line;
  var skipExisting = true;
  String? error;
  @override
  void dispose() {
    depth.dispose();
    seconds.dispose();
    nodes.dispose();
    maximum.dispose();
    super.dispose();
  }

  String? integer(String? text, int max) {
    final n = int.tryParse(text ?? '');
    return n == null || n < 0 || n > max ? '请输入0至$max的整数' : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('整谱分析'),
    content: SizedBox(
      width: 380,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ReviewMode>(
                initialValue: mode,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '分析方式'),
                items: const [
                  DropdownMenuItem(value: ReviewMode.best, child: Text('最佳着法')),
                  DropdownMenuItem(
                    value: ReviewMode.candidates,
                    child: Text('多候选'),
                  ),
                ],
                onChanged: (value) => setState(() => mode = value!),
              ),
              Text(
                mode == ReviewMode.best
                    ? '逐局面计算最佳着法。任一预算先达到即停止；0为不限，至少设置一项。'
                    : '每个局面计算多个不同合法候选，每个候选单独使用预算。评分受预算影响；0为不限，至少限制一项。',
              ),
              if (mode == ReviewMode.candidates)
                TextFormField(
                  controller: maximum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '每局面最多候选数'),
                  validator: (text) {
                    final n = int.tryParse(text ?? '');
                    return n == null || n < 2 || n > 256 ? '请输入2至256的整数' : null;
                  },
                ),
              TextFormField(
                controller: seconds,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: mode == ReviewMode.best ? '每局面用时（秒）' : '每个候选用时（秒）',
                ),
                validator: (text) {
                  final n = double.tryParse(text ?? '');
                  return n == null ||
                          !n.isFinite ||
                          n < 0 ||
                          n > 86400 ||
                          (n > 0 && n < 0.001)
                      ? '请输入0或0.001至86400秒'
                      : null;
                },
              ),
              TextFormField(
                controller: depth,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: mode == ReviewMode.best ? '每局面深度' : '每个候选深度',
                ),
                validator: (text) => integer(text, EngineRequest.maxDepth),
              ),
              TextFormField(
                controller: nodes,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: mode == ReviewMode.best ? '每局面节点数' : '每个候选节点数',
                ),
                validator: (text) => integer(text, EngineRequest.maxNodeLimit),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('包括所有变着'),
                subtitle: const Text('关闭时仅分析当前线路，包含尚未走到的后续局面'),
                value: scope == ReviewScope.tree,
                onChanged: (value) => setState(
                  () => scope = value ? ReviewScope.tree : ReviewScope.line,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('跳过已分析的局面'),
                subtitle: const Text('仅复用相同引擎、权重、历史及预算的结果'),
                value: skipExisting,
                onChanged: (value) => setState(() => skipExisting = value),
              ),
              Text('${widget.threads}线程 · ${widget.hashMb}MB · 单路最佳着法'),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        onPressed: () {
          if (!form.currentState!.validate()) return;
          final t = double.parse(seconds.text);
          final d = int.parse(depth.text);
          final n = int.parse(nodes.text);
          if (t == 0 && d == 0 && n == 0) {
            setState(() => error = '至少设置一项有限预算');
            return;
          }
          Navigator.pop(
            context,
            ReviewConfiguration(
              scope,
              ReviewLimits(
                depth: d == 0 ? null : d,
                moveTimeMs: t == 0 ? null : (t * 1000).round(),
                nodeLimit: n == 0 ? null : n,
              ),
              skipExisting,
              mode: mode,
              maximum: mode == ReviewMode.best ? 1 : int.parse(maximum.text),
            ),
          );
        },
        child: const Text('开始整谱分析'),
      ),
    ],
  );
}
