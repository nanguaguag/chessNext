import 'package:chess_next/adapters/engine/uci_parser.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/review_cache_access.dart';
import 'package:chess_next/application/review_cache_key.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:chess_next/ports/review_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

void main() {
  final estimate = WdlEstimate(wins: 8, draws: 896, losses: 96);
  test(
    'WDL validates total, swaps only win/loss and separates win from expected score',
    () {
      expect(estimate.expectedScore, closeTo(.456, 1e-10));
      expect(estimate.flipped().toJson(), [96, 896, 8]);
      expect(estimate.flipped().expectedScore, closeTo(.544, 1e-10));
      expect(
        () => WdlEstimate(wins: 1, draws: 1, losses: 1),
        throwsArgumentError,
      );
      expect(
        () => WdlEstimate(wins: -1, draws: 1001, losses: 0),
        throwsArgumentError,
      );
      expect(() => WdlEstimate.fromJson([1, 2.0, 997]), throwsFormatException);
    },
  );
  test(
    'parser preserves native WDL and ignores invalid optional statistics',
    () {
      final info = parseUciInfo(
        'info depth 4 score cp -36 wdl 8 896 96 pv h9g7',
        1,
      )!;
      expect(info.wdl!.toJson(), estimate.toJson());
      expect(info.score, -36);
      for (final data in ['8 896 97', '-1 1001 0', '1 2', '1 x 998']) {
        final invalid = parseUciInfo(
          'info depth 4 score cp -36 wdl $data pv h9g7',
          1,
        )!;
        expect(invalid.wdl, isNull);
        expect(invalid.score, -36);
      }
      expect(
        parseUciInfo('info depth 4 score cp ${'9' * 100} pv h9g7', 1),
        isNull,
      );
    },
  );
  test(
    'red and black forecast perspectives follow the actual side to move',
    () {
      final session = BoardSession();
      session.playMove(Move.parse('h2e2'));
      final controller = EngineSessionController(session, null);
      addTearDown(() {
        controller.dispose();
        session.dispose();
      });
      final info = EngineInfo(
        token: 1,
        depth: 4,
        multiPv: 1,
        score: -36,
        isMate: false,
        pv: const [],
        wdl: estimate,
      );
      expect(controller.wdlFor(info, Side.black)!.toJson(), [8, 896, 96]);
      expect(controller.wdlFor(info, Side.red)!.toJson(), [96, 896, 8]);
    },
  );
  test(
    'cached scores roundtrip WDL while old CP-only entries remain readable',
    () {
      final entry = CachedEngineScore(
        key: 'a' * 64,
        info: EngineInfo(
          token: 1,
          depth: 4,
          multiPv: 1,
          score: -36,
          isMate: false,
          pv: [Move.parse('h9g7')],
          wdl: estimate,
        ),
      );
      expect(
        CachedEngineScore.fromJson(entry.toJson()).info.wdl!.toJson(),
        estimate.toJson(),
      );
      final old = entry.toJson()..remove('wdl');
      expect(CachedEngineScore.fromJson(old).info.wdl, isNull);
      expect(
        () => CachedEngineScore.fromJson({
          ...old,
          'wdl': [0, 0, 0],
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'preferred WDL uses a separate key and CP-only metadata is not a full hit',
    () async {
      final identity = EngineIdentity(
        release: 'Synthetic fixture',
        commit: 'a' * 40,
        sourceBinarySha256: 'b' * 64,
        binarySha256: 'c' * 64,
        networkSha256: 'd' * 64,
        target: 'test',
      );
      const options = {
        'UCI_ShowWDL': EngineOption(
          name: 'UCI_ShowWDL',
          type: 'check',
          defaultValue: 'false',
        ),
      };
      final request = EngineRequest(
        token: 1,
        root: Position.initial(),
        depth: 4,
        preferWdl: true,
      );
      final plain = EngineRequest(token: 1, root: Position.initial(), depth: 4);
      expect(
        reviewCacheKey(identity, request, options),
        isNot(reviewCacheKey(identity, plain, options)),
      );
      final repository = MemoryReviewCacheRepository();
      final access = ReviewCacheAccess(identity, options, repository);
      final info = EngineInfo(
        token: 1,
        depth: 4,
        multiPv: 1,
        score: 5,
        isMate: false,
        pv: [Move.parse('h2e2')],
      );
      await access.write(request, info);
      expect(repository.length, 0);
      final key = reviewCacheKey(identity, request, options);
      await repository.save(CachedEngineScore(key: key, info: info));
      expect(await access.read(request), isNull);
      expect(repository.length, 0);
    },
  );
}
