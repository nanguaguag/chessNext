import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/review_models.dart';

/// A compact evaluation chart, not a win-probability or accuracy estimate.
class ReviewChart extends StatefulWidget {
  const ReviewChart({
    super.key,
    required this.line,
    required this.results,
    required this.cursorId,
    required this.onNavigate,
  });
  final List<GameNode> line;
  final Map<String, ReviewedPosition> results;
  final String cursorId;
  final ValueChanged<String> onNavigate;
  @override
  State<ReviewChart> createState() => _ReviewChartState();
}

class _ReviewChartState extends State<ReviewChart> {
  final focus = FocusNode();
  bool focused = false;
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  int get selected =>
      math.max(0, widget.line.indexWhere((n) => n.id == widget.cursorId));
  void select(int index) {
    if (widget.line.isEmpty) return;
    widget.onNavigate(widget.line[index.clamp(0, widget.line.length - 1)].id);
  }

  String label(int index) {
    index = index.clamp(0, widget.line.length - 1);
    final node = widget.line[index];
    final move = node.move;
    final notation = move == null
        ? '开始'
        : '$index. ${ChineseNotation.format(widget.line[index - 1].position, move)}';
    return '$notation，${widget.results[node.id]?.label ?? '未分析'}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.line.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final index = selected;
    final points = widget.line
        .map((n) => widget.results[n.id])
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('局势曲线 · 红方视角'),
        const Text('纵轴为兵值，±10封顶；三角为杀棋，无评分处断线，杀棋0仅显示文字；上下界用箭头标记。'),
        Focus(
          focusNode: focus,
          onFocusChange: (value) => setState(() => focused = value),
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            if (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isAltPressed) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              select(index - 1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              select(index + 1);
            } else if (event.logicalKey == LogicalKeyboardKey.home) {
              select(0);
            } else if (event.logicalKey == LogicalKeyboardKey.end) {
              select(widget.line.length - 1);
            } else {
              return KeyEventResult.ignored;
            }
            return KeyEventResult.handled;
          },
          child: Semantics(
            label: '局势曲线，左右方向键选择着法',
            value: label(index),
            increasedValue: index < widget.line.length - 1
                ? label(index + 1)
                : null,
            decreasedValue: index > 0 ? label(index - 1) : null,
            onIncrease: index < widget.line.length - 1
                ? () => select(index + 1)
                : null,
            onDecrease: index > 0 ? () => select(index - 1) : null,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                key: const ValueKey('review-chart'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  focus.requestFocus();
                  final area = ReviewChartPainter.area(
                    Size(constraints.maxWidth, 180),
                  );
                  final t =
                      ((details.localPosition.dx - area.left) / area.width)
                          .clamp(0.0, 1.0);
                  select((t * (widget.line.length - 1)).round());
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: focused ? scheme.primary : scheme.outlineVariant,
                      width: focused ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 180),
                    painter: ReviewChartPainter(
                      points: points,
                      selected: index,
                      curve: scheme.primary,
                      axis: scheme.outlineVariant,
                      text: scheme.onSurface,
                      surface: scheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(label(index), key: const ValueKey('review-chart-selection')),
        Slider(
          value: index.toDouble(),
          min: 0,
          max: math.max(1, widget.line.length - 1).toDouble(),
          divisions: math.max(1, widget.line.length - 1),
          label: label(index),
          semanticFormatterCallback: (value) => label(value.round()),
          onChanged: widget.line.length < 2
              ? null
              : (value) => select(value.round()),
        ),
      ],
    );
  }
}

class ReviewChartPainter extends CustomPainter {
  ReviewChartPainter({
    required this.points,
    required this.selected,
    required this.curve,
    required this.axis,
    required this.text,
    required this.surface,
  });
  final List<ReviewedPosition?> points;
  final int selected;
  final Color curve, axis, text, surface;
  static Rect area(Size size) =>
      Rect.fromLTRB(32, 14, math.max(33, size.width - 12), size.height - 24);
  static double? ordinate(ReviewedPosition? point) {
    final score = point?.redScore;
    if (score == null) return null;
    if (point!.info!.isMate && score == 0) return null;
    if (point.info!.isMate) {
      return score > 0
          ? 1
          : score < 0
          ? -1
          : 0;
    }
    return (score / 1000).clamp(-1.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = area(size);
    final grid = Paint()
      ..color = axis
      ..strokeWidth = 1;
    for (final level in [-1, 0, 1]) {
      final y = rect.center.dy - level * rect.height / 2;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      final painter = TextPainter(
        text: TextSpan(
          text: '${level * 10}',
          style: TextStyle(color: text, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(2, y - painter.height / 2));
    }
    if (points.isEmpty) return;
    Offset position(int i, double y) => Offset(
      points.length == 1
          ? rect.center.dx
          : rect.left + i * rect.width / (points.length - 1),
      rect.center.dy - y * rect.height / 2,
    );
    final path = Path();
    var connected = false;
    for (var i = 0; i < points.length; i++) {
      final y = ordinate(points[i]);
      if (y == null) {
        connected = false;
        continue;
      }
      final p = position(i, y);
      if (connected) {
        path.lineTo(p.dx, p.dy);
      } else {
        path.moveTo(p.dx, p.dy);
      }
      connected = true;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = curve
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final y = ordinate(point);
      if (y == null) continue;
      final p = position(i, y);
      final paint = Paint()
        ..color = curve
        ..strokeWidth = 1.5;
      if (point!.info!.isMate) {
        final triangle = Path()
          ..moveTo(p.dx, p.dy - 4)
          ..lineTo(p.dx - 4, p.dy + 4)
          ..lineTo(p.dx + 4, p.dy + 4)
          ..close();
        canvas.drawPath(triangle, paint);
      } else {
        canvas.drawCircle(p, i == selected ? 4 : 2, Paint()..color = surface);
        canvas.drawCircle(
          p,
          i == selected ? 4 : 2,
          paint..style = PaintingStyle.stroke,
        );
      }
      if (point.redBound != null) {
        final direction = point.redBound == 'lower' ? -1 : 1;
        final end = Offset(p.dx, p.dy + direction * 9);
        canvas.drawLine(p, end, paint);
        canvas.drawLine(end, Offset(end.dx - 3, end.dy - direction * 3), paint);
        canvas.drawLine(end, Offset(end.dx + 3, end.dy - direction * 3), paint);
      }
    }
    final x = position(selected.clamp(0, points.length - 1), 0).dx;
    canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
  }

  @override
  bool shouldRepaint(covariant ReviewChartPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.curve != curve ||
      old.axis != axis ||
      old.text != text ||
      old.surface != surface;
}
