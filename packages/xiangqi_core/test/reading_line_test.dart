import 'dart:convert';
import 'package:test/test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

GameTree branches() => GameTree()
    .play(Move.parse('h2e2'))
    .play(Move.parse('b9c7'))
    .goTo('n0')
    .play(Move.parse('b2e2'))
    .play(Move.parse('h9g7'));
List<String> ids(GameTree tree) =>
    tree.currentLine.map((node) => node.id).toList();
void main() {
  test('a chosen variation stays visible when stepping back to the start', () {
    var tree = branches();
    expect(ids(tree), ['n0', 'n3', 'n4']);
    tree = tree.goTo('n0');
    expect(ids(tree), ['n0', 'n3', 'n4']);
    expect(tree.cursorId, 'n0');
    expect(() => tree.currentLine.clear(), throwsUnsupportedError);
  });
  test(
    'selecting a different branch switches line and content edits retain the choice',
    () {
      var tree = branches().goTo('n0').goTo('n1');
      expect(ids(tree), ['n0', 'n1', 'n2']);
      tree = tree.goTo('n0').annotate('reading').promote('n3');
      expect(ids(tree), ['n0', 'n1', 'n2']);
      final removed = tree.deleteBranch('n1');
      expect(ids(removed), ['n0', 'n3', 'n4']);
      expect(removed.hasNode('n2'), isFalse);
      expect(removed.hasNode('n4'), isTrue);
    },
  );
  test(
    'optional navigation metadata roundtrips and old schema-one snapshots still open',
    () {
      final tree = branches().goTo('n0');
      final json =
          jsonDecode(jsonEncode(tree.toJson())) as Map<String, dynamic>;
      final reopened = GameTree.fromJson(json);
      expect(ids(reopened), ['n0', 'n3', 'n4']);
      expect(reopened.cursorId, 'n0');
      final legacy = Map<String, dynamic>.of(json)..remove('lineAnchor');
      expect(ids(GameTree.fromJson(legacy)), ['n0', 'n1', 'n2']);
      for (final anchor in [null, 42, 'missing']) {
        expect(
          () => GameTree.fromJson({...json, 'lineAnchor': anchor}),
          throwsFormatException,
        );
      }
      expect(
        () => GameTree.fromJson({...json, 'cursor': 'n2', 'lineAnchor': 'n4'}),
        throwsFormatException,
      );
    },
  );
}
