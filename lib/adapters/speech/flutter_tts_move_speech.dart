import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../ports/move_speech.dart';

/// Uses an installed Mandarin system voice and never requests cloud synthesis.
/// Linux is intentionally unsupported until a local system adapter is verified.
final class FlutterTtsMoveSpeech implements MoveSpeechPort {
  FlutterTtsMoveSpeech({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<void> _queue = Future.value();
  Future<void>? _prepareTask;
  bool _disposed = false;
  Map<String, String>? _voice;

  bool get _platformSupported =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => true,
        _ => false,
      };

  Future<void> _prepare() {
    if (_prepareTask != null) return _prepareTask!;
    final task = _findMandarinVoice();
    _prepareTask = task;
    return task;
  }

  Future<void> _findMandarinVoice() async {
    if (!_platformSupported) return;
    final available = await _tts.getVoices;
    if (available is! List) return;
    for (final item in available) {
      if (item is! Map) continue;
      final locale = (item['locale'] ?? '').toString();
      if (!locale.toLowerCase().replaceAll('_', '-').startsWith('zh')) {
        continue;
      }
      final networkRequired = item['network_required'];
      if (defaultTargetPlatform == TargetPlatform.android &&
          (networkRequired == true || networkRequired == 'true')) {
        continue;
      }
      final name = item['name']?.toString();
      if (name == null || name.isEmpty || locale.isEmpty) continue;
      _voice = {'name': name, 'locale': locale};
      await _tts.setVoice(_voice!);
      await _tts.setSpeechRate(.48);
      await _tts.awaitSpeakCompletion(true);
      return;
    }
  }

  @override
  Future<void> speak(String notation) {
    if (_disposed || notation.trim().isEmpty || !_platformSupported) {
      return Future.value();
    }
    final next = _queue.then((_) async {
      try {
        await _prepare();
        if (_disposed || _voice == null) return;
        await _tts.speak(notation);
      } catch (_) {
        // Speech is optional and never affects a committed board move.
      }
    });
    _queue = next.catchError((Object _) {});
    return _queue;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _tts.stop();
    } catch (_) {
      // Native speech may already be unavailable during shutdown.
    }
  }
}
