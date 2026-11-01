import 'dart:async';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../ports/engine_gateway.dart';
import 'engine_transport.dart';
import 'uci_parser.dart';

class UciEngine implements EngineGateway {
  UciEngine(
    this.transport, {
    this.networkPath,
    this.handshakeTimeout = const Duration(seconds: 10),
    this.stopTimeout = const Duration(seconds: 3),
  }) {
    if (networkPath != null && RegExp(r'[\r\n]').hasMatch(networkPath!)) {
      throw ArgumentError('Invalid network path');
    }
    _subscription = transport.lines.listen(
      _receive,
      onError: (Object e) => _fail(e),
      onDone: () {
        if (_phase != EngineLifecycle.closed) {
          _fail(StateError('Engine exited unexpectedly'));
        }
      },
    );
  }
  final EngineTransport transport;
  final String? networkPath;
  final Duration handshakeTimeout;
  final Duration stopTimeout;
  final _events = StreamController<EngineInfo>.broadcast();
  final Map<String, EngineOption> _options = {};
  Map<String, int> _appliedSettings = {};
  (int, String)? _gameKey;
  late final StreamSubscription<String> _subscription;
  Future<void> _tail = Future.value();
  EngineLifecycle _phase = EngineLifecycle.stopped;
  Object? _failure;
  Completer<void>? _waiting;
  String? _expected;
  Completer<Move?>? _result;
  int? _token;
  bool _closing = false;
  @override
  Stream<EngineInfo> get info => _events.stream;
  @override
  EngineLifecycle get phase => _phase;
  @override
  Map<String, EngineOption> get options => Map.unmodifiable(_options);
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _send(String command) {
    try {
      transport.send(command);
    } catch (e) {
      _fail(e);
      rethrow;
    }
  }

  void _check() {
    if (_phase == EngineLifecycle.closed || _closing) {
      throw StateError('Engine disposed');
    }
    if (_failure != null) throw StateError('Engine failed: $_failure');
  }

  void _fail(Object error) {
    if (_phase == EngineLifecycle.closed) return;
    _failure = error;
    _phase = EngineLifecycle.failed;
    if (_waiting != null && !_waiting!.isCompleted) {
      _waiting!.completeError(error);
    }
    if (_result != null && !_result!.isCompleted) _result!.completeError(error);
    _result = null;
    _token = null;
  }

  void _receive(String line) {
    final option = parseUciOption(line);
    if (option != null) _options[option.name] = option;
    if (line == _expected && _waiting != null && !_waiting!.isCompleted) {
      _waiting!.complete();
    }
    if (_token == null) return;
    if (line.startsWith('bestmove ')) {
      final text = line.split(' ')[1];
      Move? move;
      try {
        if (text != '(none)' && text != '0000') move = Move.parse(text);
      } on FormatException {
        _fail(StateError('Malformed bestmove'));
        return;
      }
      final result = _result;
      _result = null;
      _token = null;
      if (_phase != EngineLifecycle.failed) _phase = EngineLifecycle.ready;
      if (result != null && !result.isCompleted) result.complete(move);
    } else {
      final info = parseUciInfo(line, _token!);
      if (info != null && !_events.isClosed) _events.add(info);
    }
  }

  Future<void> _expect(String command, String response) async {
    _waiting = Completer<void>();
    _waiting!.future.ignore();
    _expected = response;
    try {
      _send(command);
      await _waiting!.future.timeout(handshakeTimeout);
    } catch (e) {
      _fail(e);
      rethrow;
    } finally {
      _waiting = null;
      _expected = null;
    }
  }

  Future<void> _initialize() async {
    _check();
    if (_phase != EngineLifecycle.stopped) return;
    _phase = EngineLifecycle.starting;
    await _expect('uci', 'uciok');
    if (networkPath != null) {
      if (!_options.containsKey('EvalFile')) {
        final error = UnsupportedError('EvalFile option not available');
        _fail(error);
        throw error;
      }
      _send('setoption name EvalFile value $networkPath');
    }
    await _expect('isready', 'readyok');
    _phase = EngineLifecycle.ready;
  }

  @override
  Future<void> initialize() => _serial(_initialize);
  Future<void> _stop() async {
    _check();
    final result = _result;
    if (result == null) return;
    _phase = EngineLifecycle.stopping;
    _send('stop');
    try {
      await result.future.timeout(stopTimeout);
    } catch (e) {
      _fail(e);
      await transport.close();
      rethrow;
    }
  }

  @override
  Future<void> stop() => _serial(_stop);
  @override
  Future<EngineSearch> start(EngineRequest request) => _serial(() async {
    _check();
    if (!request.root.validateForPlay().isValid) {
      throw ArgumentError('Invalid root');
    }
    final position = request.position;
    if (request.searchMoves != null) {
      final legal = position.legalMoves.toSet();
      if (!request.searchMoves!.every(legal.contains)) {
        throw ArgumentError('Illegal searchmoves');
      }
    }
    if (position.boardOutcome().isTerminal) {
      throw ArgumentError('Terminal position');
    }
    await _initialize();
    final settings = {
      'Threads': request.threads,
      'Hash': request.hashMb,
      'MultiPV': request.multiPv,
    };
    for (final setting in settings.entries) {
      final option = _options[setting.key];
      if (option == null || option.type != 'spin') {
        throw UnsupportedError('${setting.key} unavailable');
      }
      if ((option.minimum != null && setting.value < option.minimum!) ||
          (option.maximum != null && setting.value > option.maximum!)) {
        throw ArgumentError('${setting.key} out of range');
      }
    }
    await _stop();
    final changed = settings.entries
        .where((entry) => _appliedSettings[entry.key] != entry.value)
        .toList();
    final gameKey = (request.gameId, request.root.toFen());
    final newGame = gameKey != _gameKey;
    for (final setting in changed) {
      _send('setoption name ${setting.key} value ${setting.value}');
    }
    if (newGame) _send('ucinewgame');
    if (newGame || changed.isNotEmpty) {
      await _expect('isready', 'readyok');
      // Only remember changes after the engine has acknowledged readiness.
      _appliedSettings = settings;
      _gameKey = gameKey;
    }
    final moves = request.moves.map((m) => m.toString()).join(' ');
    _send(
      'position fen ${request.root.toFen()}${moves.isEmpty ? '' : ' moves $moves'}',
    );
    final result = Completer<Move?>();
    result.future
        .ignore(); // Callers may dispose without awaiting a pending search result.
    _result = result;
    _token = request.token;
    _phase = EngineLifecycle.searching;
    final limits = [
      if (request.depth != null) 'depth ${request.depth}',
      if (request.moveTimeMs != null) 'movetime ${request.moveTimeMs}',
      if (request.nodeLimit != null) 'nodes ${request.nodeLimit}',
    ];
    final limit = limits.isEmpty ? 'infinite' : limits.join(' ');
    final candidates = request.searchMoves == null
        ? ''
        : ' searchmoves ${request.searchMoves!.join(' ')}';
    _send('go $limit$candidates');
    return EngineSearch(request.token, result.future);
  });
  @override
  Future<void> dispose() {
    if (_closing || _phase == EngineLifecycle.closed) return _tail;
    _closing = true;
    return _serial(() async {
      _phase = EngineLifecycle.closed;
      if (_waiting != null && !_waiting!.isCompleted) {
        _waiting!.completeError(StateError('Engine disposed'));
      }
      if (_result != null && !_result!.isCompleted) {
        _result!.completeError(StateError('Engine disposed'));
      }
      _result = null;
      _token = null;
      await _subscription.cancel();
      await transport.close();
      await _events.close();
    });
  }
}
