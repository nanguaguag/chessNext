import 'selected_piece_frame.dart';
import 'move_grade_badge.dart';
import '../../application/review_report.dart';
import 'last_move_markers.dart';
import '../../application/current_move_arrows.dart';
import 'variation_arrows_painter.dart';
import 'board_arrows_painter.dart';
import '../../application/board_appearance.dart';
import '../../application/app_preferences.dart';
import 'board_display_scope.dart';
import 'board_file_coordinates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_session.dart';
import '../../ports/piece_images.dart';

String pieceName(Piece piece) => switch ((piece.side, piece.type)) {
  (Side.red, PieceType.general) => '帅',
  (Side.black, PieceType.general) => '将',
  (Side.red, PieceType.advisor) => '仕',
  (Side.black, PieceType.advisor) => '士',
  (Side.red, PieceType.elephant) => '相',
  (Side.black, PieceType.elephant) => '象',
  (_, PieceType.horse) => '马',
  (_, PieceType.rook) => '车',
  (_, PieceType.cannon) => '炮',
  (Side.red, PieceType.pawn) => '兵',
  (Side.black, PieceType.pawn) => '卒',
};

class XiangqiBoard extends StatelessWidget {
  const XiangqiBoard({
    super.key,
    required this.session,
    this.assessment,
    this.recommendation,
    this.reply,
  });
  final BoardSession session;
  final MoveAssessment? assessment;
  final Move? recommendation;
  final Move? reply;
  @override
  Widget build(BuildContext context) => BoardSurface(
    at: session.position.at,
    lastMove: session.tree.current.move,
    assessment: assessment,
    lastMoveIdentity: (session.epoch, session.tree.cursorId),
    selected: session.selected,
    targets: session.targets,
    flipped: session.flipped,
    mirrored: session.mirrored,
    enabled: !session.inputLocked && !session.outcome.isTerminal,
    onTap: session.tap,
    onCancel: session.cancelSelection,
    recommendation: recommendation,
    reply: reply,
    variations: session.showCurrentVariationArrows
        ? session.currentMoveArrows.visible
        : const [],
  );
}

class BoardDragData {
  const BoardDragData(this.piece, {this.from});
  final Piece piece;
  final Square? from;
}

class BoardSurface extends StatefulWidget {
  const BoardSurface({
    super.key,
    required this.at,
    required this.onTap,
    this.selected,
    this.lastMove,
    this.assessment,
    this.lastMoveIdentity,
    this.lastMoveMarkerStyle,
    this.selectionStyle,
    this.targets = const {},
    this.flipped = false,
    this.mirrored = false,
    this.showCoordinates,
    this.rotateOppositePieces,
    this.boardSkin,
    this.pieceSkin,
    this.pieceImages,
    this.pieceSizePercent,
    this.pieceSkinSizePercent,
    this.pieceSkinOffsetXPercent,
    this.pieceSkinOffsetYPercent,
    this.showAnalysisArrows,
    this.arrowHeadStyle,
    this.variations = const [],
    this.enabled = true,
    this.onCancel,
    this.onRemove,
    this.onDrop,
    this.recommendation,
    this.reply,
  }) : assert(
         (pieceSizePercent == null ||
                 (pieceSizePercent >= 10 &&
                     pieceSizePercent <= 200 &&
                     pieceSizePercent % 5 == 0)) &&
             (pieceSkinSizePercent == null ||
                 (pieceSkinSizePercent >= 80 && pieceSkinSizePercent <= 120)) &&
             (pieceSkinOffsetXPercent == null ||
                 (pieceSkinOffsetXPercent >= -8 &&
                     pieceSkinOffsetXPercent <= 8)) &&
             (pieceSkinOffsetYPercent == null ||
                 (pieceSkinOffsetYPercent >= -8 &&
                     pieceSkinOffsetYPercent <= 8)),
       );
  final Piece? Function(Square) at;
  final ValueChanged<Square> onTap;
  final VoidCallback? onCancel;
  final ValueChanged<Square>? onRemove;
  final void Function(BoardDragData, Square)? onDrop;
  final Square? selected;
  final Move? lastMove;
  final MoveAssessment? assessment;
  final Object? lastMoveIdentity;
  final LastMoveMarkerStyle? lastMoveMarkerStyle;
  final SelectionStyle? selectionStyle;
  final Set<Square> targets;
  final bool flipped;
  final bool mirrored;
  final bool? showCoordinates;
  final bool? rotateOppositePieces;
  final BoardSkin? boardSkin;
  final PieceSkin? pieceSkin;
  final Map<PieceImageSlot, Uint8List>? pieceImages;
  final int? pieceSizePercent;
  final int? pieceSkinSizePercent;
  final int? pieceSkinOffsetXPercent, pieceSkinOffsetYPercent;
  final bool? showAnalysisArrows;
  final ArrowHeadStyle? arrowHeadStyle;
  final List<VariationArrow> variations;
  final bool enabled;
  final Move? recommendation;
  final Move? reply;
  @override
  State<BoardSurface> createState() => _BoardSurfaceState();
}

