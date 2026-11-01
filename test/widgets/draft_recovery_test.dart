import 'dart:ui' show AppExitResponse;
import 'package:chess_next/app.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/drafts/draft_status_bar.dart';
import 'package:chess_next/ports/draft_repository.dart';
import 'package:chess_next/ports/game_repository.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingDrafts extends MemoryDraftRepository {
  @override
  Future<void> save(SavedGame value) async => throw StateError('disk full');
}

void main() {
  testWidgets(
    'recovery protects current edits and restores a dirty copy with comments',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryDraftRepository()
        ..draft = SavedGame(
          id: 'active',
          title: 'test',
          tree: GameTree().play(Move.parse('b2e2')).annotate('draft note'),
          modifiedAt: DateTime(2026),
        );
      await tester.pumpWidget(ChessNextApp(draftRepository: repository));
      await tester.pumpAndSettle();
      expect(find.text('恢复草稿'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('square-h2')));
      await tester.tap(find.byKey(const ValueKey('square-e2')));
      await tester.pump();
      await tester.tap(find.text('恢复草稿'));
      await tester.pumpAndSettle();
      expect(find.text('用草稿替换当前棋谱？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      expect(session.moves.single.toString(), 'h2e2');
      await tester.tap(find.text('恢复草稿'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('恢复'));
      await tester.pumpAndSettle();
      expect(session.moves.single.toString(), 'b2e2');
      expect(session.dirty, isTrue);
      expect(session.tree.current.comment, 'draft note');
      session.annotate('new note');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('自动草稿已更新'), findsOneWidget);
      expect(repository.draft!.tree.current.comment, 'new note');
      expect(
        tester.widget<DraftStatusBar>(find.byType(DraftStatusBar)).drafts.error,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'normal exit warns if the latest dirty draft could not be persisted',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ChessNextApp(draftRepository: FailingDrafts()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('square-h2')));
      await tester.tap(find.byKey(const ValueKey('square-e2')));
      await tester.pump();
      final observer =
          tester.state(find.byType(ChessNextApp)) as WidgetsBindingObserver;
      final requested = observer.didRequestAppExit();
      await tester.pumpAndSettle();
      expect(find.text('当前修改尚未安全保存'), findsOneWidget);
      await tester.tap(find.text('返回应用'));
      await tester.pumpAndSettle();
      expect(await requested, AppExitResponse.cancel);
      expect(
        tester
            .widget<XiangqiBoard>(find.byType(XiangqiBoard))
            .session
            .moves
            .length,
        1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
