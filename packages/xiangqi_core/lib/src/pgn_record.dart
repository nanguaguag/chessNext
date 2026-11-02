import 'game_metadata.dart';
import 'chinese_notation.dart';
import 'game_tree.dart';
import 'position.dart';
import 'validation.dart';

enum PgnMoveFormat { iccs, chinese }

const _results = {'*', '1-0', '0-1', '1/2-1/2'};
const _preferredTags = [
  'Game',
  'Event',
  'Site',
  'Date',
  'Round',
  'RedTeam',
  'Red',
  'BlackTeam',
  'Black',
  'Result',
  'FEN',
  'Format',
];
final _tagName = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}$');
final _controls = RegExp(r'[\x00-\x1f\x7f]');

void _validateTags(Map<String, String> tags) {
  GameMetadata(tags);
}

Position _pgnPosition(String fen) {
  if (fen.length > PgnCodec.maxTagValue)
    throw const FormatException('PGN FEN过长');
  final fields = fen.trim().split(RegExp(r'\s+'));
  if (fields.length >= 2 && fields[1] == 'r') fields[1] = 'w';
  return Position.fromFen(fields.join(' '));
}

/// A single game with preserved metadata. Navigation and other branches remain
/// in the tree, but the path exporter explicitly exports only root-to-cursor.
class PgnRecord {
  PgnRecord._(this.tree, this.tags);
  factory PgnRecord({
    required GameTree tree,
    Map<String, String> tags = const {},
  }) {
    _validateTags(tags);
    if (tags['Game'] != null && tags['Game'] != 'Chinese Chess') {
      throw ArgumentError('PGN游戏类型必须是Chinese Chess');
    }
    final format = tags['Format']?.toLowerCase() ?? 'chinese';
    if (format != 'chinese' && format != 'iccs') {
      throw ArgumentError('暂不支持此PGN记谱方式：${tags['Format']}');
    }
    if (tags['FEN'] != null &&
        _pgnPosition(tags['FEN']!).toFen() != tree.root.position.toFen()) {
      throw ArgumentError('PGN标签FEN与棋树根局面不一致');
    }
    final normalized = <String, String>{
      ...tags,
      'Game': 'Chinese Chess',
      'Result': tags['Result'] ?? '*',
      'FEN': tree.root.position.toFen(),
      'Format': format == 'iccs' ? 'ICCS' : 'Chinese',
    };
    if (normalized.length > PgnCodec.maxTags ||
        !_results.contains(normalized['Result'])) {
      throw ArgumentError('PGN标签数量或结果无效');
    }
    _validateTags(normalized);
    return PgnRecord._(tree, Map.unmodifiable(normalized));
  }
  final GameTree tree;
  final Map<String, String> tags;
  String get result => tags['Result']!;
}

abstract final class PgnCodec {
  static const maxLength = 64000,
      maxTags = GameMetadata.maxTags,
      maxTagValue = GameMetadata.maxValueLength;
  static const maxPlies = GameTree.maxNodes - 1, maxComment = 10000;

