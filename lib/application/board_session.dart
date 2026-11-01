import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

/// In-memory local play; tree navigation and persistence follow separately.
class BoardSession extends ChangeNotifier {
  BoardSession({Position? initial})
    : _position = initial ?? Position.initial() {
    if (!_position.validateForPlay().isValid) {
      throw ArgumentError('Invalid starting position');
    }
    _refresh();
  }
  Position _position;
  Position get position => _position;
  final List<Position> _history = [];
  final List<Move> _moves = [];
  List<Move> get moves => List.unmodifiable(_moves);
  Square? _selected;
  Square? get selected => _selected;
  bool _flipped = false;
  bool get flipped => _flipped;
  String? _notice;
  String? get notice => _notice;
  late List<Move> _legal;
  late BoardOutcome _outcome;
  BoardOutcome get outcome => _outcome;
  bool get canUndo => _history.isNotEmpty;
  Set<Square> get targets =>
      _legal.where((m) => m.from == _selected).map((m) => m.to).toSet();
  String get status {
    if (_outcome.isTerminal) {
      return '${_outcome.winner == Side.red ? '红方' : '黑方'}获胜 · ${_outcome.status == BoardStatus.checkmate ? '将死' : '困毙'}';
    }
    return '${position.turn == Side.red ? '红方' : '黑方'}行棋${position.isInCheck(position.turn) ? ' · 将军' : ''}';
  }

  void _refresh() {
    _legal = position.legalMoves.toList(growable: false);
    _outcome = position.boardOutcome();
  }

  void tap(Square square) {
    if (_outcome.isTerminal) return;
    _notice = null;
    if (square == _selected) {
      _selected = null;
    } else if (position.at(square)?.side == position.turn) {
      _selected = square;
    } else if (_selected != null) {
      final move = Move(_selected!, square);
      if (_legal.contains(move)) {
        _history.add(position);
        _moves.add(move);
        _position = position.play(move);
        _selected = null;
        _refresh();
      } else {
        _notice = '此处不能落子，请选择标记位置';
      }
    }
    notifyListeners();
  }

  void cancelSelection() {
    _selected = null;
    _notice = null;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _position = _history.removeLast();
    _moves.removeLast();
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }

  void flip() {
    _flipped = !_flipped;
    notifyListeners();
  }

  void newGame() {
    _position = Position.initial();
    _history.clear();
    _moves.clear();
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }
}
