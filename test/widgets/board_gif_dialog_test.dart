import 'dart:typed_data';
import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_gif_snapshot.dart';
import 'package:chess_next/features/export/board_gif_dialog.dart';
import 'package:chess_next/ports/gif_file_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/pump_until.dart';

final class RecordingGifExporter implements GifFileExporter {
  final images = <GifImage>[];
  Future<RecordFileExportResult> Function(FileExportCancellation)? handler;
  @override
  Future<RecordFileExportResult> saveGif(
    GifImage image, {
    required FileExportCancellation cancellation,
  }) async {
    images.add(image);
    return handler?.call(cancellation) ?? RecordFileExportResult.saved;
  }
}

BoardGifSnapshot snapshot() => BoardGifSnapshot(
  frames: [
    BoardGifFrame(position: Position.initial()),
    BoardGifFrame(
      position: Position.initial().play(Move.parse('h2e2')),
      move: Move.parse('h2e2'),
    ),
  ],
  showCoordinates: true,
  pieceSizePercent: 100,
  lastMoveStyle: LastMoveMarkerStyle.halo,
  arrowHead: ArrowHeadStyle.standard,
);

GifImage actualGif(List<int> durations) {
  final frame = image.Image(width: 2, height: 2)
    ..clear(image.ColorRgba8(20, 40, 60, 255));
  final encoder = image.GifEncoder();
  for (final duration in durations) {
    encoder.addFrame(frame.clone(), duration: duration);
  }
  return GifImage.fromEncoded(
    encoder.finish()!,
    width: 2,
    height: 2,
    frameDurations: durations,
  );
}

Widget host(BoardGifDialog dialog, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: dialog),
  ),
);

void main() {
  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows full frozen line and fixed 450 by 540 frame', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(
      host(
        BoardGifDialog(
          snapshot: snapshot(),
          initialSettings: BoardGifSettings(),
          onSettingsChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2 帧（含根局面）'), findsOneWidget);
    expect(find.bySemanticsLabel('GIF画面预览'), findsOneWidget);
    final sizes = [
      for (final element in find.byType(RepaintBoundary).evaluate())
        tester.getSize(
          find.byElementPredicate((candidate) => candidate == element),
        ),
    ];
    expect(sizes, contains(const Size(450, 540)));
    expect(find.text('第 1 帧 / 共 2 帧'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '保存GIF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'generates preview with replacement delays and saves cached GIF',
    (tester) async {
      desktop(tester);
      final exporter = RecordingGifExporter();
      final captured = <int>[];
      final encodedDurations = <int>[];
      var remembered = BoardGifSettings();
      await tester.pumpWidget(
        host(
          BoardGifDialog(
            snapshot: snapshot(),
            initialSettings: remembered,
            onSettingsChanged: (value) => remembered = value,
            exporter: exporter,
            captureFrame: (index) async {
              captured.add(index);
              return Uint8List.fromList([index]);
            },
            encoder: (frames, durations) async {
              expect(frames.map((frame) => frame.single), [0, 1]);
              encodedDurations.addAll(durations);
              return actualGif(durations);
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '本机线路');
      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      sliders[0].onChanged!(2);
      sliders[1].onChanged!(3);
      sliders[2].onChanged!(4);
      await tester.pump();
      await tester.tap(find.text('生成预览'));
      await pumpUntil(
        tester,
        () => find.text('GIF预览已生成，可保存到本机。').evaluate().isNotEmpty,
      );
      expect(captured, [0, 1]);
      expect(encodedDurations, [30, 40]);
      expect(remembered.title, '本机线路');
      expect(find.bySemanticsLabel('已生成GIF动画预览'), findsOneWidget);
      await tester.tap(find.text('保存GIF'));
      await pumpUntil(
        tester,
        () => find.text('GIF文件已保存').evaluate().isNotEmpty,
      );
      expect(exporter.images, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'generation failure stays retryable and 200 percent layout scrolls',
    (tester) async {
      desktop(tester);
      var attempts = 0;
      await tester.pumpWidget(
        host(
          BoardGifDialog(
            snapshot: snapshot(),
            initialSettings: BoardGifSettings(),
            onSettingsChanged: (_) {},
            captureFrame: (_) async => Uint8List(1),
            encoder: (_, durations) async {
              attempts++;
              if (attempts == 1) {
                throw const GifExportException(GifExportFailure.encode);
              }
              return actualGif(durations);
            },
          ),
          textScale: 2,
        ),
      );
      await tester.tap(find.text('生成预览'));
      await pumpUntil(
        tester,
        () => find.text('GIF编码失败，请重试。').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('生成预览'));
      await tester.tap(find.text('生成预览'));
      await pumpUntil(
        tester,
        () => find.text('GIF预览已生成，可保存到本机。').evaluate().isNotEmpty,
      );
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
