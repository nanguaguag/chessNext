import 'dart:io';
import 'dart:typed_data';

import 'package:chess_next/adapters/audio/audioplayers_feedback.dart';
import 'package:chess_next/ports/audio_feedback.dart';
import 'package:chess_next/adapters/speech/flutter_tts_move_speech.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chess_next/ports/audio_library.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('macOS plugin accepts synthesized offline board feedback', (
    tester,
  ) async {
    final audio = AudioplayersFeedback();
    addTearDown(audio.dispose);
    await audio.play(AudioFeedbackKind.select);
    await audio.play(AudioFeedbackKind.move);
    await audio.play(AudioFeedbackKind.capture);
    await audio.play(AudioFeedbackKind.check);
    await audio.play(AudioFeedbackKind.mate);
    final speech = FlutterTtsMoveSpeech();
    addTearDown(speech.dispose);
    await speech.speak(
      ChineseNotation.format(Position.initial(), Move.parse('h2e2')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('macOS plugin accepts a local custom audio file', (tester) async {
    final directory = await Directory.systemTemp.createTemp('custom-audio-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/custom.wav');
    await file.writeAsBytes(_wav());
    final audio = AudioplayersFeedback(overrides: _Override(file.path));
    addTearDown(audio.dispose);
    await audio.play(AudioFeedbackKind.move);
    expect(tester.takeException(), isNull);
  });
}

class _Override implements AudioOverrideRepository {
  _Override(this.path);
  final String path;
  @override
  Future<String?> pathFor(AudioFeedbackKind kind) async => path;
  @override
  Future<void> save(
    AudioFeedbackKind kind,
    String extension,
    Uint8List bytes,
  ) async {}
  @override
  Future<void> remove(AudioFeedbackKind kind) async {}
}

Uint8List _wav() {
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
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 16000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  return bytes;
}
