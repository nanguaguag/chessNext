import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/engine_session_controller.dart';
import '../../application/review_models.dart';
import 'candidate_options_dialog.dart';

class CandidatePanel extends StatelessWidget {
  const CandidatePanel({super.key, required this.engine});
  final EngineSessionController engine;
  Future<void> configure(BuildContext context) async {
    final session = engine.session;
    final epoch = session.epoch,
        revision = session.revision,
        position = session.positionRevision;
    final choice = await showDialog<CandidateConfiguration>(
      context: context,
      builder: (_) => const CandidateOptionsDialog(),
    );
    if (choice == null || !context.mounted) return;
    if (epoch != session.epoch ||
        revision != session.revision ||
        position != session.positionRevision) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('局面已变化，请重新选择候选分析。')));
      return;
    }
    unawaited(
      engine.startCandidates(
        limits: choice.limits,
        maximum: choice.maximum,
        skipExisting: choice.skipExisting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: engine,
    builder: (context, _) {
      final run = engine.candidates;
      final root = engine.session.tree.current.parentId == null;
      final stale = run != null && run.phase == ReviewPhase.stale;
      final status = switch (run?.phase) {
        ReviewPhase.running => '正在计算候选',
        ReviewPhase.stopping => '正在停止候选分析',
        ReviewPhase.completed => '候选分析完成',
        ReviewPhase.cancelled => '已取消，保留已完成候选',
        ReviewPhase.failed => run!.error ?? '候选分析失败',
        ReviewPhase.stale => '局面已变化，候选结果已过期',
        null => '候选计算完成后，可选择着法试走。',
      };
      final extent = math.max(
        104.0,
        MediaQuery.textScalerOf(context).scale(16) * 4 + 24,
      );
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('候选着法', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(root ? '计算棋谱起始局面的下一着' : '计算当前着法之前局面的替代候选'),
              Semantics(liveRegion: true, child: Text(status)),
              if (run != null) ...[
                Text(
                  '${run.results.length}/${run.total} 个候选 · 复用 ${run.cachedCount} 个',
                ),
                if (run.active)
                  LinearProgressIndicator(
                    value: run.results.length / math.max(1, run.total),
                  ),
                if (run.notice != null) Text(run.notice!),
              ],
              const SizedBox(height: 8),
              if (run?.active ?? false)
                OutlinedButton(
                  onPressed: run!.phase == ReviewPhase.stopping
                      ? null
                      : engine.disable,
                  child: const Text('停止候选分析'),
                )
              else
                FilledButton.tonal(
                  onPressed: engine.factory == null
                      ? null
                      : () => configure(context),
                  child: const Text('分析替代候选'),
                ),
              if (run != null && run.results.isNotEmpty) ...[
                Text(
                  '分析基于${run.tree.current.parentId == null ? '棋谱起始局面' : '所选着法之前的局面'}；试走保留原分支。',
                ),
                SizedBox(
                  height: math.min(300, run.results.length * extent),
                  child: ListView.builder(
                    primary: false,
                    itemExtent: extent,
                    itemCount: run.results.length,
                    itemBuilder: (context, index) {
                      final candidate = run.results[index];
                      final label = ChineseNotation.format(
                        run.position,
                        candidate.move,
                      );
                      final current =
                          run.tree.current.parentId == run.parentId &&
                          run.tree.current.move == candidate.move;
                      final stored = run.tree
                          .node(run.parentId)
                          .children
                          .any(
                            (id) => run.tree.node(id).move == candidate.move,
                          );
                      final score = ReviewedPosition(
                        nodeId: run.parentId,
                        turn: run.position.turn,
                        status: candidate.info == null
                            ? ReviewScoreStatus.noScore
                            : ReviewScoreStatus.scored,
                        info: candidate.info,
                      );
                      return ListTile(
                        key: ValueKey('candidate-${candidate.move}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${index + 1}. $label',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${score.label}${candidate.info == null ? '' : ' · 深度${candidate.info!.depth}'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: OutlinedButton(
                          key: ValueKey('trial-${candidate.move}'),
                          onPressed:
                              stale ||
                                  current ||
                                  run.phase == ReviewPhase.stopping
                              ? null
                              : () async {
                                  final applied = await engine.tryCandidate(
                                    run,
                                    candidate.move,
                                  );
                                  if (!applied && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('局面已变化或引擎未能停止，本次未试走。'),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            current
                                ? '当前着法'
                                : stored
                                ? '切换变着'
                                : '试走',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
