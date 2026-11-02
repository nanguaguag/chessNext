import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_appearance.dart';

class BoardArrowsPainter extends CustomPainter {
  const BoardArrowsPainter({
    this.recommendation,
    this.reply,
    this.flipped = false,
    this.mirrored = false,
    this.headStyle = ArrowHeadStyle.standard,
  });
  final Move? recommendation, reply;
  final bool flipped, mirrored;
  final ArrowHeadStyle headStyle;
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    if (step <= 0 || !step.isFinite) return;
    Offset location(Square square) => Offset(
      ((flipped != mirrored ? 8 - square.file : square.file) + .5) * step,
      ((flipped ? square.rank : 9 - square.rank) + .5) * step,
    );
    void arrow(Move move, Color color) {
      final from = location(move.from), to = location(move.to);
      final distance = (to - from).distance;
      if (distance == 0) return;
      final unit = (to - from) / distance;
      final start = from + unit * step * .3;
      final end = to - unit * step * .3;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      final halfWidth = switch (headStyle) {
        ArrowHeadStyle.sharp => .07,
        ArrowHeadStyle.standard => .12,
        ArrowHeadStyle.wide => .19,
      };
      final wing = Offset(-unit.dy, unit.dx) * step * halfWidth;
      final base = end - unit * step * .22;
      final head = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo((base + wing).dx, (base + wing).dy)
        ..lineTo((base - wing).dx, (base - wing).dy)
        ..close();
      canvas.drawPath(head, paint);
    }

    if (reply != null) arrow(reply!, const Color(0xff965ba3));
    if (recommendation != null) arrow(recommendation!, const Color(0xff226b9c));
  }

  @override
  bool shouldRepaint(covariant BoardArrowsPainter old) =>
      recommendation != old.recommendation ||
      reply != old.reply ||
      flipped != old.flipped ||
      mirrored != old.mirrored ||
      headStyle != old.headStyle;
}
