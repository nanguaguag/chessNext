import 'position.dart';

/// Chinese four-character file notation. Move legality remains Position's job.
abstract final class ChineseNotation {
  static const _numbers = '一二三四五六七八九';
  static const _blackNumbers = '１２３４５６７８９';
  static String _number(int value, Side side) =>
      (side == Side.red ? _numbers : _blackNumbers)[value - 1];
  static int _file(int file, Side side) =>
      side == Side.red ? 9 - file : file + 1;
  static String _name(Piece piece) => switch (piece.type) {
    PieceType.general => piece.side == Side.red ? '帅' : '将',
    PieceType.advisor => piece.side == Side.red ? '仕' : '士',
    PieceType.elephant => piece.side == Side.red ? '相' : '象',
    PieceType.horse => '马',
    PieceType.rook => '车',
    PieceType.cannon => '炮',
    PieceType.pawn => piece.side == Side.red ? '兵' : '卒',
  };

  static String format(Position position, Move move) {
    final piece = position.at(move.from);
    if (piece == null || piece.side != position.turn || move.from == move.to) {
      throw ArgumentError('Expected a moving-side piece and distinct squares');
    }
    final groups = <int, List<Square>>{};
    for (var file = 0; file < 9; file++) {
      final squares = <Square>[];
      for (var rank = 0; rank < 10; rank++) {
        final square = Square(file, rank);
        if (position.at(square)?.fen == piece.fen) squares.add(square);
      }
      squares.sort(
        (a, b) => piece.side == Side.red
            ? b.rank.compareTo(a.rank)
            : a.rank.compareTo(b.rank),
      );
      if (squares.length > 1) groups[file] = squares;
    }
    var prefix =
        '${_name(piece)}${_number(_file(move.from.file, piece.side), piece.side)}';
    final sameFile = groups[move.from.file];
    if (sameFile != null &&
        piece.type != PieceType.advisor &&
        piece.type != PieceType.elephant) {
      var index = sameFile.indexOf(move.from);
      String marker;
      if (piece.type == PieceType.pawn && groups.length > 1) {
        final files = groups.keys.toList()
          ..sort(
            (a, b) => piece.side == Side.red ? b.compareTo(a) : a.compareTo(b),
          );
        final ordered = [for (final file in files) ...groups[file]!];
        index = ordered.indexOf(move.from);
        marker = _numbers[index];
      } else if (sameFile.length == 2) {
        marker = index == 0 ? '前' : '后';
      } else if (sameFile.length == 3) {
        marker = ['前', '中', '后'][index];
      } else {
        marker = _numbers[index];
      }
      prefix = '$marker${_name(piece)}';
    }
    final delta =
        (move.to.rank - move.from.rank) * (piece.side == Side.red ? 1 : -1);
    final action = delta == 0
        ? '平'
        : delta > 0
        ? '进'
        : '退';
    final destinationFile =
        delta == 0 ||
        const {
          PieceType.horse,
          PieceType.advisor,
          PieceType.elephant,
        }.contains(piece.type);
    final suffix = destinationFile
        ? _file(move.to.file, piece.side)
        : delta.abs();
    return '$prefix$action${_number(suffix, piece.side)}';
  }

  static String _normalize(String text) {
    const aliases = {
      '車': '车',
      '俥': '车',
      '馬': '马',
      '傌': '马',
      '砲': '炮',
      '帥': '帅',
      '將': '将',
      '進': '进',
      '後': '后',
      '仕': '士',
      '相': '象',
      '帅': '将',
      '兵': '卒',
    };
    return text.split('').map((char) {
      final number = _numbers.indexOf(char);
      if (number >= 0) return '${number + 1}';
      final black = _blackNumbers.indexOf(char);
      if (black >= 0) return '${black + 1}';
      final simple = aliases[char] ?? char;
      return aliases[simple] ?? simple;
    }).join();
  }

  /// Resolves against legal candidates; never guesses among ambiguous matches.
  static Move parse(Position position, String text) {
    final target = _normalize(text.trim());
    final matches = position.legalMoves
        .where((move) => _normalize(format(position, move)) == target)
        .toList();
    if (matches.length != 1) {
      throw FormatException(
        matches.isEmpty ? '没有匹配的合法中文着法' : '中文着法存在歧义，请使用坐标着法',
      );
    }
    return matches.single;
  }
}
