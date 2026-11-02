import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_appearance.dart';
import 'board_arrows_painter.dart';

/// Presentation only: no move submission, engine access or document mutation.
class LastMoveMarkers extends StatefulWidget {
  const LastMoveMarkers({
    super.key,
    required this.move,
    required this.identity,
    required this.style,
    this.animateOnMount = false,
    this.flipped = false,
    this.mirrored = false,
  });
  final Move move;
  final Object identity;
  final LastMoveMarkerStyle style;
  final bool animateOnMount;
  final bool flipped, mirrored;
  @override
  State<LastMoveMarkers> createState() => _LastMoveMarkersState();
}

class _LastMoveMarkersState extends State<LastMoveMarkers>
    with SingleTickerProviderStateMixin {
  late final AnimationController rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1,
  );
  bool reducedMotion = false;
  bool motionInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      rotation.value = 1;
    } else if (!motionInitialized &&
        widget.animateOnMount &&
        widget.style == LastMoveMarkerStyle.halo) {
      rotation.forward(from: 0);
    }
    motionInitialized = true;
  }

  @override
  void didUpdateWidget(covariant LastMoveMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != oldWidget.style ||
        widget.identity != oldWidget.identity ||
        widget.move != oldWidget.move) {
      if (widget.style == LastMoveMarkerStyle.halo && !reducedMotion) {
        rotation.forward(from: 0);
      } else {
        rotation.value = 1;
      }
    }
  }

  @override
  void dispose() {
    rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '最后一步：${widget.move.from}至${widget.move.to}',
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: rotation,
        builder: (context, _) => CustomPaint(
          key: const ValueKey('last-move-markers'),
          painter: LastMoveMarkersPainter(
            move: widget.move,
            style: widget.style,
            phase: rotation.value,
            flipped: widget.flipped,
            mirrored: widget.mirrored,
          ),
        ),
      ),
    ),
  );
}

class LastMoveMarkersPainter extends CustomPainter {
  const LastMoveMarkersPainter({
    required this.move,
    required this.style,
    this.phase = 1,
    this.flipped = false,
    this.mirrored = false,
  });
  final Move move;
  final LastMoveMarkerStyle style;
  final double phase;
  final bool flipped, mirrored;
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    if (step <= 0 || !step.isFinite) return;
    Offset point(Square square) =>
        boardSquarePoint(square, size, flipped: flipped, mirrored: mirrored);
    final path = Path()
      ..addOval(Rect.fromCircle(center: point(move.from), radius: step * .14));
    final end = point(move.to);
    if (style == LastMoveMarkerStyle.halo) {
      final rect = Rect.fromCircle(center: end, radius: step * .45);
      for (var i = 0; i < 4; i++) {
        path.addArc(rect, phase * 2 * math.pi + i * math.pi / 2, math.pi / 3);
      }
    } else {
      final rect = Rect.fromCircle(center: end, radius: step * .44);
      final length = step * .17;
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
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xff294d36)
      ..strokeWidth = 4;
    canvas.drawPath(path, paint);
    paint
      ..color = const Color(0xfffff9de)
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LastMoveMarkersPainter old) =>
      move != old.move ||
      style != old.style ||
      phase != old.phase ||
      flipped != old.flipped ||
      mirrored != old.mirrored;
}
