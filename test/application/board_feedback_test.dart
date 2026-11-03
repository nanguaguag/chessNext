import 'package:chess_next/adapters/audio/tone_wave.dart';
import 'package:chess_next/application/board_feedback_controller.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/ports/audio_feedback.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class FakeAudio implements AudioFeedbackPort {
  final events = <AudioFeedbackKind>[];
  bool fail = false;

  @override
  Future<void> play(AudioFeedbackKind kind) async {
    events.add(kind);
    if (fail) throw StateError('audio device unavailable');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('produces bounded deterministic RIFF PCM for local tones', () {
    final select = toneWave(frequency: 880, durationMs: 45);
    final move = toneWave(frequency: 520, durationMs: 75);
    expect(String.fromCharCodes(select.take(4)), 'RIFF');
    expect(String.fromCharCodes(select.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(select.sublist(36, 40)), 'data');
    expect(select.length, 44 + 22050 * 45 ~/ 1000);
    expect(move.length, 44 + 22050 * 75 ~/ 1000);
    expect(select, isNot(move));
    for (final byte in select.skip(44)) {
      expect(byte, inInclusiveRange(0, 255));
    }
  });

  test('emits only enabled selection and committed move feedback', () async {
    final session = BoardSession();
    final engine = EngineSessionController(session, null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    final audio = FakeAudio();
    await preferences.initialize();
    final feedback = BoardFeedbackController(session, preferences, audio);
    try {
      final move = session.legalMoves.first;
      session.tap(move.from);
      session.tap(move.to);
      await Future<void>.delayed(Duration.zero);
      expect(audio.events, [AudioFeedbackKind.select, AudioFeedbackKind.move]);
      expect(session.tree.current.move, move);

      await preferences.setPlaySelectionSound(false);
      final reply = session.legalMoves.first;
      session.tap(reply.from);
      session.tap(reply.to);
      await Future<void>.delayed(Duration.zero);
      expect(audio.events, [
        AudioFeedbackKind.select,
        AudioFeedbackKind.move,
        AudioFeedbackKind.move,
      ]);
      expect(session.tree.current.move, reply);
    } finally {
      await feedback.dispose();
      preferences.dispose();
      engine.dispose();
      session.dispose();
    }
  });

  test(
    'replacing a document is silent and audio failure cannot block moves',
    () async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      final audio = FakeAudio()..fail = true;
      await preferences.initialize();
      final feedback = BoardFeedbackController(session, preferences, audio);
      try {
        session.replaceTree(GameTree());
        expect(audio.events, isEmpty);
        final move = session.legalMoves.first;
        session.tap(move.from);
        session.tap(move.to);
        await Future<void>.delayed(Duration.zero);
        expect(session.tree.current.move, move);
        expect(audio.events, [
          AudioFeedbackKind.select,
          AudioFeedbackKind.move,
        ]);
      } finally {
        await feedback.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );

  test('sound preferences default on and strictly roundtrip independently', () {
    final old = AppPreferences().toJson();
    expect(old.containsKey('playMoveSound'), isFalse);
    expect(old.containsKey('playSelectionSound'), isFalse);
    expect(AppPreferences.fromJson(old).playMoveSound, isTrue);
    final muted = AppPreferences(
      playMoveSound: false,
      playSelectionSound: true,
    );
    expect(AppPreferences.fromJson(muted.toJson()), muted);
    expect(
      () => AppPreferences.fromJson({...old, 'playMoveSound': 'false'}),
      throwsFormatException,
    );
  });
}
