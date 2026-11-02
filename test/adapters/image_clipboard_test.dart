import 'dart:async';

import 'package:chess_next/adapters/platform/macos_image_clipboard.dart';
import 'package:chess_next/ports/image_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

PngImage image() {
  final bytes = Uint8List(33);
  bytes.setAll(0, const [137, 80, 78, 71, 13, 10, 26, 10]);
  ByteData.sublistView(bytes).setUint32(8, 13);
  bytes.setAll(12, const [73, 72, 68, 82]);
  ByteData.sublistView(bytes).setUint32(16, 1);
  ByteData.sublistView(bytes).setUint32(20, 1);
  return PngImage.fromBytes(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  Matcher failure(ImageCopyFailure kind) => isA<ImageCopyException>().having(
    (error) => error.failure,
    'failure',
    kind,
  );

  test('writes the exact immutable PNG once', () async {
    final png = image();
    var writes = 0;
    final result = await MacOsImageClipboard(
      writer: (bytes) async {
        writes++;
        expect(bytes, orderedEquals(png.bytes));
        expect(() => bytes[0] = 0, throwsUnsupportedError);
      },
    ).copyPng(png, cancellation: ImageCopyCancellation());
    expect(result, ImageCopyResult.copied);
    expect(writes, 1);
  });

  test(
    'cancelled operation never starts and a started write completes',
    () async {
      final token = ImageCopyCancellation()..cancel();
      expect(
        await MacOsImageClipboard(
          writer: (_) async => throw StateError('must not write'),
        ).copyPng(image(), cancellation: token),
        ImageCopyResult.cancelled,
      );
      final started = Completer<void>(), finish = Completer<void>();
      final active = ImageCopyCancellation();
      final result = MacOsImageClipboard(
        writer: (_) async {
          started.complete();
          await finish.future;
        },
      ).copyPng(image(), cancellation: active);
      await started.future;
      active.cancel();
      finish.complete();
      expect(await result, ImageCopyResult.copied);
    },
  );

  test('unsupported platform and native failures stay typed', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await expectLater(
      MacOsImageClipboard(
        writer: (_) async => throw StateError('must not write'),
      ).copyPng(image(), cancellation: ImageCopyCancellation()),
      throwsA(failure(ImageCopyFailure.unavailable)),
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await expectLater(
      MacOsImageClipboard(
        writer: (_) async => throw MissingPluginException(),
      ).copyPng(image(), cancellation: ImageCopyCancellation()),
      throwsA(failure(ImageCopyFailure.unavailable)),
    );
    await expectLater(
      MacOsImageClipboard(
        writer: (_) async => throw PlatformException(
          code: 'clipboard_failed',
          message: '/private/value',
        ),
      ).copyPng(image(), cancellation: ImageCopyCancellation()),
      throwsA(failure(ImageCopyFailure.write)),
    );
    expect(
      const ImageCopyException(ImageCopyFailure.write).message,
      isNot(contains('/private')),
    );
  });

  test('native bridge uses dedicated binary clipboard method', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(MacOsImageClipboard.channel, null),
    );
    final png = image();
    messenger.setMockMethodCallHandler(MacOsImageClipboard.channel, (
      call,
    ) async {
      expect(call.method, 'copyPng');
      final args = call.arguments as Map;
      expect(args.keys, unorderedEquals(['bytes']));
      expect(args['bytes'], orderedEquals(png.bytes));
      return null;
    });
    expect(
      await MacOsImageClipboard().copyPng(
        png,
        cancellation: ImageCopyCancellation(),
      ),
      ImageCopyResult.copied,
    );
  });
}
