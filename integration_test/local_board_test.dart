import 'package:chess_next/features/editor/editor_page.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/features/play/play_panel.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/adapters/engine/bundled_engine.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chess_next/adapters/storage/file_game_repository.dart';
import 'package:chess_next/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('macOS local board supports a full interactive move cycle', (
    tester,
  ) async {
    await tester.pumpWidget(const ChessNextApp());
    await tester.pumpAndSettle();
    expect(find.text('红方行棋'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    expect(find.text('黑方行棋'), findsOneWidget);
    expect(find.text('1. h2e2'), findsOneWidget);
    await tester.tap(find.text('翻转'));
    await tester.pumpAndSettle();
    expect(find.text('黑方行棋'), findsOneWidget);
    await tester.tap(find.text('悔棋'));
    await tester.pumpAndSettle();
    expect(find.text('红方行棋'), findsOneWidget);
    expect(find.text('1. h2e2'), findsNothing);
    // After flip h2/e2 are still addressed by board coordinates, not pixels.
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('1. h2e2'), findsOneWidget);
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '开始新局'));
    await tester.pumpAndSettle();
    expect(find.text('红方行棋'), findsOneWidget);
    expect(find.text('1. h2e2'), findsNothing);
    await tester.tap(find.byTooltip('切换明暗主题'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'macOS sandbox saves records and a fresh app instance reopens them',
    (tester) async {
      final documents = await getApplicationDocumentsDirectory();
      final temp = await documents.createTemp('.chessnext-integration-');
      try {
        await tester.pumpWidget(
          ChessNextApp(repository: FileGameRepository(() async => temp)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('square-h2')));
        await tester.tap(find.byKey(const ValueKey('square-e2')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('保存棋谱'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('record-name')),
          '原生磁盘恢复测试',
        );
        await tester.tap(find.widgetWithText(FilledButton, '保存'));
        for (
          var i = 0;
          i < 50 && find.text('已保存到本地 · 原生磁盘恢复测试').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('已保存到本地 · 原生磁盘恢复测试'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          ChessNextApp(repository: FileGameRepository(() async => temp)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('棋谱库'));
        for (
          var i = 0;
          i < 50 && find.text('原生磁盘恢复测试').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.text('原生磁盘恢复测试'));
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 50 && find.text('1. h2e2').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('1. h2e2'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await temp.delete(recursive: true);
      }
    },
  );
  testWidgets('bundled Pikafish analyzes offline, switches MultiPV and stops', (
    tester,
  ) async {
    await tester.pumpWidget(ChessNextApp(engineFactory: openBundledEngine));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('开始分析'));
    await tester.tap(find.text('开始分析'));
    for (
      var i = 0;
      i < 100 && find.textContaining('红分').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('红分'), findsWidgets);
    expect(
      tester.widget<XiangqiBoard>(find.byType(XiangqiBoard)).recommendation,
      isNotNull,
    );
    await tester.ensureVisible(find.byTooltip('引擎参数'));
    await tester.tap(find.byTooltip('引擎参数'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '同时分析变化数'), '2');
    await tester.tap(find.widgetWithText(FilledButton, '应用'));
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 100 && find.byKey(const ValueKey('pv-2')).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('pv-2')), findsOneWidget);
    await tester.ensureVisible(find.text('停止分析'));
    await tester.tap(find.text('停止分析'));
    await tester.pumpAndSettle();
    expect(find.text('分析已停止'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets('bundled AI replies, changes its move and undoes both plies', (
    tester,
  ) async {
    await tester.pumpWidget(ChessNextApp(engineFactory: openBundledEngine));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('引擎执黑'));
    await tester.tap(find.text('引擎执黑'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('square-h2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    final session = tester
        .widget<XiangqiBoard>(find.byType(XiangqiBoard))
        .session;
    for (var i = 0; i < 100 && session.moves.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(session.moves.length, 2);
    final old = session.moves.last;
    await tester.ensureVisible(find.text('变招'));
    await tester.tap(find.text('变招'));
    for (
      var i = 0;
      i < 100 && (session.moves.length < 2 || session.moves.last == old);
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(session.moves.length, 2);
    expect(session.moves.last, isNot(old));
    expect(session.tree.node('n1').children.length, 2);
    await tester.ensureVisible(find.text('悔棋'));
    await tester.tap(find.text('悔棋'));
    await tester.pumpAndSettle();
    expect(session.moves, isEmpty);
    await tester.ensureVisible(find.text('引擎执红'));
    await tester.tap(find.text('引擎执红'));
    await tester.pump();
    await tester.ensureVisible(find.text('停止对弈'));
    await tester.tap(find.text('停止对弈'));
    await tester.pumpAndSettle();
    final engine = tester.widget<PlayPanel>(find.byType(PlayPanel)).engine;
    expect(engine.aiSides, isEmpty);
    expect(session.inputLocked, isFalse);
  });
  testWidgets(
    'native editor rejects facing generals and applies a valid chosen turn',
    (tester) async {
      await tester.pumpWidget(const ChessNextApp());
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final before = session.tree.toJson();
      await tester.ensureVisible(find.text('编辑局面'));
      await tester.tap(find.text('编辑局面'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清空'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('square-d9')));
      await tester.tap(find.byKey(const ValueKey('square-e9')));
      await tester.pump();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsOneWidget);
      expect(session.tree.toJson(), before);
      await tester.tap(find.text('清空'));
      await tester.tap(find.text('黑先'));
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsNothing);
      expect(session.position.turn, Side.black);
      expect(session.position.validateForPlay().isValid, isTrue);
      expect(session.dirty, isTrue);
    },
  );
}
