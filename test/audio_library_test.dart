import 'dart:io';
import 'dart:typed_data';

import 'package:chess_next/adapters/storage/file_audio_override_repository.dart';
import 'package:chess_next/application/audio_import_validator.dart';
import 'package:chess_next/application/audio_library_controller.dart';
import 'package:chess_next/ports/audio_feedback.dart';
import 'package:chess_next/ports/audio_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:chess_next/features/settings/audio_options_dialog.dart';

void main() {
  test('validates WAV/MP3 size, structure, and duration boundaries', () {
    expect(
      AudioImportValidator.validate(SelectedAudioFile('wav', _wav(8000))),
      1000,
    );
    expect(
      AudioImportValidator.validate(SelectedAudioFile('mp3', _mp3(191))),
      4990,
    );
    expect(
      () => AudioImportValidator.validate(SelectedAudioFile('mp3', _mp3(192))),
      throwsA(
        isA<AudioLibraryException>().having(
          (e) => e.failure,
          'failure',
          AudioLibraryFailure.duration,
        ),
      ),
    );
    expect(
      () => AudioImportValidator.validate(
        SelectedAudioFile('wav', Uint8List(AudioLibraryLimits.maxBytes + 1)),
      ),
      throwsA(
        isA<AudioLibraryException>().having(
          (e) => e.failure,
          'failure',
          AudioLibraryFailure.tooLarge,
        ),
      ),
    );
    expect(
      () => AudioImportValidator.validate(
        SelectedAudioFile('wav', Uint8List(44)),
      ),
      throwsA(
        isA<AudioLibraryException>().having(
          (e) => e.failure,
          'failure',
          AudioLibraryFailure.format,
        ),
      ),
    );
  });

  test(
    'stores each override locally and restores only the requested event',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'audio-overrides-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = FileAudioOverrideRepository(() async => directory);
      final wav = _wav(8000);
      await repository.save(AudioFeedbackKind.capture, 'wav', wav);
      final customPath = await repository.pathFor(AudioFeedbackKind.capture);
      expect(customPath, isNotNull);
      expect(await File(customPath!).readAsBytes(), wav);
      expect(await repository.pathFor(AudioFeedbackKind.move), isNull);
      expect(await repository.moveSoundChoice(), MoveSoundChoice.sound1);
      await repository.setMoveSoundChoice(MoveSoundChoice.sound2);
      expect(await repository.moveSoundChoice(), MoveSoundChoice.sound2);
      expect(
        await FileAudioOverrideRepository(
          () async => directory,
        ).moveSoundChoice(),
        MoveSoundChoice.sound2,
      );
      await File(
        '${directory.path}/chessnext-audio/move-choice.json',
      ).writeAsString('{broken');
      expect(await repository.moveSoundChoice(), MoveSoundChoice.sound1);
      await repository.remove(AudioFeedbackKind.capture);
      expect(await repository.pathFor(AudioFeedbackKind.capture), isNull);
    },
  );

  test(
    'rejects a tampered manifest path outside the audio directory',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'audio-manifest-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final folder = Directory('${directory.path}/chessnext-audio');
      await folder.create();
      await File('${folder.path}/move.json').writeAsString(
        '{"schema":1,"extension":"wav","file":"move-../../outside.wav"}',
      );
      final repository = FileAudioOverrideRepository(() async => directory);
      expect(await repository.pathFor(AudioFeedbackKind.move), isNull);
    },
  );

  test(
    'controller handles import cancellation, preview, validation, and reset',
    () async {
      final repository = _MemoryOverrides();
      final picker = _Picker()..selected = SelectedAudioFile('wav', _wav(8000));
      final audio = _Audio();
      final controller = AudioLibraryController(picker, repository, audio);
      addTearDown(controller.dispose);

      expect(await controller.importCustom(AudioFeedbackKind.move), isTrue);
      expect(controller.hasCustom(AudioFeedbackKind.move), isTrue);
      expect(
        await controller.selectMoveSoundChoice(MoveSoundChoice.sound2),
        isFalse,
      );
      expect(await controller.preview(AudioFeedbackKind.move), isTrue);
      expect(audio.played, [AudioFeedbackKind.move]);
      expect(await controller.reset(AudioFeedbackKind.move), isTrue);
      expect(controller.hasCustom(AudioFeedbackKind.move), isFalse);
      expect(controller.moveChoice, MoveSoundChoice.sound1);
      expect(
        await controller.selectMoveSoundChoice(MoveSoundChoice.sound2),
        isTrue,
      );
      expect(await controller.previewMoveSound(MoveSoundChoice.sound2), isTrue);
      expect(
        await controller.previewMoveSound(
          MoveSoundChoice.followPieceSkin,
          followSkinChoice: MoveSoundChoice.sound2,
        ),
        isTrue,
      );
      expect(audio.previewed, [MoveSoundChoice.sound2, MoveSoundChoice.sound2]);

      picker.selected = null;
      expect(await controller.importCustom(AudioFeedbackKind.move), isFalse);
      expect(controller.error, isNull);
      picker.selected = SelectedAudioFile('wav', Uint8List(44));
      expect(await controller.importCustom(AudioFeedbackKind.move), isFalse);
      expect(controller.error, contains('有效的 WAV'));
    },
  );

  testWidgets('audio options show local override and offer reset', (
    tester,
  ) async {
    final repository = _MemoryOverrides();
    final picker = _Picker()..selected = SelectedAudioFile('wav', _wav(8000));
    final library = AudioLibraryController(picker, repository, _Audio());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AudioOptionsDialog(
            kind: AudioFeedbackKind.move,
            title: '走棋',
            library: library,
          ),
        ),
      ),
    );
    expect(find.text('当前：音效1'), findsOneWidget);
    final soundChoiceDropdown = find.byType(
      DropdownButtonFormField<MoveSoundChoice>,
    );
    await tester.ensureVisible(soundChoiceDropdown);
    await tester.pumpAndSettle();
    await tester.tap(soundChoiceDropdown.hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('音效2').last);
    await tester.pumpAndSettle();
    expect(find.text('当前：音效2'), findsOneWidget);
    await tester.tap(find.text('导入自定义音效'));
    await tester.pumpAndSettle();
    expect(find.text('当前：自定义音效'), findsOneWidget);
    await tester.tap(find.text('恢复默认音效'));
    await tester.pumpAndSettle();
    expect(find.text('当前：音效1'), findsOneWidget);
    library.dispose();
  });
}

