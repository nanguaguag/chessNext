import 'dart:async';
import 'package:chess_next/adapters/engine/engine_transport.dart';
import 'package:chess_next/adapters/engine/uci_engine.dart';
import 'package:chess_next/adapters/engine/uci_parser.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransport implements EngineTransport {
  final output = StreamController<String>(sync: true);
  final commands = <String>[];
  bool respond = true;
  bool offerWdl = false;
  bool autoStop = true;
  bool autoReady = true;
  bool closed = false;
  @override
  Stream<String> get lines => output.stream;
  @override
  void send(String command) {
    commands.add(command);
    if (!respond) return;
    if (command == 'uci') {
      output.add('id name Synthetic UCI 1.0');
      if (offerWdl) {
        output.add('option name UCI_ShowWDL type check default false');
      }
      for (final option in [
        'Threads type spin default 1 min 1 max 8',
        'Hash type spin default 16 min 1 max 128',
        'MultiPV type spin default 1 min 1 max 5',
        'EvalFile type string default pikafish.nnue',
      ]) {
        output.add('option name $option');
      }
      output.add('uciok');
    }
    if (command == 'isready' && autoReady) output.add('readyok');
    if (command == 'stop' && autoStop) {
      scheduleMicrotask(() => output.add('bestmove h2e2'));
    }
  }

  @override
  Future<void> close() async {
    if (!closed) {
      closed = true;
      await output.close();
    }
  }
}

EngineRequest request(int token) =>
    EngineRequest(token: token, root: Position.initial());
