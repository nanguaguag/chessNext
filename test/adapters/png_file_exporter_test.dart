import 'dart:async';

import 'package:chess_next/adapters/platform/macos_png_file_exporter.dart';
import 'package:chess_next/ports/png_file_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pngHeader() {
  final bytes = Uint8List(33);
  bytes.setAll(0, const [137, 80, 78, 71, 13, 10, 26, 10]);
  ByteData.sublistView(bytes).setUint32(8, 13);
  bytes.setAll(12, const [73, 72, 68, 82]);
  ByteData.sublistView(bytes).setUint32(16, 1);
  ByteData.sublistView(bytes).setUint32(20, 1);
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PngImage image;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    image = PngImage.fromBytes(pngHeader());
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  Matcher failure(PngExportFailure kind) => isA<PngExportException>().having(
    (error) => error.failure,
    'failure',
    kind,
  );

  test('writes the exact owned snapshot to the selected destination', () async {
    String? selected;
    final result = await MacOsPngFileExporter(
      chooser: (extension) async {
        expect(extension, 'png');
        return '/selected/board.png';
      },
      writer: (path, bytes) async {
        selected = path;
        expect(bytes, orderedEquals(image.bytes));
        expect(() => bytes[0] = 0, throwsUnsupportedError);
      },
    ).savePng(image, cancellation: FileExportCancellation());
    expect(result, RecordFileExportResult.saved);
    expect(selected, '/selected/board.png');
  });

  test('cancellation before and after chooser never starts writing', () async {
    final cancelled = FileExportCancellation()..cancel();
    final service = MacOsPngFileExporter(
      chooser: (_) async => throw StateError('must not choose'),
      writer: (_, _) async => throw StateError('must not write'),
    );
    expect(
      await service.savePng(image, cancellation: cancelled),
      RecordFileExportResult.cancelled,
    );
    final gate = Completer<String?>();
    final token = FileExportCancellation();
    final late = MacOsPngFileExporter(
      chooser: (_) => gate.future,
      writer: (_, _) async => throw StateError('must not write'),
    ).savePng(image, cancellation: token);
    token.cancel();
    gate.complete('/selected/late.png');
    expect(await late, RecordFileExportResult.cancelled);
  });

  test('a started atomic write finishes despite later cancellation', () async {
    final started = Completer<void>(), finish = Completer<void>();
    final token = FileExportCancellation();
    final result = MacOsPngFileExporter(
      chooser: (_) async => '/selected/board.png',
      writer: (_, _) async {
        started.complete();
        await finish.future;
      },
    ).savePng(image, cancellation: token);
    await started.future;
    token.cancel();
    finish.complete();
    expect(await result, RecordFileExportResult.saved);
  });

  test('unsupported, chooser and writer failures remain typed', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await expectLater(
      MacOsPngFileExporter(
        chooser: (_) async => throw StateError('must not choose'),
      ).savePng(image, cancellation: FileExportCancellation()),
      throwsA(failure(PngExportFailure.unavailable)),
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await expectLater(
      MacOsPngFileExporter(
        chooser: (_) async => throw StateError('/private/path'),
      ).savePng(image, cancellation: FileExportCancellation()),
      throwsA(failure(PngExportFailure.selection)),
    );
    await expectLater(
      MacOsPngFileExporter(
        chooser: (_) async => throw MissingPluginException(),
      ).savePng(image, cancellation: FileExportCancellation()),
      throwsA(failure(PngExportFailure.unavailable)),
    );
    await expectLater(
      MacOsPngFileExporter(
        chooser: (_) async => '/selected/board.png',
        writer: (_, _) async => throw StateError('/private/path'),
      ).savePng(image, cancellation: FileExportCancellation()),
      throwsA(failure(PngExportFailure.write)),
    );
    await expectLater(
      MacOsPngFileExporter(
        chooser: (_) async => '/selected/board.png',
        writer: (_, _) async => throw MissingPluginException(),
      ).savePng(image, cancellation: FileExportCancellation()),
      throwsA(failure(PngExportFailure.unavailable)),
    );
  });

  test('native bridge uses the dedicated binary method', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        MacOsPngFileExporter.channel,
        null,
      ),
    );
    messenger.setMockMethodCallHandler(MacOsPngFileExporter.channel, (
      call,
    ) async {
      expect(call.method, 'writePngAtomic');
      final args = call.arguments as Map;
      expect(args['path'], '/selected/board.png');
      expect(args['bytes'], orderedEquals(image.bytes));
      return null;
    });
    expect(
      await MacOsPngFileExporter(
        chooser: (_) async => '/selected/board.png',
      ).savePng(image, cancellation: FileExportCancellation()),
      RecordFileExportResult.saved,
    );
  });
}
