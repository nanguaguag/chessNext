import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test(
    'draft edits do not mutate the original position and can be incomplete',
    () {
      final original = Position.initial();
      final draft = SetupDraft.fromPosition(
        original,
      ).place(Square.parse('e0'), null);
      expect(
        draft.validation.issues.single.code,
        PositionIssueCode.missingGeneral,
      );
      expect(() => draft.toPosition(), throwsArgumentError);
      expect(original.toFen(), Position.initialFen);
      expect(
        draft
            .place(Square.parse('e0'), const Piece(Side.red, PieceType.general))
            .validation
            .isValid,
        isTrue,
      );
    },
  );
  test('clear preserves turn, while initial resets to red, matching E10', () {
    final draft = SetupDraft.fromPosition(
      Position.initial(),
    ).withTurn(Side.black).clear();
    expect(draft.turn, Side.black);
    expect(draft.at(Square.parse('d9'))?.type, PieceType.general);
    expect(draft.at(Square.parse('e0'))?.type, PieceType.general);
    expect(draft.validation.isValid, isTrue);
    expect(draft.initial().turn, Side.red);
  });
  test('swap mirrors ranks, swaps colors and side, retaining the file', () {
    final draft = SetupDraft.fromPosition(Position.initial()).clear();
    final swapped = draft.swapSides();
    expect(swapped.at(Square.parse('d0'))?.side, Side.red);
    expect(swapped.at(Square.parse('e9'))?.side, Side.black);
    expect(swapped.turn, Side.black);
    expect(swapped.swapSides().toFen(), draft.toFen());
  });
  test(
    'free piece placement reports invalid geometry, counts and facing generals',
    () {
      final base = SetupDraft.fromPosition(Position.initial()).clear();
      expect(
        base
            .move(Square.parse('d9'), Square.parse('e9'))
            .validation
            .issues
            .map((i) => i.code),
        contains(PositionIssueCode.facingGenerals),
      );
      final extra = base.place(
        Square.parse('f0'),
        const Piece(Side.red, PieceType.general),
      );
      expect(
        extra.validation.issues.single.code,
        PositionIssueCode.tooManyPieces,
      );
      expect(
        () => base.move(Square.parse('a0'), Square.parse('b0')),
        throwsArgumentError,
      );
    },
  );
  test(
    'structural FEN may populate an invalid editor draft but not a play position',
    () {
      const empty = '9/9/9/9/9/9/9/9/9/9 w - - 0 1';
      expect(SetupDraft.fromFen(empty).validation.issues.length, 2);
      expect(() => Position.fromFen(empty), throwsFormatException);
      expect(() => SetupDraft.fromFen('x' * 5000), throwsFormatException);
    },
  );
}
