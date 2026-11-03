import 'dart:async';

import '../ports/audio_feedback.dart';
import '../ports/move_speech.dart';
import '../ports/audio_library.dart';
import 'board_appearance.dart';
import 'board_session.dart';
import 'preferences_controller.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

/// Turns committed board/selection state changes into optional local feedback.
class BoardFeedbackController {
  BoardFeedbackController(
    this.session,
    this.preferences,
    this.audio, [
    this.speech = const SilentMoveSpeech(),
    this.audioOverrides,
  ]) {
    _epoch = session.epoch;
    _positionRevision = session.positionRevision;
    _selected = session.selected;
    session.addListener(_changed);
  }

  final BoardSession session;
  final PreferencesController preferences;
  final AudioFeedbackPort audio;
  final MoveSpeechPort speech;
  final AudioOverrideRepository? audioOverrides;
  late int _epoch;
  late int _positionRevision;
  Square? _selected;
  bool _disposed = false;

  void _changed() {
    if (_disposed) return;
    final epoch = session.epoch;
    final revision = session.positionRevision;
    final selected = session.selected;
    if (epoch == _epoch && revision != _positionRevision) {
      final node = session.tree.current;
      final move = node.move;
      final parent = node.parentId == null
          ? null
          : session.tree.node(node.parentId!);
      if (move != null && parent != null) {
        final prefs = preferences.value;
        if (prefs.speakMoves) {
          unawaited(_speak(ChineseNotation.format(parent.position, move)));
        }
        final kind = session.outcome.status == BoardStatus.checkmate
            ? (prefs.playMateSound ? AudioFeedbackKind.mate : null)
            : node.position.isInCheck(node.position.turn)
            ? (prefs.playCheckSound ? AudioFeedbackKind.check : null)
            : parent.position.at(move.to) != null
            ? (prefs.playCaptureSound ? AudioFeedbackKind.capture : null)
            : null;
        final fallback = kind == null && prefs.playMoveSound
            ? AudioFeedbackKind.move
            : kind;
        if (fallback != null) unawaited(_play(fallback));
      }
    } else if (epoch == _epoch &&
        revision == _positionRevision &&
        selected != null &&
        selected != _selected &&
        preferences.value.playSelectionSound) {
      unawaited(_play(AudioFeedbackKind.select));
    }
    _epoch = epoch;
    _positionRevision = revision;
    _selected = selected;
  }

  Future<void> _play(AudioFeedbackKind kind) async {
    try {
      var choice = MoveSoundChoice.sound1;
      if (kind == AudioFeedbackKind.move) {
        final stored =
            await audioOverrides?.moveSoundChoice() ?? MoveSoundChoice.sound1;
        choice = stored == MoveSoundChoice.followPieceSkin
            ? preferences.value.pieceSkin == PieceSkin.roundSeal
                  ? MoveSoundChoice.sound1
                  : MoveSoundChoice.sound2
            : stored;
      }
      await audio.play(kind, moveChoice: choice);
    } catch (_) {
      // Audio is optional and must not affect board state or engine work.
    }
  }

  Future<void> _speak(String notation) async {
    try {
      await speech.speak(notation);
    } catch (_) {
      // A missing system voice must never affect board state.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    session.removeListener(_changed);
    await audio.dispose();
    await speech.dispose();
  }
}
