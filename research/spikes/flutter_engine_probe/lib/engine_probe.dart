import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A bounded, single-session diagnostic, not the production engine adapter.
Future<String> runEngineProbe(String directory, {int stopCycles = 3}) async {
  final log = StringBuffer();
  final process = await Process.start(
    '$directory/Pikafish-MacOS-universal',
    const [],
    workingDirectory: directory,
  );
  final output = StreamIterator(
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
  );
  final errors = process.stderr
      .transform(utf8.decoder)
      .listen((line) => log.writeln('stderr: $line'));
  void send(String command) {
    log.writeln('>>> $command');
    process.stdin.writeln(command);
  }

  Future<List<String>> until(String prefix) async {
    final lines = <String>[];
    while (await output.moveNext().timeout(const Duration(seconds: 20))) {
      final line = output.current;
      log.writeln(line);
      lines.add(line);
      if (line.startsWith(prefix)) return lines;
    }
    throw StateError('Engine EOF while waiting for $prefix');
  }

  try {
    send('uci');
    final handshake = await until('uciok');
    for (final name in ['Threads', 'Hash', 'MultiPV', 'EvalFile']) {
      if (!handshake.any((line) => line.startsWith('option name $name '))) {
        throw StateError('Required option missing: $name');
      }
    }
    send('setoption name Threads value 1');
    send('setoption name Hash value 16');
    send('setoption name MultiPV value 2');
    send('setoption name EvalFile value $directory/pikafish.nnue');
    send('isready');
    await until('readyok');
    send('ucinewgame');
    send('position startpos');
    send('go depth 6');
    final search = await until('bestmove ');
    if (!search.any((line) => line.contains('NNUE evaluation using')) ||
        !search.any((line) => line.contains('multipv 2')) ||
        !RegExp(r'^bestmove [a-i][0-9][a-i][0-9]').hasMatch(search.last)) {
      throw StateError('NNUE / MultiPV / bestmove validation failed');
    }
    send('position startpos moves h2e2');
    send('go movetime 200');
    await until('bestmove ');
    for (var i = 0; i < stopCycles; i++) {
      send('position startpos');
      send('go infinite');
      await until('info depth ');
      send('stop');
      await until('bestmove ');
    }
    send('quit');
    await process.stdin.close();
    final code = await process.exitCode.timeout(const Duration(seconds: 5));
    if (code != 0) throw StateError('Exit code $code');
    log.writeln(
      'PASS: NNUE, MultiPV, timed search, $stopCycles stop cycles, exit=$code',
    );
    return log.toString();
  } catch (error) {
    throw StateError('$error\n$log');
  } finally {
    process.kill();
    await output.cancel();
    await errors.cancel();
  }
}
