import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/application/review_report.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';
import 'review_report_test.dart' as report;

class LateGrades extends MemoryPreferencesRepository {
  final gate = Completer<void>();
  @override
  Future<LoadedPreferences?> load() async {
    await gate.future;
    return super.load();
  }
}

void main() {
  test(
    'single assessment is identical to report for both sides; root and missing have no move',
    () {
      final run = report.sampleRun();
      for (final row in ReviewReport.fromRun(run).rows) {
        final single = ReviewReport.assess(run, row.nodeId)!;
        expect(single.grade, row.grade);
        expect(single.lossUnits, row.lossUnits);
        expect(single.beforeUnits, row.beforeUnits);
        expect(single.actualUnits, row.actualUnits);
        expect(single.source, row.source);
      }
      expect(ReviewReport.assess(run, 'n0'), isNull);
      expect(ReviewReport.assess(run, 'missing'), isNull);
      expect(ReviewReport.algorithmVersion, 'native-wdl-loss-v1');
    },
  );
  test(
    'coordinator projects current node only, caches, and rejects edits and reused IDs',
    () async {
      final session = BoardSession(), fake = FakeEngine();
      final engine = EngineSessionController(session, () async => fake);
      try {
        session.playMove(Move.parse('h2e2'));
        final job = engine.startReview(limits: ReviewLimits(depth: 2));
        var seen = 0;
        for (
          var i = 0;
          i < 100 && engine.review?.phase != ReviewPhase.completed;
          i++
        ) {
          if (fake.requests.length > seen) {
            seen = fake.requests.length;
            final r = fake.requests.last;
            fake.emit(
              r.token,
              pv: r.position.legalMoves.first.toString(),
              wdl: WdlEstimate(wins: 300, draws: 400, losses: 300),
            );
            await Future<void>.delayed(const Duration(milliseconds: 2));
            fake.results.last.complete(r.position.legalMoves.first);
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await job;
        expect(engine.currentMoveAssessment!.grade, MoveGrade.excellent);
        final cached = engine.currentMoveAssessment;
        session.flip();
        expect(engine.currentMoveAssessment, same(cached));
        session.first();
        expect(engine.currentMoveAssessment, isNull);
        session.navigate('n1');
        expect(engine.currentMoveAssessment!.lossUnits, cached!.lossUnits);
        session.playMove(session.position.legalMoves.first);
        expect(engine.review!.phase, ReviewPhase.stale);
        expect(engine.currentMoveAssessment, isNull);
        session.newGame();
        session.playMove(Move.parse('h2e2'));
        expect(engine.currentMoveAssessment, isNull);
      } finally {
        engine.dispose();
        session.dispose();
      }
    },
  );
  test(
    'optional flag is strict, preserves other prefs and merges a late load',
    () async {
      final old = AppPreferences().toJson();
      expect(old.containsKey('showMoveGrades'), isFalse);
      expect(AppPreferences.fromJson(old).showMoveGrades, isTrue);
      final off = AppPreferences(showMoveGrades: false);
      expect(AppPreferences.fromJson(off.toJson()), off);
      for (final bad in [null, 0, 'false', []]) {
        expect(
          () => AppPreferences.fromJson({...old, 'showMoveGrades': bad}),
          throwsFormatException,
        );
      }
      final session = BoardSession();
      final engine = EngineSessionController(session, null);
      final store = LateGrades()
        ..value = AppPreferences(
          pieceSizePercent: 150,
          showEvaluationBar: false,
        );
      final prefs = PreferencesController(engine, store);
      try {
        final load = prefs.initialize();
        final save = prefs.setMoveGrades(false);
        store.gate.complete();
        await load;
        await save;
        await prefs.flush();
        expect(prefs.value.showMoveGrades, isFalse);
        expect(prefs.value.pieceSizePercent, 150);
        expect(prefs.value.showEvaluationBar, isFalse);
        expect(store.value, prefs.value);
        expect(session.dirty, isFalse);
      } finally {
        prefs.dispose();
        engine.dispose();
        session.dispose();
      }
    },
  );
}
