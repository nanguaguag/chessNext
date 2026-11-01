import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/recent_reading_controller.dart';
import '../../ports/recent_reading_repository.dart';

class RecentReadingDialog extends StatelessWidget {
  const RecentReadingDialog({super.key, required this.readings});
  final RecentReadingController readings;
  Future<void> _open(BuildContext context, RecentReading entry) async {
    final library = readings.library;
    final session = library.session;
    final epoch = session.epoch;
    final revision = session.revision;
    final positionRevision = session.positionRevision;
    if (session.dirty && session.hasContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('打开最近阅读的棋谱？'),
          content: const Text('当前未保存的修改将被替换。阅读历史只保存位置，不保存未提交的棋谱内容。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('放弃修改并打开'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    if (session.epoch != epoch ||
        session.revision != revision ||
        session.positionRevision != positionRevision) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('确认期间棋谱已变化，请重新打开。')));
      }
      return;
    }
    if (await readings.open(entry) && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([readings, readings.library]),
    builder: (context, _) => AlertDialog(
      title: const Text('最近阅读'),
      content: SizedBox(
        width: 520,
        height: math.min(480, MediaQuery.sizeOf(context).height * .55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('本机已保存棋谱 · 最多50条 · 记录阅读位置，未保存内容由独立草稿管理'),
            if (readings.loading || readings.library.busy)
              const LinearProgressIndicator(),
            if (readings.notice != null) Text(readings.notice!),
            if (readings.error != null) ...[
              Text(
                readings.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: readings.loading
                    ? null
                    : () => readings.canWrite
                          ? readings.flush()
                          : readings.initialize(),
                child: const Text('重试阅读历史'),
              ),
            ],
            if (readings.library.error != null)
              Text(
                readings.library.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Expanded(
              child: readings.entries.isEmpty
                  ? Center(
                      child: Text(readings.loading ? '正在读取…' : '还没有本地阅读记录'),
                    )
                  : ListView.builder(
                      itemCount: readings.entries.length,
                      itemBuilder: (context, index) {
                        final entry = readings.entries[index];
                        return ListTile(
                          key: ValueKey('recent-${entry.gameId}'),
                          title: Text(entry.title),
                          subtitle: Text(
                            '第${entry.path.length}着 · ${entry.readAt.toLocal().toString().substring(0, 16)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: !readings.library.busy,
                          onTap: () => _open(context, entry),
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
    ),
  );
}
