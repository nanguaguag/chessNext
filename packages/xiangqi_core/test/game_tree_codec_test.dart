import 'dart:convert';
import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

Map<String, dynamic> copy(GameTree tree) =>
    jsonDecode(jsonEncode(tree.toJson())) as Map<String, dynamic>;
void main() {
  test(
    'versioned snapshot roundtrips branches, notes, cursor and ID sequence',
    () {
      final tree = GameTree()
          .annotate('开局')
          .play(Move.parse('h2e2'))
          .annotate('中炮')
          .goTo('n0')
          .play(Move.parse('c3c4'))
          .promote('n2');
      final restored = GameTree.fromJson(copy(tree));
      expect(restored.toJson(), tree.toJson());
      expect(
        restored.goTo('n0').play(Move.parse('h2e2')).current.comment,
        '中炮',
      );
      expect(restored.play(Move.parse('b9c7')).cursorId, 'n3');
    },
  );
  test(
    'corrupt schemas and graph structures fail without repairing away data',
    () {
      final tree = GameTree().play(Move.parse('h2e2'));
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j['schema'] = 99,
        (j) => j['cursor'] = 'missing',
        (j) => j['nextId'] = 1,
        (j) => (j['nodes'] as List).add((j['nodes'] as List).first),
        (j) => (j['nodes'] as List)[1]['move'] = 'a9a8',
        (j) => (j['nodes'] as List)[1]['parent'] = 'missing',
        (j) => (j['nodes'] as List)[0]['children'] = <String>[],
        (j) => (j['nodes'] as List)[1]['children'] = ['n0'],
        (j) => (j['nodes'] as List)[1]['comment'] = 42,
      ]) {
        final data = copy(tree);
        mutate(data);
        expect(() => GameTree.fromJson(data), throwsFormatException);
      }
      expect(tree.nodeCount, 2);
    },
  );
}
