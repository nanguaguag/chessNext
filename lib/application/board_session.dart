import 'package:flutter/foundation.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

/// In-memory document and cursor; persistence is provided through a separate port.
class BoardSession extends ChangeNotifier {
  BoardSession({Position? initial}) : _tree = GameTree(initial: initial) {
    _refresh();
  }
  GameTree _tree;
  GameTree get tree => _tree;
  Position get position => tree.current.position;
  List<Move> get moves =>
      List.unmodifiable(tree.path.skip(1).map((node) => node.move!));
  bool get hasMoves => tree.nodeCount > 1;
  bool get hasContent => hasMoves || tree.root.comment.isNotEmpty;
  int _revision = 0;
  int get revision => _revision;
  Square? _selected;
  Square? get selected => _selected;
  bool _flipped = false;
  bool get flipped => _flipped;
  String? _notice;
  String? get notice => _notice;
  late List<Move> _legal;
  late BoardOutcome _outcome;
  BoardOutcome get outcome => _outcome;
  bool get canUndo => tree.current.parentId != null;
  bool get canForward => tree.current.children.isNotEmpty;
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
        final before = tree.nodeCount;
        _tree = tree.play(move);
        if (tree.nodeCount != before) _revision++;
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

  void navigate(String id) {
    _tree = tree.goTo(id);
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }

  void undo() {
    if (canUndo) navigate(tree.current.parentId!);
  }

  void forward() {
    if (canForward) navigate(tree.current.children.first);
  }

  void first() => navigate(tree.root.id);
  void last() {
    var node = tree.current;
    while (node.children.isNotEmpty) {
      node = tree.node(node.children.first);
    }
    navigate(node.id);
  }

  void annotate(String comment) {
    if (comment == tree.current.comment) return;
    _tree = tree.annotate(comment);
    _revision++;
    notifyListeners();
  }

  void promote(String id) {
    _tree = tree.promote(id);
    _revision++;
    notifyListeners();
  }

  void deleteBranch(String id) {
    _tree = tree.deleteBranch(id);
    _revision++;
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
    _tree = GameTree();
    _revision++;
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }
}
