enum AudioFeedbackKind { select, move, capture, check, mate }

/// Offline, best-effort presentation feedback. Failures never reject a move.
abstract interface class AudioFeedbackPort {
  Future<void> play(AudioFeedbackKind kind);
  Future<void> dispose();
}

final class SilentAudioFeedback implements AudioFeedbackPort {
  const SilentAudioFeedback();

  @override
  Future<void> play(AudioFeedbackKind kind) async {}

  @override
  Future<void> dispose() async {}
}
