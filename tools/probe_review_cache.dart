// Storage protocol probe only; this fixture does not claim an engine evaluation.
import 'dart:convert';
import 'dart:io';
import 'package:chess_next/adapters/storage/file_review_cache_repository.dart';
import 'package:chess_next/ports/review_cache_repository.dart';
import 'package:chess_next/ports/engine_gateway.dart';
import 'package:xiangqi_core/xiangqi_core.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2 || !{'write', 'read'}.contains(args[0])) {
    throw ArgumentError(
      'Usage: dart run tools/probe_review_cache.dart write|read TEMP_DIRECTORY',
    );
  }
  final repository = FileReviewCacheRepository(() async => Directory(args[1]));
  final key = 'f' * 64;
  if (args[0] == 'write') {
    await repository.save(
      CachedEngineScore(
        key: key,
        info: EngineInfo(
          token: 123,
          depth: 4,
          multiPv: 1,
          score: 42,
          isMate: false,
          pv: [Move.parse('h2e2')],
        ),
      ),
    );
  } else {
    final cached = await repository.load(key);
    if (cached == null ||
        cached.info.score != 42 ||
        cached.info.token != 0 ||
        cached.info.pv.single.toString() != 'h2e2') {
      throw StateError('Independent process did not recover the fixture');
    }
  }
  stdout.writeln(
    jsonEncode({
      'phase': args[0],
      'result': 'pass',
      'pid': pid,
      'fixture': 'storage-only',
    }),
  );
}
