import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/review_models.dart';

Future<void> showReviewCandidates(
  BuildContext context,
  ReviewRun run,
  String id,
) => showDialog<void>(
  context: context,
  builder: (_) => ReviewCandidatesDialog(run: run, nodeId: id),
);

class ReviewCandidatesDialog extends StatelessWidget {
  const ReviewCandidatesDialog({
    super.key,
    required this.run,
    required this.nodeId,
  });
  final ReviewRun run;
  final String nodeId;
  @override
  Widget build(BuildContext context) {
    final set = run.candidateResults[nodeId]!;
    final position = run.tree.node(nodeId).position;
    final extent = math.max(
      96.0,
      MediaQuery.textScalerOf(context).scale(16) * 4 + 24,
    );
    return AlertDialog(
      scrollable: true,
      title: Text(set.complete ? '局面候选详情' : '部分候选（局面未完成）'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('该局面轮到${position.turn == Side.red ? '红方' : '黑方'}，评分统一红方视角。'),
            if (set.notice != null) Text(set.notice!),
            if (set.entries.isEmpty) const Text('未取得可评估候选。'),
            if (set.entries.isNotEmpty)
              SizedBox(
                height: math.min(
                  360.0,
                  math.min(
                    extent * set.entries.length,
                    MediaQuery.sizeOf(context).height * .35,
                  ),
                ),
                child: ListView.builder(
                  primary: false,
                  itemExtent: extent,
                  itemCount: set.entries.length,
                  itemBuilder: (context, index) {
                    final candidate = set.entries[index];
                    final score = ReviewedPosition(
                      nodeId: nodeId,
                      turn: position.turn,
                      status: candidate.info == null
                          ? ReviewScoreStatus.noScore
                          : ReviewScoreStatus.scored,
                      info: candidate.info,
                    );
                    return ListTile(
                      key: ValueKey('review-detail-${candidate.move}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${index + 1}. ${ChineseNotation.format(position, candidate.move)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${score.label}${candidate.info == null ? '' : ' · 深度${candidate.info!.depth}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Tooltip(
                        message: candidate.move.toString(),
                        child: const Icon(Icons.info_outline),
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
}
