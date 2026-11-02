import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_evaluation.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class DelayedBarPreferences extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  final ongoing = Position.initial().boardOutcome();
  EngineInfo info({
    int score = 72,
    bool mate = false,
    String? bound,
    WdlEstimate? wdl,
    int pv = 1,
  }) => EngineInfo(
    token: 1,
    depth: 10,
    multiPv: pv,
    score: score,
    isMate: mate,
    pv: const [],
    bound: bound,
    wdl: wdl,
  );
  test(
    'WDL expected score normalizes moving side to red and can retain a stopped snapshot',
    () {
      final value = info(wdl: WdlEstimate(wins: 274, draws: 724, losses: 2));
      final red = BoardEvaluation.fromInfo(
        turn: Side.red,
        outcome: ongoing,
        info: value,
      );
      final black = BoardEvaluation.fromInfo(
        turn: Side.black,
        outcome: ongoing,
        info: value,
        frozen: true,
      );
      expect(red.kind, EvaluationKind.model);
      expect(red.redUnits, 1272);
      expect(red.redRatio, .636);
      expect(red.description, contains('63.6%'));
      expect(red.description, contains('不是实战胜率'));
      expect(black.redUnits, 728);
      expect(black.description, contains('保留的当前局面结果'));
      expect(
        BoardEvaluation.fromInfo(
          turn: Side.red,
          outcome: ongoing,
          info: info(wdl: WdlEstimate(wins: 0, draws: 1000, losses: 0)),
        ).redRatio,
        .5,
      );
    },
  );
  test(
    'missing WDL, CP zero, non-primary PV and bounds never become a made-up half bar',
    () {
      final wdl = WdlEstimate(wins: 500, draws: 500, losses: 0);
      for (final value in [null, info(score: 0), info(pv: 2, wdl: wdl)]) {
        final summary = BoardEvaluation.fromInfo(
          turn: Side.red,
          outcome: ongoing,
          info: value,
        );
        expect(summary.kind, EvaluationKind.unavailable);
        expect(summary.redRatio, isNull);
      }
      for (final bound in ['lower', 'upper']) {
        final summary = BoardEvaluation.fromInfo(
          turn: Side.red,
          outcome: ongoing,
          info: info(bound: bound, wdl: wdl),
        );
        expect(summary.kind, EvaluationKind.bound);
        expect(summary.redRatio, isNull);
      }
    },
  );
  test(
    'mate forecasts including zero remain separate from model proportions',
    () {
      for (final (turn, score, label) in [
        (Side.red, 3, '红方3步杀'),
        (Side.red, -3, '黑方3步杀'),
        (Side.black, 2, '黑方2步杀'),
      ]) {
        final summary = BoardEvaluation.fromInfo(
          turn: turn,
          outcome: ongoing,
          info: info(mate: true, score: score),
        );
        expect(summary.kind, EvaluationKind.mate);
        expect(summary.redRatio, isNull);
        expect(summary.description, contains(label));
      }
      final zero = BoardEvaluation.fromInfo(
        turn: Side.red,
        outcome: ongoing,
        info: info(mate: true, score: 0),
      );
      expect(zero.redRatio, isNull);
      expect(zero.description, contains('未由此判定胜方'));
    },
  );
  test(
    'optional bar setting defaults old files on and late reads preserve user choice',
    () async {
      final old = AppPreferences().toJson();
      expect(old.containsKey('showEvaluationBar'), isFalse);
      expect(AppPreferences.fromJson(old).showEvaluationBar, isTrue);
      for (final bad in [null, 'true', 0]) {
        expect(
          () => AppPreferences.fromJson({...old, 'showEvaluationBar': bad}),
          throwsFormatException,
        );
      }
      final session = BoardSession(), store = DelayedBarPreferences();
      final engine = EngineSessionController(session, null);
      final prefs = PreferencesController(engine, store);
      store.value = AppPreferences(
        pieceSizePercent: 125,
        showVariationArrows: false,
      );
      try {
        final reading = prefs.initialize();
        final change = prefs.setEvaluationBar(false);
        store.gate.complete();
        await reading;
        await change;
        await prefs.flush();
        expect(prefs.value.showEvaluationBar, isFalse);
        expect(prefs.value.pieceSizePercent, 125);
        expect(prefs.value.showVariationArrows, isFalse);
        expect(AppPreferences.fromJson(store.value!.toJson()), store.value);
      } finally {
        prefs.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
  test(
    'actual mate and stalemate outcomes take precedence over any engine forecast',
    () {
      for (final (fen, winner, label) in [
        ('4k4/9/9/9/4p4/9/9/9/3rrp3/4K4 w - - 0 1', Side.black, '将死'),
        ('4k4/9/9/9/4p4/9/9/9/3r1r3/4K4 w - - 0 1', Side.black, '困毙'),
        ('4k4/3R1R3/9/9/9/4P4/9/9/9/4K4 b - - 0 1', Side.red, '困毙'),
      ]) {
        final position = Position.fromFen(fen);
        final summary = BoardEvaluation.fromInfo(
          turn: position.turn,
          outcome: position.boardOutcome(),
          info: info(mate: true, score: 7),
        );
        expect(summary.kind, EvaluationKind.terminal);
        expect(summary.redUnits, winner == Side.red ? 2000 : 0);
        expect(summary.description, contains('已获胜'));
        expect(summary.description, contains(label));
      }
    },
  );
}