class _BoardSurfaceState extends State<BoardSurface> {
  final boardFocus = FocusNode(debugLabel: 'xiangqi-board');
  Square cursor = Square(4, 0);
  bool hasFocus = false;
  bool animateMarkerOnMount = false;
  @override
  void didUpdateWidget(covariant BoardSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    animateMarkerOnMount =
        widget.lastMove != oldWidget.lastMove ||
        widget.lastMoveIdentity != oldWidget.lastMoveIdentity;
  }

  @override
  void dispose() {
    boardFocus.dispose();
    super.dispose();
  }

  void _tap(Square square) {
    if (!widget.enabled) return;
    boardFocus.requestFocus();
    setState(() => cursor = square);
    widget.onTap(square);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onCancel?.call();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _tap(cursor);
    } else {
      var dx = 0;
      var dy = 0;
      if (key == LogicalKeyboardKey.arrowLeft) {
        dx = -1;
      } else if (key == LogicalKeyboardKey.arrowRight) {
        dx = 1;
      } else if (key == LogicalKeyboardKey.arrowUp) {
        dy = 1;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        dy = -1;
      } else {
        return KeyEventResult.ignored;
      }
      setState(
        () => cursor = Square(
          (cursor.file + dx * (widget.flipped != widget.mirrored ? -1 : 1))
              .clamp(0, 8),
          (cursor.rank + dy * (widget.flipped ? -1 : 1)).clamp(0, 9),
        ),
      );
    }
    return KeyEventResult.handled;
  }

  MoveAssessment? get visibleAssessment =>
      BoardDisplayScope.moveGradesOf(context) &&
          widget.lastMove != null &&
          widget.assessment?.rated == true &&
          widget.assessment?.lossUnits != null
      ? widget.assessment
      : null;

  @override
  Widget build(BuildContext context) {
    final board = Focus(
      autofocus: true,
      focusNode: boardFocus,
      onKeyEvent: _key,
      onFocusChange: (value) => setState(() => hasFocus = value),
      child: AspectRatio(
        aspectRatio: 9 / 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final step = constraints.maxWidth / 9;
            final skin =
                widget.boardSkin ?? BoardDisplayScope.boardSkinOf(context);
            return DecoratedBox(
              key: const ValueKey('board-skin-background'),
              decoration: BoxDecoration(
                color: Color(skin.boardColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _BoardPainter(skin)),
                  ),
                  if ((widget.showAnalysisArrows ??
                          BoardDisplayScope.analysisArrowsOf(context)) &&
                      (widget.recommendation != null || widget.reply != null))
                    Positioned.fill(
                      child: Semantics(
                        container: true,
                        label: [
                          if (widget.recommendation != null)
                            '引擎推荐：${widget.recommendation!.from}至${widget.recommendation!.to}',
                          if (widget.reply != null)
                            '预计应着：${widget.reply!.from}至${widget.reply!.to}',
                        ].join('；'),
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: BoardArrowsPainter(
                              recommendation: widget.recommendation,
                              reply: widget.reply,
                              flipped: widget.flipped,
                              mirrored: widget.mirrored,
                              headStyle:
                                  widget.arrowHeadStyle ??
                                  BoardDisplayScope.arrowHeadOf(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (BoardDisplayScope.variationArrowsOf(context) &&
                      widget.variations.isNotEmpty)
                    Positioned.fill(
                      child: Semantics(
                        container: true,
                        label:
                            '上一局面的本步变着：${widget.variations.take(CurrentMoveArrows.maxVisible).map((a) => '${a.number} ${a.notation}').join('；')}',
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: VariationArrowsPainter(
                              arrows: widget.variations,
                              flipped: widget.flipped,
                              mirrored: widget.mirrored,
                              headStyle:
                                  widget.arrowHeadStyle ??
                                  BoardDisplayScope.arrowHeadOf(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (var row = 0; row < 10; row++)
                    for (var col = 0; col < 9; col++)
                      _cell(
                        Square(
                          widget.flipped != widget.mirrored ? 8 - col : col,
                          widget.flipped ? row : 9 - row,
                        ),
                        col,
                        row,
                        step,
                      ),
                  if (widget.lastMove != null)
                    Positioned.fill(
                      child: LastMoveMarkers(
                        animateOnMount: animateMarkerOnMount,
                        move: widget.lastMove!,
                        identity: widget.lastMoveIdentity ?? widget.lastMove!,
                        style:
                            widget.lastMoveMarkerStyle ??
                            BoardDisplayScope.lastMoveMarkerOf(context),
                        duration: BoardDisplayScope.animationSpeedOf(
                          context,
                        ).duration,
                        flipped: widget.flipped,
                        mirrored: widget.mirrored,
                      ),
                    ),
                  if (visibleAssessment != null)
                    Positioned.fill(
                      child: MoveGradeBadge(
                        square: widget.lastMove!.to,
                        grade: visibleAssessment!.grade,
                        flipped: widget.flipped,
                        mirrored: widget.mirrored,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
    return (widget.showCoordinates ?? BoardDisplayScope.coordinatesOf(context))
        ? BoardFileCoordinates(
            flipped: widget.flipped,
            mirrored: widget.mirrored,
            child: board,
          )
        : board;
  }

  Widget _face(
    Piece? piece,
    double step,
    bool selected,
    bool target, {
    bool focused = false,
  }) {
    final selectionStyle =
        widget.selectionStyle ?? BoardDisplayScope.selectionStyleOf(context);
    final rotateOppositePieces =
        widget.rotateOppositePieces ??
        BoardDisplayScope.rotateOppositePiecesOf(context);
    final pieceSkin =
        widget.pieceSkin ?? BoardDisplayScope.pieceSkinOf(context);
    final customImage = piece == null
        ? null
        : (widget.pieceImages ??
              BoardDisplayScope.pieceImagesOf(
                context,
              ))[PieceImageSlotInfo.forPiece(piece)!];
    final topSide = widget.flipped ? Side.red : Side.black;
    final rotateGlyph =
        piece != null && rotateOppositePieces && piece.side == topSide;
    final lifted =
        selected && piece != null && selectionStyle == SelectionStyle.lift;
    final face = Container(
      margin: EdgeInsets.all(step * .06),
      decoration: BoxDecoration(
        shape: pieceSkin == PieceSkin.roundSeal
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: pieceSkin == PieceSkin.squareInk
            ? BorderRadius.circular(step * .16)
            : null,
        color: selected
            ? const Color(0xffc6d8b2)
            : piece != null && customImage == null
            ? Color(pieceSkin.faceColor)
            : null,
        border: Border.all(
          color: selected || focused
              ? const Color(0xff3c624a)
              : piece != null && customImage == null
              ? Color(pieceSkin.borderColor)
              : Colors.transparent,
          width: selected ? 3 : 1.5,
        ),
        boxShadow:
            piece == null ||
                customImage != null ||
                pieceSkin == PieceSkin.squareInk
            ? null
            : lifted
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 7),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: piece == null
          ? Center(
              child: target
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xff3c624a),
                      ),
                    )
                  : null,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: RotatedBox(
                    quarterTurns: rotateGlyph ? 2 : 0,
                    child: customImage == null
                        ? FittedBox(
                            child: Text(
                              pieceName(piece),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: piece.side == Side.red
                                    ? const Color(0xffa12f29)
                                    : const Color(0xff26362d),
                              ),
                            ),
                          )
                        : Image.memory(
                            customImage,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => FittedBox(
                              child: Text(
                                pieceName(piece),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: piece.side == Side.red
                                      ? const Color(0xffa12f29)
                                      : const Color(0xff26362d),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (target)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.circle,
                      size: 12,
                      color: Color(0xff3c624a),
                    ),
                  ),
              ],
            ),
    );
    if (piece == null) return face;
    Widget scaled = Transform.scale(
      key: const ValueKey('piece-size'),
      scale:
          (widget.pieceSizePercent ?? BoardDisplayScope.pieceSizeOf(context)) /
          100 *
          (widget.pieceSkinSizePercent ??
              BoardDisplayScope.pieceSkinSizeOf(context)) /
          100,
      transformHitTests: false,
      child: face,
    );
    if (lifted) {
      scaled = Transform.translate(
        key: const ValueKey('selected-piece-lift'),
        offset: Offset(0, -step * .08),
        transformHitTests: false,
        child: scaled,
      );
    }
    final offsetX =
        widget.pieceSkinOffsetXPercent ??
        BoardDisplayScope.pieceSkinOffsetXOf(context);
    final offsetY =
        widget.pieceSkinOffsetYPercent ??
        BoardDisplayScope.pieceSkinOffsetYOf(context);
    if (offsetX != 0 || offsetY != 0) {
      scaled = Transform.translate(
        key: const ValueKey('piece-skin-position'),
        offset: Offset(step * offsetX / 100, step * offsetY / 100),
        transformHitTests: false,
        child: scaled,
      );
    }
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        scaled,
        if (selected && selectionStyle == SelectionStyle.frame)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: ValueKey('selected-piece-frame'),
                painter: SelectedPieceFramePainter(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cell(Square square, int col, int row, double step) {
    final piece = widget.at(square);
    final selected = widget.selected == square;
    final target = widget.targets.contains(square);
    final label =
        '${piece == null ? '空位' : '${piece.side == Side.red ? '红方' : '黑方'}${pieceName(piece)}'} $square${target ? ' 可落子' : ''}${visibleAssessment != null && square == widget.lastMove!.to ? '；${moveGradeDescription(visibleAssessment!)}' : ''}';
    Widget tile = Semantics(
      label: label,
      button: true,
      enabled: widget.enabled,
      selected: selected,
      onTap: widget.enabled ? () => _tap(square) : null,
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: GestureDetector(
            onSecondaryTap: widget.onRemove == null
                ? null
                : () => widget.onRemove!(square),
            child: InkWell(
              key: ValueKey('square-$square'),
              onTap: widget.enabled ? () => _tap(square) : null,
              borderRadius: BorderRadius.circular(step / 2),
              child: _face(
                piece,
                step,
                selected,
                target,
                focused: hasFocus && cursor == square,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.onDrop != null) {
      if (piece != null) {
        tile = Draggable<BoardDragData>(
          data: BoardDragData(piece, from: square),
          feedback: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: step,
              height: step,
              child: _face(piece, step, false, false),
            ),
          ),
          childWhenDragging: Opacity(opacity: .3, child: tile),
          onDragEnd: (details) {
            if (!details.wasAccepted && mounted) widget.onRemove?.call(square);
          },
          child: tile,
        );
      }
      final child = tile;
      tile = DragTarget<BoardDragData>(
        onWillAcceptWithDetails: (_) => widget.enabled,
        onAcceptWithDetails: (details) => widget.onDrop!(details.data, square),
        builder: (context, candidates, rejected) => DecoratedBox(
          decoration: BoxDecoration(
            color: candidates.isEmpty ? null : const Color(0x663c624a),
          ),
          child: child,
        ),
      );
    }
    return Positioned(
      left: col * step,
      top: row * step,
      width: step,
      height: step,
      child: tile,
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter(this.skin);
  final BoardSkin skin;
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    final paint = Paint()
      ..color = Color(skin.gridColor)
      ..strokeWidth = 1;
    Offset point(double x, double y) =>
        Offset((x + .5) * step, (y + .5) * step);
    for (var y = 0; y < 10; y++) {
      canvas.drawLine(point(0, y.toDouble()), point(8, y.toDouble()), paint);
    }
    for (var x = 0; x < 9; x++) {
      if (x == 0 || x == 8) {
        canvas.drawLine(point(x.toDouble(), 0), point(x.toDouble(), 9), paint);
      } else {
        canvas.drawLine(point(x.toDouble(), 0), point(x.toDouble(), 4), paint);
        canvas.drawLine(point(x.toDouble(), 5), point(x.toDouble(), 9), paint);
      }
    }
    for (final y in [0.0, 7.0]) {
      canvas.drawLine(point(3, y), point(5, y + 2), paint);
      canvas.drawLine(point(5, y), point(3, y + 2), paint);
    }
    final text = TextPainter(
      text: TextSpan(
        text: '楚 河          汉 界',
        style: TextStyle(
          color: Color(skin.labelColor),
          fontSize: 18,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    text.paint(
      canvas,
      Offset((size.width - text.width) / 2, step * 5 - text.height / 2),
    );
    text.dispose();
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      skin != oldDelegate.skin;
}
