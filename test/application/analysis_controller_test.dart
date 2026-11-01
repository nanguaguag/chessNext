import 'package:chess_next/application/analysis_controller.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/chess_next.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

void main() {
  test(
    'position revisions reject old info and restart with the full move history',
    () async {
      final session = BoardSession();
      final engine = FakeEngine();
      final analysis = AnalysisController(session, () async => engine);
      addTearDown(() {
        analysis.dispose();
        session.dispose();
      });
      await analysis.enable();
      final first = engine.requests.last.token;
      engine.emit(first, bound: 'lower');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(analysis.infos.single.score, 10);
      expect(analysis.scoreFor(analysis.infos.single, Side.black), -10);
      expect(analysis.boundFor(analysis.infos.single, Side.black), 'upper');
      session.tap(Square.parse('h2'));
      session.tap(Square.parse('e2'));
      engine.emit(first, score: 999);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(analysis.infos, isEmpty);
      expect(engine.requests.last.moves.map((m) => m.toString()), ['h2e2']);
      final second = engine.requests.last.token;
      expect(second, isNot(first));
      engine.emit(second, pv: 'b9c7');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(analysis.scoreFor(analysis.infos.single, Side.red), -10);
      await analysis.disable();
      engine.emit(second, score: 999);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(analysis.infos.single.score, 10);
      expect(engine.stops, greaterThan(0));
    },
  );
  test(
    'resource changes restart search and invalid settings do not reach the engine',
    () async {
      final session = BoardSession();
      final engine = FakeEngine();
      final analysis = AnalysisController(
        session,
        () async => engine,
        deviceThreads: 2,
      );
      addTearDown(() {
        analysis.dispose();
        session.dispose();
      });
      await analysis.enable();
      await analysis.configure(
        const AnalysisSettings(threads: 2, hashMb: 32, multiPv: 2),
      );
      expect(engine.requests.last.threads, 2);
      expect(engine.requests.last.multiPv, 2);
      await expectLater(
        analysis.configure(const AnalysisSettings(threads: 9)),
        throwsArgumentError,
      );
      expect(engine.requests.length, 2);
    },
  );
  test(
    'unavailable engine reports a recoverable state rather than fabricated output',
    () async {
      final session = BoardSession();
      final analysis = AnalysisController(session, null);
      addTearDown(() {
        analysis.dispose();
        session.dispose();
      });
      await analysis.enable();
      expect(analysis.enabled, isFalse);
      expect(analysis.error, isNotNull);
      expect(analysis.infos, isEmpty);
    },
  );
}