  static PgnRecord parse(String text) {
    if (text.length > maxLength) throw const FormatException('PGN超过64000字符限制');
    final reader = _Reader(text.replaceFirst(RegExp(r'^\uFEFF'), ''));
    final tags = <String, String>{};
    reader.space();
    while (!reader.end && reader.char == '[') {
      final (key, value) = reader.tag();
      if (tags.containsKey(key)) reader.fail('PGN标签重复：$key');
      if (tags.isEmpty && key != 'Game') reader.fail('PGN首标签需要Game');
      tags[key] = value;
      if (tags.length > maxTags) reader.fail('PGN标签超过64个');
      reader.space();
    }
    if (tags['Game'] != 'Chinese Chess') reader.fail('需要Chinese Chess类型的PGN');
    final format = (tags['Format'] ?? 'Chinese').toLowerCase();
    if (!{'chinese', 'iccs'}.contains(format)) {
      reader.fail('暂不支持PGN的${tags['Format']}记谱方式');
    }
    if (tags['Result'] != null && !_results.contains(tags['Result'])) {
      reader.fail('PGN结果标签无效');
    }
    GameTree tree;
    try {
      final root = tags['FEN'] == null
          ? Position.initial()
          : _pgnPosition(tags['FEN']!);
      if (!root.validateForPlay().isValid) reader.fail('PGN初始局面无效');
      tree = GameTree(initial: root);
    } on FormatException {
      reader.fail('PGN初始局面或FEN格式无效');
    } on ArgumentError {
      reader.fail('PGN初始局面无效');
    }
    var plies = 0;
    var numberPending = false;
    String? result;
    while (true) {
      reader.space();
      if (reader.end) break;
      if (reader.char == '{') {
        final comment = reader.comment();
        final previous = tree.current.comment;
        final merged = previous.isEmpty ? comment : '$previous\n$comment';
        if (merged.length > maxComment) reader.fail('单节点评注超过10000字符');
        tree = tree.annotate(merged);
        continue;
      }
      if (reader.char == '[') reader.fail('暂不支持多局PGN或着法中的标签');
      if (reader.char == '(' || reader.char == ')') reader.fail('暂不支持PGN括号变着');
      if (reader.char == '}') reader.fail('PGN评注结束符没有起始符');
      var token = reader.token();
      if (result != null) reader.fail('PGN结果后只能有评注');
      final number = RegExp(r'^([0-9]+)(\.\.\.|\.)(.*)$').firstMatch(token);
      if (number != null) {
        if (numberPending) reader.fail('PGN回合编号后缺少着法');
        final expectedDots = tree.current.position.turn == Side.red
            ? '.'
            : '...';
        if (int.tryParse(number[1]!) != tree.current.position.fullmove ||
            number[2] != expectedDots) {
          reader.fail('PGN回合编号或红黑先手不匹配');
        }
        numberPending = true;
        token = number[3]!;
        if (token.isEmpty) continue;
      }
      if (_results.contains(token)) {
        if (numberPending) reader.fail('PGN回合编号后缺少着法');
        if (tags['Result'] != null && tags['Result'] != token)
          reader.fail('PGN标签与正文结果不一致');
        result = token;
        continue;
      }
      if (plies >= maxPlies) reader.fail('PGN着法超过$maxPlies步');
      try {
        final move = format == 'iccs'
            ? _iccs(token)
            : ChineseNotation.parse(tree.current.position, token);
        tree = tree.play(move);
      } on FormatException {
        reader.fail('PGN第${plies + 1}步格式不支持或无合法匹配：$token');
      } on ArgumentError {
        reader.fail('PGN第${plies + 1}步不合法：$token');
      } on StateError {
        reader.fail('PGN第${plies + 1}步无法继续：$token');
      }
      plies++;
      numberPending = false;
    }
    if (result == null) reader.fail('PGN缺少正文结束结果');
    try {
      return PgnRecord(tree: tree, tags: {...tags, 'Result': result});
    } on ArgumentError catch (error) {
      reader.fail(error.message?.toString() ?? 'PGN标签无效');
    }
  }

  static Move _iccs(String token) {
    if (!RegExp(r'^[A-Ia-i][0-9]-?[A-Ia-i][0-9]$').hasMatch(token)) {
      throw const FormatException('Invalid ICCS');
    }
    return Move.parse(token.toLowerCase().replaceAll('-', ''));
  }

