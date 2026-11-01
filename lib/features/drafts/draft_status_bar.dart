import 'package:flutter/material.dart';
import '../../application/draft_controller.dart';

class DraftStatusBar extends StatelessWidget {
  const DraftStatusBar({
    super.key,
    required this.drafts,
    required this.onRestore,
  });
  final DraftController drafts;
  final VoidCallback onRestore;
  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drafts.loading || drafts.saving) const LinearProgressIndicator(),
          Semantics(
            liveRegion: true,
            child: Text(
              drafts.error ?? drafts.status,
              style: drafts.error == null
                  ? null
                  : TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          if (drafts.pending != null) ...[
            Text(drafts.pending!.title),
            const Text('恢复为未保存副本；使用当前棋谱会更新自动草稿。棋谱库中的原文件保留。'),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: onRestore, child: const Text('恢复草稿')),
                TextButton(
                  onPressed: drafts.keepCurrent,
                  child: const Text('使用当前棋谱'),
                ),
              ],
            ),
          ] else if (drafts.error != null)
            Wrap(
              spacing: 8,
              children: [
                if (drafts.canSave)
                  TextButton(
                    onPressed: drafts.loading ? null : () => drafts.flush(),
                    child: const Text('重试保存草稿'),
                  ),
                TextButton(
                  onPressed: drafts.loading ? null : drafts.initialize,
                  child: const Text('重读草稿'),
                ),
                TextButton(
                  onPressed: drafts.loading ? null : drafts.keepCurrent,
                  child: const Text('继续当前棋谱'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
