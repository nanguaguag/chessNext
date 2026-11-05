import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../application/board_skin_geometry.dart';

/// Project-designed draggable 9×10 grid calibration preview.
class BoardGeometryEditor extends StatefulWidget {
  const BoardGeometryEditor({
    super.key,
    required this.geometry,
    required this.onChanged,
    this.enabled = true,
  });

  final BoardSkinGeometry geometry;
  final ValueChanged<BoardSkinGeometry> onChanged;
  final bool enabled;

  @override
  State<BoardGeometryEditor> createState() => _BoardGeometryEditorState();
}

class _BoardGeometryEditorState extends State<BoardGeometryEditor> {
  late BoardSkinGeometry _geometry = widget.geometry;
  BoardSkinGeometry? _dragOriginGeometry;
  Offset? _dragOriginPosition;
  final FocusNode _topLeftFocus = FocusNode(debugLabel: '左上格点');
  final FocusNode _bottomRightFocus = FocusNode(debugLabel: '右下格点');

  @override
  void dispose() {
    _topLeftFocus.dispose();
    _bottomRightFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BoardGeometryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _geometry = widget.geometry;
  }

  void _move(
    double dx,
    double dy, {
    required bool topLeft,
    BoardSkinGeometry? base,
  }) {
    if (!widget.enabled) return;
    final current = base ?? _geometry;
    final next = topLeft
        ? current.copyWith(
            leftPercent: (current.leftPercent + dx).clamp(
              BoardSkinGeometry.minEdgePercent,
              current.rightPercent - BoardSkinGeometry.minSpanPercent,
            ),
            topPercent: (current.topPercent + dy).clamp(
              BoardSkinGeometry.minEdgePercent,
              current.bottomPercent - BoardSkinGeometry.minSpanPercent,
            ),
          )
        : current.copyWith(
            rightPercent: (current.rightPercent + dx).clamp(
              current.leftPercent + BoardSkinGeometry.minSpanPercent,
              BoardSkinGeometry.maxEdgePercent,
            ),
            bottomPercent: (current.bottomPercent + dy).clamp(
              current.topPercent + BoardSkinGeometry.minSpanPercent,
              BoardSkinGeometry.maxEdgePercent,
            ),
          );
    if (next == current) return;
    setState(() => _geometry = next);
    widget.onChanged(next);
  }

  void _startDrag(DragStartDetails details) {
    _dragOriginGeometry ??= _geometry;
    _dragOriginPosition ??= details.globalPosition;
  }

  void _updateDrag(
    DragUpdateDetails details,
    Size size, {
    required bool topLeft,
  }) {
    final originGeometry = _dragOriginGeometry;
    final originPosition = _dragOriginPosition;
    if (!widget.enabled ||
        size.width <= 0 ||
        size.height <= 0 ||
        originGeometry == null ||
        originPosition == null) {
      return;
    }
    final delta = details.globalPosition - originPosition;
    _move(
      delta.dx / size.width * 100,
      delta.dy / size.height * 100,
      topLeft: topLeft,
      base: originGeometry,
    );
  }

  void _endDrag() {
    _dragOriginGeometry = null;
    _dragOriginPosition = null;
  }

  KeyEventResult _onKey(
    FocusNode node,
    KeyEvent event, {
    required bool topLeft,
  }) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const Offset(-1, 0),
      LogicalKeyboardKey.arrowRight => const Offset(1, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, -1),
      LogicalKeyboardKey.arrowDown => const Offset(0, 1),
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    _move(delta.dx, delta.dy, topLeft: topLeft);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 9 / 10,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Semantics(
          label: '棋盘格点预览，九列十行',
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BoardGeometryPainter(
                    geometry: _geometry,
                    lineColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              _handle(
                context,
                size: size,
                topLeft: true,
                alignment: Alignment(
                  _geometry.leftPercent / 50 - 1,
                  _geometry.topPercent / 50 - 1,
                ),
              ),
              _handle(
                context,
                size: size,
                topLeft: false,
                alignment: Alignment(
                  _geometry.rightPercent / 50 - 1,
                  _geometry.bottomPercent / 50 - 1,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _handle(
    BuildContext context, {
    required Size size,
    required bool topLeft,
    required Alignment alignment,
  }) => Align(
    alignment: alignment,
    child: Focus(
      focusNode: topLeft ? _topLeftFocus : _bottomRightFocus,
      canRequestFocus: widget.enabled,
      onKeyEvent: (node, event) => _onKey(node, event, topLeft: topLeft),
      child: Semantics(
        container: true,
        focusable: widget.enabled,
        label: topLeft ? '左上格点' : '右下格点',
        value: topLeft
            ? '左 ${_geometry.leftPercent.toStringAsFixed(1)}%，上 ${_geometry.topPercent.toStringAsFixed(1)}%'
            : '右 ${_geometry.rightPercent.toStringAsFixed(1)}%，下 ${_geometry.bottomPercent.toStringAsFixed(1)}%',
        hint: '拖动或聚焦后使用方向键，每次移动1%；读屏可用方向操作调整',
        customSemanticsActions: widget.enabled
            ? {
                for (final direction in _directions)
                  CustomSemanticsAction(label: direction.label): () =>
                      _move(direction.dx, direction.dy, topLeft: topLeft),
              }
            : const {},
        child: Listener(
          onPointerDown: widget.enabled
              ? (event) {
                  _dragOriginGeometry = _geometry;
                  _dragOriginPosition = event.position;
                }
              : null,
          onPointerCancel: (_) => _endDrag(),
          onPointerUp: (_) => _endDrag(),
          child: GestureDetector(
            key: ValueKey(
              topLeft
                  ? 'board-grid-handle-top-left'
                  : 'board-grid-handle-bottom-right',
            ),
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled
                ? () => (topLeft ? _topLeftFocus : _bottomRightFocus)
                      .requestFocus()
                : null,
            onPanStart: widget.enabled ? _startDrag : null,
            onPanUpdate: widget.enabled
                ? (details) => _updateDrag(details, size, topLeft: topLeft)
                : null,
            onPanEnd: widget.enabled ? (_) => _endDrag() : null,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: const SizedBox(width: 18, height: 18),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  static const _directions = <({String label, double dx, double dy})>[
    (label: '格点左移1%', dx: -1, dy: 0),
    (label: '格点右移1%', dx: 1, dy: 0),
    (label: '格点上移1%', dx: 0, dy: -1),
    (label: '格点下移1%', dx: 0, dy: 1),
  ];
}

class _BoardGeometryPainter extends CustomPainter {
  const _BoardGeometryPainter({
    required this.geometry,
    required this.lineColor,
    required this.backgroundColor,
  });

  final BoardSkinGeometry geometry;
  final Color lineColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    final left = size.width * geometry.leftPercent / 100;
    final right = size.width * geometry.rightPercent / 100;
    final top = size.height * geometry.topPercent / 100;
    final bottom = size.height * geometry.bottomPercent / 100;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var column = 0; column < 9; column++) {
      final x = left + (right - left) * column / 8;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    for (var row = 0; row < 10; row++) {
      final y = top + (bottom - top) * row / 9;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardGeometryPainter oldDelegate) =>
      geometry != oldDelegate.geometry ||
      lineColor != oldDelegate.lineColor ||
      backgroundColor != oldDelegate.backgroundColor;
}
