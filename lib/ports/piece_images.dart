import 'dart:typed_data';

import 'package:xiangqi_core/xiangqi_core.dart';

enum PieceSkin { roundSeal, squareInk }

enum PieceImageSlot {
  redRook,
  redHorse,
  redElephant,
  redAdvisor,
  redGeneral,
  redCannon,
  redPawn,
  blackRook,
  blackHorse,
  blackElephant,
  blackAdvisor,
  blackGeneral,
  blackCannon,
  blackPawn,
}

extension PieceImageSlotInfo on PieceImageSlot {
  String get label => switch (this) {
    PieceImageSlot.redRook => '红车',
    PieceImageSlot.redHorse => '红马',
    PieceImageSlot.redElephant => '红相',
    PieceImageSlot.redAdvisor => '红仕',
    PieceImageSlot.redGeneral => '红帅',
    PieceImageSlot.redCannon => '红炮',
    PieceImageSlot.redPawn => '红兵',
    PieceImageSlot.blackRook => '黑车',
    PieceImageSlot.blackHorse => '黑马',
    PieceImageSlot.blackElephant => '黑象',
    PieceImageSlot.blackAdvisor => '黑士',
    PieceImageSlot.blackGeneral => '黑将',
    PieceImageSlot.blackCannon => '黑炮',
    PieceImageSlot.blackPawn => '黑卒',
  };

  static PieceImageSlot? forPiece(Piece piece) =>
      switch ((piece.side, piece.type)) {
        (Side.red, PieceType.rook) => PieceImageSlot.redRook,
        (Side.red, PieceType.horse) => PieceImageSlot.redHorse,
        (Side.red, PieceType.elephant) => PieceImageSlot.redElephant,
        (Side.red, PieceType.advisor) => PieceImageSlot.redAdvisor,
        (Side.red, PieceType.general) => PieceImageSlot.redGeneral,
        (Side.red, PieceType.cannon) => PieceImageSlot.redCannon,
        (Side.red, PieceType.pawn) => PieceImageSlot.redPawn,
        (Side.black, PieceType.rook) => PieceImageSlot.blackRook,
        (Side.black, PieceType.horse) => PieceImageSlot.blackHorse,
        (Side.black, PieceType.elephant) => PieceImageSlot.blackElephant,
        (Side.black, PieceType.advisor) => PieceImageSlot.blackAdvisor,
        (Side.black, PieceType.general) => PieceImageSlot.blackGeneral,
        (Side.black, PieceType.cannon) => PieceImageSlot.blackCannon,
        (Side.black, PieceType.pawn) => PieceImageSlot.blackPawn,
      };
}

abstract final class PieceImageLimits {
  static const maxBytes = 512 * 1024;
  static const maxDimension = 1024;
  static const maxPixels = 1024 * 1024;
  static const maxBatchFiles = 14;
  static const maxBatchBytes = maxBytes * maxBatchFiles;
}

final class SelectedPieceImage {
  SelectedPieceImage(this.extension, Uint8List bytes)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final String extension;
  final Uint8List bytes;
}

final class NamedPieceImage {
  const NamedPieceImage({required this.name, required this.image});
  final String name;
  final SelectedPieceImage image;
}

enum PieceImageFailure {
  tooLarge,
  format,
  dimensions,
  read,
  unavailable,
  write,
  batchLimit,
}

class PieceImageException implements Exception {
  const PieceImageException(this.failure);
  final PieceImageFailure failure;
  String get message => switch (failure) {
    PieceImageFailure.tooLarge => '棋子图片不能超过512 KiB。',
    PieceImageFailure.format => '请选择有效的 PNG 或 JPEG 图片。',
    PieceImageFailure.dimensions => '图片尺寸不能超过1024×1024像素。',
    PieceImageFailure.read => '无法读取所选图片，请确认文件仍可用。',
    PieceImageFailure.unavailable => '当前平台的本机图片选择器不可用。',
    PieceImageFailure.write => '棋子图片未能保存在本机，请重试。',
    PieceImageFailure.batchLimit => '一次最多导入14张图片，总大小不能超过7 MiB。',
  };
}

abstract interface class PieceImagePicker {
  Future<SelectedPieceImage?> pickImage();
}

abstract interface class PieceImageBatchPicker {
  Future<List<NamedPieceImage>?> pickImages();
}

abstract interface class PieceImageRepository {
  Future<Map<String, Map<PieceImageSlot, Uint8List>>> load();
  Future<void> save(
    String skinId,
    PieceImageSlot slot,
    String extension,
    Uint8List bytes,
  );
  Future<void> remove(String skinId, PieceImageSlot slot);
  Future<void> removeSkin(String skinId);
  Future<void> cloneSkin(String sourceId, String destinationId);
}
