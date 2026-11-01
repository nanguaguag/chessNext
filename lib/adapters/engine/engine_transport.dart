import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract interface class EngineTransport {
  Stream<String> get lines;
  void send(String command);
  Future<void> close();
}

class ProcessEngineTransport implements EngineTransport {
  ProcessEngineTransport._(this._process) {
    _stdout = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _lines.add,
          onError: _lines.addError,
          onDone: () {
            if (!_lines.isClosed) _lines.close();
          },
        );
    // Always drain stderr, even when an engine emits no stdout.
    _stderr = _process.stderr.listen((_) {});
  }
  static Future<ProcessEngineTransport> spawn(
    String executable, {
    String? workingDirectory,
  }) async => ProcessEngineTransport._(
    await Process.start(
      executable,
      const [],
      workingDirectory: workingDirectory,
    ),
  );
  final Process _process;
  final _lines = StreamController<String>();
  late final StreamSubscription<String> _stdout;
  late final StreamSubscription<List<int>> _stderr;
  bool _closed = false;
  @override
  Stream<String> get lines => _lines.stream;
  @override
  void send(String command) {
    if (_closed || command.contains('\n') || command.contains('\r')) {
      throw StateError('Transport is closed or command is not a single line');
    }
    _process.stdin.writeln(command);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      _process.stdin.writeln('quit');
      await _process.stdin.close();
      await _process.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      _process.kill();
      await _process.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () => -1,
      );
    } finally {
      await _stdout.cancel();
      await _stderr.cancel();
      if (!_lines.isClosed) await _lines.close();
    }
  }
}
