import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../ports/engine_gateway.dart';

/// Exact-budget reuse; a deeper score is not silently substituted for this job.
String reviewCacheKey(
  EngineIdentity identity,
  EngineRequest request,
  Map<String, EngineOption> options,
) {
  final names =
      options.keys
          .where(
            (name) =>
                !{'Threads', 'Hash', 'MultiPV', 'EvalFile'}.contains(name),
          )
          .toList()
        ..sort();
  return sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'schema': 1,
            'algorithm': 'best-pv-v1',
            'rules': 'chessnext-static-rules-v1',
            'engine': identity.toJson(),
            'root': request.root.toFen(),
            'history': request.moves.map((m) => m.toString()).toList(),
            'depth': request.depth,
            'timeMs': request.moveTimeMs,
            'nodes': request.nodeLimit,
            'threads': request.threads,
            'hashMb': request.hashMb,
            'multiPv': request.multiPv,
            'searchMoves': request.searchMoves
                ?.map((m) => m.toString())
                .toList(),
            'defaults': [
              for (final name in names)
                {
                  'name': name,
                  'type': options[name]!.type,
                  'default': options[name]!.defaultValue,
                },
            ],
          }),
        ),
      )
      .toString();
}
