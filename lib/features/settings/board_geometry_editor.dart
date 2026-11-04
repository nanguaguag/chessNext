import 'package:flutter/material.dart';

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

  @override
  void didUpdateWidget(covariant BoardGeometryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _geometry = widget.geometry;
  }

  void _drag(Offset delta, Size size, {required bool topLeft}) {
    if (!widget.enabled || size.width <= 0 || size.height <= 0) return;
    final current = _geometry;
    final dx = delta.dx / size.width * 100;
    final dy = delta.dy / size.height * 100;
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
    setState(() => _geometry = next);
    widget.onChanged(next);
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
    child: Semantics(
      label: topLeft ? '左上格点' : '右下格点',
      hint: '拖动以调整格网边距',
      child: GestureDetector(
        key: ValueKey(
          topLeft
              ? 'board-grid-handle-top-left'
              : 'board-grid-handle-bottom-right',
        ),
        behavior: HitTestBehavior.opaque,
        onPanUpdate: widget.enabled
            ? (details) => _drag(details.delta, size, topLeft: topLeft)
            : null,
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
  );
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
