import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../application/app_preferences.dart';

/// A desktop workspace with four independent, accessible splitters.
/// The ranges are project geometry proposals; source-site endpoints remain U.
class ResizableWorkspace extends StatefulWidget {
  const ResizableWorkspace({
    super.key,
    required this.leftTop,
    required this.leftBottom,
    required this.board,
    required this.rightTop,
    required this.rightBottom,
    required this.rightHeader,
    this.layoutPreset = BoardLayoutPreset.centered,
  });

  final Widget leftTop;
  final Widget leftBottom;
  final Widget board;
  final Widget rightTop;
  final Widget rightBottom;
  final Widget rightHeader;
  final BoardLayoutPreset layoutPreset;

  @override
  State<ResizableWorkspace> createState() => _ResizableWorkspaceState();
}

class _ResizableWorkspaceState extends State<ResizableWorkspace> {
  static const _defaults = (
    left: 22.0,
    board: 70.0,
    leftSplit: 55.0,
    rightSplit: 55.0,
  );
  double _left = _defaults.left;
  double _board = _defaults.board;
  double _leftSplit = _defaults.leftSplit;
  double _rightSplit = _defaults.rightSplit;
  double _boardLeftShare = 45;

  void _reset() => setState(() {
    _left = _defaults.left;
    _board = _defaults.board;
    _leftSplit = _defaults.leftSplit;
    _rightSplit = _defaults.rightSplit;
    _boardLeftShare = 45;
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (widget.layoutPreset == BoardLayoutPreset.boardOnLeft) {
        return _buildBoardLeft(context, width);
      }
      final available = width - 96;
      const minBoardWidth = 492.0;
      const minRightWidth = 220.0;
      final maxLeft =
          ((available - minBoardWidth - minRightWidth) * 100 / available)
              .clamp(19, 34)
              .toDouble();
      final leftWidth = available * _left / 100;
      final rest = available - leftWidth;
      final boardMin = math.max(60, minBoardWidth * 100 / rest);
      final boardMax = math.min(80, (rest - minRightWidth) * 100 / rest);
      final boardShare = _board.clamp(boardMin, boardMax).toDouble();
      final boardWidth = rest * boardShare / 100;
      final rightWidth = rest - boardWidth;
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('reset-workspace-layout'),
              onPressed: _reset,
              icon: const Icon(Icons.restore),
              label: const Text('重置布局'),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: leftWidth,
                  child: Column(
                    children: [
                      Expanded(
                        flex: _leftSplit.round(),
                        key: const ValueKey('workspace-left-top'),
                        child: _scroll(widget.leftTop),
                      ),
                      _Splitter(
                        axis: Axis.vertical,
                        label: '调整左侧上下分区',
                        value: _leftSplit,
                        onChanged: (v) => setState(
                          () => _leftSplit = v.clamp(25, 72).toDouble(),
                        ),
                      ),
                      Expanded(
                        flex: 100 - _leftSplit.round(),
                        key: const ValueKey('workspace-left-bottom'),
                        child: _scroll(widget.leftBottom),
                      ),
                    ],
                  ),
                ),
                _Splitter(
                  axis: Axis.horizontal,
                  label: '调整左栏宽度',
                  value: _left,
                  onChanged: (v) {
                    final left = v.clamp(19, maxLeft).toDouble();
                    final nextRest = available * (100 - left) / 100;
                    final minBoard = math.max(
                      60,
                      minBoardWidth * 100 / nextRest,
                    );
                    final maxBoard = math.min(
                      80,
                      (nextRest - minRightWidth) * 100 / nextRest,
                    );
                    setState(() {
                      _left = left;
                      _board = _board.clamp(minBoard, maxBoard).toDouble();
                    });
                  },
                ),
                SizedBox(
                  key: const ValueKey('workspace-board-pane'),
                  width: boardWidth,
                  child: _scroll(
                    Align(alignment: Alignment.topCenter, child: widget.board),
                  ),
                ),
                _Splitter(
                  axis: Axis.horizontal,
                  label: '调整棋盘宽度',
                  value: boardShare,
                  onChanged: (v) => setState(
                    () => _board = v.clamp(boardMin, boardMax).toDouble(),
                  ),
                ),
                SizedBox(
                  key: const ValueKey('workspace-right-pane'),
                  width: rightWidth,
                  child: Column(
                    children: [
                      widget.rightHeader,
                      Expanded(
                        flex: _rightSplit.round(),
                        key: const ValueKey('workspace-right-top'),
                        child: _scroll(widget.rightTop),
                      ),
                      _Splitter(
                        axis: Axis.vertical,
                        label: '调整右侧引擎与云库上下分区',
                        value: _rightSplit,
                        onChanged: (v) => setState(
                          () => _rightSplit = v.clamp(25, 75).toDouble(),
                        ),
                      ),
                      Expanded(
                        flex: 100 - _rightSplit.round(),
                        key: const ValueKey('workspace-right-bottom'),
                        child: _scroll(widget.rightBottom),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _buildBoardLeft(BuildContext context, double width) {
    final available = width - 72;
    const minBoardWidth = 508.0;
    const maxBoardWidth = 556.0;
    const minRecordWidth = 220.0;
    const minRightWidth = 220.0;
    final minShare = minBoardWidth * 100 / available;
    final maxShare = math.min(
      maxBoardWidth * 100 / available,
      (available - minRecordWidth - minRightWidth) * 100 / available,
    );
    final boardWidth = (available * _boardLeftShare / 100)
        .clamp(minBoardWidth, math.min(maxBoardWidth, available - 440))
        .toDouble();
    final remaining = available - boardWidth;
    final recordsWidth = math.max(minRecordWidth, remaining * .38);
    final rightWidth = remaining - recordsWidth;
    final boardValue = boardWidth * 100 / available;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('reset-workspace-layout'),
            onPressed: _reset,
            icon: const Icon(Icons.restore),
            label: const Text('重置布局'),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: const ValueKey('workspace-board-pane'),
                width: boardWidth,
                child: _scroll(
                  Align(alignment: Alignment.topCenter, child: widget.board),
                ),
              ),
              _Splitter(
                axis: Axis.horizontal,
                label: '调整棋盘宽度',
                value: boardValue,
                minimum: minShare,
                maximum: maxShare,
                onChanged: (value) => setState(() {
                  _boardLeftShare = value.clamp(minShare, maxShare).toDouble();
                }),
              ),
              SizedBox(
                key: const ValueKey('workspace-middle-pane'),
                width: recordsWidth,
                child: Column(
                  children: [
                    Expanded(flex: 43, child: _scroll(widget.leftTop)),
                    Expanded(flex: 57, child: _scroll(widget.leftBottom)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                key: const ValueKey('workspace-right-pane'),
                width: rightWidth,
                child: Column(
                  children: [
                    widget.rightHeader,
                    Expanded(
                      flex: _rightSplit.round(),
                      key: const ValueKey('workspace-right-top'),
                      child: _scroll(widget.rightTop),
                    ),
                    _Splitter(
                      axis: Axis.vertical,
                      label: '调整右侧引擎与云库上下分区',
                      value: _rightSplit,
                      onChanged: (value) => setState(
                        () => _rightSplit = value.clamp(25, 75).toDouble(),
                      ),
                    ),
                    Expanded(
                      flex: 100 - _rightSplit.round(),
                      key: const ValueKey('workspace-right-bottom'),
                      child: _scroll(widget.rightBottom),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scroll(Widget child) => SingleChildScrollView(
    child: Padding(padding: const EdgeInsets.all(8), child: child),
  );
}

class _Splitter extends StatelessWidget {
  const _Splitter({
    required this.axis,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    this.maximum = 100,
  });

  final Axis axis;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double minimum;
  final double maximum;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    return SizedBox(
      width: horizontal ? 48 : double.infinity,
      height: horizontal ? double.infinity : 48,
      child: FocusableActionDetector(
        key: ValueKey(label),
        shortcuts: {
          if (horizontal)
            LogicalKeySet(LogicalKeyboardKey.arrowLeft): _Adjust(-1),
          if (horizontal)
            LogicalKeySet(LogicalKeyboardKey.arrowRight): _Adjust(1),
          if (!horizontal)
            LogicalKeySet(LogicalKeyboardKey.arrowUp): _Adjust(-1),
          if (!horizontal)
            LogicalKeySet(LogicalKeyboardKey.arrowDown): _Adjust(1),
        },
        actions: {
          _Adjust: CallbackAction<_Adjust>(
            onInvoke: (intent) {
              onChanged(value + intent.delta);
              return null;
            },
          ),
        },
        child: Semantics(
          slider: true,
          label: label,
          value: '${value.toStringAsFixed(0)}%',
          increasedValue: value < maximum
              ? '${math.min(value + 1, maximum).toStringAsFixed(0)}%'
              : null,
          decreasedValue: value > minimum
              ? '${math.max(value - 1, minimum).toStringAsFixed(0)}%'
              : null,
          hint: horizontal ? '使用左右方向键调整' : '使用上下方向键调整',
          onIncrease: value < maximum ? () => onChanged(value + 1) : null,
          onDecrease: value > minimum ? () => onChanged(value - 1) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: horizontal
                ? (d) => onChanged(value + d.delta.dx / 8)
                : null,
            onVerticalDragUpdate: horizontal
                ? null
                : (d) => onChanged(value + d.delta.dy / 8),
            child: MouseRegion(
              cursor: horizontal
                  ? SystemMouseCursors.resizeColumn
                  : SystemMouseCursors.resizeRow,
              child: Center(
                child: Container(
                  width: horizontal ? 4 : 36,
                  height: horizontal ? 36 : 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Adjust extends Intent {
  const _Adjust(this.delta);
  final double delta;
}
