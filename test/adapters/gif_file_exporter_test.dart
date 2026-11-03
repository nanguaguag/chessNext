import 'dart:async';
import 'package:chess_next/adapters/platform/macos_gif_file_exporter.dart';
import 'package:chess_next/ports/gif_file_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

GifImage gifImage() => GifImage.fromEncoded(
  Uint8List.fromList([...'GIF89a'.codeUnits, 1, 0, 1, 0, 0, 0, 0, 0]),
  width: 1,
  height: 1,
  frameDurations: const [20],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('writes exact owned GIF and preserves cancellation boundary', () async {
    final image = gifImage();
    final service = MacOsGifFileExporter(
      chooser: (extension) async {
        expect(extension, 'gif');
        return '/selected/line.gif';
      },
      writer: (path, bytes) async {
        expect(path, '/selected/line.gif');
        expect(bytes, orderedEquals(image.bytes));
      },
    );
    expect(
      await service.saveGif(image, cancellation: FileExportCancellation()),
      RecordFileExportResult.saved,
    );
    final gate = Completer<String?>();
    final token = FileExportCancellation();
    var wrote = false;
    final late = MacOsGifFileExporter(
      chooser: (_) => gate.future,
      writer: (_, _) async => wrote = true,
    ).saveGif(image, cancellation: token);
    token.cancel();
    gate.complete('/selected/late.gif');
    expect(await late, RecordFileExportResult.cancelled);
    expect(wrote, isFalse);
  });

  test('bridge method and failures remain GIF-specific', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        MacOsGifFileExporter.channel,
        null,
      ),
    );
    messenger.setMockMethodCallHandler(MacOsGifFileExporter.channel, (
      call,
    ) async {
      expect(call.method, 'writeGifAtomic');
      expect((call.arguments as Map)['path'], '/selected/line.gif');
      return null;
    });
    expect(
      await MacOsGifFileExporter(
        chooser: (_) async => '/selected/line.gif',
      ).saveGif(gifImage(), cancellation: FileExportCancellation()),
      RecordFileExportResult.saved,
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await expectLater(
      MacOsGifFileExporter().saveGif(
        gifImage(),
        cancellation: FileExportCancellation(),
      ),
      throwsA(
        isA<GifExportException>().having(
          (error) => error.failure,
          'failure',
          GifExportFailure.unavailable,
        ),
      ),
    );
  });
}
