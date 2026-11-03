import 'package:chess_next/adapters/audio/audioplayers_feedback.dart';
import 'package:chess_next/ports/audio_feedback.dart';
import 'package:chess_next/adapters/speech/flutter_tts_move_speech.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
}
