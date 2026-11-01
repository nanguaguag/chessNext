import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_session.dart';

/// Lazily renders the chosen reading line, including moves after the cursor.
class MoveList extends StatefulWidget {
  const MoveList({super.key, required this.session, required this.onNavigate});
  final BoardSession session;
  final ValueChanged<String> onNavigate;
  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final scroll = ScrollController();
  GameTree? cachedTree;
  List<GameNode> nodes = const [];
  String? lastCursor, lastAnchor;
  int? lastEpoch;
  double lastExtent = 0;
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant MoveList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_changed);
      widget.session.addListener(_changed);
      cachedTree = null;
      lastEpoch = null;
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_changed);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final tree = session.tree;
    final epoch = session.epoch;
    if (!identical(cachedTree, tree)) {
      cachedTree = tree;
      nodes = tree.currentLine;
    }
    final line = nodes;
    final extent = math
        .max(56.0, MediaQuery.textScalerOf(context).scale(16) * 1.6 + 24)
        .ceilToDouble();
    if (tree.cursorId != lastCursor ||
        tree.lineAnchorId != lastAnchor ||
        epoch != lastEpoch ||
        extent != lastExtent) {
      lastCursor = tree.cursorId;
      lastAnchor = tree.lineAnchorId;
      lastEpoch = epoch;
      lastExtent = extent;
      final index = line.indexWhere((node) => node.id == tree.cursorId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !scroll.hasClients ||
            widget.session.epoch != epoch ||
            widget.session.tree.cursorId != tree.cursorId ||
            widget.session.tree.lineAnchorId != tree.lineAnchorId ||
            !identical(widget.session, session)) {
          return;
        }
        final position = scroll.position;
        final top = index * extent;
        final bottom = top + extent;
        final target = top < position.pixels
            ? top
            : bottom > position.pixels + position.viewportDimension
            ? bottom - position.viewportDimension
            : position.pixels;
        if (target != position.pixels) {
          scroll.jumpTo(target.clamp(0, position.maxScrollExtent));
        }
      });
    }
    return Semantics(
      label: '棋谱着法列表，${line.length - 1}着',
      child: SizedBox(
        height: math.min(280.0, line.length * extent),
        child: Scrollbar(
          controller: scroll,
          thumbVisibility: true,
          child: ListView.builder(
            key: const ValueKey('reading-line'),
            controller: scroll,
            primary: false,
            itemExtent: extent,
            itemCount: line.length,
            itemBuilder: (context, index) {
              final node = line[index];
              final parent = node.parentId == null
                  ? null
                  : tree.node(node.parentId!);
              final notation = node.move == null
                  ? '开始'
                  : '$index. ${ChineseNotation.format(parent!.position, node.move!)}';
              final side = parent?.position.turn;
              return Tooltip(
                message: node.move?.toString() ?? '棋谱开始',
                child: ListTile(
                  key: ValueKey('move-${node.id}'),
                  selected: node.id == tree.cursorId,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    notation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: side == null
                        ? '棋谱开始'
                        : '${side == Side.red ? '红方' : '黑方'} 第$index着 $notation ${node.move}',
                  ),
                  trailing: node.comment.isEmpty
                      ? null
                      : const Icon(
                          Icons.comment_outlined,
                          size: 18,
                          semanticLabel: '有注释',
                        ),
                  onTap: () {
                    if (mounted &&
                        identical(widget.session, session) &&
                        widget.session.epoch == epoch) {
                      widget.onNavigate(node.id);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
