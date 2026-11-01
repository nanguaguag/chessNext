import 'package:chess_next/app.dart';
import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/transfer/text_transfer_dialog.dart';
import 'package:chess_next/ports/text_clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

class TestClipboard implements TextClipboard {
  String? text;
  bool fail = false;
  @override
  Future<String?> read() async {
    if (fail) throw StateError('denied');
    return text;
  }

  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('denied');
    text = value;
  }
}

void desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1120, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'import errors preserve the tree; successful import protects dirty content',
    (tester) async {
      desktop(tester);
      await tester.pumpWidget(const ChessNextApp());
      final session = tester
          .widget<XiangqiBoard>(find.byType(XiangqiBoard))
          .session;
      await tester.tap(find.text('导入文字'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '导入'))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('import-text')),
        'startpos moves a0a9',
      );
      await tester.pump();
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(find.textContaining('第1步不合法'), findsOneWidget);
      expect(session.hasMoves, isFalse);
      await tester.enterText(
        find.byKey(const ValueKey('import-text')),
        'startpos moves h2e2 b9c7',
      );
      await tester.pump();
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(session.moves.length, 2);
      expect(session.dirty, isTrue);
      await tester.tap(find.text('导入文字'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('import-text')),
        'startpos',
      );
      await tester.pump();
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(find.text('导入前保留当前棋谱？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(session.moves.length, 2);
    },
  );
  testWidgets(
    'clipboard failures remain actionable and export copies the selected format',
    (tester) async {
      desktop(tester);
      final clipboard = TestClipboard()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<GameTree>(
                context: context,
                builder: (_) => ImportTextDialog(clipboard: clipboard),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('读取剪贴板'));
      await tester.pumpAndSettle();
      expect(find.text('无法读取剪贴板，请手动粘贴'), findsOneWidget);
      clipboard.fail = false;
      clipboard.text = 'startpos moves h2e2';
      await tester.tap(find.text('读取剪贴板'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        clipboard.text,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: ExportTextDialog(
            tree: GameTree().play(Move.parse('h2e2')),
            clipboard: clipboard,
          ),
        ),
      );
      await tester.tap(find.text('FEN + 着法'));
      await tester.pump();
      await tester.tap(find.text('复制'));
      await tester.pumpAndSettle();
      expect(clipboard.text, '${Position.initialFen} moves h2e2');
      expect(find.text('已复制'), findsOneWidget);
      clipboard.fail = true;
      await tester.tap(find.text('复制'));
      await tester.pumpAndSettle();
      expect(find.textContaining('复制失败'), findsOneWidget);
    },
  );
  testWidgets(
    'Chinese notation imports and exports from the Material dialogs',
    (tester) async {
      desktop(tester);
      final clipboard = TestClipboard();
      await tester.pumpWidget(ChessNextApp(clipboard: clipboard));
      await tester.tap(find.text('导入文字'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('import-text')),
        '1. 炮二平五 馬２進３',
      );
      await tester.pump();
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(find.text('1. 炮二平五'), findsOneWidget);
      expect(find.text('2. 马２进３'), findsOneWidget);
      expect(find.byTooltip('h2e2'), findsOneWidget);
      await tester.tap(find.text('导出文字'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文棋谱'));
      await tester.pump();
      await tester.tap(find.text('复制'));
      await tester.pumpAndSettle();
      expect(clipboard.text, contains('moves 炮二平五 马２进３'));
      final tree = TextRecord.parse(clipboard.text!);
      expect(tree.path.last.move.toString(), 'b9c7');
    },
  );
}
