import 'dart:io';
import 'package:engine_probe/engine_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'real Pikafish NNUE and serialized UCI lifecycle',
    () async {
      final directory = Platform.environment['PIKAFISH_DIR'];
      expect(
        directory,
        isNotNull,
        reason: 'Set PIKAFISH_DIR to official bundle',
      );
      final log = await runEngineProbe(directory!, stopCycles: 100);
      final path = Platform.environment['PIKAFISH_PROBE_LOG'];
      if (path != null) File(path).writeAsStringSync(log);
      expect(log, contains('100 stop cycles, exit=0'));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test('missing engine is a failure rather than false success', () async {
    final directory = await Directory.systemTemp.createTemp(
      'missing-pikafish-',
    );
    try {
      await expectLater(
        runEngineProbe(directory.path),
        throwsA(isA<ProcessException>()),
      );
    } finally {
      await directory.delete();
    }
  });
}
