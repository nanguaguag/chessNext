import 'package:chess_next/app.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/records/move_list.dart';
import 'package:chess_next/features/analysis/analysis_panel.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/ports/text_clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/branched_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('playback interval choices persist from settings', (
    tester,
  ) async {
    desktop(tester);
    final store = MemoryPreferencesRepository();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('棋谱与操作'));
    await tap(tester, find.text('0.5秒'));
    expect(store.value?.recordPlaybackIntervalMs, 500);
    await tap(tester, find.text('关闭'));
  });

  testWidgets('custom playback interval reaches 0.1 and 60 seconds', (
    tester,
  ) async {
    desktop(tester);
    final store = MemoryPreferencesRepository();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('棋谱与操作'));

    final sliderFinder = find.byKey(const ValueKey('record-playback-interval'));
    var slider = tester.widget<Slider>(sliderFinder);
    expect(slider.min, 0);
    expect(slider.max, 120);
    expect(slider.divisions, 120);
    expect(slider.value, 4);
    expect(find.text('自定义范围0.1–60秒；最低0.1秒，其后每步0.5秒。'), findsOneWidget);

    await tester.drag(sliderFinder, const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(store.value?.recordPlaybackIntervalMs, 100);
    slider = tester.widget<Slider>(sliderFinder);
    expect(slider.value, 0);
    expect(slider.semanticFormatterCallback!(0), '0.1秒');

    await tester.drag(sliderFinder, const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(store.value?.recordPlaybackIntervalMs, 60000);
    slider = tester.widget<Slider>(sliderFinder);
    expect(slider.value, 120);
    expect(slider.semanticFormatterCallback!(120), '60秒');
    await tap(tester, find.text('关闭'));
  });

  testWidgets('move list and playback button visibility persist and apply', (
    tester,
  ) async {
    desktop(tester);
    final store = MemoryPreferencesRepository();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('应用设置'));
    await tap(tester, find.text('棋谱与操作'));
    await tap(tester, find.text('显示棋谱栏'));
    expect(find.byType(MoveList), findsNothing);
    expect(store.value?.showMoveList, isFalse);

    await tap(tester, find.text('显示播放按钮'));
    expect(find.byTooltip('播放棋谱'), findsNothing);
    expect(store.value?.showRecordPlaybackButton, isFalse);
    await tap(tester, find.text('显示面板切换栏'));
    await tap(tester, find.text('关闭'));
    await tap(tester, find.text('取消'));
    expect(find.byType(SegmentedButton<SidePanel>), findsOneWidget);
    expect(find.byType(PlayPanel), findsOneWidget);
    expect(find.byType(AnalysisPanel), findsNothing);
    await tap(tester, find.text('分析'));
    expect(store.value?.activeSidePanel, SidePanel.analysis);
    expect(find.byType(AnalysisPanel), findsOneWidget);
    expect(find.byType(PlayPanel), findsNothing);
  });

  testWidgets(
    'playback follows the current line, pauses, and never dirties the record',
    (tester) async {
      desktop(tester);
      final store = MemoryPreferencesRepository()
        ..value = AppPreferences(recordPlaybackIntervalMs: 500);
      await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
      await tester.pumpAndSettle();

      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.replaceTree(branchedRecord());
      session.first();
      await tester.pumpAndSettle();
      final rootId = session.tree.root.id;
      final contentRevision = session.revision;
      expect(session.nextNodeId, isNotNull);
      final playbackButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('播放棋谱'),
          matching: find.byType(IconButton),
        ),
      );
      expect(playbackButton.onPressed, isNotNull);

      await tester.tap(find.byTooltip('播放棋谱'));
      await tester.pump();
      expect(
        find.byTooltip('暂停播放'),
        findsOneWidget,
        reason: 'playback button did not enter playing state',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(session.tree.cursorId, isNot(rootId));
      expect(session.revision, contentRevision);

      await tester.tap(find.byTooltip('暂停播放'));
      await tester.pump();
      final pausedAt = session.tree.cursorId;
      await tester.pump(const Duration(seconds: 2));
      expect(session.tree.cursorId, pausedAt);
      expect(find.byTooltip('播放棋谱'), findsOneWidget);

      await tester.tap(find.byTooltip('播放棋谱'));
      await tester.pump();
      for (
        var i = 0;
        i < 5 && find.byTooltip('暂停播放').evaluate().isNotEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }
      expect(session.tree.cursorId, session.tree.currentLine.last.id);
      expect(find.byTooltip('播放棋谱'), findsOneWidget);
      expect(session.revision, contentRevision);
      expect(session.dirty, isFalse);
    },
  );

  testWidgets('board long press runs configured copy FEN action', (
    tester,
  ) async {
    desktop(tester);
    final store = MemoryPreferencesRepository()
      ..value = AppPreferences(
        boardContextActions: const [BoardContextAction.copyFen],
      );
    final clipboard = _FakeClipboard();
    await tester.pumpWidget(
      ChessNextApp(preferencesRepository: store, clipboard: clipboard),
    );
    await tester.pumpAndSettle();
    final board = find.byType(XiangqiBoard);
    await tester.longPressAt(tester.getCenter(board));
    await tester.pumpAndSettle();
    expect(find.text('复制当前局面（FEN）'), findsOneWidget);
    await tester.tap(find.text('复制当前局面（FEN）'));
    await tester.pumpAndSettle();
    final session = tester.widget<XiangqiBoard>(board).session;
    expect(clipboard.value, session.position.toFen());
  });
}

class _FakeClipboard implements TextClipboard {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String text) async => value = text;
}
