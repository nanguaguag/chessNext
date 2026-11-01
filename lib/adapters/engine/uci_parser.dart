import 'package:xiangqi_core/xiangqi_core.dart';
import '../../ports/engine_gateway.dart';

EngineOption? parseUciOption(String line) {
  final match = RegExp(
    r'^option name (.+) type (spin|check|string|button|combo)(?: (.*))?$',
  ).firstMatch(line);
  if (match == null) return null;
  final rest = match.group(3) ?? '';
  String? field(String name) => RegExp(
    '(?:^| )$name (.*?)(?= (?:min|max|var) |\$)',
  ).firstMatch(rest)?.group(1);
  return EngineOption(
    name: match.group(1)!,
    type: match.group(2)!,
    defaultValue: field('default'),
    minimum: int.tryParse(field('min') ?? ''),
    maximum: int.tryParse(field('max') ?? ''),
  );
}

EngineInfo? parseUciInfo(String line, int token) {
  if (!line.startsWith('info ') || line.startsWith('info string ')) return null;
  final score = RegExp(r'\bscore (cp|mate) (-?\d+)').firstMatch(line);
  if (score == null) return null;
  int? number(String key) => int.tryParse(
    RegExp('(?:^| )$key (\\d+)').firstMatch(line)?.group(1) ?? '',
  );
  final pvText = RegExp(r'\bpv (.+)$').firstMatch(line)?.group(1);
  final pv = <Move>[];
  if (pvText != null) {
    for (final value in pvText.split(RegExp(r'\s+'))) {
      try {
        pv.add(Move.parse(value));
      } on FormatException {
        return null;
      }
    }
  }
  return EngineInfo(
    token: token,
    depth: number('depth') ?? 0,
    multiPv: number('multipv') ?? 1,
    score: int.parse(score.group(2)!),
    isMate: score.group(1) == 'mate',
    bound: line.contains('lowerbound')
        ? 'lower'
        : line.contains('upperbound')
        ? 'upper'
        : null,
    pv: List.unmodifiable(pv),
    nodes: number('nodes'),
    nps: number('nps'),
    timeMs: number('time'),
  );
}
