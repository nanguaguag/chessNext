import 'chinese_notation.dart';
import 'game_tree.dart';
import 'position.dart';
import 'validation.dart';

/// Strict offline FEN/UCI text interchange. No URL fetching or silent repair.
abstract final class TextRecord {
  static const maxLength = 64000;
  static GameTree parse(String text) {
    if (text.length > maxLength) {
      throw const FormatException('文字超过64000字符限制');
    }
    var source = text.trim().replaceFirst('\uFEFF', '').trim();
    if (source.isEmpty) throw const FormatException('请输入局面或着法');
    if (source.startsWith('position ')) source = source.substring(9).trim();
    final parts = source.split(RegExp(r'\s+moves(?:\s+|$)'));
    if (parts.length > 2) throw const FormatException('只能包含一个moves分隔符');
    var root = parts.first.trim();
    if (root.startsWith('fen ')) root = root.substring(4).trim();
    Position initial;
    String moveText;
    final bareNotation =
        parts.length == 1 && root != 'startpos' && !root.contains('/');
    moveText = bareNotation
        ? root
        : parts.length > 1
        ? parts[1]
        : '';
    if (bareNotation) root = 'startpos';
    try {
      initial = root == 'startpos'
          ? Position.initial()
          : Position.fromFen(root);
    } on FormatException {
      throw const FormatException('FEN格式错误：需要10行棋子、w/b先手及可选的四个计数字段');
    }
    if (!initial.validateForPlay().isValid) {
      throw const FormatException('初始局面无效，请在局面编辑器中检查棋子数量、落点和先手');
    }
    var tree = GameTree(initial: initial);
    moveText = moveText.replaceAll(RegExp(r'(?<!\S)[0-9]+\.(?:\.\.)?'), ' ');
    final moves = moveText.trim().isEmpty
        ? <String>[]
        : moveText.trim().split(RegExp(r'\s+'));
    if (moves.length > GameTree.maxNodes - 1)
      throw const FormatException('着法超过${GameTree.maxNodes - 1}步限制');
    for (var i = 0; i < moves.length; i++) {
      try {
        final token = moves[i];
        final move = RegExp(r'^[a-iA-I][0-9]-?[a-iA-I][0-9]$').hasMatch(token)
            ? Move.parse(token.toLowerCase().replaceAll('-', ''))
            : ChineseNotation.parse(tree.current.position, token);
        tree = tree.play(move);
      } on FormatException {
        throw FormatException('第${i + 1}步格式错误或无合法匹配：${moves[i]}（例如h2e2或炮二平五）');
      } on ArgumentError {
        throw FormatException('第${i + 1}步不合法：${moves[i]}');
      } on StateError {
        throw FormatException('第${i + 1}步无法继续：${moves[i]}');
      }
    }
    return tree;
  }

  /// Exports only the root-to-cursor path. Other branches and comments are lost.
  static String path(GameTree tree, {bool chinese = false}) {
    final moves = tree.path
        .where((n) => n.move != null)
        .map(
          (n) => chinese
              ? ChineseNotation.format(tree.node(n.parentId!).position, n.move!)
              : n.move.toString(),
        )
        .join(' ');
    return '${tree.root.position.toFen()}${moves.isEmpty ? '' : ' moves $moves'}';
  }
}
