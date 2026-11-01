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

      // Each case leaves two loose bounds and one terminating bound.
      final limits = [
        (token: 10, depth: 2, time: 10000, nodes: 1000000000),
        (token: 11, depth: 100, time: 200, nodes: 1000000000),
        (token: 12, depth: 100, time: 10000, nodes: 2000),
      ];
      for (final limit in limits) {
        final search = await engine.start(
          EngineRequest(
            token: limit.token,
            root: root,
            depth: limit.depth,
            moveTimeMs: limit.time,
            nodeLimit: limit.nodes,
          ),
        );
        final move = await search.bestMove.timeout(const Duration(seconds: 10));
        expect(root.legalMoves, contains(move));
        await Future<void>.delayed(Duration.zero);
        final infos = seen.where((info) => info.token == limit.token).toList();
        expect(infos, isNotEmpty);
        final last = infos.last;
        if (limit.token == 10) expect(last.depth, lessThanOrEqualTo(2));
        if (limit.token == 11) {
          expect(last.depth, lessThan(100));
          expect(last.timeMs, lessThan(5000));
        }
        if (limit.token == 12) {
          expect(last.depth, lessThan(100));
          expect(
            last.nodes,
            lessThan(50000),
            reason: 'node polling may overshoot the exact requested bound',
          );
        }
      }
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
  test(
    'pinned NNUE supplies native WDL for both sides to move',
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
      final infos = <EngineInfo>[];
      final subscription = engine.info.listen(infos.add);
      addTearDown(subscription.cancel);
      for (var token = 20; token < 22; token++) {
        final search = await engine.start(
          EngineRequest(
            token: token,
            root: Position.initial(),
            moves: token == 20 ? const [] : [Move.parse('h2e2')],
            depth: 4,
            preferWdl: true,
          ),
        );
        await search.bestMove.timeout(const Duration(seconds: 15));
        await Future<void>.delayed(Duration.zero);
        final current = infos.where((i) => i.token == token).toList();
        expect(current, isNotEmpty);
        expect(current.every((i) => i.wdl != null), isTrue);
        for (final info in current) {
          expect(info.wdl!.toJson().reduce((a, b) => a + b), 1000);
        }
      }
    },
    skip: executable == null ? 'Set PIKAFISH_EXECUTABLE for native WDL' : false,
  );
}