Uint8List _wav(int sampleRate) {
  const samples = 8000;
  final bytes = Uint8List(44 + samples * 2);
  final data = ByteData.sublistView(bytes);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes[offset + i] = value.codeUnitAt(i);
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, bytes.length - 8, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  return bytes;
}

Uint8List _mp3(int frames) {
  const frameLength = 417;
  final bytes = Uint8List(frames * frameLength);
  for (var offset = 0; offset < bytes.length; offset += frameLength) {
    bytes[offset] = 0xff;
    bytes[offset + 1] = 0xfb;
    bytes[offset + 2] = 0x90;
    bytes[offset + 3] = 0x64;
  }
  return bytes;
}

class _Picker implements AudioFilePicker {
  SelectedAudioFile? selected;
  @override
  Future<SelectedAudioFile?> pickAudio() async => selected;
}

class _MemoryOverrides implements AudioOverrideRepository {
  final files = <AudioFeedbackKind, String>{};
  MoveSoundChoice choice = MoveSoundChoice.sound1;
  @override
  Future<String?> pathFor(AudioFeedbackKind kind) async => files[kind];
  @override
  Future<void> save(
    AudioFeedbackKind kind,
    String extension,
    Uint8List bytes,
  ) async {
    files[kind] = '${kind.name}.$extension';
  }

  @override
  Future<void> remove(AudioFeedbackKind kind) async => files.remove(kind);

  @override
  Future<MoveSoundChoice> moveSoundChoice() async => choice;

  @override
  Future<void> setMoveSoundChoice(MoveSoundChoice value) async {
    choice = value;
  }
}

class _Audio implements AudioFeedbackPort, AudioSoundPreviewPort {
  final played = <AudioFeedbackKind>[];
  final previewed = <MoveSoundChoice>[];
  @override
  Future<void> play(
    AudioFeedbackKind kind, {
    MoveSoundChoice moveChoice = MoveSoundChoice.sound1,
  }) async => played.add(kind);
  @override
  Future<void> previewMoveSound(MoveSoundChoice choice) async =>
      previewed.add(choice);
  @override
  Future<void> dispose() async {}
}
