import 'dart:typed_data';

import 'audio_feedback.dart';

enum MoveSoundChoice { sound1, sound2, followPieceSkin }

extension MoveSoundChoicePresentation on MoveSoundChoice {
  String get label => switch (this) {
    MoveSoundChoice.sound1 => '音效1',
    MoveSoundChoice.sound2 => '音效2',
    MoveSoundChoice.followPieceSkin => '随棋子皮肤',
  };
}

abstract final class AudioLibraryLimits {
  static const maxBytes = 512 * 1024;
}

final class SelectedAudioFile {
  SelectedAudioFile(this.extension, Uint8List bytes)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final String extension;
  final Uint8List bytes;
}

enum AudioLibraryFailure {
  tooLarge,
  format,
  duration,
  read,
  unavailable,
  write,
}

class AudioLibraryException implements Exception {
  const AudioLibraryException(this.failure);
  final AudioLibraryFailure failure;
  String get message => switch (failure) {
    AudioLibraryFailure.tooLarge => '音效文件不能超过512 KiB。',
    AudioLibraryFailure.format => '请选择有效的 WAV 或 MP3 音效。',
    AudioLibraryFailure.duration => '音效时长不能超过5秒。',
    AudioLibraryFailure.read => '无法读取所选音效，请确认文件仍可用。',
    AudioLibraryFailure.unavailable => '当前平台的本机文件选择器不可用。',
    AudioLibraryFailure.write => '音效未能保存在本机，请重试。',
  };
}

abstract interface class AudioFilePicker {
  Future<SelectedAudioFile?> pickAudio();
}

abstract interface class AudioOverrideRepository {
  Future<String?> pathFor(AudioFeedbackKind kind);
  Future<void> save(AudioFeedbackKind kind, String extension, Uint8List bytes);
  Future<void> remove(AudioFeedbackKind kind);
  Future<MoveSoundChoice> moveSoundChoice();
  Future<void> setMoveSoundChoice(MoveSoundChoice choice);
}

abstract interface class AudioSoundPreviewPort {
  Future<void> previewMoveSound(MoveSoundChoice choice);
}
