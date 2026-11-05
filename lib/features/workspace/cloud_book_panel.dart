import 'package:flutter/material.dart';

import '../../application/book_lookup_controller.dart';
import '../../ports/book_service.dart';

class CloudBookPanel extends StatelessWidget {
  const CloudBookPanel({
    super.key,
    required this.controller,
    required this.endpoint,
  });

  final BookLookupController controller;
  final String endpoint;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final busy = controller.status == BookLookupStatus.loading;
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('云库', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SegmentedButton<BookKind>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: BookKind.opening,
                    label: Text('开局库'),
                    icon: Icon(Icons.auto_stories_outlined),
                  ),
                  ButtonSegment(
                    value: BookKind.endgame,
                    label: Text('残局库'),
                    icon: Icon(Icons.grid_on_outlined),
                  ),
                ],
                selected: {controller.kind},
                onSelectionChanged: (selected) =>
                    controller.setKind(selected.single),
              ),
              const SizedBox(height: 8),
              Text(
                endpoint.trim().isEmpty
                    ? '未配置自建服务。配置前不会发送局面或联网。'
                    : '查询会向已配置的自建服务发送当前局面和着法历史。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: busy ? null : () => controller.query(endpoint),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(busy ? '查询中' : '查询当前局面'),
              ),
              if (controller.message case final message?) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  key: const ValueKey('cloud-book-status'),
                  style: TextStyle(
                    color: switch (controller.status) {
                      BookLookupStatus.unavailable ||
                      BookLookupStatus.rejected ||
                      BookLookupStatus.invalid => Theme.of(
                        context,
                      ).colorScheme.error,
                      _ => Theme.of(context).colorScheme.onSurfaceVariant,
                    },
                  ),
                ),
              ],
              for (final candidate in controller.candidates)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(candidate.notation),
                  subtitle: Text(
                    '${candidate.uci} · 分值 ${candidate.scoreCp} · 权重 ${candidate.weight}',
                  ),
                ),
              if (controller.datasetId case final id?)
                Text('数据集：$id', style: Theme.of(context).textTheme.bodySmall),
              if (controller.license case final value?)
                Text('许可：$value', style: Theme.of(context).textTheme.bodySmall),
              if (controller.attribution case final value?)
                Text('署名：$value', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    },
  );
}
