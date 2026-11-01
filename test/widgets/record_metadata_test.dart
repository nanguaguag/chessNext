import 'package:chess_next/app.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/metadata/record_metadata_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  late BoardSession session;
  setUp(() {
    session = BoardSession();
  });
  tearDown(() {
    session.dispose();
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => RecordMetadataDialog(session: session),
              ),
              child: const Text('资料'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('资料'));
    await tester.pumpAndSettle();
  }

  Future<void> text(WidgetTester tester, String key, String value) async {
    final target = find.byKey(ValueKey('metadata-$key'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.enterText(target, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'apply preserves unknown fields and navigation while cancel and no-op stay clean',
    (tester) async {
      session.replaceTree(
        GameTree().play(Move.parse('h2e2')),
        metadata: GameMetadata({'Red': '原棋手', 'Custom': '保留😀'}),
      );
      var revision = session.revision;
      await open(tester);
      await text(tester, 'Red', '取消的改动');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(session.metadata.tags['Red'], '原棋手');
      expect(session.revision, revision);
      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用资料'));
      await tester.pumpAndSettle();
      expect(session.revision, revision);
      expect(session.dirty, isFalse);
      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();
      await text(tester, 'Event', '自制赛');
      session.first();
      final positionRevision = session.positionRevision;
      await tester.tap(find.text('应用资料'));
      await tester.pumpAndSettle();
      expect(session.metadata.tags, {
        'Red': '原棋手',
        'Custom': '保留😀',
        'Event': '自制赛',
      });
      expect(session.tree.cursorId, 'n0');
      expect(session.positionRevision, positionRevision);
      expect(session.revision, revision + 1);
      expect(session.dirty, isTrue);
    },
  );
  testWidgets('stale form cannot overwrite another document or newer content', (
    tester,
  ) async {
    await open(tester);
    await text(tester, 'Red', '旧表单');
    session.newGame();
    session.updateMetadata(GameMetadata({'Red': '新文档'}));
    await tester.tap(find.text('应用资料'));
    await tester.pumpAndSettle();
    expect(find.text('棋谱内容已变化，请关闭资料窗口后重新打开。'), findsOneWidget);
    expect(session.metadata.tags['Red'], '新文档');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('资料'));
    await tester.pumpAndSettle();
    session.annotate('新注释');
    await text(tester, 'Event', '过期资料');
    await tester.tap(find.text('应用资料'));
    await tester.pumpAndSettle();
    expect(session.metadata.tags.containsKey('Event'), isFalse);
    expect(session.tree.root.comment, '新注释');
  });
  testWidgets(
    'large text supports result declaration and readonly extra data',
    (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      session.replaceTree(
        GameTree(),
        metadata: GameMetadata({'Custom': '原始字段'}),
      );
      await open(tester);
      final extras = find.text('查看其它资料（1项）');
      await tester.ensureVisible(extras);
      await tester.pumpAndSettle();
      await tester.tap(extras);
      await tester.pumpAndSettle();
      expect(find.text('原始字段'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      final result = find.byKey(const ValueKey('metadata-Result'));
      await tester.ensureVisible(result);
      await tester.pumpAndSettle();
      await tester.tap(result);
      await tester.pumpAndSettle();
      await tester.tap(find.text('黑方胜').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用资料'));
      await tester.pumpAndSettle();
      expect(session.metadata.result, '0-1');
      expect(session.outcome.isTerminal, isFalse);
      expect(session.metadata.tags['Custom'], '原始字段');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('clearing the last data item still protects the unsaved change', (
    tester,
  ) async {
    await tester.pumpWidget(const ChessNextApp());
    await tester.pumpAndSettle();
    final appSession = tester
        .widget<XiangqiBoard>(find.byType(XiangqiBoard))
        .session;
    appSession.replaceTree(
      GameTree(),
      metadata: GameMetadata({'Event': '要清除'}),
    );
    await tester.pumpAndSettle();
    final entry = find.widgetWithText(OutlinedButton, '棋谱资料');
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await text(tester, 'Event', '');
    await tester.tap(find.text('应用资料'));
    await tester.pumpAndSettle();
    expect(appSession.metadata.isEmpty, isTrue);
    expect(appSession.hasContent, isFalse);
    expect(appSession.dirty, isTrue);
    await tester.ensureVisible(find.text('新局'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新局'));
    await tester.pumpAndSettle();
    expect(find.text('开始新局？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(appSession.dirty, isTrue);
    expect(tester.takeException(), isNull);
  });
}
