import 'package:xiangqi_core/xiangqi_core.dart';

// Original hand-placed fixtures. e0/e9 generals with an e5 blocker by default.
Position board(Map<String, String> pieces, {String turn = 'w'}) {
  final cells = <String, String>{'e0': 'K', 'e9': 'k', 'e5': 'P', ...pieces};
  final rows = <String>[];
  for (var r = 9; r >= 0; r--) {
    var row = '';
    var empty = 0;
    for (var f = 0; f < 9; f++) {
      final p = cells['${String.fromCharCode(97 + f)}$r'];
      if (p == null || p.isEmpty) {
        empty++;
      } else {
        if (empty > 0) row += '$empty';
        empty = 0;
        row += p;
      }
    }
    if (empty > 0) row += '$empty';
    rows.add(row);
  }
  return Position.fromFen('${rows.join('/')} $turn - - 0 1');
}
