import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test('FEN and UCI position text roundtrip the root-to-cursor path', () {
    final tree = TextRecord.parse('position startpos moves h2e2\n b9c7');
    expect(tree.path.length, 3);
    expect(
      TextRecord.parse(TextRecord.path(tree)).current.position.toFen(),
      tree.current.position.toFen(),
    );
    expect(
      TextRecord.parse(Position.initialFen).root.position.toFen(),
      Position.initialFen,
    );
    expect(
      TextRecord.parse(
        'position fen ${Position.initialFen} moves h2e2',
      ).path.length,
      2,
    );
    expect(
      TextRecord.parse(
        '${Position.initialFen.split(' ').take(2).join(' ')}',
      ).root.position.toFen(),
      Position.initialFen,
    );
  });
  test(
    'invalid roots and moves fail atomically and identify the offending ply',
    () {
      for (final text in [
        '',
        'https://example.com',
        '9/9/9/9/9/9/9/9/9/9 w',
        'x' * 64001,
        'startpos moves h2e2 moves b9c7',
      ]) {
        expect(() => TextRecord.parse(text), throwsFormatException);
      }
      expect(
        () => TextRecord.parse('startpos moves h2e2 broken'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('第2步'),
          ),
        ),
      );
      expect(
        () => TextRecord.parse('startpos moves a0a9'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('第1步不合法'),
          ),
        ),
      );
      expect(
        () => TextRecord.parse(
          'startpos moves ${List.filled(2000, 'h2e2').join(' ')}',
        ),
        throwsFormatException,
      );
    },
  );
  test('path export explicitly excludes alternative branches and comments', () {
    var tree = GameTree().play(Move.parse('h2e2')).annotate('test');
    tree = tree.goTo('n0').play(Move.parse('b2e2'));
    expect(TextRecord.path(tree), '${Position.initialFen} moves b2e2');
    final imported = TextRecord.parse(TextRecord.path(tree));
    expect(imported.nodeCount, 2);
    expect(imported.current.comment, isEmpty);
  });
}
