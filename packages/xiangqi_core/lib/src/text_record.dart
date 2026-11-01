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
    final moves = parts.length == 1 || parts[1].trim().isEmpty
        ? <String>[]
        : parts[1].trim().split(RegExp(r'\s+'));
    if (moves.length > 1999) throw const FormatException('着法超过1999步限制');
    for (var i = 0; i < moves.length; i++) {
      try {
        tree = tree.play(Move.parse(moves[i]));
      } on FormatException {
        throw FormatException('第${i + 1}步格式错误：${moves[i]}（例如h2e2）');
      } on ArgumentError {
        throw FormatException('第${i + 1}步不合法：${moves[i]}');
      } on StateError {
        throw FormatException('第${i + 1}步无法继续：${moves[i]}');
      }
    }
    return tree;
  }

  /// Exports only the root-to-cursor path. Other branches and comments are lost.
  static String path(GameTree tree) {
    final moves = tree.path.map((n) => n.move).whereType<Move>().join(' ');
    return '${tree.root.position.toFen()}${moves.isEmpty ? '' : ' moves $moves'}';
  }
}
