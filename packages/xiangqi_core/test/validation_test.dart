import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'support/position_fixture.dart';

Set<PositionIssueCode> codes(Position p) =>
    p.validateForPlay().issues.map((i) => i.code).toSet();

void main() {
  test(
    'initial and legal opening positions pass validation without mutation',
    () {
      var p = Position.initial();
      for (final move in ['h2e2', 'b9c7', 'b0c2', 'h9g7']) {
        final before = p.toFen();
        expect(p.validateForPlay().isValid, isTrue);
        expect(p.toFen(), before);
        p = p.play(Move.parse(move));
      }
      expect(p.validateForPlay().isValid, isTrue);
    },
  );
  test('general and advisor points are checked for both sides', () {
    for (final turn in ['w', 'b']) {
      final p = board({'e0': '', 'c0': 'K', 'd1': 'A', 'd8': 'a'}, turn: turn);
      expect(codes(p), contains(PositionIssueCode.generalOutsidePalace));
      final issues = p
          .validateForPlay()
          .issues
          .where((i) => i.code == PositionIssueCode.advisorOffPoint)
          .toList();
      expect(issues.map((i) => i.side).toSet(), {Side.red, Side.black});
      expect(issues.expand((i) => i.squares).map((s) => s.toString()).toSet(), {
        'd1',
        'd8',
      });
    }
    expect(
      codes(board({'d2': 'A', 'e8': 'a'})),
      isNot(contains(PositionIssueCode.advisorOffPoint)),
    );
  });
  test(
    'elephants must occupy reachable home-side points, not just own half',
    () {
      expect(
        codes(board({'d2': 'B', 'd7': 'b'})),
        contains(PositionIssueCode.elephantOffPoint),
      );
      expect(
        codes(board({'c5': 'B', 'c4': 'b'})),
        contains(PositionIssueCode.elephantOffPoint),
      );
      expect(
        codes(board({'c4': 'B', 'g5': 'b'})),
        isNot(contains(PositionIssueCode.elephantOffPoint)),
      );
    },
  );
  test('piece count limits apply independently to each side', () {
    for (final symbol in ['R', 'N', 'C', 'A', 'B', 'r', 'n', 'c', 'a', 'b']) {
      final p = board({'a1': symbol, 'b1': symbol, 'c1': symbol});
      final issue = p.validateForPlay().issues.singleWhere(
        (i) => i.code == PositionIssueCode.tooManyPieces,
      );
      expect(issue.squares.length, 3);
      expect(
        issue.side,
        symbol == symbol.toUpperCase() ? Side.red : Side.black,
      );
    }
    expect(
      codes(board({'a5': 'P', 'b5': 'P', 'c5': 'P', 'd5': 'P', 'f5': 'P'})),
      contains(PositionIssueCode.tooManyPieces),
    ); // plus e5 default
  });
  test(
    'pawns cannot retreat behind initial rank or shift files before river',
    () {
      expect(
        codes(board({'a2': 'P', 'a7': 'p'})),
        contains(PositionIssueCode.pawnBeforeStartingRank),
      );
      expect(
        codes(board({'b3': 'P', 'b6': 'p'})),
        contains(PositionIssueCode.pawnOffStartingFile),
      );
      expect(
        codes(board({'b5': 'P', 'b4': 'p'})),
        isNot(contains(PositionIssueCode.pawnOffStartingFile)),
      );
      expect(
        codes(board({'a4': 'P', 'a5': 'p'})),
        isNot(contains(PositionIssueCode.pawnOffStartingFile)),
      );
    },
  );
  test(
    'facing generals rejected with both coordinates; blocker makes it pass',
    () {
      final issue = board({'e5': ''}).validateForPlay().issues.firstWhere(
        (i) => i.code == PositionIssueCode.facingGenerals,
      );
      expect(issue.squares.map((s) => s.toString()), ['e0', 'e9']);
      expect(board({}).validateForPlay().isValid, isTrue);
    },
  );
  test('two uncrossed pawns cannot originate on the same file', () {
    expect(
      codes(board({'a3': 'P', 'a4': 'P'})),
      contains(PositionIssueCode.duplicateUncrossedPawnFile),
    );
    expect(
      codes(board({'a6': 'p', 'a5': 'p'})),
      contains(PositionIssueCode.duplicateUncrossedPawnFile),
    );
    expect(
      codes(board({'a5': 'P', 'a6': 'P'})),
      isNot(contains(PositionIssueCode.duplicateUncrossedPawnFile)),
    );
  });
  test('moving side can be in check, non-moving side cannot', () {
    final pieces = {'e3': 'r'};
    expect(board(pieces).isInCheck(Side.red), isTrue);
    expect(board(pieces).validateForPlay().isValid, isTrue);
    final issues = board(pieces, turn: 'b').validateForPlay().issues;
    expect(issues.single.code, PositionIssueCode.nonMovingSideInCheck);
    expect(issues.single.side, Side.red);
    expect(issues.single.squares.single, Square.parse('e0'));
  });
  test('issue collections cannot be changed by editor clients', () {
    final result = board({'e5': ''}).validateForPlay();
    expect(() => result.issues.clear(), throwsUnsupportedError);
    expect(() => result.issues.first.squares.clear(), throwsUnsupportedError);
  });
}
