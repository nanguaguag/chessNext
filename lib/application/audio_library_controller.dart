import 'dart:async';
import 'package:flutter/foundation.dart';

import '../ports/audio_feedback.dart';
import '../ports/audio_library.dart';
import 'audio_import_validator.dart';

class AudioLibraryController extends ChangeNotifier {
  AudioLibraryController(this.picker, this.repository, this.audio);

  final AudioFilePicker picker;
  final AudioOverrideRepository repository;
  final AudioFeedbackPort audio;
  final Set<AudioFeedbackKind> _custom = {};
  AudioFeedbackKind? busyKind;
  AudioFeedbackKind? errorKind;
  String? error;
  MoveSoundChoice moveChoice = MoveSoundChoice.sound1;
  bool _disposed = false;

  bool hasCustom(AudioFeedbackKind kind) => _custom.contains(kind);

  Future<void> initialize() async {
    for (final kind in AudioFeedbackKind.values) {
      try {
        if (await repository.pathFor(kind) != null) _custom.add(kind);
      } catch (_) {
        // Keep the application usable if one local setting file is damaged.
      }
    }
    try {
      moveChoice = await repository.moveSoundChoice();
    } catch (_) {
      moveChoice = MoveSoundChoice.sound1;
    }
    _notify();
  }

  Future<bool> selectMoveSoundChoice(MoveSoundChoice choice) async {
    if (busyKind != null || _disposed) return false;
    if (hasCustom(AudioFeedbackKind.move)) {
      _begin(AudioFeedbackKind.move);
      _setError(AudioFeedbackKind.move, '请先恢复默认音效，再选择内置方案。');
      _finish();
      return false;
    }
    _begin(AudioFeedbackKind.move);
    try {
      await repository.setMoveSoundChoice(choice);
      moveChoice = choice;
      return true;
    } catch (_) {
      _setError(AudioFeedbackKind.move, '音效方案未能保存在本机，请重试。');
      return false;
    } finally {
      _finish();
    }
  }

  Future<bool> previewMoveSound(
    MoveSoundChoice choice, {
    MoveSoundChoice followSkinChoice = MoveSoundChoice.sound1,
  }) async {
    if (busyKind != null || _disposed) return false;
    if (audio is! AudioSoundPreviewPort) {
      _setError(AudioFeedbackKind.move, '当前音效播放器不支持方案试听。');
      _notify();
      return false;
    }
    _begin(AudioFeedbackKind.move);
    try {
      await (audio as AudioSoundPreviewPort).previewMoveSound(
        choice == MoveSoundChoice.followPieceSkin ? followSkinChoice : choice,
      );
      return true;
    } catch (_) {
      _setError(AudioFeedbackKind.move, '音效播放失败，请检查本机音频设备后重试。');
      return false;
    } finally {
      _finish();
    }
  }

  Future<bool> importCustom(AudioFeedbackKind kind) async {
    if (busyKind != null || _disposed) return false;
    _begin(kind);
    try {
      final selected = await picker.pickAudio();
      if (selected == null) return false;
      AudioImportValidator.validate(selected);
      await repository.save(kind, selected.extension, selected.bytes);
      _custom.add(kind);
      return true;
    } on AudioLibraryException catch (exception) {
      _setError(kind, exception.message);
      return false;
    } catch (_) {
      _setError(
        kind,
        const AudioLibraryException(AudioLibraryFailure.write).message,
      );
      return false;
    } finally {
      _finish();
    }
  }

  Future<bool> preview(AudioFeedbackKind kind) async {
    if (busyKind != null || _disposed) return false;
    _begin(kind);
    try {
      await audio.play(kind);
      return true;
    } catch (_) {
      _setError(kind, '音效播放失败，请检查本机音频设备后重试。');
      return false;
    } finally {
      _finish();
    }
  }

  Future<bool> reset(AudioFeedbackKind kind) async {
    if (busyKind != null || _disposed) return false;
    _begin(kind);
    try {
      await repository.remove(kind);
      _custom.remove(kind);
      if (kind == AudioFeedbackKind.move) {
        await repository.setMoveSoundChoice(MoveSoundChoice.sound1);
        moveChoice = MoveSoundChoice.sound1;
      }
      return true;
    } catch (_) {
      _setError(kind, '无法恢复默认音效，请重试。');
      return false;
    } finally {
      _finish();
    }
  }

  void clearError() {
    error = null;
    errorKind = null;
    _notify();
  }

  void _begin(AudioFeedbackKind kind) {
    busyKind = kind;
    error = null;
    errorKind = null;
    _notify();
  }

  void _setError(AudioFeedbackKind kind, String message) {
    errorKind = kind;
    error = message;
  }

  void _finish() {
    busyKind = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
