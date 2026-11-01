// macOS developer benchmark; no production UI or runtime behavior is changed.
import 'dart:convert';
import 'dart:io';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:chess_next/adapters/engine/engine_transport.dart';
import 'package:chess_next/adapters/engine/uci_engine.dart';
import 'package:chess_next/ports/engine_gateway.dart';

class ResetComparisonTransport implements EngineTransport {
  ResetComparisonTransport(this.inner, {required this.cold});
  final EngineTransport inner;
  final bool cold;
  final commands = <String>[];
  @override
  Stream<String> get lines => inner.lines;
  void _forward(String command) {
    commands.add(command);
    inner.send(command);
  }

  @override
  void send(String command) {
    if (cold && command.startsWith('position fen ')) {
      // Cold comparison deliberately rebuilds resources and clears search state.
      // This is not an assertion of bit-for-bit timing equivalence to an old GUI.
      _forward('setoption name Threads value 1');
      _forward('setoption name Hash value 64');
      _forward('setoption name MultiPV value 1');
      _forward('ucinewgame');
    }
    _forward(command);
  }

  @override
  Future<void> close() => inner.close();
}

double median(List<double> numbers) {
  final ordered = [...numbers]..sort();
  final middle = ordered.length ~/ 2;
  return ordered.length.isOdd
      ? ordered[middle]
      : (ordered[middle - 1] + ordered[middle]) / 2;
}

Future<Map<String, Object?>> measure(
  String executable,
  String network, {
  required bool cold,
}) async {
  final process = await ProcessEngineTransport.spawn(
    executable,
    workingDirectory: File(executable).parent.path,
  );
  final transport = ResetComparisonTransport(process, cold: cold);
  final engine = UciEngine(transport, networkPath: network);
  final infos = <EngineInfo>[];
  final subscription = engine.info.listen(infos.add);
  final samples = <Map<String, Object?>>[];
  var measuredFrom = 0;
  try {
    await engine.initialize();
    for (var index = -1; index < 10; index++) {
      final token = index + 2;
      final request = EngineRequest(
        token: token,
        gameId: 0,
        root: Position.initial(),
        moves: index.isOdd
            ? [Move.parse('h2e2'), Move.parse('b9c7')]
            : const [],
        depth: 10,
        threads: 1,
        hashMb: 64,
        multiPv: 1,
      );
      final watch = Stopwatch()..start();
      final search = await engine.start(request);
      final move = await search.bestMove.timeout(const Duration(seconds: 30));
      watch.stop();
      if (!request.position.legalMoves.contains(move)) {
        throw StateError('Illegal benchmark result');
      }
      await Future<void>.delayed(Duration.zero);
      final info = infos.where((item) => item.token == token).last;
      if (index == -1) {
        measuredFrom = transport.commands.length;
        continue;
      }
      samples.add({
        'history': request.moves.join(' '),
        'wall_ms': watch.elapsedMicroseconds / 1000,
        'nodes': info.nodes,
        'engine_ms': info.timeMs,
        'depth': info.depth,
        'bestmove': move.toString(),
      });
    }
    final commands = transport.commands.skip(measuredFrom);
    return {
      'mode': cold ? 'forced_resource_reset' : 'same_game_reuse',
      'samples': samples,
      'median_wall_ms': median(
        samples.map((sample) => sample['wall_ms'] as double).toList(),
      ),
      'measured_setoption_count': commands
          .where((c) => c.startsWith('setoption'))
          .length,
      'measured_ucinewgame_count': commands
          .where((c) => c == 'ucinewgame')
          .length,
    };
  } finally {
    await subscription.cancel();
    await engine.dispose();
  }
}

Future<void> main(List<String> arguments) async {
  final executable = File(
    Platform.environment['PIKAFISH_EXECUTABLE'] ??
        '.local/pikafish/Pikafish-MacOS-universal',
  ).absolute.path;
  final network = File(
    Platform.environment['PIKAFISH_NETWORK'] ?? '.local/pikafish/pikafish.nnue',
  ).absolute.path;
  final lock =
      jsonDecode(await File('docs/engine/pikafish.lock.json').readAsString())
          as Map<String, dynamic>;
  for (final item in [
    (executable, 'macos_binary_sha256'),
    (network, 'network_sha256'),
  ]) {
    final result = await Process.run('shasum', ['-a', '256', item.$1]);
    if (result.exitCode != 0 ||
        result.stdout.toString().split(RegExp(r'\s+')).first != lock[item.$2]) {
      throw StateError(
        'Official artifact checksum mismatch; run tools/setup_pikafish.py',
      );
    }
  }
  final output = <String, Object?>{
    'date': DateTime.now().toUtc().toIso8601String(),
    'release': lock['release'],
    'commit': lock['commit'],
    'binary_sha256': lock['macos_binary_sha256'],
    'network_sha256': lock['network_sha256'],
    'os': Platform.operatingSystemVersion,
    'logical_processors': Platform.numberOfProcessors,
    'dart': Platform.version,
    'settings': {
      'threads': 1,
      'hash_mb': 64,
      'multipv': 1,
      'depth': 10,
      'samples_per_mode': 10,
      'warmup_per_mode': 1,
    },
    'note':
        'Alternating initial/two-ply positions, one process per mode. Warm cache benefit is workload-specific; this is not an Elo, general speedup, or <=5% adapter-overhead claim.',
    'modes': [
      await measure(executable, network, cold: true),
      await measure(executable, network, cold: false),
    ],
  };
  final json = '${const JsonEncoder.withIndent('  ').convert(output)}\n';
  if (arguments.isEmpty) {
    stdout.write(json);
  } else {
    final destination = File(arguments.single);
    await destination.parent.create(recursive: true);
    await destination.writeAsString(json);
    stdout.writeln('Benchmark saved: ${destination.path}');
  }
}
