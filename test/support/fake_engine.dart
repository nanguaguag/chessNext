import 'dart:async';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/ports/engine_gateway.dart';

class FakeEngine implements EngineGateway {
  final events = StreamController<EngineInfo>.broadcast();
  final requests = <EngineRequest>[];
  final results = <Completer<Move?>>[];
  int stops = 0;
  Move? stopMove;
  @override
  EngineLifecycle phase = EngineLifecycle.stopped;
  @override
  Stream<EngineInfo> get info => events.stream;
  @override
  Map<String, EngineOption> get options => const {
    'Threads': EngineOption(
      name: 'Threads',
      type: 'spin',
      minimum: 1,
      maximum: 8,
    ),
    'Hash': EngineOption(name: 'Hash', type: 'spin', minimum: 1, maximum: 1024),
    'MultiPV': EngineOption(
      name: 'MultiPV',
      type: 'spin',
      minimum: 1,
      maximum: 5,
    ),
  };
  @override
  Future<void> initialize() async {
    phase = EngineLifecycle.ready;
  }

  @override
  Future<EngineSearch> start(EngineRequest request) async {
    await stop();
    requests.add(request);
    phase = EngineLifecycle.searching;
    final result = Completer<Move?>();
    result.future.ignore();
    results.add(result);
    return EngineSearch(request.token, result.future);
  }

  void emit(
    int token, {
    int score = 10,
    String? bound,
    String pv = 'h2e2 b9c7',
  }) => events.add(
    EngineInfo(
      token: token,
      depth: 8,
      multiPv: 1,
      score: score,
      isMate: false,
      bound: bound,
      pv: pv.split(' ').map(Move.parse).toList(growable: false),
      timeMs: 100,
      nps: 20000,
    ),
  );
  @override
  Future<void> stop() async {
    if (results.isNotEmpty && !results.last.isCompleted) {
      stops++;
      results.last.complete(stopMove);
    }
    phase = EngineLifecycle.ready;
  }

  @override
  Future<void> dispose() async {
    if (phase == EngineLifecycle.closed) return;
    for (final result in results) {
      if (!result.isCompleted) result.complete(null);
    }
    phase = EngineLifecycle.closed;
    await events.close();
  }
}
