import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/review_report.dart';
import 'board_arrows_painter.dart';

/// Original Material glyphs; grade is also exposed on the actual square.
IconData moveGradeIcon(MoveGrade grade) => switch (grade) {
  MoveGrade.best => Icons.star,
  MoveGrade.excellent => Icons.thumb_up,
  MoveGrade.good => Icons.check,
  MoveGrade.inaccuracy => Icons.question_mark,
  MoveGrade.mistake => Icons.priority_high,
  MoveGrade.blunder => Icons.close,
  MoveGrade.unrated => Icons.more_horiz,
};
Color moveGradeColor(MoveGrade grade) => switch (grade) {
  MoveGrade.best ||
  MoveGrade.excellent ||
  MoveGrade.good => const Color(0xff285b3a),
  MoveGrade.inaccuracy => const Color(0xff735300),
  MoveGrade.mistake || MoveGrade.blunder => const Color(0xffa02020),
  MoveGrade.unrated => const Color(0xff555555),
};
String moveGradeDescription(MoveAssessment row) =>
    '本机模型评级：${row.grade.label}，预期损失 ${row.lossPercent!.toStringAsFixed(2)} 个百分点';

class MoveGradeBadge extends StatelessWidget {
  const MoveGradeBadge({
    super.key,
    required this.square,
    required this.grade,
    this.flipped = false,
    this.mirrored = false,
  });
  final Square square;
  final MoveGrade grade;
  final bool flipped, mirrored;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final step = box.maxWidth / 9;
          final point = boardSquarePoint(
            square,
            box.biggest,
            flipped: flipped,
            mirrored: mirrored,
          );
          final size = step * .34;
          return Stack(
            children: [
              Positioned(
                left: point.dx + step * .28 - size / 2,
                top: point.dy - step * .28 - size / 2,
                width: size,
                height: size,
                child: DecoratedBox(
                  key: const ValueKey('move-grade-glyph'),
                  decoration: BoxDecoration(
                    color: moveGradeColor(grade),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    moveGradeIcon(grade),
                    size: size * .72,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
