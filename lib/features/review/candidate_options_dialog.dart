import 'package:flutter/material.dart';
import '../../application/review_models.dart';
import '../../ports/engine_gateway.dart';

class CandidateConfiguration {
  const CandidateConfiguration(this.limits, this.maximum, this.skipExisting);
  final ReviewLimits limits;
  final int maximum;
  final bool skipExisting;
}

class CandidateOptionsDialog extends StatefulWidget {
  const CandidateOptionsDialog({super.key});
  @override
  State<CandidateOptionsDialog> createState() => _CandidateOptionsDialogState();
}

class _CandidateOptionsDialogState extends State<CandidateOptionsDialog> {
  final seconds = TextEditingController(text: '2');
  final depth = TextEditingController(text: '16');
  final nodes = TextEditingController(text: '0');
  final maximum = TextEditingController(text: '5');
  final form = GlobalKey<FormState>();
  bool skip = true;
  String? error;
  @override
  void dispose() {
    seconds.dispose();
    depth.dispose();
    nodes.dispose();
    maximum.dispose();
    super.dispose();
  }

  String? integer(String? text, int min, int max) {
    final n = int.tryParse(text ?? '');
    return n == null || n < min || n > max ? '请输入$min至$max的整数' : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('候选分析预算'),
    content: SizedBox(
      width: 380,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('逐个寻找不同首着，评分受搜索预算影响。每个候选单独使用以下预算，0为不限，至少限制一项。'),
              TextFormField(
                controller: seconds,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '每个候选用时（秒）'),
                validator: (text) {
                  final n = double.tryParse(text ?? '');
                  return n == null ||
                          !n.isFinite ||
                          n < 0 ||
                          n > 86400 ||
                          (n > 0 && n < .001)
                      ? '请输入0或0.001至86400秒'
                      : null;
                },
              ),
              TextFormField(
                controller: depth,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '每个候选深度'),
                validator: (text) => integer(text, 0, EngineRequest.maxDepth),
              ),
              TextFormField(
                controller: nodes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '每个候选节点数'),
                validator: (text) =>
                    integer(text, 0, EngineRequest.maxNodeLimit),
              ),
              TextFormField(
                controller: maximum,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '最多候选数（含首选）'),
                validator: (text) => integer(text, 2, 256),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('复用已有候选计算'),
                value: skip,
                onChanged: (value) => setState(() => skip = value),
              ),
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
            CandidateConfiguration(
              ReviewLimits(
                depth: d == 0 ? null : d,
                moveTimeMs: t == 0 ? null : (t * 1000).round(),
                nodeLimit: n == 0 ? null : n,
              ),
              int.parse(maximum.text),
              skip,
            ),
          );
        },
        child: const Text('开始候选分析'),
      ),
    ],
  );
}
