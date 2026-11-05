import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/book_lookup_controller.dart';
import 'package:chess_next/application/master_games_lookup_controller.dart';
import 'package:chess_next/features/workspace/cloud_book_panel.dart';
import 'package:chess_next/ports/book_service.dart';
import 'package:chess_next/ports/master_games_service.dart';

void main() {
  testWidgets('filters do not query until the user presses search', (
    tester,
  ) async {
    final session = BoardSession();
    final book = BookLookupController(session, _BookService());
    final master = _MasterGamesService();
    final masterController = MasterGamesLookupController(session, master);
    var source = BookLookupSource.cloud;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SingleChildScrollView(
              child: CloudBookPanel(
                controller: book,
                masterGamesController: masterController,
                endpoint: 'http://localhost:8080',
                source: source,
                onSourceChanged: (value) => setState(() => source = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('大师谱'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '棋手甲');
    await tester.pumpAndSettle();
    expect(master.calls, 0);
    await tester.tap(find.text('查询大师谱'));
    await tester.pumpAndSettle();
    expect(master.calls, 1);
    expect(master.lastQuery!.text, '棋手甲');
    expect(find.text('找到 1 条记录。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    masterController.dispose();
    book.dispose();
    session.dispose();
  });
}

final class _BookService implements BookService {
  @override
  Future<BookLookup> query({
    required Uri endpoint,
    required BookPositionKey position,
  }) async => const BookLookup(
    hit: false,
    candidates: [],
    datasetId: null,
    license: null,
    attribution: null,
  );
}

final class _MasterGamesService implements MasterGamesService {
  int calls = 0;
  MasterGamesQuery? lastQuery;

  @override
  Future<MasterGamesPage> query({
    required Uri endpoint,
    required MasterGamesQuery query,
  }) async {
    calls++;
    lastQuery = query;
    return const MasterGamesPage(
      datasetId: 'sample',
      license: 'CC0',
      attribution: 'operator',
      page: 1,
      pageSize: 24,
      total: 1,
      records: [
        MasterGameRecord(
          id: 'match',
          category: MasterGameCategory.game,
          red: '红方',
          black: '黑方',
          event: '邀请赛',
          year: 2025,
          result: MasterGameResult.draw,
        ),
      ],
    );
  }
}
