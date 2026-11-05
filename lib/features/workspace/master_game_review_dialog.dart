import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

import '../../ports/master_games_service.dart';
import '../board/xiangqi_board.dart';

/// Read-only game review; it owns an immutable PGN snapshot and never writes to
/// the active BoardSession.
final class MasterGameReviewDialog extends StatefulWidget {
  const MasterGameReviewDialog({
    super.key,
    required this.record,
    required this.pgn,
    required this.datasetId,
    required this.license,
    required this.attribution,
  });

  final MasterGameRecord record;
  final PgnRecord pgn;
  final String datasetId;
  final String license;
  final String attribution;

  @override
  State<MasterGameReviewDialog> createState() => _MasterGameReviewDialogState();
}

final class _MasterGameReviewDialogState extends State<MasterGameReviewDialog> {
  late final List<GameNode> line = widget.pgn.tree.currentLine;
  int cursor = 0;

  @override
  Widget build(BuildContext context) {
    final node = line[cursor];
    final position = node.position;
    return AlertDialog(
      title: Text('${widget.record.red} — ${widget.record.black}'),
      content: SizedBox(
        width: 820,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.record.event} · ${widget.record.year} · ${widget.datasetId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '许可：${widget.license}${widget.attribution.isEmpty ? '' : ' · 署名：${widget.attribution}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 390,
                    child: AspectRatio(
                      aspectRatio: 0.9,
                      child: BoardSurface(
                        at: position.at,
                        onTap: (_) {},
                        enabled: false,
                        lastMove: node.move,
                        lastMoveIdentity: (widget.record.id, cursor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: line.length,
                      itemBuilder: (context, index) {
                        final item = line[index];
                        final text = index == 0
                            ? '起始局面'
                            : '${(index + 1) ~/ 2}${index.isOdd ? '. ' : '... '}${ChineseNotation.format(line[index - 1].position, item.move!)}';
                        return ListTile(
                          dense: true,
                          selected: index == cursor,
                          title: Text(text),
                          onTap: () => setState(() => cursor = index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text('进度 $cursor/${line.length - 1}'),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '起始局面',
                  onPressed: cursor == 0
                      ? null
                      : () => setState(() => cursor = 0),
                  icon: const Icon(Icons.first_page),
                ),
                IconButton(
                  tooltip: '上一着',
                  onPressed: cursor == 0
                      ? null
                      : () => setState(() => cursor--),
                  icon: const Icon(Icons.navigate_before),
                ),
                Expanded(
                  child: Slider(
                    value: cursor.toDouble(),
                    max: (line.length - 1).toDouble(),
                    divisions: line.length > 1 ? line.length - 1 : null,
                    label: '$cursor/${line.length - 1}',
                    onChanged: line.length <= 1
                        ? null
                        : (value) => setState(() => cursor = value.round()),
                  ),
                ),
                IconButton(
                  tooltip: '下一着',
                  onPressed: cursor >= line.length - 1
                      ? null
                      : () => setState(() => cursor++),
                  icon: const Icon(Icons.navigate_next),
                ),
                IconButton(
                  tooltip: '最后一着',
                  onPressed: cursor >= line.length - 1
                      ? null
                      : () => setState(() => cursor = line.length - 1),
                  icon: const Icon(Icons.last_page),
                ),
              ],
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
