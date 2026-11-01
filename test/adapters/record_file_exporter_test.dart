import 'dart:async';
import 'dart:convert';
import 'package:chess_next/adapters/platform/macos_record_file_exporter.dart';
import 'package:chess_next/ports/record_file_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  Matcher failure(RecordExportFailure kind) =>
      isA<RecordExportException>().having((e) => e.failure, 'failure', kind);
  Future<RecordFileExportResult> save(
    MacOsRecordFileExporter service, {
    String text = '自制棋谱',
    String extension = 'pgn',
    FileExportCancellation? token,
  }) => service.saveText(
    text: text,
    extension: extension,
    cancellation: token ?? FileExportCancellation(),
  );

  test(
    'selected destination receives the exact UTF8 snapshot and extension',
    () async {
      String? path;
      final service = MacOsRecordFileExporter(
        chooser: (extension) async {
          expect(extension, 'pgn');
          return '/selected/test.pgn';
        },
        writer: (target, bytes) async {
          path = target;
          expect(utf8.decode(bytes), '自制棋谱');
        },
      );
      expect(await save(service), RecordFileExportResult.saved);
      expect(path, '/selected/test.pgn');
    },
  );
  test('cancelled token never opens a chooser or writes', () async {
    final token = FileExportCancellation()..cancel();
    expect(
      await save(
        MacOsRecordFileExporter(
          chooser: (_) async => throw StateError('must not choose'),
          writer: (_, _) async => throw StateError('must not write'),
        ),
        token: token,
      ),
      RecordFileExportResult.cancelled,
    );
  });
  test('native cancel does not write', () async {
    expect(
      await save(
        MacOsRecordFileExporter(
          chooser: (_) async => null,
          writer: (_, _) async => throw StateError('must not write'),
        ),
      ),
      RecordFileExportResult.cancelled,
    );
  });
  test('late chooser result is discarded after cancellation', () async {
    final gate = Completer<String?>();
    final token = FileExportCancellation();
    final result = save(
      MacOsRecordFileExporter(
        chooser: (_) => gate.future,
        writer: (_, _) async => throw StateError('late write'),
      ),
      token: token,
    );
    token.cancel();
    gate.complete('/selected/late.pgn');
    expect(await result, RecordFileExportResult.cancelled);
  });
  test(
    'a started write finishes instead of pretending cancellation rolled it back',
    () async {
      final writing = Completer<void>(), finish = Completer<void>();
      final token = FileExportCancellation();
      final result = save(
        MacOsRecordFileExporter(
          chooser: (_) async => '/selected/file.pgn',
          writer: (_, _) async {
            writing.complete();
            await finish.future;
          },
        ),
        token: token,
      );
      await writing.future;
      token.cancel();
      finish.complete();
      expect(await result, RecordFileExportResult.saved);
    },
  );
  test(
    'oversize fails before choosing; exact character budget passes',
    () async {
      var calls = 0;
      final service = MacOsRecordFileExporter(
        chooser: (_) async {
          calls++;
          return null;
        },
      );
      await expectLater(
        save(service, text: '棋' * 64001),
        throwsA(failure(RecordExportFailure.tooLarge)),
      );
      expect(calls, 0);
      expect(
        await save(service, text: '棋' * 64000),
        RecordFileExportResult.cancelled,
      );
      expect(calls, 1);
    },
  );
  test(
    'unpaired surrogate cannot be silently changed by UTF8 encoding',
    () async {
      await expectLater(
        save(
          MacOsRecordFileExporter(
            chooser: (_) async => throw StateError('must not choose'),
          ),
          text: String.fromCharCode(0xd800),
        ),
        throwsA(failure(RecordExportFailure.encoding)),
      );
    },
  );
  test(
    'extension is allowlisted and unsupported platforms do not open chooser',
    () async {
      final service = MacOsRecordFileExporter(
        chooser: (_) async => throw StateError('must not choose'),
      );
      await expectLater(
        save(service, extension: '../../secret'),
        throwsArgumentError,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await expectLater(
        save(service),
        throwsA(failure(RecordExportFailure.unavailable)),
      );
    },
  );
  test(
    'selection failures and missing plugins have actionable typed errors',
    () async {
      await expectLater(
        save(
          MacOsRecordFileExporter(
            chooser: (_) async => throw StateError('/private/location'),
          ),
        ),
        throwsA(failure(RecordExportFailure.selection)),
      );
      await expectLater(
        save(
          MacOsRecordFileExporter(
            chooser: (_) async => throw MissingPluginException(),
          ),
        ),
        throwsA(failure(RecordExportFailure.unavailable)),
      );
    },
  );
  test(
    'write failure and missing writer never report success or leak a path',
    () async {
      await expectLater(
        save(
          MacOsRecordFileExporter(
            chooser: (_) async => '/private/location',
            writer: (_, _) async => throw StateError('/private/location'),
          ),
        ),
        throwsA(failure(RecordExportFailure.write)),
      );
      await expectLater(
        save(
          MacOsRecordFileExporter(
            chooser: (_) async => '/private/location',
            writer: (_, _) async => throw MissingPluginException(),
          ),
        ),
        throwsA(failure(RecordExportFailure.unavailable)),
      );
      expect(
        const RecordExportException(RecordExportFailure.write).message,
        isNot(contains('/private')),
      );
    },
  );
  test(
    'native bridge carries typed bytes once and maps native error without details',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          MacOsRecordFileExporter.channel,
          null,
        ),
      );
      var calls = 0;
      messenger.setMockMethodCallHandler(MacOsRecordFileExporter.channel, (
        call,
      ) async {
        calls++;
        expect(call.method, 'writeAtomic');
        final args = call.arguments as Map;
        expect(args['path'], '/selected/file.pgn');
        expect(args['bytes'], isA<Uint8List>());
        expect(utf8.decode(args['bytes'] as Uint8List), '自制棋谱');
        if (calls == 2) {
          throw PlatformException(
            code: 'write_failed',
            message: '/private/path',
          );
        }
        return null;
      });
      final service = MacOsRecordFileExporter(
        chooser: (_) async => '/selected/file.pgn',
      );
      expect(await save(service), RecordFileExportResult.saved);
      await expectLater(
        save(service),
        throwsA(failure(RecordExportFailure.write)),
      );
      expect(calls, 2);
    },
  );
}
