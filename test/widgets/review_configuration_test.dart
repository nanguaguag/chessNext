import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_models.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/review/review_options_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';
import '../application/review_cache_test.dart' show VerifiedFake;
import '../support/pump_until.dart';

class ModeStore extends MemoryPreferencesRepository {
  bool fail = false;
  @override
  Future<void> save(AppPreferences value) async {
    if (fail) throw StateError('disk');
    return super.save(value);
  }
}

void main() {
  void desktop(WidgetTester t) {
    t.view.physicalSize = const Size(1120, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Finder inside(Finder f) =>
      find.descendant(of: find.byType(ReviewOptionsDialog), matching: f);
  Finder skip() => inside(find.widgetWithText(SwitchListTile, '跳过已分析的局面'));
  Future<void> choose(WidgetTester t, String label) async {
    await tap(t, inside(find.byType(DropdownButtonFormField<ReviewMode>)));
    await tap(t, find.text(label).last);
  }

  testWidgets(
    'cancel preserves mode, failed save retries and restart restores without automatic jobs',
    (t) async {
      desktop(t);
      final store = ModeStore(), fake = FakeEngine();
      Widget app() => ChessNextApp(
        key: UniqueKey(),
        preferencesRepository: store,
        engineFactory: () async => fake,
      );
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      final engine = t
          .widget<AnalysisPanel>(find.byType(AnalysisPanel))
          .analysis;
      final session = engine.session, tree = engine.session.tree;
      await tap(t, find.text('开始分析'));
      await pumpUntil(t, () => fake.requests.isNotEmpty);
      final count = fake.requests.length, stops = fake.stops;
      await tap(t, find.text('分析整盘棋'));
      expect(t.widget<SwitchListTile>(skip()).value, isTrue);
      store.fail = true;
      await choose(t, '多候选');
      expect(inside(find.textContaining('设置保存失败')), findsOneWidget);
      expect(fake.requests.length, count);
      expect(fake.stops, stops);
      await tap(t, inside(find.text('取消')));
      await tap(t, find.text('分析整盘棋'));
      expect(
        t
            .widget<DropdownButtonFormField<ReviewMode>>(
              inside(find.byType(DropdownButtonFormField<ReviewMode>)),
            )
            .initialValue,
        ReviewMode.candidates,
      );
      expect(inside(find.text('每个候选用时（秒）')), findsOneWidget);
      store.fail = false;
      await tap(t, inside(find.text('重试保存分析方式')));
      expect(store.value!.reviewMode, ReviewMode.candidates);
      await tap(t, inside(find.text('取消')));
      expect(session.tree, same(tree));
      expect(session.dirty, isFalse);
      expect(fake.requests.length, count);
      expect(fake.stops, stops);
      await engine.disable();
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await tap(t, find.text('分析整盘棋'));
      expect(
        t
            .widget<DropdownButtonFormField<ReviewMode>>(
              inside(find.byType(DropdownButtonFormField<ReviewMode>)),
            )
            .initialValue,
        ReviewMode.candidates,
      );
      expect(fake.requests.length, count);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(ReviewOptionsDialog), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'reanalysis resets skip to false each open; explicit cache reuse still works',
    (t) async {
      desktop(t);
      final fake = VerifiedFake();
      await t.pumpWidget(ChessNextApp(engineFactory: () async => fake));
      await t.pumpAndSettle();
      final engine = t
          .widget<AnalysisPanel>(find.byType(AnalysisPanel))
          .analysis;
      final job = engine.startReview(
        limits: ReviewLimits(depth: 2, moveTimeMs: null),
      );
      await pumpUntil(t, () => fake.requests.isNotEmpty);
      final request = fake.requests.last;
      fake.emit(
        request.token,
        pv: request.position.legalMoves.first.toString(),
      );
      await t.pump();
      fake.results.last.complete(request.position.legalMoves.first);
      await pumpUntil(t, () => engine.review?.phase == ReviewPhase.completed);
      await job;
      await t.pumpAndSettle();
      final count = fake.requests.length;
      Future<void> open() async {
        await tap(t, find.text('分析整盘棋'));
        expect(t.widget<SwitchListTile>(skip()).value, isFalse);
      }

      await open();
      await tap(t, skip());
      await tap(t, inside(find.text('取消')));
      await open();
      await tap(t, skip());
      Finder field(String label) => inside(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        ),
      );
      await t.ensureVisible(field('每局面用时（秒）'));
      await t.enterText(field('每局面用时（秒）'), '0');
      await t.pumpAndSettle();
      await t.ensureVisible(field('每局面深度'));
      await t.enterText(field('每局面深度'), '2');
      await t.pumpAndSettle();
      await tap(t, inside(find.text('开始整谱分析')));
      await pumpUntil(t, () => engine.review?.phase == ReviewPhase.completed);
      expect(engine.review!.cachedCount, 1);
      expect(fake.requests.length, count);
      await open();
      await t.ensureVisible(field('每局面用时（秒）'));
      await t.enterText(field('每局面用时（秒）'), '0');
      await t.pumpAndSettle();
      await t.ensureVisible(field('每局面深度'));
      await t.enterText(field('每局面深度'), '2');
      await t.pumpAndSettle();
      await tap(t, inside(find.text('开始整谱分析')));
      await pumpUntil(t, () => fake.requests.length == count + 1);
      expect(engine.reviewing, isTrue);
      await engine.cancelReview();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    '200 percent narrow configuration switches mode, scrolls fields and cancels',
    (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ReviewOptionsDialog(
                    threads: 1,
                    hashMb: 16,
                    initialSkipExisting: false,
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tap(t, find.text('打开'));
      await choose(t, '多候选');
      await t.ensureVisible(inside(find.text('每局面最多候选数')));
      await t.pumpAndSettle();
      await t.ensureVisible(skip());
      await t.pumpAndSettle();
      expect(t.widget<SwitchListTile>(skip()).value, isFalse);
      await tap(t, inside(find.text('取消')));
      expect(t.takeException(), isNull);
    },
  );
}
