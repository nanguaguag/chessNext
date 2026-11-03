import 'dart:async';

import 'package:flutter/foundation.dart';
import 'board_session.dart';
import 'engine_session_controller.dart';

/// Reads the current selected line without changing document content.
class RecordPlaybackController extends ChangeNotifier {
  RecordPlaybackController(this.session, this.engine, {int intervalMs = 2000})
    : _interval = Duration(milliseconds: intervalMs) {
    _validateInterval(intervalMs);
    session.addListener(_sessionChanged);
  }

  final BoardSession session;
  final EngineSessionController engine;
  Duration _interval;
  Timer? _timer;
  bool _playing = false;
  bool _navigating = false;
  bool _disposed = false;
  int _epoch = 0;
  int _revision = 0;
  int _positionRevision = 0;
  String? _cursorId;

  bool get playing => _playing;
  bool get canPlay => session.nextNodeId != null;
  Duration get interval => _interval;

  static void _validateInterval(int milliseconds) {
    if (milliseconds < 500 || milliseconds > 30000 || milliseconds % 100 != 0) {
      throw ArgumentError.value(milliseconds, 'milliseconds');
    }
  }

  void _capturePosition() {
    _epoch = session.epoch;
    _revision = session.revision;
    _positionRevision = session.positionRevision;
    _cursorId = session.tree.cursorId;
  }

  bool _positionIsCurrent() =>
      session.epoch == _epoch &&
      session.revision == _revision &&
      session.positionRevision == _positionRevision &&
      session.tree.cursorId == _cursorId;

  void _sessionChanged() {
    if (_playing && !_navigating && !_positionIsCurrent()) stop();
  }

  bool start() {
    if (_disposed || _playing || !canPlay) return false;
    _capturePosition();
    _playing = true;
    _notify();
    _schedule();
    return true;
  }

  void stop() {
    if (!_playing && _timer == null) return;
    _timer?.cancel();
    _timer = null;
    _playing = false;
    _notify();
  }

  void setInterval(int milliseconds) {
    _validateInterval(milliseconds);
    final next = Duration(milliseconds: milliseconds);
    if (next == _interval) return;
    _interval = next;
    if (_playing) {
      _timer?.cancel();
      _schedule();
    }
    _notify();
  }

  void _schedule() {
    if (!_playing || _disposed) return;
    _timer = Timer(_interval, _advance);
  }

  Future<void> _advance() async {
    _timer = null;
    if (!_playing || _disposed || !_positionIsCurrent()) {
      stop();
      return;
    }
    final target = session.nextNodeId;
    if (target == null) {
      stop();
      return;
    }
    final expectedEpoch = session.epoch;
    final expectedRevision = session.revision;
    _navigating = true;
    try {
      await engine.navigateToNode(target);
    } catch (_) {
      stop();
      return;
    } finally {
      _navigating = false;
    }
    if (_disposed ||
        !_playing ||
        session.epoch != expectedEpoch ||
        session.revision != expectedRevision ||
        session.tree.cursorId != target) {
      stop();
      return;
    }
    _capturePosition();
    if (canPlay) {
      _schedule();
    } else {
      stop();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _playing = false;
    session.removeListener(_sessionChanged);
    super.dispose();
  }
}
