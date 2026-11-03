import 'package:chess_next/adapters/audio/tone_wave.dart';
import 'package:chess_next/application/board_feedback_controller.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/ports/audio_feedback.dart';
import 'package:chess_next/ports/move_speech.dart';
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

class FakeSpeech implements MoveSpeechPort {
  final utterances = <String>[];

  @override
  Future<void> speak(String notation) async => utterances.add(notation);

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
    for (final frequency in [660, 740, 980]) {
      final special = toneWave(frequency: frequency, durationMs: 90);
      expect(String.fromCharCodes(special.take(4)), 'RIFF');
      expect(special.length, lessThan(44 + 22050));
    }
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
    expect(AppPreferences.fromJson(old).playCaptureSound, isTrue);
    expect(AppPreferences.fromJson(old).playCheckSound, isTrue);
    expect(AppPreferences.fromJson(old).playMateSound, isTrue);
    expect(AppPreferences.fromJson(old).speakMoves, isFalse);
    final muted = AppPreferences(
      playMoveSound: false,
      playSelectionSound: true,
      playCaptureSound: false,
      playCheckSound: true,
      playMateSound: false,
    );
    expect(AppPreferences.fromJson(muted.toJson()), muted);
    expect(
      () => AppPreferences.fromJson({...old, 'playMoveSound': 'false'}),
      throwsFormatException,
    );
  });

  test(
    'move speech is independent and uses the committed Chinese notation',
    () async {
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      final audio = FakeAudio();
      final speech = FakeSpeech();
      await preferences.initialize();
      final feedback = BoardFeedbackController(
        session,
        preferences,
        audio,
        speech,
      );
      try {
        await preferences.setSpeakMoves(true);
        await preferences.setPlayMoveSound(false);
        final move = session.legalMoves.first;
        session.playMove(move);
        await Future<void>.delayed(Duration.zero);
        expect(speech.utterances, [
          ChineseNotation.format(Position.initial(), move),
        ]);
        expect(audio.events, isEmpty);
        await preferences.setSpeakMoves(false);
        session.undo();
        session.playMove(move);
        await Future<void>.delayed(Duration.zero);
        expect(speech.utterances, hasLength(1));
      } finally {
        await feedback.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );

  test(
    'capture has a distinct event when it does not also give check',
    () async {
      final session = BoardSession(
        initial: Position.fromFen('4k4/9/9/9/9/9/9/p8/R8/3K5 w - - 0 1'),
      );
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      final audio = FakeAudio();
      await preferences.initialize();
      final feedback = BoardFeedbackController(session, preferences, audio);
      try {
        expect(session.playMove(Move.parse('a1a2')), isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(audio.events, [AudioFeedbackKind.capture]);
      } finally {
        await feedback.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );

  test(
    'check has a dedicated event and can fall back to ordinary move',
    () async {
      final session = BoardSession(
        initial: Position.fromFen('4k4/3R5/9/9/9/9/9/9/9/3K5 w - - 0 1'),
      );
      final engine = EngineSessionController(session, null);
      final preferences = PreferencesController(
        engine,
        MemoryPreferencesRepository(),
      );
      final audio = FakeAudio();
      await preferences.initialize();
      final feedback = BoardFeedbackController(session, preferences, audio);
      try {
        expect(session.playMove(Move.parse('d8e8')), isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(audio.events, [AudioFeedbackKind.check]);
        await preferences.setPlayCheckSound(false);
        session.undo();
        session.playMove(Move.parse('d8e8'));
        await Future<void>.delayed(Duration.zero);
        expect(audio.events.last, AudioFeedbackKind.move);
      } finally {
        await feedback.dispose();
        preferences.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
