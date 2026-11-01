import 'dart:math';
import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

SetupDraft base() => SetupDraft.fromPosition(Position.initial()).clear();
void main() {
  test('published coordinate examples render canonical Chinese notation', () {
    var position = Position.initial();
    final examples = {
      'h2e2': '炮二平五',
      'h7e7': '炮８平５',
      'e2e6': '炮五进四',
      'd9e8': '士４进５',
      'h0g2': '马二进三',
      'h9g7': '马８进７',
      'b2e2': '炮八平五',
      'b9c7': '马２进３',
      'e6e4': '前炮退二',
      'i9h9': '车９平８',
    };
    for (final entry in examples.entries) {
      final move = Move.parse(entry.key);
      expect(ChineseNotation.format(position, move), entry.value);
      expect(ChineseNotation.parse(position, entry.value), move);
      position = position.play(move);
    }
  });
  test('advisors and elephants on the same file retain file numbers', () {
    final advisors = base()
        .place(Square.parse('d0'), const Piece(Side.red, PieceType.advisor))
        .place(Square.parse('d2'), const Piece(Side.red, PieceType.advisor))
        .toPosition();
    expect(ChineseNotation.format(advisors, Move.parse('d0e1')), '仕六进五');
    expect(ChineseNotation.format(advisors, Move.parse('d2e1')), '仕六退五');
    final elephants = base()
        .place(Square.parse('c0'), const Piece(Side.red, PieceType.elephant))
        .place(Square.parse('c4'), const Piece(Side.red, PieceType.elephant))
        .toPosition();
    expect(ChineseNotation.format(elephants, Move.parse('c0e2')), '相七进五');
    expect(ChineseNotation.format(elephants, Move.parse('c4e2')), '相七退五');
  });
  test(
    'three and four tandem pawns use front-middle-rear or Chinese indices',
    () {
      var draft = base();
      for (final square in ['a5', 'a6', 'a7']) {
        draft = draft.place(
          Square.parse(square),
          const Piece(Side.red, PieceType.pawn),
        );
      }
      final three = draft.toPosition();
      expect(ChineseNotation.format(three, Move.parse('a7b7')), '前兵平八');
      expect(ChineseNotation.format(three, Move.parse('a6b6')), '中兵平八');
      expect(ChineseNotation.format(three, Move.parse('a5b5')), '后兵平八');
      final four = draft
          .place(Square.parse('a8'), const Piece(Side.red, PieceType.pawn))
          .toPosition();
      expect(ChineseNotation.format(four, Move.parse('a8b8')), '一兵平八');
      expect(ChineseNotation.format(four, Move.parse('a5b5')), '四兵平八');
    },
  );
  test(
    'multiple tandem files number only stacked pawns from right to left',
    () {
      var draft = base()
          .move(Square.parse('e0'), Square.parse('d0'))
          .move(Square.parse('d9'), Square.parse('e9'));
      for (final square in ['f8', 'f6', 'e7', 'd8', 'd6']) {
        draft = draft.place(
          Square.parse(square),
          const Piece(Side.red, PieceType.pawn),
        );
      }
      final position = draft.toPosition();
      for (final entry in {
        'f8e8': '一兵平五',
        'f6e6': '二兵平五',
        'e7e8': '兵五进一',
        'd8e8': '三兵平五',
        'd6e6': '四兵平五',
      }.entries) {
        expect(
          ChineseNotation.format(position, Move.parse(entry.key)),
          entry.value,
        );
        expect(
          ChineseNotation.parse(position, entry.value),
          Move.parse(entry.key),
        );
      }
      final swapped = draft.swapSides().toPosition();
      expect(ChineseNotation.format(swapped, Move.parse('d1e1')), '一卒平５');
    },
  );
  test('traditional aliases and digit width resolve legal candidates only', () {
    expect(
      ChineseNotation.parse(Position.initial(), '馬二進三'),
      Move.parse('h0g2'),
    );
    expect(
      ChineseNotation.parse(Position.initial(), '砲2平5'),
      Move.parse('h2e2'),
    );
    expect(
      () => ChineseNotation.parse(Position.initial(), '車九進九'),
      throwsFormatException,
    );
    final tree = TextRecord.parse('1. 炮二平五 馬２進３\n2. 馬二進三 車１平２');
    expect(tree.path.length, 5);
    expect(
      TextRecord.parse(
        TextRecord.path(tree, chinese: true),
      ).current.position.toFen(),
      tree.current.position.toFen(),
    );
    expect(TextRecord.parse('startpos moves H2-E2 B9-C7').path.length, 3);
  });
  test(
    'legal moves remain uniquely reversible over deterministic played positions',
    () {
      var position = Position.initial();
      final random = Random(281);
      for (var ply = 0; ply < 16; ply++) {
        final legal = position.legalMoves.toList();
        if (legal.isEmpty) break;
        for (final move in legal) {
          expect(
            ChineseNotation.parse(
              position,
              ChineseNotation.format(position, move),
            ),
            move,
          );
        }
        position = position.play(legal[random.nextInt(legal.length)]);
      }
    },
  );
}