  /// Includes only the selected path, never other branches or future moves.
  /// Brace-containing comments cannot be represented losslessly; callers must
  /// explicitly omit them or ask the user to edit, rather than silently repair.
  static String path(
    PgnRecord record, {
    PgnMoveFormat format = PgnMoveFormat.iccs,
    bool includeComments = true,
  }) {
    final tags = {
      ...record.tags,
      'Format': format == PgnMoveFormat.iccs ? 'ICCS' : 'Chinese',
    };
    String quoted(String value) =>
        value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    final extras = tags.keys.where((k) => !_preferredTags.contains(k)).toList()
      ..sort();
    final order = [..._preferredTags.where(tags.containsKey), ...extras];
    final nodes = record.tree.path;
    if (nodes.length > maxPlies + 1) {
      throw const FormatException('PGN导出超过$maxPlies步限制');
    }
    final output = StringBuffer();
    void emit(String text) {
      if (output.length + text.length > maxLength) {
        throw const FormatException('PGN导出超过64000字符限制');
      }
      output.write(text);
    }

    for (final key in order) {
      emit('[$key "${quoted(tags[key]!)}"]\n');
    }
    emit('\n');
    void comment(String text) {
      if (!includeComments || text.isEmpty) return;
      if (text.contains('{') || text.contains('}')) {
        throw const FormatException('PGN评注包含花括号，无法无损导出；请明确选择不含评注或修改评注');
      }
      if (text.length > maxComment) throw const FormatException('PGN评注过长');
      emit('{$text} ');
    }

    comment(record.tree.root.comment);
    var first = true;
    for (final node in nodes.skip(1)) {
      final before = record.tree.node(node.parentId!).position;
      if (before.turn == Side.red) {
        if (!first) emit('\n');
        emit('${before.fullmove}. ');
      } else if (first) {
        emit('${before.fullmove}... ');
      }
      final move = node.move!;
      emit(
        format == PgnMoveFormat.chinese
            ? ChineseNotation.format(before, move)
            : '${move.from}-${move.to}'.toUpperCase(),
      );
      emit(' ');
      comment(node.comment);
      first = false;
    }
    emit('${record.result}\n');
    final text = output.toString();

    return text;
  }
}

class _Reader {
  _Reader(this.source);
  final String source;
  int offset = 0;
  bool get end => offset == source.length;
  String get char => source[offset];
  Never fail(String message) =>
      throw FormatException('$message（字符${offset + 1}）');
  void space() {
    while (!end && char.trim().isEmpty) {
      offset++;
    }
  }

  (String, String) tag() {
    offset++;
    space();
    final start = offset;
    while (!end && RegExp(r'[A-Za-z0-9_]').hasMatch(char)) {
      offset++;
    }
    final name = source.substring(start, offset);
    if (!_tagName.hasMatch(name)) fail('PGN标签名无效');
    if (end || !char.trim().isEmpty) fail('PGN标签名后需要空白');
    space();
    if (end || char != '"') fail('PGN标签值需要双引号');
    offset++;
    final value = StringBuffer();
    var closed = false;
    while (!end) {
      var part = char;
      offset++;
      if (part == '"') {
        closed = true;
        break;
      }
      if (part == '\\') {
        if (end || (char != '\\' && char != '"')) fail('PGN标签转义无效');
        part = char;
        offset++;
      }
      if (_controls.hasMatch(part)) fail('PGN标签不能包含控制字符');
      value.write(part);
      if (value.length > PgnCodec.maxTagValue) fail('PGN标签值超过4096字符');
    }
    if (!closed) fail('PGN标签引号未结束');
    space();
    if (end || char != ']') fail('PGN标签缺少右方括号');
    offset++;
    return (name, value.toString());
  }

  String comment() {
    offset++;
    final start = offset;
    while (!end && char != '}') {
      if (char == '{') fail('PGN评注不能嵌套花括号');
      offset++;
      if (offset - start > PgnCodec.maxComment) fail('PGN评注超过10000字符');
    }
    if (end) fail('PGN评注未结束');
    final value = source.substring(start, offset);
    offset++;
    return value;
  }

  String token() {
    final start = offset;
    while (!end && !char.trim().isEmpty && !'{}[]()'.contains(char)) {
      offset++;
      if (offset - start > 128) fail('PGN着法标记过长');
    }
    if (start == offset) fail('PGN含不支持的标记');
    return source.substring(start, offset);
  }
}
