import 'package:chess_next/app.dart';
import 'package:chess_next/chess_next.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/editor/editor_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1120, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'invalid completion stays in editor and cancellation preserves original tree',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      final original = session.tree.toJson();
      await tester.tap(find.text('编辑局面'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清空'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('square-d9')));
      await tester.tap(find.byKey(const ValueKey('square-e9')));
      await tester.pump();
      expect(find.textContaining('帅将照面'), findsOneWidget);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorPage), findsOneWidget);
      expect(session.tree.toJson(), original);
      await tester.tap(find.byTooltip('取消编辑'));
      await tester.pumpAndSettle();
      expect(session.tree.toJson(), original);
      expect(session.dirty, isFalse);
    },
  );
  testWidgets(
    'valid edited setup becomes a dirty new root with the chosen turn',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      await tester.tap(find.text('编辑局面'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('黑先'));
      await tester.tap(find.text('清空'));
      await tester.pump();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(session.position.turn, Side.black);
      expect(session.position.at(Square.parse('d9'))?.type, PieceType.general);
      expect(session.dirty, isTrue);
      expect(session.hasContent, isTrue);
      expect(session.tree.nodeCount, 1);
    },
  );
  testWidgets('piece-box drag and secondary click edit the raw board', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(
      MaterialApp(home: EditorPage(initial: Position.initial())),
    );
    await tester.tap(find.text('清空'));
    await tester.pump();
    final from = tester.getCenter(
      find.byKey(const ValueKey('palette-red-pawn')),
    );
    final to = tester.getCenter(find.byKey(const ValueKey('square-a3')));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BoardSurface>(find.byType(BoardSurface))
          .at(Square.parse('a3'))
          ?.type,
      PieceType.pawn,
    );
    await tester.tap(
      find.byKey(const ValueKey('square-a3')),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(
      tester
          .widget<BoardSurface>(find.byType(BoardSurface))
          .at(Square.parse('a3')),
      isNull,
    );
    final before = tester
        .widget<BoardSurface>(find.byType(BoardSurface))
        .at(Square.parse('d9'));
    await tester.tap(find.text('左右翻转'));
    await tester.tap(find.text('旋转棋盘'));
    await tester.pump();
    final surface = tester.widget<BoardSurface>(find.byType(BoardSurface));
    expect(surface.mirrored, isTrue);
    expect(surface.flipped, isTrue);
    expect(surface.at(Square.parse('d9')), before);
  });
  testWidgets(
    'editing a dirty record prompts first and cancelling leaves all moves',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      await tester.tap(find.byKey(const ValueKey('square-h2')));
      await tester.tap(find.byKey(const ValueKey('square-e2')));
      await tester.pump();
      await tester.tap(find.text('编辑局面'));
      await tester.pumpAndSettle();
      expect(find.text('编辑前保留当前棋谱？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('1. h2e2'), findsOneWidget);
      await tester.tap(find.text('编辑局面'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('取消编辑'));
      await tester.pumpAndSettle();
      expect(find.text('1. h2e2'), findsOneWidget);
    },
  );
  testWidgets(
    'palette enforces quantities and keeps selection for repeated placement',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(
        MaterialApp(home: EditorPage(initial: Position.initial())),
      );
      final general = find.byKey(const ValueKey('palette-red-general'));
      expect(tester.widget<ChoiceChip>(general).onSelected, isNull);
      await tester.tap(find.text('清空'));
      await tester.pump();
      final pawn = find.byKey(const ValueKey('palette-red-pawn'));
      await tester.tap(pawn);
      for (final square in ['a3', 'c3', 'e3', 'g3', 'i3']) {
        await tester.tap(find.byKey(ValueKey('square-$square')));
        await tester.pump();
      }
      expect(tester.widget<ChoiceChip>(pawn).onSelected, isNull);
      final board = tester.widget<BoardSurface>(find.byType(BoardSurface));
      for (final square in ['a3', 'c3', 'e3', 'g3', 'i3']) {
        expect(board.at(Square.parse(square))?.type, PieceType.pawn);
      }
      await tester.tap(find.byKey(const ValueKey('square-e0')));
      await tester.pump();
      // Even an exhausted box can remove a selected board piece.
      await tester.tap(general);
      await tester.pump();
      expect(
        tester
            .widget<BoardSurface>(find.byType(BoardSurface))
            .at(Square.parse('e0')),
        isNull,
      );
      expect(tester.widget<ChoiceChip>(general).onSelected, isNotNull);
    },
  );
}
