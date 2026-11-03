import 'dart:typed_data';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_gif_encoder.dart';
import 'package:chess_next/application/board_gif_snapshot.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/ports/gif_file_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  test('snapshot freezes root plus selected future and excludes sibling', () {
    var tree = GameTree()
        .play(Move.parse('h2e2'))
        .play(Move.parse('b9c7'))
        .play(Move.parse('h0g2'));
    tree = tree.goTo('n1').play(Move.parse('h9g7'));
    tree = tree.goTo('n2');
    final session = BoardSession()..replaceTree(tree, saved: false);
    session.mirror();
    final snapshot = BoardGifSnapshot.capture(
      session,
      AppPreferences(
        boardSkin: BoardSkin.jade,
        pieceSkin: PieceSkin.squareInk,
        squareInkPieceScalePercent: 115,
        squareInkPieceOffsetX: 3,
        squareInkPieceOffsetY: -2,
        pieceSkinShadows: {
          PieceSkin.squareInk: PieceSkinShadow(
            style: PieceShadowStyle.soft,
            angleDegrees: 120,
            distancePercent: 5,
            blurPercent: 3,
            opacityPercent: 45,
          ),
        },
      ),
      pieceSkinSizePercent: 117,
      pieceSkinOffsetXPercent: -4,
      pieceSkinOffsetYPercent: 6,
      pieceSkinShadow: const PieceSkinShadow.standard(),
    );
    expect(snapshot.frames.map((frame) => frame.move?.toString()), [
      null,
      'h2e2',
      'b9c7',
      'h0g2',
    ]);
    expect(snapshot.mirrored, isTrue);
    expect(snapshot.boardSkin, BoardSkin.jade);
    expect(snapshot.pieceSkin, PieceSkin.squareInk);
    expect(snapshot.pieceSkinSizePercent, 117);
    expect(snapshot.pieceSkinOffsetXPercent, -4);
    expect(snapshot.pieceSkinOffsetYPercent, 6);
    expect(snapshot.pieceSkinShadow, const PieceSkinShadow.standard());
    session.playVariation('n2', Move.parse('b0c2'));
    expect(snapshot.frames.length, 4);
    expect(snapshot.frames.last.move, Move.parse('h0g2'));
  });

  test('settings use replacement opening and ending frame delays', () {
    final settings = BoardGifSettings(
      title: '',
      stepTenths: 2,
      openingTenths: 3,
      endingTenths: 4,
    );
    expect(settings.durationsCentiseconds(6), [30, 20, 20, 20, 20, 40]);
    expect(settings.durationsCentiseconds(1), [30]);
    expect(() => BoardGifSettings(stepTenths: 1), throwsArgumentError);
    expect(
      () => BoardGifSettings(title: List.filled(61, 'x').join()),
      throwsArgumentError,
    );
  });

  test('snapshot refuses over 64 frames instead of truncating', () {
    final frame = BoardGifFrame(position: Position.initial());
    expect(
      () => BoardGifSnapshot(
        frames: List.filled(65, frame),
        showCoordinates: true,
        pieceSizePercent: 100,
        lastMoveStyle: LastMoveMarkerStyle.halo,
        arrowHead: ArrowHeadStyle.standard,
      ),
      throwsA(isA<BoardGifCapacityException>()),
    );
  });

  test('encoder creates bounded animation with exact delays', () async {
    Uint8List png(int color) => Uint8List.fromList(
      image.encodePng(
        image.Image(width: 2, height: 2)
          ..clear(image.ColorRgba8(color, 0, 0, 255)),
      ),
    );
    final gif = await encodeBoardGif([png(10), png(200)], [30, 40]);
    expect(String.fromCharCodes(gif.bytes.take(6)), 'GIF89a');
    expect(gif.width, 2);
    expect(gif.height, 2);
    expect(gif.frameCount, 2);
    expect(gif.frameDurations, [30, 40]);
    final decoded = image.decodeGif(gif.bytes)!;
    expect(decoded.numFrames, 2);
    expect(decoded.frames.map((frame) => frame.frameDuration), [300, 400]);
    expect(() => gif.bytes[0] = 0, throwsUnsupportedError);
  });

  test(
    'encoder rejects mismatched frame dimensions and invalid metadata',
    () async {
      Uint8List png(int width) => Uint8List.fromList(
        image.encodePng(image.Image(width: width, height: 1)),
      );
      await expectLater(
        encodeBoardGif([png(1), png(2)], [20, 20]),
        throwsA(
          isA<GifExportException>().having(
            (error) => error.failure,
            'failure',
            GifExportFailure.encode,
          ),
        ),
      );
      expect(
        () => GifImage.fromEncoded(
          Uint8List.fromList('GIF89a\x01\x00\x01\x00'.codeUnits),
          width: 1,
          height: 1,
          frameDurations: const [10],
        ),
        throwsA(isA<GifExportException>()),
      );
    },
  );
}
