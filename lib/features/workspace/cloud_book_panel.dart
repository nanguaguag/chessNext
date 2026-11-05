import 'package:flutter/material.dart';

import '../../application/book_lookup_controller.dart';
import '../../application/master_games_lookup_controller.dart';
import '../../application/app_preferences.dart';
import '../../ports/book_service.dart';
import '../../ports/master_games_service.dart';

class CloudBookPanel extends StatefulWidget {
  const CloudBookPanel({
    super.key,
    required this.controller,
    required this.masterGamesController,
    required this.endpoint,
    required this.source,
    required this.onSourceChanged,
  });

  final BookLookupController controller;
  final MasterGamesLookupController masterGamesController;
  final String endpoint;
  final BookLookupSource source;
  final ValueChanged<BookLookupSource> onSourceChanged;

  @override
  State<CloudBookPanel> createState() => _CloudBookPanelState();
}

class _CloudBookPanelState extends State<CloudBookPanel> {
  final _text = TextEditingController();
  final _fromYear = TextEditingController();
  final _toYear = TextEditingController();
  final Set<MasterGameResult> _results = {};

  @override
  void dispose() {
    _text.dispose();
    _fromYear.dispose();
    _toYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('云库／大师谱', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<BookLookupSource>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: BookLookupSource.cloud, label: Text('云库')),
              ButtonSegment(
                value: BookLookupSource.masterGames,
                label: Text('大师谱'),
              ),
            ],
            selected: {widget.source},
            onSelectionChanged: (value) => widget.onSourceChanged(value.single),
          ),
          const SizedBox(height: 8),
          if (widget.source == BookLookupSource.cloud)
            _buildCloud(context)
          else
            _buildMasterGames(context),
        ],
      ),
    ),
  );

  Widget _buildCloud(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final busy = controller.status == BookLookupStatus.loading;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<BookKind>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: BookKind.opening, label: Text('开局库')),
              ButtonSegment(value: BookKind.endgame, label: Text('残局库')),
            ],
            selected: {controller.kind},
            onSelectionChanged: (selected) =>
                controller.setKind(selected.single),
          ),
          const SizedBox(height: 8),
          Text(
            widget.endpoint.trim().isEmpty
                ? '未配置自建服务。配置前不会发送局面或联网。'
                : '查询会向已配置的自建服务发送当前局面和着法历史。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : () => controller.query(widget.endpoint),
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
                color: _errorForCloud(controller.status, context),
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
      );
    },
  );

  Color? _errorForCloud(BookLookupStatus status, BuildContext context) =>
      switch (status) {
        BookLookupStatus.unavailable ||
        BookLookupStatus.rejected ||
        BookLookupStatus.invalid => Theme.of(context).colorScheme.error,
        _ => Theme.of(context).colorScheme.onSurfaceVariant,
      };

  Widget _buildMasterGames(BuildContext context) => AnimatedBuilder(
    animation: widget.masterGamesController,
    builder: (context, _) {
      final controller = widget.masterGamesController;
      final busy = controller.status == MasterGamesStatus.loading;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<MasterGameCategory?>(
            initialValue: controller.category,
            decoration: const InputDecoration(labelText: '范围'),
            items: const [
              DropdownMenuItem(value: null, child: Text('全部')),
              DropdownMenuItem(
                value: MasterGameCategory.game,
                child: Text('对局'),
              ),
              DropdownMenuItem(
                value: MasterGameCategory.chessbook,
                child: Text('棋书'),
              ),
            ],
            onChanged: (value) => controller.setFilters(
              category: value,
              clearCategory: value == null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: '棋手或赛事',
              counterText: '',
            ),
            onChanged: (value) => controller.setFilters(text: value),
          ),
          Row(
            children: [
              Expanded(child: _yearField('起始年份', _fromYear, true, controller)),
              const SizedBox(width: 8),
              Expanded(child: _yearField('截止年份', _toYear, false, controller)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              for (final result in MasterGameResult.values)
                FilterChip(
                  label: Text(switch (result) {
                    MasterGameResult.redWin => '红胜',
                    MasterGameResult.draw => '和棋',
                    MasterGameResult.blackWin => '黑胜',
                  }),
                  selected: _results.contains(result),
                  onSelected: (selected) {
                    setState(
                      () => selected
                          ? _results.add(result)
                          : _results.remove(result),
                    );
                    controller.setFilters(results: _results);
                  },
                ),
            ],
          ),
          Text(
            widget.endpoint.trim().isEmpty
                ? '未配置自建服务。修改筛选条件不会联网。'
                : '仅在点击查询后发送当前局面、着法历史和筛选条件。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : () => controller.query(widget.endpoint),
            icon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(busy ? '查询中' : '查询大师谱'),
          ),
          if (controller.message case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              key: const ValueKey('master-games-status'),
              style: TextStyle(
                color: switch (controller.status) {
                  MasterGamesStatus.unavailable ||
                  MasterGamesStatus.rejected ||
                  MasterGamesStatus.invalid => Theme.of(
                    context,
                  ).colorScheme.error,
                  _ => Theme.of(context).colorScheme.onSurfaceVariant,
                },
              ),
            ),
          ],
          for (final record in controller.records)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${record.red} — ${record.black}'),
              subtitle: Text(
                '${record.event} · ${record.year} · ${switch (record.result) {
                  MasterGameResult.redWin => '红胜',
                  MasterGameResult.draw => '和棋',
                  MasterGameResult.blackWin => '黑胜',
                }} · ${record.category == MasterGameCategory.game ? '对局' : '棋书'}',
              ),
            ),
          if (controller.total > 0)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('第${controller.page}页 · 共${controller.total}条'),
                TextButton.icon(
                  onPressed: busy || controller.page <= 1
                      ? null
                      : () => controller.previousPage(widget.endpoint),
                  icon: const Icon(Icons.navigate_before),
                  label: const Text('上一页'),
                ),
                TextButton.icon(
                  onPressed:
                      busy ||
                          controller.page * controller.pageSize >=
                              controller.total
                      ? null
                      : () => controller.nextPage(widget.endpoint),
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('下一页'),
                ),
              ],
            ),
          if (controller.datasetId case final id?)
            Text('数据集：$id', style: Theme.of(context).textTheme.bodySmall),
          if (controller.license case final value?)
            Text('许可：$value', style: Theme.of(context).textTheme.bodySmall),
          if (controller.attribution case final value?)
            Text('署名：$value', style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    },
  );

  Widget _yearField(
    String label,
    TextEditingController field,
    bool isFrom,
    MasterGamesLookupController controller,
  ) => TextField(
    controller: field,
    keyboardType: TextInputType.number,
    maxLength: 4,
    decoration: InputDecoration(labelText: label, counterText: ''),
    onChanged: (raw) {
      final value = int.tryParse(raw);
      if (raw.isEmpty || (value != null && value >= 1 && value <= 9999)) {
        controller.setFilters(
          fromYear: isFrom ? value : null,
          clearFromYear: isFrom && raw.isEmpty,
          toYear: isFrom ? null : value,
          clearToYear: !isFrom && raw.isEmpty,
        );
      } else {
        controller.setInvalidFilter('年份须为1至9999的整数。');
      }
    },
  );
}
