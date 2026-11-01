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
  bool autoStop = true;
  bool closed = false;
  @override
  Stream<String> get lines => output.stream;
  @override
  void send(String command) {
    commands.add(command);
    if (!respond) return;
    if (command == 'uci') {
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
    if (command == 'isready') output.add('readyok');
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
}
