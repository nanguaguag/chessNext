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
    _notify();
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
