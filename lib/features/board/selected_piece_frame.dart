import 'package:flutter/material.dart';

/// Selection stays attached to the intersection, independent of piece scale.
class SelectedPieceFramePainter extends CustomPainter {
  const SelectedPieceFramePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width;
    if (step <= 0 || !step.isFinite) return;
    final rect = (Offset.zero & size).deflate(step * .05);
    final length = step * .18;
    final path = Path();
    for (final (x, y, sx, sy) in [
      (rect.left, rect.top, 1, 1),
      (rect.right, rect.top, -1, 1),
      (rect.left, rect.bottom, 1, -1),
      (rect.right, rect.bottom, -1, -1),
    ]) {
      path
        ..moveTo(x + sx * length, y)
        ..lineTo(x, y)
        ..lineTo(x, y + sy * length);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xfffff9de);
    canvas.drawPath(path, paint);
    paint
      ..strokeWidth = 2
      ..color = const Color(0xff24613c);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SelectedPieceFramePainter oldDelegate) => false;
}
