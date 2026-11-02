import 'dart:async';
import 'dart:typed_data';

import 'package:chess_next/application/board_appearance.dart';
import 'package:chess_next/application/board_image_snapshot.dart';
import 'package:chess_next/features/export/board_image_dialog.dart';
import 'package:chess_next/ports/png_file_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

import '../support/pump_until.dart';

class RecordingPngExporter implements PngFileExporter {
  final images = <PngImage>[];
  Future<RecordFileExportResult> Function(FileExportCancellation)? handler;

  @override
  Future<RecordFileExportResult> savePng(
    PngImage image, {
    required FileExportCancellation cancellation,
  }) async {
    images.add(image);
    return handler?.call(cancellation) ?? RecordFileExportResult.saved;
  }
}

BoardImageSnapshot snapshot({bool flipped = false, bool mirrored = false}) =>
    BoardImageSnapshot(
      position: Position.initial(),
      showCoordinates: true,
      pieceSizePercent: 100,
      lastMoveStyle: LastMoveMarkerStyle.halo,
      arrowHead: ArrowHeadStyle.standard,
      flipped: flipped,
      mirrored: mirrored,
    );

Widget host(BoardImageDialog dialog, {double textScale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: dialog),
  ),
);

void main() {
  void desktop(WidgetTester tester, {Size size = const Size(900, 1200)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('preview owns a fixed 450 by 500 capture boundary', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(host(BoardImageDialog(snapshot: snapshot())));
    await tester.pumpAndSettle();
    final sizes = [
      for (final element in find.byType(RepaintBoundary).evaluate())
        tester.getSize(
          find.byElementPredicate((candidate) => candidate == element),
        ),
    ];
    expect(sizes, contains(const Size(450, 500)));
    expect(find.bySemanticsLabel('PNG局面快照'), findsOneWidget);
    expect(find.byKey(const ValueKey('square-a0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save reports success and reuses the captured immutable PNG', (
    tester,
  ) async {
    desktop(tester);
    final exporter = RecordingPngExporter();
    final bytes = Uint8List.fromList(const [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);
    var captures = 0;
    await tester.pumpWidget(
      host(
        BoardImageDialog(
          snapshot: snapshot(),
          exporter: exporter,
          capture: () async {
            captures++;
            return PngImage.fromBytes(bytes);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('保存图片'));
      await pumpUntil(tester, () => exporter.images.length == i + 1);
    }
    expect(captures, 1);
    expect(find.text('图片文件已保存'), findsOneWidget);
  });

  testWidgets('render failure is actionable and retry captures again', (
    tester,
  ) async {
    desktop(tester);
    final exporter = RecordingPngExporter();
    var captures = 0;
    await tester.pumpWidget(
      host(
        BoardImageDialog(
          snapshot: snapshot(),
          exporter: exporter,
          capture: () async {
            if (captures++ == 0) {
              throw const PngExportException(PngExportFailure.render);
            }
            return PngImage.fromBytes(
              Uint8List.fromList(const [
                137,
                80,
                78,
                71,
                13,
                10,
                26,
                10,
                0,
                0,
                0,
                13,
                73,
                72,
                68,
                82,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
              ]),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存图片'));
    await pumpUntil(
      tester,
      () => find.text('棋盘图片生成失败，请重试。').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('保存图片'));
    await pumpUntil(tester, () => exporter.images.length == 1);
    expect(captures, 2);
    expect(find.text('图片文件已保存'), findsOneWidget);
  });

  testWidgets('200 percent narrow preview stays read-only and scrollable', (
    tester,
  ) async {
    desktop(tester, size: const Size(520, 640));
    await tester.pumpWidget(
      host(BoardImageDialog(snapshot: snapshot(mirrored: true)), textScale: 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('当前设备暂不支持图片文件保存。'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存图片'),
    );
    expect(save.onPressed, isNull);
    final square = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('square-a0')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(square.properties.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing during late capture cancels before chooser and write', (
    tester,
  ) async {
    desktop(tester);
    final capture = Completer<PngImage>();
    final exporter = RecordingPngExporter();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BoardImageDialog(
                  snapshot: snapshot(),
                  exporter: exporter,
                  capture: () => capture.future,
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存图片'));
    await tester.pump();
    expect(find.text('正在保存…'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    capture.complete(
      PngImage.fromBytes(
        Uint8List.fromList(const [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
          73,
          72,
          68,
          82,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ]),
      ),
    );
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(exporter.images, isEmpty);
    expect(find.text('打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
