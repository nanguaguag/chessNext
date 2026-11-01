import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_session.dart';
import '../../application/engine_session_controller.dart';

/// Current-move alternatives and next moves have different parent positions.
/// Both are document nodes; engine suggestions will be a separate projection.
class VariationPanel extends StatelessWidget {
  const VariationPanel({
    super.key,
    required this.session,
    required this.engine,
  });
  final BoardSession session;
  final EngineSessionController engine;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final tree = session.tree;
      final parent = tree.current.parentId;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parent != null)
            _group(context, '本步变着', tree.node(parent), current: true),
          if (tree.current.children.isNotEmpty)
            _group(context, '下一着选择', tree.current, current: false),
        ],
      );
    },
  );

  Widget _group(
    BuildContext context,
    String title,
    GameNode parent, {
    required bool current,
  }) {
    final tree = session.tree;
    final epoch = session.epoch;
    final revision = session.revision;
    final extent = math.max(
      80.0,
      MediaQuery.textScalerOf(context).scale(16) * 3 + 24,
    );
    final scope = current ? 'sibling' : 'next';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            '$title（${parent.children.length}）',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: math.min(240, parent.children.length * extent),
          child: ListView.builder(
            key: ValueKey('$scope-variations'),
            primary: false,
            itemExtent: extent,
            itemCount: parent.children.length,
            itemBuilder: (context, index) {
              final id = parent.children[index];
              final node = tree.node(id);
              final notation = ChineseNotation.format(
                parent.position,
                node.move!,
              );
              bool valid() =>
                  session.epoch == epoch && session.tree.hasNode(id);
              return ListTile(
                key: ValueKey('$scope-$id'),
                selected: current && id == tree.cursorId,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                contentPadding: const EdgeInsets.only(left: 8),
                title: Tooltip(
                  message: node.move.toString(),
                  child: Text(
                    current ? notation : '继续 $notation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Text(index == 0 ? '主线' : '变着'),
                onTap: () {
                  if (valid()) engine.navigateToNode(id);
                },
                trailing: PopupMenuButton<String>(
                  key: ValueKey('$scope-actions-$id'),
                  tooltip: '$notation的分支操作',
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'main',
                      enabled: index != 0,
                      child: const Text('提升为主线'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('删除变着')),
                  ],
                  onSelected: (action) async {
                    if (!valid()) return;
                    if (action == 'main') {
                      session.promote(id);
                      return;
                    }
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('删除这条变着？'),
                        content: Text('$notation及其后续着法和注释将被删除。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final deleted = await engine.deleteConfirmedBranch(
                      id,
                      epoch: epoch,
                      revision: revision,
                    );
                    if (!deleted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('棋谱已变化，本次未删除，请重新选择。')),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
