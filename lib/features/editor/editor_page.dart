import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../board/xiangqi_board.dart';

String setupIssueText(PositionIssue issue) {
  final side = issue.side == Side.red ? '红方' : '黑方';
  final reason = switch (issue.code) {
    PositionIssueCode.missingGeneral => '缺少帅或将',
    PositionIssueCode.tooManyPieces => '同类棋子数量超限',
    PositionIssueCode.generalOutsidePalace => '帅或将必须在九宫内',
    PositionIssueCode.advisorOffPoint => '士或仕不在合法落点',
    PositionIssueCode.elephantOffPoint => '象或相不在合法落点',
    PositionIssueCode.pawnBeforeStartingRank => '兵卒不能退到初始线后方',
    PositionIssueCode.pawnOffStartingFile => '未过河兵卒不能偏离初始列',
    PositionIssueCode.duplicateUncrossedPawnFile => '同列有重复的未过河兵卒',
    PositionIssueCode.facingGenerals => '帅将照面',
    PositionIssueCode.nonMovingSideInCheck => '非行棋方仍被将军，请检查先手',
  };
  return '$side：$reason${issue.squares.isEmpty ? '' : '（${issue.squares.join('、')}）'}';
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.initial});
  final Position initial;
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late SetupDraft draft;
  Square? selected;
  Piece? palette;
  bool flipped = false;
  bool mirrored = false;
  @override
  void initState() {
    super.initState();
    draft = SetupDraft.fromPosition(widget.initial);
  }

  void _apply(SetupDraft value) {
    if (!mounted) return;
    setState(() {
      draft = value;
      selected = null;
      palette = null;
    });
  }

  void _tap(Square square) {
    if (palette != null) {
      final piece = palette!;
      if (draft.remaining(piece) == 0 && draft.at(square)?.fen != piece.fen) {
        return;
      }
      setState(() {
        draft = draft.place(square, piece);
        selected = null;
        if (draft.remaining(piece) == 0) palette = null;
      });
    } else if (selected == square) {
      setState(() => selected = null);
    } else if (selected != null) {
      _apply(draft.move(selected!, square));
    } else if (draft.at(square) != null) {
      setState(() => selected = square);
    }
  }

  void _palette(Piece piece) {
    setState(() {
      if (selected != null) {
        draft = draft.place(selected!, null);
        selected = null;
      }
      palette = draft.remaining(piece) > 0 ? piece : null;
    });
  }

  void _complete() {
    if (!draft.validation.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无效的局面，请先修正提示的问题')));
      return;
    }
    Navigator.pop(context, draft.toPosition());
  }

  Widget _paletteRow(Side side) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final type in PieceType.values)
        Draggable<BoardDragData>(
          data: BoardDragData(Piece(side, type)),
          maxSimultaneousDrags: draft.remaining(Piece(side, type)) > 0 ? 1 : 0,
          feedback: Material(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                pieceName(Piece(side, type)),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          child: ChoiceChip(
            key: ValueKey('palette-${side.name}-${type.name}'),
            label: Text(
              '${side == Side.red ? '红' : '黑'}${pieceName(Piece(side, type))}',
            ),
            selected: palette?.side == side && palette?.type == type,
            onSelected:
                selected != null || draft.remaining(Piece(side, type)) > 0
                ? (active) {
                    if (active) {
                      _palette(Piece(side, type));
                    } else {
                      setState(() => palette = null);
                    }
                  }
                : null,
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final report = draft.validation;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '取消编辑',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: const Text('编辑局面'),
        actions: [TextButton(onPressed: _complete, child: const Text('完成'))],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final width = (constraints.maxWidth - 48 - (wide ? 350 : 0))
              .clamp(432, 540)
              .toDouble();
          final board = Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: BoardSurface(
                    at: draft.at,
                    onTap: _tap,
                    selected: selected,
                    flipped: flipped,
                    mirrored: mirrored,
                    onCancel: () {
                      if (selected == null && palette == null) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          selected = null;
                          palette = null;
                        });
                      }
                    },
                    onRemove: (square) => _apply(draft.place(square, null)),
                    onDrop: (data, square) {
                      if (data.from == null &&
                          draft.remaining(data.piece) == 0) {
                        return;
                      }
                      _apply(
                        data.from == null
                            ? draft.place(square, data.piece)
                            : draft.move(data.from!, square),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _paletteRow(Side.red),
              const SizedBox(height: 8),
              _paletteRow(Side.black),
              const SizedBox(height: 8),
              const Text('点棋子盒再点棋盘放子；点棋盘棋子再点棋子盒移除。支持拖动与右键删除。'),
            ],
          );
          final controls = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<Side>(
                segments: const [
                  ButtonSegment(value: Side.red, label: Text('红先')),
                  ButtonSegment(value: Side.black, label: Text('黑先')),
                ],
                selected: {draft.turn},
                onSelectionChanged: (value) =>
                    _apply(draft.withTurn(value.single)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _apply(draft.initial()),
                    child: const Text('初始局面'),
                  ),
                  OutlinedButton(
                    onPressed: () => _apply(draft.clear()),
                    child: const Text('清空'),
                  ),
                  OutlinedButton(
                    onPressed: () => _apply(draft.swapSides()),
                    child: const Text('红黑互换'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => flipped = !flipped),
                    child: const Text('旋转棋盘'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => mirrored = !mirrored),
                    child: const Text('左右翻转'),
                  ),
                  if (selected != null)
                    TextButton(
                      onPressed: () => _apply(draft.place(selected!, null)),
                      child: const Text('移除选中棋子'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (report.isValid)
                const Text('局面有效，可点击完成')
              else
                for (final issue in report.issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      setupIssueText(issue),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              const Text('取消会保留原棋谱。完成后将以此局面开始新的棋谱。'),
            ],
          );
          return Padding(
            padding: const EdgeInsets.all(24),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SingleChildScrollView(child: board)),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 326,
                        child: SingleChildScrollView(child: controls),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [board, const SizedBox(height: 24), controls],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
