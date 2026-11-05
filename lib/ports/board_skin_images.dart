import 'dart:typed_data';

enum BoardSkin { parchment, jade }

extension BoardSkinInfo on BoardSkin {
  String get label => switch (this) {
    BoardSkin.parchment => '宣纸木色',
    BoardSkin.jade => '松石青',
  };
}

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
  Future<Map<String, Map<BoardSkinImageSlot, Uint8List>>> load();
  Future<void> save(
    String skinId,
    BoardSkinImageSlot slot,
    String extension,
    Uint8List bytes,
  );
  Future<void> remove(String skinId, BoardSkinImageSlot slot);
  Future<void> removeSkin(String skinId);
  Future<void> cloneSkin(String sourceId, String destinationId);
  Future<void> pruneCustomSkins(Set<String> retainedIds);
}
