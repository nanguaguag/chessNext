import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test('immutable equality and hash ignore tag insertion order', () {
    final raw = {'Red': '红方', 'Extra': '保留'};
    final value = GameMetadata(raw);
    raw['Red'] = '外部修改';
    final same = GameMetadata({'Extra': '保留', 'Red': '红方'});
    expect(value, same);
    expect(value.hashCode, same.hashCode);
    expect(value.tags['Red'], '红方');
    expect(() => value.tags['Black'] = 'mutate', throwsUnsupportedError);
    expect(GameMetadata({}), GameMetadata.empty);
    expect(GameMetadata.empty.result, '*');
  });
  test(
    'edits preserve unknown tags and explicit null removes only that field',
    () {
      final original = GameMetadata({
        'Event': '赛事',
        'Extra': '未知',
        'Result': '1-0',
      });
      final edited = original.copyWith({'Event': null, 'Red': '棋手'});
      expect(edited.tags, {'Extra': '未知', 'Result': '1-0', 'Red': '棋手'});
      expect(original.tags['Event'], '赛事');
      expect(GameMetadata.fromJson(edited.toJson()), edited);
    },
  );
  test('bounds and typed declarations reject malformed input', () {
    for (final raw in <Map<String, String>>[
      {'bad-key': 'x'},
      {'Event': 'x\ny'},
      {'Event': 'x' * 4097},
      {'Result': 'win'},
      {'Game': 'Chess'},
      {for (var i = 0; i < 65; i++) 'X$i': 'x'},
    ]) {
      expect(() => GameMetadata(raw), throwsArgumentError);
    }
    for (final raw in <Object?>[
      null,
      <Object?>[],
      {'Event': 1},
      {'Result': 'bad'},
      {1: 'x'},
    ]) {
      expect(() => GameMetadata.fromJson(raw), throwsFormatException);
    }
    expect(
      GameMetadata({for (var i = 0; i < 64; i++) 'X$i': 'x'}).tags.length,
      64,
    );
  });
  test(
    'opaque format tags remain available to the appropriate notation codec',
    () {
      final value = GameMetadata({
        'FEN': '原始资料',
        'Format': 'FutureCodec',
        'Custom': '标记',
      });
      expect(GameMetadata.fromJson(value.toJson()), value);
      expect(
        () => PgnRecord(tree: GameTree(), tags: value.tags),
        throwsArgumentError,
      );
    },
  );
}
