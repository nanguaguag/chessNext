import 'package:flutter/material.dart';
import '../../application/current_move_arrows.dart';
import '../../application/board_appearance.dart';
import 'board_arrows_painter.dart';

class VariationArrowsPainter extends CustomPainter {
  const VariationArrowsPainter({
    required this.arrows,
    this.flipped = false,
    this.mirrored = false,
    this.headStyle = ArrowHeadStyle.standard,
  });
  final List<VariationArrow> arrows;
  final bool flipped, mirrored;
  final ArrowHeadStyle headStyle;
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    if (step <= 0 || !step.isFinite) return;
    for (final arrow in arrows.take(CurrentMoveArrows.maxVisible)) {
      final color = arrow.selected
          ? const Color(0xcc527637)
          : const Color(0x9954773e);
      BoardArrowsPainter(
        recommendation: arrow.move,
        recommendationColor: color,
        flipped: flipped,
        mirrored: mirrored,
        headStyle: headStyle,
      ).paint(canvas, size);
      final from = boardSquarePoint(
        arrow.move.from,
        size,
        flipped: flipped,
        mirrored: mirrored,
      );
      final to = boardSquarePoint(
        arrow.move.to,
        size,
        flipped: flipped,
        mirrored: mirrored,
      );
      final center = Offset.lerp(from, to, .65)!;
      final radius = step * .13;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xff527637),
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${arrow.number}',
          style: TextStyle(color: Colors.white, fontSize: radius * 1.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final scale = (radius * 1.7 / text.width).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant VariationArrowsPainter old) =>
      !identical(arrows, old.arrows) ||
      flipped != old.flipped ||
      mirrored != old.mirrored ||
      headStyle != old.headStyle;
}
