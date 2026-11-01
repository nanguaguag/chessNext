import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_session.dart';

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

class XiangqiBoard extends StatefulWidget {
  const XiangqiBoard({
    super.key,
    required this.session,
    this.recommendation,
    this.reply,
  });
  final Move? recommendation;
  final Move? reply;
  final BoardSession session;
  @override
  State<XiangqiBoard> createState() => _XiangqiBoardState();
}

class _XiangqiBoardState extends State<XiangqiBoard> {
  final boardFocus = FocusNode(debugLabel: 'xiangqi-board');
  @override
  void dispose() {
    boardFocus.dispose();
    super.dispose();
  }

  void _tap(Square square) {
    boardFocus.requestFocus();
    setState(() => cursor = square);
    widget.session.tap(square);
  }

  Square cursor = Square(4, 0);
  bool hasFocus = false;
  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.session.cancelSelection();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      widget.session.tap(cursor);
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
      final sign = widget.session.flipped ? -1 : 1;
      setState(
        () => cursor = Square(
          (cursor.file + dx * sign).clamp(0, 8),
          (cursor.rank + dy * sign).clamp(0, 9),
        ),
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final targets = session.targets;
    return Focus(
      autofocus: true,
      focusNode: boardFocus,
      onKeyEvent: _key,
      onFocusChange: (value) => setState(() => hasFocus = value),
      child: AspectRatio(
        aspectRatio: 9 / 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final step = constraints.maxWidth / 9;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xfff1dfbf),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BoardPainter(
                        recommendation: widget.recommendation,
                        reply: widget.reply,
                        flipped: session.flipped,
                      ),
                    ),
                  ),
                  for (var row = 0; row < 10; row++)
                    for (var col = 0; col < 9; col++)
                      _cell(
                        context,
                        Square(
                          session.flipped ? 8 - col : col,
                          session.flipped ? row : 9 - row,
                        ),
                        col,
                        row,
                        step,
                        targets,
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    Square square,
    int col,
    int row,
    double step,
    Set<Square> targets,
  ) {
    final session = widget.session;
    final piece = session.position.at(square);
    final selected = session.selected == square;
    final target = targets.contains(square);
    final label =
        '${piece == null ? '空位' : '${piece.side == Side.red ? '红方' : '黑方'}${pieceName(piece)}'} $square${target ? ' 可落子' : ''}';
    return Positioned(
      left: col * step,
      top: row * step,
      width: step,
      height: step,
      child: Semantics(
        label: label,
        button: true,
        enabled: !session.inputLocked && !session.outcome.isTerminal,
        selected: selected,
        onTap: () => _tap(square),
        child: ExcludeSemantics(
          child: ExcludeFocus(
            child: InkWell(
              key: ValueKey('square-$square'),
              onTap: () => _tap(square),
              borderRadius: BorderRadius.circular(step / 2),
              child: Container(
                margin: EdgeInsets.all(step * .06),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xffc6d8b2)
                      : piece != null
                      ? const Color(0xfffff4da)
                      : null,
                  border: Border.all(
                    color: selected || (hasFocus && cursor == square)
                        ? const Color(0xff3c624a)
                        : piece != null
                        ? const Color(0xffbda177)
                        : Colors.transparent,
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: piece == null
                      ? null
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
                            child: FittedBox(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({this.recommendation, this.reply, this.flipped = false});
  final Move? recommendation;
  final Move? reply;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 9;
    final paint = Paint()
      ..color = const Color(0xff947c57)
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
      text: const TextSpan(
        text: '楚 河          汉 界',
        style: TextStyle(
          color: Color(0xff806b4d),
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
    void arrow(Move move, Color color) {
      Offset location(Square square) => point(
        (flipped ? 8 - square.file : square.file).toDouble(),
        (flipped ? square.rank : 9 - square.rank).toDouble(),
      );
      final from = location(move.from);
      final to = location(move.to);
      final distance = (to - from).distance;
      if (distance == 0) return;
      final unit = (to - from) / distance;
      final start = from + unit * step * .3;
      final end = to - unit * step * .3;
      final arrowPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, arrowPaint);
      final wing = Offset(-unit.dy, unit.dx) * step * .12;
      final base = end - unit * step * .22;
      final head = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo((base + wing).dx, (base + wing).dy)
        ..lineTo((base - wing).dx, (base - wing).dy)
        ..close();
      canvas.drawPath(head, arrowPaint);
    }

    if (reply != null) arrow(reply!, const Color(0xff965ba3));
    if (recommendation != null) arrow(recommendation!, const Color(0xff226b9c));
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      recommendation != oldDelegate.recommendation ||
      reply != oldDelegate.reply ||
      flipped != oldDelegate.flipped;
}
