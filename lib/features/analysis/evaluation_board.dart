import 'package:flutter/material.dart';
import '../../application/board_evaluation.dart';

class EvaluationBoard extends StatelessWidget {
  const EvaluationBoard({
    super.key,
    required this.evaluation,
    required this.child,
    this.flipped = false,
    this.visible = true,
  });
  final BoardEvaluation evaluation;
  final Widget child;
  final bool flipped, visible;
  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: (constraints.maxWidth - 28) * 10 / 9,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              key: const ValueKey('evaluation-strip'),
              label: '局势条',
              value: evaluation.description,
              container: true,
              liveRegion: false,
              child: ExcludeSemantics(
                child: Tooltip(
                  message: evaluation.description,
                  child: SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(flipped ? '红' : '黑'),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: evaluation.redRatio == null
                                ? ColoredBox(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: FittedBox(child: Text('?')),
                                    ),
                                  )
                                : CustomPaint(
                                    key: const ValueKey('evaluation-fill'),
                                    painter: EvaluationStripPainter(
                                      redRatio: evaluation.redRatio!,
                                      flipped: flipped,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(flipped ? '黑' : '红'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class EvaluationStripPainter extends CustomPainter {
  const EvaluationStripPainter({required this.redRatio, this.flipped = false})
    : assert(redRatio >= 0 && redRatio <= 1);
  final double redRatio;
  final bool flipped;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff333b37),
    );
    final height = size.height * redRatio;
    canvas.drawRect(
      Rect.fromLTWH(0, flipped ? 0 : size.height - height, size.width, height),
      Paint()..color = const Color(0xffab4039),
    );
  }

  @override
  bool shouldRepaint(covariant EvaluationStripPainter old) =>
      redRatio != old.redRatio || flipped != old.flipped;
}
