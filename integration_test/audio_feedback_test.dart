import 'package:chess_next/adapters/audio/audioplayers_feedback.dart';
import 'package:chess_next/ports/audio_feedback.dart';
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
    expect(tester.takeException(), isNull);
  });
}
