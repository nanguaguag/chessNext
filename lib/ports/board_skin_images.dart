import 'dart:typed_data';

enum BoardSkin { parchment, jade }

enum BoardSkinImageSlot {
  boardBackground,
  startMarker,
  landingMarker,
  selectionFrame,
}

extension BoardSkinImageSlotInfo on BoardSkinImageSlot {
  String get label => switch (this) {
    BoardSkinImageSlot.boardBackground => '棋盘背景',
    BoardSkinImageSlot.startMarker => '起点标记',
    BoardSkinImageSlot.landingMarker => '落点标记',
    BoardSkinImageSlot.selectionFrame => '选中框',
  };
}

abstract interface class BoardSkinImageRepository {
  Future<Map<BoardSkin, Map<BoardSkinImageSlot, Uint8List>>> load();
  Future<void> save(
    BoardSkin skin,
    BoardSkinImageSlot slot,
    String extension,
    Uint8List bytes,
  );
  Future<void> remove(BoardSkin skin, BoardSkinImageSlot slot);
}
