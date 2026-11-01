import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/library_controller.dart';
import 'package:chess_next/application/recent_reading_controller.dart';
import 'package:chess_next/features/library/recent_reading_dialog.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:chess_next/ports/recent_reading_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class FailHistory extends MemoryRecentReadingRepository {
  bool fail = false;
  @override
  Future<LoadedRecentReadings> load() async {
    if (fail) throw StateError('bad file');
    return super.load();
  }
}

void main() {
  late BoardSession session;
  late LibraryController library;
  late FailHistory repository;
  late RecentReadingController history;
  setUp(() {
    session = BoardSession();
    library = LibraryController(session, MemoryGameRepository());
    repository = FailHistory();
    history = RecentReadingController(
      library,
      repository,
      debounce: const Duration(days: 1),
    );
  });
  tearDown(() {
    history.dispose();
    library.dispose();
    session.dispose();
  });
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => RecentReadingDialog(readings: history),
              ),
              child: const Text('打开历史'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开历史'));
    await tester.pumpAndSettle();
  }

  Future<void> saved() async {
    await history.initialize();
    session.playMove(Move.parse('h2e2'));
    session.playMove(Move.parse('b9c7'));
    await library.save('练习谱');
    session.first();
    await history.flush();
    library.newGame();
  }

  testWidgets(
    'empty and failed history has explicit retry without overwriting originals',
    (tester) async {
      repository.fail = true;
      await history.initialize();
      await show(tester);
      expect(find.textContaining('原文件已保留'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('重试阅读历史'));
      await tester.pumpAndSettle();
      expect(find.text('还没有本地阅读记录'), findsOneWidget);
      expect(history.canWrite, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dirty cancellation preserves current tree then confirmed open restores cursor',
    (tester) async {
      await saved();
      session.playMove(Move.parse('b2e2'));
      final revision = session.revision;
      await show(tester);
      await tester.tap(find.text('练习谱'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(session.revision, revision);
      expect(session.tree.current.move, Move.parse('b2e2'));
      await tester.tap(find.text('练习谱'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('放弃修改并打开'));
      await tester.pumpAndSettle();
      expect(session.tree.cursorId, 'n0');
      expect(session.tree.nodeCount, 3);
      expect(session.dirty, isFalse);
      expect(find.text('最近阅读'), findsNothing);
      await history.flush();
    },
  );
  testWidgets(
    'edits while confirmation is open cannot be discarded by stale approval',
    (tester) async {
      await saved();
      session.playMove(Move.parse('b2e2'));
      await show(tester);
      await tester.tap(find.text('练习谱'));
      await tester.pumpAndSettle();
      session.annotate('确认期间新编辑');
      await tester.tap(find.text('放弃修改并打开'));
      await tester.pumpAndSettle();
      expect(session.tree.current.comment, '确认期间新编辑');
      expect(find.text('确认期间棋谱已变化，请重新打开。'), findsOneWidget);
      expect(find.text('最近阅读'), findsOneWidget);
    },
  );
  testWidgets(
    '200 percent text keeps history list scrollable and missing records readable',
    (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      repository.entries = List.generate(
        50,
        (i) => RecentReading.capture(
          'g$i',
          '本地长名称$i',
          GameTree(),
          DateTime.utc(2026),
        ),
      );
      await history.initialize();
      await show(tester);
      expect(find.byType(ListTile).evaluate().length, lessThan(12));
      await tester.tap(find.text('本地长名称0'));
      await tester.pumpAndSettle();
      expect(find.text('棋谱不存在'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
    },
  );
}
