import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chess_next/adapters/platform/file_selector_record_picker.dart';
import 'package:chess_next/application/record_text_exchange.dart';
import 'package:chess_next/ports/record_file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class StreamingFile extends XFile {
  StreamingFile({
    required this.size,
    required this.chunks,
    this.label = '谱.pgn',
  }) : super('/not-used');
  final Future<int> size;
  final Stream<Uint8List> chunks;
  final String label;
  bool opened = false;
  @override
  String get name => label;
  @override
  Future<int> length() => size;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    opened = true;
    return chunks;
  }
}

void main() {
  Matcher failure(RecordFileFailure kind) =>
      isA<RecordFileException>().having((e) => e.failure, 'failure', kind);

  test('real UTF8 file keeps metadata/comments and original bytes', () async {
    final dir = await Directory.systemTemp.createTemp('chessnext-import-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/自制.pgn');
    final bytes = utf8.encode(
      '\uFEFF[Game "Chinese Chess"]\n[Format "ICCS"]\n[Event "赛事"]\n{根注} 1. H2-E2 {炮注} *',
    );
    await file.writeAsBytes(bytes);
    final selected = await FileSelectorRecordPicker(
      chooser: (_) async => XFile(file.path),
    ).openText();
    expect(selected!.displayName, '自制.pgn');
    final imported = await RecordTextExchange.parseInWorker(selected.text);
    expect(imported.metadata.tags['Event'], '赛事');
    expect(imported.tree.root.comment, '根注');
    expect(imported.tree.current.comment, '炮注');
    expect(await file.readAsBytes(), bytes);
  });

  test('cancel is ordinary and native wait has no read timeout', () async {
    final gate = Completer<XFile?>();
    final future = FileSelectorRecordPicker(
      chooser: (_) => gate.future,
      readTimeout: const Duration(milliseconds: 5),
    ).openText();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete(null);
    expect(await future, isNull);
  });

  test('declared byte size is checked before opening the stream', () async {
    final file = StreamingFile(
      size: Future.value(256001),
      chunks: const Stream.empty(),
    );
    await expectLater(
      FileSelectorRecordPicker(chooser: (_) async => file).openText(),
      throwsA(failure(RecordFileFailure.tooLarge)),
    );
    expect(file.opened, isFalse);
  });

  test(
    'actual stream byte limit protects against a lying length and cancels',
    () async {
      var cancelled = false;
      final stream = StreamController<Uint8List>(
        onCancel: () => cancelled = true,
      );
      stream.add(Uint8List(128001));
      stream.add(Uint8List(128000));
      final file = StreamingFile(size: Future.value(1), chunks: stream.stream);
      await expectLater(
        FileSelectorRecordPicker(chooser: (_) async => file).openText(),
        throwsA(failure(RecordFileFailure.tooLarge)),
      );
      expect(cancelled, isTrue);
      await stream.close();
    },
  );

  test(
    'exact character budget accepts ASCII and multibyte text but rejects overflow',
    () async {
      for (final text in ['a' * 64000, '棋' * 64000]) {
        final selected = await FileSelectorRecordPicker(
          chooser: (_) async =>
              XFile.fromData(Uint8List.fromList(utf8.encode(text))),
        ).openText();
        expect(selected!.text, text);
      }
      await expectLater(
        FileSelectorRecordPicker(
          chooser: (_) async => XFile.fromData(Uint8List(64001)),
        ).openText(),
        throwsA(failure(RecordFileFailure.tooLarge)),
      );
    },
  );

  test('strict UTF8 rejects GBK and truncated multibyte data', () async {
    for (final bytes in [
      [0xd6, 0xd0],
      [0xe4, 0xb8],
    ]) {
      await expectLater(
        FileSelectorRecordPicker(
          chooser: (_) async => XFile.fromData(Uint8List.fromList(bytes)),
        ).openText(),
        throwsA(failure(RecordFileFailure.encoding)),
      );
    }
  });

  test(
    'stat/read failures expose no file paths and missing plugin is distinct',
    () async {
      await expectLater(
        FileSelectorRecordPicker(
          chooser: (_) async => throw MissingPluginException(),
        ).openText(),
        throwsA(failure(RecordFileFailure.unavailable)),
      );
      await expectLater(
        FileSelectorRecordPicker(
          chooser: (_) async => XFile('/private/missing/secret.pgn'),
        ).openText(),
        throwsA(failure(RecordFileFailure.read)),
      );
      final file = StreamingFile(
        size: Future.value(1),
        chunks: Stream.error(StateError('/private/secret')),
      );
      await expectLater(
        FileSelectorRecordPicker(chooser: (_) async => file).openText(),
        throwsA(failure(RecordFileFailure.read)),
      );
      expect(
        const RecordFileException(RecordFileFailure.read).message,
        isNot(contains('/private')),
      );
    },
  );

  test('silent stream times out and cancels its subscription', () async {
    var cancelled = false;
    final stream = StreamController<Uint8List>(
      onCancel: () => cancelled = true,
    );
    final file = StreamingFile(size: Future.value(10), chunks: stream.stream);
    await expectLater(
      FileSelectorRecordPicker(
        chooser: (_) async => file,
        readTimeout: const Duration(milliseconds: 15),
      ).openText(),
      throwsA(failure(RecordFileFailure.timeout)),
    );
    expect(cancelled, isTrue);
    await stream.close();
  });

  test(
    'continuous trickle obeys absolute read deadline rather than idle timeout',
    () async {
      final stream = StreamController<Uint8List>();
      final timer = Timer.periodic(
        const Duration(milliseconds: 2),
        (_) => stream.add(Uint8List(1)),
      );
      stream.onCancel = timer.cancel;
      final file = StreamingFile(size: Future.value(1), chunks: stream.stream);
      await expectLater(
        FileSelectorRecordPicker(
          chooser: (_) async => file,
          readTimeout: const Duration(milliseconds: 20),
        ).openText(),
        throwsA(failure(RecordFileFailure.timeout)),
      );
      expect(timer.isActive, isFalse);
      await stream.close();
    },
  );

  test(
    'stat has a deadline and names cannot inject paths/control or huge text',
    () async {
      final pending = StreamingFile(
        size: Completer<int>().future,
        chunks: const Stream.empty(),
      );
      await expectLater(
        FileSelectorRecordPicker(
          chooser: (_) async => pending,
          readTimeout: const Duration(milliseconds: 10),
        ).openText(),
        throwsA(failure(RecordFileFailure.timeout)),
      );
      expect(pending.opened, isFalse);
      final file = StreamingFile(
        size: Future.value(0),
        chunks: const Stream.empty(),
        label: '../\u202e\n${'🐟' * 200}.pgn',
      );
      final result = await FileSelectorRecordPicker(
        chooser: (_) async => file,
      ).openText();
      expect(result!.displayName.runes.length, 160);
      expect(result.displayName, isNot(contains('/')));
      expect(result.displayName, isNot(contains('\n')));
      expect(result.displayName, isNot(contains('\u202e')));
    },
  );

  test('iOS uses a supported UTI, desktop uses extensions', () {
    expect(
      FileSelectorRecordPicker.typesFor(
        TargetPlatform.iOS,
      ).single.uniformTypeIdentifiers,
      ['public.data'],
    );
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      expect(FileSelectorRecordPicker.typesFor(platform).single.extensions, [
        'pgn',
        'fen',
        'txt',
      ]);
    }
  });
}
