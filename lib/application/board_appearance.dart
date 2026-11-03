/// Stable storage values. Drawing geometry belongs to the presentation layer.
enum ArrowHeadStyle { sharp, standard, wide }

enum LastMoveMarkerStyle { halo, box }

enum SelectionStyle { lift, frame }

enum BoardSkin { parchment, jade }

enum PieceSkin { roundSeal, squareInk }

extension BoardSkinPalette on BoardSkin {
  int get boardColor => switch (this) {
    BoardSkin.parchment => 0xfff1dfbf,
    BoardSkin.jade => 0xffe5eee4,
  };
  int get gridColor => switch (this) {
    BoardSkin.parchment => 0xff947c57,
    BoardSkin.jade => 0xff668270,
  };
  int get labelColor => switch (this) {
    BoardSkin.parchment => 0xff806b4d,
    BoardSkin.jade => 0xff587261,
  };
  int get pieceColor => switch (this) {
    BoardSkin.parchment => 0xfffff4da,
    BoardSkin.jade => 0xfff2f6ef,
  };
  int get pieceBorderColor => switch (this) {
    BoardSkin.parchment => 0xffbda177,
    BoardSkin.jade => 0xff9bb3a0,
  };
}

extension PieceSkinPalette on PieceSkin {
  int get faceColor => switch (this) {
    PieceSkin.roundSeal => 0xfffff4da,
    PieceSkin.squareInk => 0xfff2eddf,
  };
  int get borderColor => switch (this) {
    PieceSkin.roundSeal => 0xffbda177,
    PieceSkin.squareInk => 0xff756a58,
  };
}
