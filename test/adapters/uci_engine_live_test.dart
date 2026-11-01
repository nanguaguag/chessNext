import 'dart:io';
import 'package:chess_next/adapters/engine/engine_transport.dart';
import 'package:chess_next/adapters/engine/uci_engine.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final executable = Platform.environment['PIKAFISH_EXECUTABLE'];
  test(
    'production UCI adapter drives pinned Pikafish NNUE and repeated cancellation',
    () async {
      final transport = await ProcessEngineTransport.spawn(
        executable!,
        workingDirectory: File(executable).parent.path,
      );
      final engine = UciEngine(
        transport,
        networkPath: Platform.environment['PIKAFISH_NETWORK'],
      );
      addTearDown(engine.dispose);
      final seen = <EngineInfo>[];
      final subscription = engine.info.listen(seen.add);
      addTearDown(subscription.cancel);
      final root = Position.initial();
      final search = await engine.start(
        EngineRequest(token: 1, root: root, depth: 8, multiPv: 2),
      );
      final best = await search.bestMove.timeout(const Duration(seconds: 20));
      expect(root.legalMoves, contains(best));
      expect(seen.any((e) => e.multiPv == 2), isTrue);
      expect(engine.options['Threads']?.type, 'spin');
      final restricted = await engine.start(
        EngineRequest(
          token: 9,
          root: root,
          depth: 3,
          searchMoves: [Move.parse('h2e2')],
        ),
      );
      expect(
        await restricted.bestMove.timeout(const Duration(seconds: 10)),
        Move.parse('h2e2'),
      );
      for (var token = 2; token <= 6; token++) {
        final current = await engine.start(
          EngineRequest(token: token, root: root),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await engine.stop();
        expect(root.legalMoves, contains(await current.bestMove));
      }
      expect(engine.phase, EngineLifecycle.ready);
    },
    skip: executable == null
        ? 'Set PIKAFISH_EXECUTABLE for the official-engine test'
        : false,
  );
}