void main() {
  test(
    'engine name comes from handshake, not late search output or provenance guess',
    () async {
      final transport = FakeTransport();
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      expect(engine.name, isNull);
      expect(engine.identity, isNull);
      await engine.initialize();
      expect(engine.name, 'Synthetic UCI 1.0');
      transport.output.add('id name late replacement');
      expect(engine.name, 'Synthetic UCI 1.0');
    },
  );

  test(
    'UCI parser preserves score kind, bounds, MultiPV and spaced option names',
    () {
      final option = parseUciOption(
        'option name Move Overhead type spin default 10 min 0 max 5000',
      )!;
      expect(option.name, 'Move Overhead');
      expect(option.minimum, 0);
      expect(option.maximum, 5000);
      expect(option.defaultValue, '10');
      final info = parseUciInfo(
        'info depth 8 score mate -3 upperbound nodes 200 time 10 nps 20000 multipv 2 pv h2e2 b9c7',
        9,
      )!;
      expect(info.token, 9);
      expect(info.score, -3);
      expect(info.isMate, isTrue);
      expect(info.bound, 'upper');
      expect(info.multiPv, 2);
      expect(info.pv.map((m) => m.toString()), ['h2e2', 'b9c7']);
      expect(parseUciInfo('info string loading network', 1), isNull);
      expect(parseUciInfo('info score cp 10 pv malformed', 1), isNull);
    },
  );
  test(
    'next search waits for stop/bestmove barrier and tags old info correctly',
    () async {
      final transport = FakeTransport()..autoStop = false;
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      final seen = <EngineInfo>[];
      final subscription = engine.info.listen(seen.add);
      addTearDown(subscription.cancel);
      final first = await engine.start(request(1));
      final secondFuture = engine.start(request(2));
      await Future<void>.delayed(Duration.zero);
      expect(transport.commands.where((c) => c.startsWith('go ')).length, 1);
      transport.output.add('info depth 2 score cp 8 pv h2e2');
      transport.output.add('bestmove h2e2');
      expect((await first.bestMove).toString(), 'h2e2');
      final second = await secondFuture;
      transport.output.add('info depth 3 score cp 10 pv h2e2');
      transport.output.add('bestmove h2e2');
      await second.bestMove;
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((e) => e.token), [1, 2]);
      expect(engine.phase, EngineLifecycle.ready);
    },
  );
  test(
    'unsupported resource range rejects before interrupting active search',
    () async {
      final transport = FakeTransport();
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      final current = await engine.start(request(1));
      await expectLater(
        engine.start(
          EngineRequest(token: 2, root: Position.initial(), threads: 100),
        ),
        throwsArgumentError,
      );
      expect(transport.commands, isNot(contains('stop')));
      await engine.stop();
      expect(await current.bestMove, Move.parse('h2e2'));
    },
  );
  test('EOF and handshake timeout fail boundedly and allow disposal', () async {
    final transport = FakeTransport()..respond = false;
    final engine = UciEngine(
      transport,
      handshakeTimeout: const Duration(milliseconds: 20),
    );
    await expectLater(engine.initialize(), throwsA(isA<TimeoutException>()));
    expect(engine.phase, EngineLifecycle.failed);
    await engine.dispose();
    expect(transport.closed, isTrue);
    final other = FakeTransport();
    final client = UciEngine(other);
    final current = await client.start(request(1));
    final failed = expectLater(current.bestMove, throwsStateError);
    await other.close();
    await failed;
    expect(client.phase, EngineLifecycle.failed);
    await client.dispose();
  });
  test(
    'stop timeout closes the transport rather than starting overlapping work',
    () async {
      final transport = FakeTransport()..autoStop = false;
      final engine = UciEngine(
        transport,
        stopTimeout: const Duration(milliseconds: 20),
      );
      final search = await engine.start(request(1));
      final failed = expectLater(search.bestMove, throwsA(anything));
      await expectLater(engine.stop(), throwsA(isA<TimeoutException>()));
      await failed;
      expect(transport.closed, isTrue);
      expect(engine.phase, EngineLifecycle.failed);
      await engine.dispose();
    },
  );
  test('searchmoves is sent last and illegal subsets are rejected', () async {
    final transport = FakeTransport();
    final engine = UciEngine(transport);
    addTearDown(engine.dispose);
    final search = await engine.start(
      EngineRequest.fromTree(
        token: 1,
        tree: GameTree(),
        depth: 1,
        searchMoves: [Move.parse('h2e2')],
      ),
    );
    expect(transport.commands.last, 'go depth 1 searchmoves h2e2');
    transport.output.add('bestmove h2e2');
    await search.bestMove;
    await expectLater(
      engine.start(
        EngineRequest(
          token: 2,
          root: Position.initial(),
          searchMoves: [Move.parse('a9a8')],
        ),
      ),
      throwsArgumentError,
    );
  });
  test(
    'combined depth, time and node limits precede the final searchmoves clause',
    () async {
      final transport = FakeTransport();
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      final search = await engine.start(
        EngineRequest.fromTree(
          token: 17,
          tree: GameTree(),
          depth: 16,
          moveTimeMs: 2000,
          nodeLimit: 50000,
          searchMoves: [Move.parse('h2e2')],
        ),
      );
      expect(
        transport.commands.last,
        'go depth 16 movetime 2000 nodes 50000 searchmoves h2e2',
      );
      transport.output.add('bestmove h2e2');
      await search.bestMove;
      final nodesOnly = await engine.start(
        EngineRequest(token: 18, root: Position.initial(), nodeLimit: 1000),
      );
      expect(transport.commands.last, 'go nodes 1000');
      transport.output.add('bestmove h2e2');
      await nodesOnly.bestMove;
    },
  );
  test(
    'both request factories reject invalid budgets and retain a fully unrestricted mode',
    () {
      final makers = <EngineRequest Function(int?, int?, int?)>[
        (depth, time, nodes) => EngineRequest(
          token: 1,
          root: Position.initial(),
          depth: depth,
          moveTimeMs: time,
          nodeLimit: nodes,
        ),
        (depth, time, nodes) => EngineRequest.fromTree(
          token: 1,
          tree: GameTree(),
          depth: depth,
          moveTimeMs: time,
          nodeLimit: nodes,
        ),
      ];
      for (final make in makers) {
        for (final limits in [
          (0, null, null),
          (-1, null, null),
          (256, null, null),
          (null, 0, null),
          (null, EngineRequest.maxMoveTimeMs + 1, null),
          (null, null, 0),
          (null, null, -1),
          (null, null, EngineRequest.maxNodeLimit + 1),
        ]) {
          expect(
            () => make(limits.$1, limits.$2, limits.$3),
            throwsArgumentError,
          );
        }
        expect(make(null, null, null).nodeLimit, isNull);
        expect(make(16, 2000, 10000).nodeLimit, 10000);
      }
    },
  );
  test(
    'same document reuses resources and cache; changed options and game epochs are acknowledged',
    () async {
      final transport = FakeTransport();
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      Future<void> search(EngineRequest request, [String best = 'h2e2']) async {
        final result = await engine.start(request);
        transport.output.add('bestmove $best');
        await result.bestMove;
      }

      final root = Position.initial();
      await search(EngineRequest(token: 1, gameId: 7, root: root, depth: 1));
      final firstCommands = transport.commands.length;
      expect(
        transport.commands.where((c) => c.startsWith('setoption')).length,
        3,
      );
      expect(transport.commands.where((c) => c == 'ucinewgame').length, 1);
      expect(
        transport.commands.indexOf('ucinewgame'),
        lessThan(transport.commands.lastIndexOf('isready')),
      );
      await search(
        EngineRequest.fromTree(token: 2, gameId: 7, tree: GameTree(), depth: 2),
      );
      expect(
        transport.commands
            .skip(firstCommands)
            .where(
              (c) =>
                  c.startsWith('setoption') ||
                  c == 'ucinewgame' ||
                  c == 'isready',
            ),
        isEmpty,
      );
      await search(
        EngineRequest(
          token: 3,
          gameId: 7,
          root: root,
          hashMb: 32,
          multiPv: 2,
          depth: 1,
        ),
      );
      expect(
        transport.commands
            .where((c) => c == 'setoption name Threads value 1')
            .length,
        1,
      );
      expect(
        transport.commands
            .where((c) => c == 'setoption name Hash value 32')
            .length,
        1,
      );
      expect(
        transport.commands
            .where((c) => c == 'setoption name MultiPV value 2')
            .length,
        1,
      );
      expect(transport.commands.where((c) => c == 'ucinewgame').length, 1);
      await search(
        EngineRequest(
          token: 4,
          gameId: 8,
          root: root,
          hashMb: 32,
          multiPv: 2,
          depth: 1,
        ),
      );
      expect(transport.commands.where((c) => c == 'ucinewgame').length, 2);
      final custom = SetupDraft.fromPosition(root).clear().toPosition();
      await search(
        EngineRequest(
          token: 5,
          gameId: 8,
          root: custom,
          hashMb: 32,
          multiPv: 2,
          depth: 1,
        ),
        'e0e1',
      );
      expect(transport.commands.where((c) => c == 'ucinewgame').length, 3);
    },
  );
  test('changed cached resources wait for readyok before the next go', () async {
    final transport = FakeTransport();
    final engine = UciEngine(
      transport,
      handshakeTimeout: const Duration(seconds: 1),
    );
    addTearDown(engine.dispose);
    final first = await engine.start(
      EngineRequest(token: 1, root: Position.initial(), depth: 1),
    );
    transport.output.add('bestmove h2e2');
    await first.bestMove;
    transport.autoReady = false;
    final pending = engine.start(
      EngineRequest(token: 2, root: Position.initial(), hashMb: 32, depth: 1),
    );
    await Future<void>.delayed(Duration.zero);
    expect(transport.commands.last, 'isready');
    expect(transport.commands.where((c) => c.startsWith('go ')).length, 1);
    transport.output.add('readyok');
    final second = await pending;
    transport.output.add('bestmove h2e2');
    await second.bestMove;
    // The acknowledged value can now be reused without another readiness wait.
    final third = await engine.start(
      EngineRequest(token: 3, root: Position.initial(), hashMb: 32, depth: 1),
    );
    transport.output.add('bestmove h2e2');
    await third.bestMove;
    expect(transport.commands.where((c) => c.startsWith('go ')).length, 3);
  });
  test(
    'native WDL preference changes once and waits ready before starting',
    () async {
      final transport = FakeTransport()..offerWdl = true;
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      final seen = <EngineInfo>[];
      final subscription = engine.info.listen(seen.add);
      addTearDown(subscription.cancel);
      final first = await engine.start(
        EngineRequest(
          token: 1,
          root: Position.initial(),
          depth: 3,
          preferWdl: true,
        ),
      );
      transport.output.add('info depth 3 score cp 10 wdl 200 700 100 pv h2e2');
      transport.output.add('bestmove h2e2');
      await first.bestMove;
      await Future<void>.delayed(Duration.zero);
      expect(seen.single.wdl!.toJson(), [200, 700, 100]);
      final second = await engine.start(
        EngineRequest(
          token: 2,
          root: Position.initial(),
          depth: 3,
          preferWdl: true,
        ),
      );
      transport.output.add('bestmove h2e2');
      await second.bestMove;
      expect(
        transport.commands
            .where((c) => c == 'setoption name UCI_ShowWDL value true')
            .length,
        1,
      );
      transport.autoReady = false;
      final pending = engine.start(
        EngineRequest(token: 3, root: Position.initial(), depth: 3),
      );
      await Future<void>.delayed(Duration.zero);
      expect(transport.commands.last, 'isready');
      expect(
        transport.commands,
        contains('setoption name UCI_ShowWDL value false'),
      );
      expect(transport.commands.where((c) => c.startsWith('go ')).length, 2);
      transport.output.add('readyok');
      final third = await pending;
      transport.output.add('bestmove h2e2');
      await third.bestMove;
    },
  );
  test(
    'an engine without WDL continues normal search when statistics are preferred',
    () async {
      final transport = FakeTransport();
      final engine = UciEngine(transport);
      addTearDown(engine.dispose);
      final search = await engine.start(
        EngineRequest(
          token: 1,
          root: Position.initial(),
          depth: 3,
          preferWdl: true,
        ),
      );
      transport.output.add('bestmove h2e2');
      expect(await search.bestMove, Move.parse('h2e2'));
      expect(
        transport.commands.any(
          (c) => c.startsWith('setoption name UCI_ShowWDL'),
        ),
        isFalse,
      );
    },
  );
  test('unacknowledged WDL settings fail before sending go', () async {
    final transport = FakeTransport()..offerWdl = true;
    final engine = UciEngine(
      transport,
      handshakeTimeout: const Duration(milliseconds: 30),
    );
    addTearDown(engine.dispose);
    await engine.initialize();
    transport.autoReady = false;
    await expectLater(
      engine.start(
        EngineRequest(
          token: 1,
          root: Position.initial(),
          depth: 3,
          preferWdl: true,
        ),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(engine.phase, EngineLifecycle.failed);
    expect(transport.commands.any((c) => c.startsWith('go ')), isFalse);
  });
}
