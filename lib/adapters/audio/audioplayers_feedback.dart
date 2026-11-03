import 'package:audioplayers/audioplayers.dart';
import '../../ports/audio_feedback.dart';
import '../../ports/audio_library.dart';

/// audioplayers-backed local feedback; media is synthesized in memory.
final class AudioplayersFeedback implements AudioFeedbackPort {
  AudioplayersFeedback({this.overrides}) {
    // Short effects do not need a per-frame position stream.
    _selection.positionUpdater = null;
    _move.positionUpdater = null;
    _capture.positionUpdater = null;
    _check.positionUpdater = null;
    _mate.positionUpdater = null;
  }

  final AudioOverrideRepository? overrides;
  final AudioPlayer _selection = AudioPlayer(playerId: 'chessnext-select');
  final AudioPlayer _move = AudioPlayer(playerId: 'chessnext-move');
  final AudioPlayer _capture = AudioPlayer(playerId: 'chessnext-capture');
  final AudioPlayer _check = AudioPlayer(playerId: 'chessnext-check');
  final AudioPlayer _mate = AudioPlayer(playerId: 'chessnext-mate');
  bool _disposed = false;

  @override
  Future<void> play(AudioFeedbackKind kind) async {
    if (_disposed) return;
    final (player, asset) = switch (kind) {
      AudioFeedbackKind.select => (_selection, 'audio/select.wav'),
      AudioFeedbackKind.move => (_move, 'audio/move.wav'),
      AudioFeedbackKind.capture => (_capture, 'audio/capture.wav'),
      AudioFeedbackKind.check => (_check, 'audio/check.wav'),
      AudioFeedbackKind.mate => (_mate, 'audio/mate.wav'),
    };
    String? customPath;
    try {
      customPath = await overrides?.pathFor(kind);
    } catch (_) {
      // Damaged custom audio falls back to the bundled offline sound.
    }
    await player.play(
      customPath == null ? AssetSource(asset) : DeviceFileSource(customPath),
      volume: .45,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait([
      _selection.dispose(),
      _move.dispose(),
      _capture.dispose(),
      _check.dispose(),
      _mate.dispose(),
    ]);
  }
}
