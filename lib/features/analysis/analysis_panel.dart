import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/engine_session_controller.dart';
import '../../ports/engine_gateway.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key, required this.analysis});
  final EngineSessionController analysis;
  Future<void> _settings(BuildContext context) async {
    final form = GlobalKey<FormState>();
    var threads = analysis.settings.threads;
    var hash = analysis.settings.hashMb;
    var pv = analysis.settings.multiPv;
    Widget number(
      String name,
      int initial,
      int maximum,
      ValueChanged<int> change,
    ) => TextFormField(
      initialValue: '$initial',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: name, helperText: '1 – $maximum'),
      onChanged: (value) => change(int.tryParse(value) ?? 0),
      validator: (value) {
        final n = int.tryParse(value ?? '');
        return n == null || n < 1 || n > maximum ? '请输入1至$maximum之间的整数' : null;
      },
    );
    final value = await showDialog<AnalysisSettings>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('本地引擎参数'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                number(
                  '计算线程',
                  threads,
                  analysis.maxThreads,
                  (value) => threads = value,
                ),
                number(
                  '置换表内存（MB）',
                  hash,
                  analysis.maxHash,
                  (value) => hash = value,
                ),
                number('同时分析变化数', pv, analysis.maxPv, (value) => pv = value),
              ],
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
              if (form.currentState!.validate()) {
                Navigator.pop(
                  context,
                  AnalysisSettings(threads: threads, hashMb: hash, multiPv: pv),
                );
              }
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
    if (value != null) await analysis.configure(value);
  }

  String _score(EngineInfo info) {
    final side = analysis.session.flipped ? Side.black : Side.red;
    final score = analysis.scoreFor(info, side);
    final name = side == Side.red ? '红' : '黑';
    if (info.isMate) return '$name方${score < 0 ? '被杀' : '杀棋'} ${score.abs()}';
    final bound = analysis.boundFor(info, side);
    return '$name分 ${bound == 'lower'
        ? '≥ '
        : bound == 'upper'
        ? '≤ '
        : ''}${score > 0 ? '+' : ''}$score';
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本地分析', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: analysis.enabled
                    ? analysis.disable
                    : analysis.enable,
                icon: Icon(
                  analysis.enabled
                      ? Icons.stop_circle_outlined
                      : Icons.analytics_outlined,
                ),
                label: Text(analysis.enabled ? '停止分析' : '开始分析'),
              ),
              IconButton(
                onPressed: analysis.options.isEmpty
                    ? null
                    : () => _settings(context),
                tooltip: '引擎参数',
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          if (analysis.engineName != null)
            Text(
              analysis.engineName!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          if (analysis.busy) const LinearProgressIndicator(),
          Semantics(
            liveRegion: true,
            child: Text(analysis.error ?? analysis.status),
          ),
          const SizedBox(height: 8),
          Text(
            '${analysis.settings.threads} 线程 · ${analysis.settings.hashMb} MB · ${analysis.settings.multiPv} 条变化',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final info in analysis.infos)
            ExpansionTile(
              key: ValueKey('pv-${info.multiPv}'),
              initiallyExpanded: info.multiPv == 1,
              tilePadding: EdgeInsets.zero,
              title: Text('${info.multiPv}. ${_score(info)}'),
              subtitle: Text(
                '深度 ${info.depth} · ${((info.timeMs ?? 0) / 1000).toStringAsFixed(1)} 秒 · ${info.nps ?? 0} 节点/秒',
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    info.pv.map((move) => move.toString()).join(' '),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
