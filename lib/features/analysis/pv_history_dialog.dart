import '../../application/pv_prefix_action.dart';
import 'pv_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/analysis_history.dart';

class PvHistoryDialog extends StatelessWidget {
  PvHistoryDialog({
    super.key,
    required List<PvHistoryEntry> entries,
    required this.side,
    this.actionFactory,
    this.sourceChanges,
  }) : entries = List.unmodifiable(entries);
  final List<PvHistoryEntry> entries;
  final Side side;
  final PvPrefixActionFactory? actionFactory;
  final Listenable? sourceChanges;
  String score(PvHistoryEntry entry) {
    final value = entry.scoreFor(side), bound = entry.boundFor(side);
    final name = side == Side.red ? '红' : '黑';
    if (entry.info.isMate && value == 0) {
      return '杀棋评分0（未据此判胜）';
    }
    if (entry.info.isMate) {
      return '$name方${value < 0 ? '被杀' : '杀棋'} ${value.abs()}';
    }
    return '$name分 ${bound == 'lower'
        ? '≥ '
        : bound == 'upper'
        ? '≤ '
        : ''}${value > 0 ? '+' : ''}$value';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('本谱PV历史'),
    content: SizedBox(
      width: 600,
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('打开时的${entries.length}条快照；最多64条，跨局面保留，换谱清空，不写入棋谱。'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, index) {
                final entry = entries[index],
                    info = entry.info,
                    wdl = entry.wdlFor(side);
                return Card.outlined(
                  key: ValueKey('pv-history-${entry.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '变化 ${info.multiPv} · 深度 ${info.depth} · ${score(entry)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${entry.sourceLabel} · ${entry.position.turn == Side.red ? "红方" : "黑方"}行棋',
                        ),
                        Text(
                          '${((info.timeMs ?? 0) / 1000).toStringAsFixed(1)} 秒 · ${info.nps ?? 0} 节点/秒',
                        ),
                        if (wdl != null && info.bound == null && !info.isMate)
                          Text(
                            '本机WDL：胜${(wdl.wins / 10).toStringAsFixed(1)}% · 和${(wdl.draws / 10).toStringAsFixed(1)}% · 负${(wdl.losses / 10).toStringAsFixed(1)}%（模型估计）',
                          ),
                        TextButton.icon(
                          key: ValueKey('pv-history-preview-${entry.id}'),
                          onPressed: () async {
                            final action = actionFactory?.call(entry);
                            final result = await showDialog<PvPreviewExit>(
                              context: context,
                              builder: (_) => PvPreviewDialog(
                                entry: entry,
                                flipped: side == Side.black,
                                action: action,
                                sourceChanges: sourceChanges,
                              ),
                            );
                            if (result == PvPreviewExit.applied &&
                                context.mounted &&
                                ModalRoute.of(context)?.isCurrent == true) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text('预览'),
                        ),
                        SelectableText(
                          info.pv.map((move) => move.toString()).join(' '),
                        ),
                        if (entry.truncated)
                          Text('原PV为${entry.originalPvLength}步，仅保留前128步。'),
                      ],
                    ),
                  ),
                );
              },
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
}
