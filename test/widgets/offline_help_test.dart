import 'package:chess_next/app.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/help/offline_help_dialog.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../support/fake_engine.dart';

class CountingGames extends MemoryGameRepository {
  int calls = 0;
  @override
  Future<void> save(SavedGame game) async {
    calls++;
    await super.save(game);
  }

  @override
  Future<SavedGame> load(String id) async {
    calls++;
    return super.load(id);
  }

  @override
  Future<LibrarySnapshot> list() async {
    calls++;
    return super.list();
  }
}

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const OfflineHelpDialog(),
              ),
              child: const Text('帮助'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('帮助'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'searches original title and body, ignores case and clears empty results',
    (tester) async {
      await open(tester);
      final search = find.byKey(const ValueKey('help-search'));
      await tester.enterText(search, 'pIkAfIsH');
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('当前局面分析与胜和负'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.enterText(search, '不存在的功能12345');
      await tester.pumpAndSettle();
      expect(find.text('未找到匹配的帮助，请换个关键词。'), findsOneWidget);
      await tester.tap(find.byTooltip('清空帮助搜索'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.text('走棋与读谱'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'expand and dismiss via Escape leaves app, document and engine untouched',
    (tester) async {
      var factories = 0;
      final games = CountingGames();
      await tester.pumpWidget(
        ChessNextApp(
          repository: games,
          engineFactory: () async {
            factories++;
            return FakeEngine();
          },
        ),
      );
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      session.playMove(Move.parse('h2e2'));
      final tree = session.tree;
      final revision = session.revision;
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('帮助与按钮说明'));
      await tester.pumpAndSettle();
      expect(find.byType(OfflineHelpDialog), findsOneWidget);
      await tester.tap(find.text('走棋与读谱'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineHelpDialog), findsNothing);
      expect(session.tree, same(tree));
      expect(session.revision, revision);
      expect(session.dirty, isTrue);
      expect(factories, 0);
      expect(games.calls, 0);
      await tester.tap(find.byTooltip('帮助与按钮说明'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(session.tree, same(tree));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    '200 percent text keeps search and expanded long help scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tester.enterText(find.byKey(const ValueKey('help-search')), '最近阅读');
      await tester.pumpAndSettle();
      expect(find.text('保存、草稿与最近阅读'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(OfflineHelpDialog), findsNothing);
    },
  );
}
