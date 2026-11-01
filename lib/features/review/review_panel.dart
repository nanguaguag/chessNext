import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/engine_session_controller.dart';
import '../../application/review_models.dart';
import 'review_options_dialog.dart';
import 'review_chart.dart';

class ReviewPanel extends StatelessWidget {
  const ReviewPanel({super.key, required this.engine});
  final EngineSessionController engine;

  Future<void> _configure(BuildContext context) async {
    final epoch = engine.session.epoch;
    final revision = engine.session.revision;
    final choice = await showDialog<ReviewConfiguration>(
      context: context,
      builder: (_) => ReviewOptionsDialog(
        threads: engine.settings.threads,
        hashMb: engine.settings.hashMb,
      ),
    );
    if (choice == null || !context.mounted) return;
    if (engine.session.epoch != epoch || engine.session.revision != revision) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('棋谱已变化，请重新选择分析范围。')));
      return;
    }
    unawaited(
      engine.startReview(
        scope: choice.scope,
        limits: choice.limits,
        skipExisting: choice.skipExisting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: engine,
    builder: (context, _) {
      final run = engine.review;
      final phase = run?.phase;
      final missing =
          run?.results.values
              .where((r) => r.status == ReviewScoreStatus.noScore)
              .length ??
          0;
      final status = switch (phase) {
        ReviewPhase.running => '正在分析',
        ReviewPhase.stopping => '正在取消',
        ReviewPhase.cancelled => '已取消，保留已完成的局面',
        ReviewPhase.completed =>
          missing == 0 ? '分析完成' : '分析结束，$missing个局面未取得评分',
        ReviewPhase.failed => run!.error ?? '分析失败',
        ReviewPhase.stale => '棋谱已变化，本次结果已过期',
        null => '离线逐局面计算，支持复用已有分析',
      };
      final ids =
          run?.nodeIds.where((id) => run.results.containsKey(id)).toList() ??
          <String>[];
      final canNavigate =
          run != null &&
          phase != ReviewPhase.stale &&
          run.epoch == engine.session.epoch &&
          run.revision == engine.session.revision;
      final extent = math.max(
        80.0,
        MediaQuery.textScalerOf(context).scale(16) * 3 + 24,
      );
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('整谱复盘', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Semantics(liveRegion: true, child: Text(status)),
              if (run != null) ...[
                Text('${run.results.length}/${run.nodeIds.length} 个局面'),
                if (run.cachedCount > 0) Text('复用 ${run.cachedCount} 个局面'),
                if (run.cacheNotice != null) Text(run.cacheNotice!),
                if (run.active)
                  LinearProgressIndicator(
                    value: run.results.length / run.nodeIds.length,
                  ),
                if (run.phase == ReviewPhase.running &&
                    run.currentNodeId != null)
                  Text('当前：${_notation(run, run.currentNodeId!)}'),
              ],
              const SizedBox(height: 8),
              if (run?.active ?? false)
                OutlinedButton(
                  onPressed: phase == ReviewPhase.stopping
                      ? null
                      : engine.cancelReview,
                  child: Text(
                    phase == ReviewPhase.stopping ? '正在取消' : '取消整谱分析',
                  ),
                )
              else
                FilledButton.tonal(
                  onPressed: engine.factory == null
                      ? null
                      : () => _configure(context),
                  child: const Text('分析整盘棋'),
                ),
              if (ids.isNotEmpty) ...[
                if (canNavigate)
                  ListenableBuilder(
                    listenable: engine.session,
                    builder: (context, _) => ReviewChart(
                      line: engine.session.tree.currentLine,
                      results: run.results,
                      cursorId: engine.session.tree.cursorId,
                      onNavigate: engine.navigateToNode,
                    ),
                  ),
                const Text('红方视角 · 杀棋/上下界分别保留；无评分不计作0'),
                SizedBox(
                  height: math.min(240, ids.length * extent),
                  child: ListView.builder(
                    primary: false,
                    itemExtent: extent,
                    itemCount: ids.length,
                    itemBuilder: (context, index) {
                      final id = ids[index];
                      final result = run!.results[id]!;
                      return ListTile(
                        key: ValueKey('review-$id'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _notation(run, id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${result.label}${result.info == null ? '' : ' · 深度${result.info!.depth}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: canNavigate
                            ? () => engine.navigateToNode(id)
                            : null,
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

  String _notation(ReviewRun run, String id) {
    final node = run.tree.node(id);
    if (node.parentId == null) return '开始';
    return ChineseNotation.format(
      run.tree.node(node.parentId!).position,
      node.move!,
    );
  }
}
