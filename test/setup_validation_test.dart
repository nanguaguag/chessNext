import 'package:chess_next/chess_next.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editor can accept an initial setup through the application API', () {
    expect(Position.initial().validateForPlay().isValid, isTrue);
  });
  test('editor can explain facing generals without parsing native output', () {
    final p = Position.fromFen('4k4/9/9/9/9/9/9/9/9/4K4 w - - 0 1');
    final issue = p.validateForPlay().issues.firstWhere(
      (issue) => issue.code == PositionIssueCode.facingGenerals,
    );
    expect(issue.squares.map((s) => s.toString()), ['e0', 'e9']);
    expect(p.validateForPlay().isValid, isFalse);
  });
  test('parser success is distinct from setup validity', () {
    final p = Position.fromFen('4k4/9/9/9/4P4/9/9/9/9/2K6 w - - 0 1');
    expect(
      p.validateForPlay().issues.map((i) => i.code),
      contains(PositionIssueCode.generalOutsidePalace),
    );
  });
}
