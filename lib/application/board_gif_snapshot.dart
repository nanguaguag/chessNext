import 'dart:typed_data';

import 'package:xiangqi_core/xiangqi_core.dart';
import 'app_preferences.dart';
import 'board_appearance.dart';
import 'board_session.dart';
import '../ports/piece_images.dart';

final class BoardGifCapacityException implements Exception {
  const BoardGifCapacityException(this.frames);
  final int frames;
}

final class BoardGifFrame {
  const BoardGifFrame({required this.position, this.move});
  final Position position;
  final Move? move;
}

/// Frozen root-to-selected-line frames. Sibling variations are never sampled.
final class BoardGifSnapshot {
  BoardGifSnapshot({
    required Iterable<BoardGifFrame> frames,
    required this.showCoordinates,
    required this.pieceSizePercent,
    this.pieceSkinSizePercent = 100,
    required this.lastMoveStyle,
    required this.arrowHead,
    this.flipped = false,
    this.mirrored = false,
    this.rotateOppositePieces = false,
    this.boardSkin = BoardSkin.parchment,
    this.pieceSkin = PieceSkin.roundSeal,
    Map<PieceImageSlot, Uint8List> pieceImages = const {},
  }) : pieceImages = Map.unmodifiable({
         for (final entry in pieceImages.entries)
           entry.key: Uint8List.fromList(entry.value).asUnmodifiableView(),
       }),
       frames = List.unmodifiable(frames) {
    if (this.frames.isEmpty || this.frames.length > maxFrames) {
      throw BoardGifCapacityException(this.frames.length);
    }
  }

  factory BoardGifSnapshot.capture(
    BoardSession session,
    AppPreferences prefs, {
    Map<PieceImageSlot, Uint8List> pieceImages = const {},
  }) {
    final nodes = session.tree.currentLine;
    if (nodes.length > maxFrames) throw BoardGifCapacityException(nodes.length);
    return BoardGifSnapshot(
      frames: [
        for (final node in nodes)
          BoardGifFrame(position: node.position, move: node.move),
      ],
      showCoordinates: prefs.showCoordinates,
      pieceSizePercent: prefs.pieceSizePercent,
      pieceSkinSizePercent: prefs.pieceSkin == PieceSkin.roundSeal
          ? prefs.roundSealPieceScalePercent
          : prefs.squareInkPieceScalePercent,
      lastMoveStyle: prefs.lastMoveMarker,
      arrowHead: prefs.arrowHead,
      flipped: session.flipped,
      mirrored: session.mirrored,
      rotateOppositePieces: prefs.rotateOppositePieces,
      boardSkin: prefs.boardSkin,
      pieceSkin: prefs.pieceSkin,
      pieceImages: pieceImages,
    );
  }

  static const maxFrames = 64;
  final List<BoardGifFrame> frames;
  final bool flipped, mirrored, showCoordinates, rotateOppositePieces;
  final BoardSkin boardSkin;
  final PieceSkin pieceSkin;
  final Map<PieceImageSlot, Uint8List> pieceImages;
  final int pieceSizePercent;
  final int pieceSkinSizePercent;
  final LastMoveMarkerStyle lastMoveStyle;
  final ArrowHeadStyle arrowHead;
}

/// Tenths avoid floating-point drift and match the observed 0.1-second controls.
final class BoardGifSettings {
  BoardGifSettings({
    this.title = '',
    this.stepTenths = 20,
    this.openingTenths = 20,
    this.endingTenths = 30,
  }) {
    if (title.length > maxTitleLength) {
      throw ArgumentError.value(title, 'title');
    }
    if (stepTenths < 2 || stepTenths > 100) {
      throw ArgumentError.value(stepTenths, 'stepTenths');
    }
    if (openingTenths < 2 || openingTenths > 300) {
      throw ArgumentError.value(openingTenths, 'openingTenths');
    }
    if (endingTenths < 2 || endingTenths > 300) {
      throw ArgumentError.value(endingTenths, 'endingTenths');
    }
  }

  static const maxTitleLength = 60;
  final String title;
  final int stepTenths, openingTenths, endingTenths;

  List<int> durationsCentiseconds(int frameCount) {
    if (frameCount < 1 || frameCount > BoardGifSnapshot.maxFrames) {
      throw ArgumentError.value(frameCount, 'frameCount');
    }
    if (frameCount == 1) return [openingTenths * 10];
    return [
      openingTenths * 10,
      for (var i = 1; i < frameCount - 1; i++) stepTenths * 10,
      endingTenths * 10,
    ];
  }

  BoardGifSettings copyWith({
    String? title,
    int? stepTenths,
    int? openingTenths,
    int? endingTenths,
  }) => BoardGifSettings(
    title: title ?? this.title,
    stepTenths: stepTenths ?? this.stepTenths,
    openingTenths: openingTenths ?? this.openingTenths,
    endingTenths: endingTenths ?? this.endingTenths,
  );
}
