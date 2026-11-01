import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

String pgn(
  String moves, {
  String extra = '',
  String format = 'ICCS',
  String result = '*',
}) =>
    '[Game "Chinese Chess"]\n[Result "$result"]\n${format.isEmpty ? '' : '[Format "$format"]\n'}$extra\n$moves';
void main() {
  test('ICCS parses canonical moves and immutable normalized metadata', () {
    final record = PgnCodec.parse(pgn('1. B2-E2 B9-C7 2. H2-H4 *'));
    expect(record.tree.path.skip(1).map((n) => n.move.toString()), [
      'b2e2',
      'b9c7',
      'h2h4',
    ]);
    expect(record.tags['FEN'], Position.initialFen);
    expect(record.result, '*');
    expect(() => record.tags['Event'] = 'mutate', throwsUnsupportedError);
    expect(
      PgnCodec.parse(pgn('1.b2e2 b9c7 2.h2h4 *')).tree.current.position.toFen(),
      record.tree.current.position.toFen(),
    );
  });
  test(
    'unknown unicode metadata, escaped quotes and backslashes survive roundtrip',
    () {
      final record = PgnCodec.parse(r'''[Game "Chinese Chess"]
[Format "ICCS"]
[Event "上海 \"友谊\" \\ club"]
[Custom_1 "资料😀"]
1. B2-E2 *''');
      expect(record.tags['Event'], '上海 "友谊" \\ club');
      final output = PgnCodec.path(record);
      expect(output.startsWith('[Game "Chinese Chess"]\n'), isTrue);
      final restored = PgnCodec.parse(output);
      expect(restored.tags, record.tags);
      expect(
        restored.tree.current.position.toFen(),
        record.tree.current.position.toFen(),
      );
    },
  );
  test('root, consecutive move and after-result comments are preserved', () {
    final record = PgnCodec.parse(
      pgn('{序言}\n1. B2-E2 {当头炮} {补充}\nB9-C7 * {尾注}'),
    );
    expect(record.tree.root.comment, '序言');
    expect(record.tree.node('n1').comment, '当头炮\n补充');
    expect(record.tree.current.comment, '尾注');
    for (final format in PgnMoveFormat.values) {
      final restored = PgnCodec.parse(PgnCodec.path(record, format: format));
      expect(
        restored.tree.path.map((n) => n.comment),
        record.tree.path.map((n) => n.comment),
      );
      expect(
        restored.tree.current.position.toFen(),
        record.tree.current.position.toFen(),
      );
    }
  });
  test(
    'omitted Format defaults to Chinese and coordinate grammar remains distinct',
    () {
      final record = PgnCodec.parse(pgn('1. 炮八平五 马２进３ *', format: ''));
      expect(record.tags['Format'], 'Chinese');
      expect(record.tree.current.move, Move.parse('b9c7'));
      expect(
        () => PgnCodec.parse(pgn('1. B2-E2 *', format: '')),
        throwsFormatException,
      );
      expect(() => PgnCodec.parse(pgn('1. 炮八平五 *')), throwsFormatException);
    },
  );
  test(
    'black-first custom round counter and PGN red-r alias normalize safely',
    () {
      final fen = Position.initialFen.replaceFirst(' w - - 0 1', ' b - - 0 42');
      final black = PgnCodec.parse(
        pgn('42... B9-C7 43. B0-C2 *', extra: '[FEN "$fen"]'),
      );
      final output = PgnCodec.path(black);
      expect(output, contains('42... B9-C7'));
      expect(output, contains('43. B0-C2'));
      expect(
        PgnCodec.parse(output).tree.current.position.toFen(),
        black.tree.current.position.toFen(),
      );
      final red = Position.initialFen.replaceFirst(' w ', ' r ');
      expect(
        PgnCodec.parse(
          pgn('1. B2-E2 *', extra: '[FEN "$red"]'),
        ).tree.root.position.toFen(),
        Position.initialFen,
      );
      expect(
        () => Position.fromFen(red),
        throwsFormatException,
      ); // Alias scoped to PGN.
    },
  );
  test(
    'path export excludes other branches and future but keeps selected comments and tags',
    () {
      var tree = GameTree().annotate('根');
      tree = tree
          .play(Move.parse('b2e2'))
          .annotate('主线')
          .play(Move.parse('b9c7'));
      tree = tree.goTo('n0').play(Move.parse('h2e2')).goTo('n1');
      final record = PgnRecord(tree: tree, tags: {'Red': '自制红方'});
      final before = tree.toJson();
      final restored = PgnCodec.parse(PgnCodec.path(record));
      expect(restored.tree.nodeCount, 2);
      expect(restored.tree.current.move, Move.parse('b2e2'));
      expect(restored.tree.current.comment, '主线');
      expect(restored.tags['Red'], '自制红方');
      expect(tree.toJson(), before);
    },
  );
  test(
    'brace comments require explicit omission instead of silent data repair',
    () {
      final record = PgnRecord(tree: GameTree().annotate('包含{原始}文字'));
      expect(() => PgnCodec.path(record), throwsFormatException);
      final restored = PgnCodec.parse(
        PgnCodec.path(record, includeComments: false),
      );
      expect(restored.tree.root.comment, isEmpty);
      expect(record.tree.root.comment, '包含{原始}文字');
    },
  );
  test(
    'declared resignation result remains metadata, independent of board terminal status',
    () {
      final record = PgnCodec.parse(pgn('1-0', result: '1-0'));
      expect(record.tree.root.position.boardOutcome().isTerminal, isFalse);
      expect(record.result, '1-0');
      expect(PgnCodec.parse(PgnCodec.path(record)).result, '1-0');
    },
  );
  test(
    'illegal moves, wrong counters, malformed headers and unsupported syntax fail explicitly',
    () {
      final invalid = [
        '',
        '[Event "x"] *',
        '[Game "Chess"] *',
        '[Game "Chinese Chess"]',
        '[Game "Chinese Chess"]\n[Game "Chinese Chess"] *',
        '[Game"Chinese Chess"] *',
        '[Game "Chinese Chess" *',
        '[Game "Chinese Chess"] [Event "unclosed] *',
        '[Game "Chinese Chess"] [Event "bad\\q"] *',
        '[Game "Chinese Chess"] [Event "line\nbreak"] *',
        pgn('1. B2-E2 *', result: '1-0'),
        pgn('1. B2-E2 * B9-C7'),
        pgn('1. B2-E2 B9-C7 *\n[Game "Chinese Chess"] *'),
        pgn('1. B2-E2 (1. H2-E2) *'),
        pgn('1. B2-E2 \$1 *'),
        pgn('1. B2-E2! *'),
        pgn('1. C2-E2 *'),
        pgn('1. B2-E2 A9-A6 *'),
        pgn('2. B2-E2 *'),
        pgn('1... B2-E2 *'),
        pgn('1. 1. B2-E2 *'),
        pgn('1. *'),
        pgn('1. B2-E2 * {unclosed'),
        pgn('{nested {x}} *'),
        pgn('} *'),
        pgn('*', format: 'WXF'),
        pgn('*', extra: '[FEN "not-a-fen"]'),
      ];
      for (final text in invalid) {
        expect(() => PgnCodec.parse(text), throwsFormatException, reason: text);
      }
    },
  );
  test(
    'bounds reject oversized input, metadata, merged comments and excessive plies',
    () {
      expect(
        () => PgnCodec.parse('x' * (PgnCodec.maxLength + 1)),
        throwsFormatException,
      );
      expect(
        () => PgnCodec.parse(pgn('*', extra: '[Event "${'x' * 4097}"]')),
        throwsFormatException,
      );
      final tags = List.generate(61, (i) => '[Tag$i "x"]').join('\n');
      expect(
        () => PgnCodec.parse(pgn('*', extra: tags)),
        throwsFormatException,
      );
      expect(
        () => PgnCodec.parse(pgn('{${'x' * 10001}} *')),
        throwsFormatException,
      );
      expect(
        () => PgnCodec.parse(pgn('{${'x' * 5001}} {${'y' * 5001}} *')),
        throwsFormatException,
      );
      final cycle = ['B0-C2', 'H9-G7', 'C2-B0', 'G7-H9'];
      final moves = List.generate(1999, (i) => cycle[i % 4]).join(' ');
      expect(PgnCodec.parse(pgn('$moves *')).tree.nodeCount, 2000);
      expect(
        () => PgnCodec.parse(pgn('$moves G7-H9 *')),
        throwsFormatException,
      );
    },
  );
  test(
    'bounded exporter rejects excessive output and mismatched typed metadata',
    () {
      var tree = GameTree();
      for (final move in [
        'h2e2',
        'b9c7',
        'b0c2',
        'h9g7',
        'a0a1',
        'i9i8',
        'a1a2',
      ]) {
        tree = tree.annotate('x' * 10000).play(Move.parse(move));
      }
      expect(() => PgnCodec.path(PgnRecord(tree: tree)), throwsFormatException);
      expect(
        () => PgnRecord(tree: GameTree(), tags: {'Game': 'Chess'}),
        throwsArgumentError,
      );
      expect(
        () => PgnRecord(tree: GameTree(), tags: {'Result': 'win'}),
        throwsArgumentError,
      );
      expect(
        () => PgnRecord(tree: GameTree(), tags: {'bad-name': 'x'}),
        throwsArgumentError,
      );
      final fen = Position.initialFen.replaceFirst(' w ', ' b ');
      expect(
        () => PgnRecord(tree: GameTree(), tags: {'FEN': fen}),
        throwsArgumentError,
      );
    },
  );
  test('typed metadata budgets and adjacent escaping also roundtrip', () {
    final full = PgnRecord(
      tree: GameTree(),
      tags: {for (var i = 0; i < 60; i++) 'Extra$i': '值'},
    );
    expect(full.tags.length, 64);
    expect(
      PgnCodec.parse(PgnCodec.path(full, format: PgnMoveFormat.chinese)).tags,
      full.tags,
    );
    expect(
      () => PgnRecord(
        tree: GameTree(),
        tags: {for (var i = 0; i < 61; i++) 'Extra$i': '值'},
      ),
      throwsArgumentError,
    );
    expect(
      () => PgnRecord(tree: GameTree(), tags: {'FEN': 'x' * 4097}),
      throwsArgumentError,
    );
    for (final value in ['"', '\\', r'\"', r'\\', '第一行😀']) {
      final record = PgnRecord(tree: GameTree(), tags: {'Event': value});
      expect(PgnCodec.parse(PgnCodec.path(record)).tags['Event'], value);
    }
  });
}
