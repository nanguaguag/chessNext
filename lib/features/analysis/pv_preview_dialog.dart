import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/analysis_history.dart';
import '../../application/pv_preview.dart';
import '../board/xiangqi_board.dart';

class PvPreviewDialog extends StatefulWidget {
  const PvPreviewDialog({
    super.key,
    required this.entry,
    this.flipped = false,
    this.loader = PvPreview.prepareInWorker,
  });
  final PvHistoryEntry entry;
  final bool flipped;
  final PvPreviewLoader loader;
  @override
  State<PvPreviewDialog> createState() => _PvPreviewDialogState();
}

class _PvPreviewDialogState extends State<PvPreviewDialog>
    with WidgetsBindingObserver {
  PvPreview? preview;
  String? error;
  int cursor = 0, generation = 0;
  bool closed = false;
  Timer? timer;
  final scroll = ScrollController();
  double rowExtent = 48;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    final task = ++generation;
    setState(() => error = null);
    try {
      final value = await widget.loader(widget.entry);
      if (!mounted ||
          closed ||
          task != generation ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      setState(() {
        preview = value;
        cursor = 1;
      });
    } catch (exception) {
      if (!mounted ||
          closed ||
          task != generation ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      setState(
        () => error = exception is FormatException
            ? exception.message
            : '无法准备此PV，请重试',
      );
    }
  }

  void _stop() {
    timer?.cancel();
    timer = null;
  }

  void _pause() {
    if (timer == null) return;
    _stop();
    if (mounted && !closed) setState(() {});
  }

  void _jump(int target) {
    final value = preview;
    if (value == null || closed) return;
    _stop();
    setState(() => cursor = target.clamp(0, value.length));
  }

  void _toggle() {
    final value = preview;
    if (value == null || closed) return;
    if (timer != null) {
      _pause();
      return;
    }
    setState(() {
      if (cursor == value.length) cursor = 0;
      timer = Timer.periodic(const Duration(milliseconds: 800), (tick) {
        if (!mounted || closed || !identical(timer, tick)) return;
        if (ModalRoute.of(context)?.isCurrent != true) {
          _pause();
          return;
        }
        setState(() {
          cursor = math.min(cursor + 1, value.length);
          if (cursor == value.length) _stop();
        });
      });
    });
  }

  void _retire() {
    closed = true;
    generation++;
    _stop();
  }

  void _close() {
    _retire();
    Navigator.pop(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    _retire();
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    super.dispose();
  }

  void _revealCursor() {
    final expected = cursor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || closed || cursor != expected || !scroll.hasClients) {
        return;
      }
      if (cursor == 0) {
        if (scroll.offset != 0) scroll.jumpTo(0);
        return;
      }
      final start = (cursor - 1) * rowExtent, end = start + rowExtent;
      final offset = scroll.offset,
          viewport = scroll.position.viewportDimension;
      if (start < offset || end > offset + viewport) {
        scroll.jumpTo(start.clamp(0, scroll.position.maxScrollExtent));
      }
    });
  }

  String _scoreLabel() {
    final side = widget.flipped ? Side.black : Side.red;
    final value = widget.entry.scoreFor(side);
    final bound = widget.entry.boundFor(side);
    final name = side == Side.red ? '红' : '黑';
    if (widget.entry.info.isMate) {
      return value == 0
          ? '杀棋评分0（未据此判胜）'
          : '$name方${value < 0 ? '被杀' : '杀棋'} ${value.abs()}';
    }
    return '$name分 ${bound == 'lower'
        ? '≥ '
        : bound == 'upper'
        ? '≤ '
        : ''}${value > 0 ? '+' : ''}$value';
  }

  Widget _body(BuildContext context, PvPreview value) {
    rowExtent = math.max(
      48,
      MediaQuery.textScalerOf(
                context,
              ).scale(Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) *
              2.8 +
          8,
    );
    _revealCursor();
    final position = value.positions[cursor];
    final board = Semantics(
      container: true,
      label: '第$cursor步只读局面',
      value:
          '${cursor == 0 ? '原局面' : value.notation[cursor - 1]}，${position.turn == Side.red ? '红方' : '黑方'}行棋',
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 10,
              child: BoardSurface(
                at: position.at,
                onTap: (_) {},
                enabled: false,
                flipped: widget.flipped,
                lastMove: cursor == 0 ? null : value.entry.info.pv[cursor - 1],
                lastMoveIdentity: cursor,
              ),
            ),
          ),
        ),
      ),
    );
    final moves = ListView.builder(
      controller: scroll,
      itemExtent: rowExtent,
      itemCount: value.length,
      itemBuilder: (context, index) => TextButton(
        key: ValueKey('pv-preview-step-${index + 1}'),
        style: TextButton.styleFrom(
          backgroundColor: cursor == index + 1
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          alignment: Alignment.centerLeft,
        ),
        onPressed: () => _jump(index + 1),
        child: Text(
          '${index + 1}. ${value.notation[index]}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_scoreLabel()} · 深度${value.entry.info.depth} · 变化${value.entry.info.multiPv} · 未写入棋谱',
        ),
        if (value.entry.truncated)
          Text('仅预览前128步（原PV共${value.entry.originalPvLength}步）'),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 560
                ? Row(
                    children: [
                      Expanded(child: board),
                      const SizedBox(width: 12),
                      Expanded(child: moves),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 3, child: board),
                      const SizedBox(height: 8),
                      Expanded(flex: 2, child: moves),
                    ],
                  ),
          ),
        ),
        Text(
          '$cursor / ${value.length}',
          key: const ValueKey('pv-preview-progress'),
        ),
        Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: '回到原局面',
              onPressed: cursor == 0 ? null : () => _jump(0),
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              tooltip: '上一步',
              onPressed: cursor == 0 ? null : () => _jump(cursor - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: timer == null ? '播放' : '暂停',
              onPressed: _toggle,
              icon: Icon(timer == null ? Icons.play_arrow : Icons.pause),
            ),
            IconButton(
              tooltip: '下一步',
              onPressed: cursor == value.length
                  ? null
                  : () => _jump(cursor + 1),
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: '到预览末尾',
              onPressed: cursor == value.length
                  ? null
                  : () => _jump(value.length),
              icon: const Icon(Icons.last_page),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _retire();
    },
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _jump(cursor - 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _jump(cursor + 1),
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: const Text('PV只读预览'),
          content: SizedBox(
            width: 640,
            height: 520,
            child: preview != null
                ? _body(context, preview!)
                : error != null
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(error!),
                        TextButton(
                          onPressed: () => unawaited(_load()),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          actions: [TextButton(onPressed: _close, child: const Text('关闭预览'))],
        ),
      ),
    ),
  );
}
