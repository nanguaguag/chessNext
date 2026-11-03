import 'dart:async';

import '../ports/audio_feedback.dart';
import 'board_session.dart';
import 'preferences_controller.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

/// Turns committed board/selection state changes into optional local feedback.
class BoardFeedbackController {
  BoardFeedbackController(this.session, this.preferences, this.audio) {
    _epoch = session.epoch;
    _positionRevision = session.positionRevision;
    _selected = session.selected;
    session.addListener(_changed);
  }

  final BoardSession session;
  final PreferencesController preferences;
  final AudioFeedbackPort audio;
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
        final kind =
            session.outcome.status == BoardStatus.checkmate
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
      await audio.play(kind);
    } catch (_) {
      // Audio is optional and must not affect board state or engine work.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    session.removeListener(_changed);
    await audio.dispose();
  }
}
