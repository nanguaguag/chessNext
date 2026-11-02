import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/analysis_history.dart';
import '../../application/pv_preview.dart';
import '../../application/pv_prefix_action.dart';
import '../board/xiangqi_board.dart';

enum PvPreviewExit { applied }

class PvPreviewDialog extends StatefulWidget {
  const PvPreviewDialog({
    super.key,
    required this.entry,
    this.flipped = false,
    this.loader = PvPreview.prepareInWorker,
    this.action,
    this.sourceChanges,
  });
  final PvHistoryEntry entry;
  final bool flipped;
  final PvPreviewLoader loader;
  final PvPrefixAction? action;
  final Listenable? sourceChanges;
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
  bool applying = false;
  PvApplyResult? applyResult;
  PvApplyCancellation? applyCancellation;
  final scroll = ScrollController();
  final applyMessageKey = GlobalKey();
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
    if (value == null || closed || applying) return;
    _stop();
    setState(() => cursor = target.clamp(0, value.length));
  }

  void _toggle() {
    final value = preview;
    if (value == null || closed || applying) return;
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
    applyCancellation?.cancel();
    generation++;
    _stop();
  }

  void _close() {
    _retire();
    Navigator.pop(context);
  }

  Future<void> _applyPrefix() async {
    final action = widget.action;
    if (action == null ||
        preview == null ||
        applying ||
        cursor == 0 ||
        !action.isCurrent) {
      return;
    }
    final plies = cursor, task = ++generation;
    final cancellation = PvApplyCancellation();
    applyCancellation = cancellation;
    _stop();
    setState(() {
      applying = true;
      applyResult = null;
    });
    PvApplyResult result;
    try {
      result = await action.apply(plies, cancellation);
    } catch (_) {
      result = PvApplyResult.failed;
    }
    if (!mounted ||
        closed ||
        generation != task ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (result == PvApplyResult.applied) {
      _retire();
      Navigator.pop(context, PvPreviewExit.applied);
    } else {
      setState(() {
        applying = false;
        applyResult = result;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messageContext = applyMessageKey.currentContext;
        if (mounted && !closed && messageContext != null) {
          unawaited(Scrollable.ensureVisible(messageContext));
        }
      });
    }
  }

  String _applyMessage(PvApplyResult result) => switch (result) {
    PvApplyResult.applied => '已应用所选PV前缀',
    PvApplyResult.stale => '来源局面或棋谱已变化，请重新打开预览',
    PvApplyResult.cancelled => '操作已取消，棋谱未改变',
    PvApplyResult.invalid => '所选PV路径无效，棋谱未改变',
    PvApplyResult.capacity => '应用后超过2000节点限制，棋谱未改变',
    PvApplyResult.stopFailed => '停止引擎失败，棋谱未改变，请重试',
    PvApplyResult.failed => 'PV处理失败，棋谱未改变，请重试',
    PvApplyResult.busy => '正在处理所选PV，请稍候',
  };

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
        onPressed: applying ? null : () => _jump(index + 1),
        child: Text(
          '${index + 1}. ${value.notation[index]}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final header = <Widget>[
      Text(
        '${_scoreLabel()} · 深度${value.entry.info.depth} · 变化${value.entry.info.multiPv} · 未写入棋谱',
      ),
      Text('来源：${value.entry.sourceLabel}'),
      if (value.entry.truncated)
        Text('仅预览前128步（原PV共${value.entry.originalPvLength}步）'),
      if (widget.action != null) ...[
        const Text('走到棋盘上将暂停计算，仅应用当前所选前缀。'),
        if (!widget.action!.isCurrent && !applying)
          const Text(
            '请返回来源着法后重开预览；来源已删除时仅可查看',
            key: ValueKey('pv-apply-stale'),
          ),
        if (applying) const LinearProgressIndicator(),
        if (applyResult != null)
          Text(_applyMessage(applyResult!), key: applyMessageKey),
      ],
      const SizedBox(height: 8),
    ];
    final progress = Text(
      '$cursor / ${value.length}',
      key: const ValueKey('pv-preview-progress'),
    );
    final controls = Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: '回到原局面',
          onPressed: applying || cursor == 0 ? null : () => _jump(0),
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: '上一步',
          onPressed: applying || cursor == 0 ? null : () => _jump(cursor - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: timer == null ? '播放' : '暂停',
          onPressed: applying ? null : _toggle,
          icon: Icon(timer == null ? Icons.play_arrow : Icons.pause),
        ),
        IconButton(
          tooltip: '下一步',
          onPressed: applying || cursor == value.length
              ? null
              : () => _jump(cursor + 1),
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: '到预览末尾',
          onPressed: applying || cursor == value.length
              ? null
              : () => _jump(value.length),
          icon: const Icon(Icons.last_page),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 560 ||
            constraints.maxHeight < 500 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        if (compact) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...header,
                SizedBox(height: 300, child: board),
                const SizedBox(height: 8),
                SizedBox(height: 200, child: moves),
                progress,
                controls,
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...header,
            Expanded(
              child: Row(
                children: [
                  Expanded(child: board),
                  const SizedBox(width: 12),
                  Expanded(child: moves),
                ],
              ),
            ),
            progress,
            controls,
          ],
        );
      },
    );
  }

  Widget _dialog(BuildContext context) => PopScope<PvPreviewExit>(
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
          title: const Text('PV预览'),
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
          actions: [
            if (widget.action != null)
              FilledButton(
                key: const ValueKey('pv-apply-prefix'),
                onPressed:
                    preview == null ||
                        applying ||
                        cursor == 0 ||
                        !widget.action!.isCurrent
                    ? null
                    : () => unawaited(_applyPrefix()),
                child: Text(applying ? '正在处理…' : '走到棋盘上'),
              ),
            TextButton(onPressed: _close, child: const Text('关闭预览')),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => widget.sourceChanges == null
      ? _dialog(context)
      : ListenableBuilder(
          listenable: widget.sourceChanges!,
          builder: (context, _) => _dialog(context),
        );
}
