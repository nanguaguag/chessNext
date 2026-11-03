import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_skin_geometry.dart';

/// Dedicated rails keep labels outside the grid and never intercept a square.
class BoardFileCoordinates extends StatelessWidget {
  const BoardFileCoordinates({
    super.key,
    required this.child,
    this.flipped = false,
    this.mirrored = false,
    this.geometry = const BoardSkinGeometry.standard(),
  });
  final Widget child;
  final bool flipped, mirrored;
  final BoardSkinGeometry geometry;
  String _fileLabel(Side side, int file) =>
      side == Side.red ? '九八七六五四三二一'[file] : '${file + 1}';
  Widget _rail(Side side, String edge, double height, double boardWidth) {
    final labels = [
      for (var column = 0; column < 9; column++)
        _fileLabel(side, flipped != mirrored ? 8 - column : column),
    ];
    return Semantics(
      container: true,
      label:
          '${edge == 'top' ? '顶部' : '底部'}${side == Side.red ? '红方' : '黑方'}路数：${labels.join('、')}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: boardWidth,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var column = 0; column < 9; column++)
                Positioned(
                  left: _gridX(column) * boardWidth - 12,
                  top: 0,
                  bottom: 0,
                  width: 24,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[column],
                        key: ValueKey('coordinate-$edge-$column'),
                        style: TextStyle(
                          fontSize: 14,
                          color: side == Side.red
                              ? const Color(0xffa12f29)
                              : const Color(0xff26362d),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _gridX(int column) =>
      (geometry.leftPercent +
          (geometry.rightPercent - geometry.leftPercent) * column / 8) /
      100;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 9 / 10,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final vertical = (constraints.maxWidth * .035).clamp(12.0, 24.0);
        final horizontal = vertical * .9;
        final boardWidth = constraints.maxWidth - horizontal * 2;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xfff1dfbf),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Column(
              children: [
                _rail(
                  flipped ? Side.red : Side.black,
                  'top',
                  vertical,
                  boardWidth,
                ),
                Expanded(child: child),
                _rail(
                  flipped ? Side.black : Side.red,
                  'bottom',
                  vertical,
                  boardWidth,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
