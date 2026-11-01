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
  bool get hasContent =>
      hasMoves ||
      tree.root.comment.isNotEmpty ||
      tree.root.position.toFen() != Position.initialFen;
  int _revision = 0;
  int get revision => _revision;
  int _savedRevision = 0;
  int _epoch = 0;
  int get epoch => _epoch;
  int _positionRevision = 0;
  int get positionRevision => _positionRevision;
  bool get dirty => revision != _savedRevision;
  void markSaved(int revision) {
    _savedRevision = revision;
    notifyListeners();
  }

  void replaceTree(GameTree value, {bool saved = true}) {
    _inputLocked = false;
    _tree = value;
    _revision++;
    _savedRevision = saved ? _revision : -1;
    _epoch++;
    _positionRevision++;
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }

  bool _inputLocked = false;
  bool get inputLocked => _inputLocked;
  void setInputLocked(bool value) {
    if (_inputLocked == value) return;
    _inputLocked = value;
    _selected = null;
    notifyListeners();
  }

  List<Move> get legalMoves => List.unmodifiable(_legal);
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

  bool isLegalMove(Move move) => _legal.contains(move);

  void _refresh() {
    _legal = position.legalMoves.toList(growable: false);
    _outcome = position.boardOutcome();
  }

  void tap(Square square) {
    if (_outcome.isTerminal || _inputLocked) return;
    _notice = null;
    if (square == _selected) {
      _selected = null;
    } else if (position.at(square)?.side == position.turn) {
      _selected = square;
    } else if (_selected != null) {
      final move = Move(_selected!, square);
      if (_legal.contains(move)) {
        playMove(move);
        return;
      } else {
        _notice = '此处不能落子，请选择标记位置';
      }
    }
    notifyListeners();
  }

  bool playMove(Move move, {bool fromEngine = false}) {
    if (_outcome.isTerminal ||
        (_inputLocked && !fromEngine) ||
        !_legal.contains(move)) {
      return false;
    }
    final before = tree.nodeCount;
    _tree = tree.play(move);
    _positionRevision++;
    if (tree.nodeCount != before) _revision++;
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
    return true;
  }

  /// Creates or selects an alternative from its parent in one notification.
  bool playVariation(String parentId, Move move) {
    if (_inputLocked ||
        !tree.hasNode(parentId) ||
        !tree.node(parentId).position.legalMoves.contains(move)) {
      return false;
    }
    final next = tree.goTo(parentId).play(move);
    if (next.cursorId == tree.cursorId) return true;
    if (next.nodeCount != tree.nodeCount) _revision++;
    _tree = next;
    _positionRevision++;
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
    return true;
  }

  void cancelSelection() {
    _selected = null;
    _notice = null;
    notifyListeners();
  }

  void navigate(String id) {
    final next = tree.goTo(id);
    if (next.cursorId != tree.cursorId) _positionRevision++;
    _tree = next;
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }

  void undo() {
    if (canUndo) navigate(tree.current.parentId!);
  }

  String? get nextNodeId {
    final line = tree.currentLine;
    final index = line.indexWhere((node) => node.id == tree.cursorId);
    return index + 1 < line.length ? line[index + 1].id : null;
  }

  void forward() {
    final next = nextNodeId;
    if (next != null) navigate(next);
  }

  void first() => navigate(tree.root.id);
  void last() => navigate(tree.currentLine.last.id);

  void annotate(String comment) {
    if (comment == tree.current.comment) return;
    _tree = tree.annotate(comment);
    _revision++;
    notifyListeners();
  }

  void promote(String id) {
    final next = tree.promote(id);
    if (identical(next, tree)) return;
    _tree = next;
    _revision++;
    notifyListeners();
  }

  void deleteBranch(String id) {
    final oldCursor = tree.cursorId;
    _tree = tree.deleteBranch(id);
    if (oldCursor != tree.cursorId) _positionRevision++;
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
    _inputLocked = false;
    _tree = GameTree();
    _revision++;
    _savedRevision = _revision;
    _epoch++;
    _positionRevision++;
    _selected = null;
    _notice = null;
    _refresh();
    notifyListeners();
  }
}
