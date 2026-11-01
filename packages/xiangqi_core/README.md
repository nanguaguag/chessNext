# xiangqi_core

纯 Dart 离线中国象棋规则核心，无 Flutter、引擎、存储或网络依赖。

```dart
import 'package:xiangqi_core/xiangqi_core.dart';

final start = Position.initial();
final next = start.play(Move.parse('h2e2'));
print(next.toFen());
print(next.isInCheck(next.turn));
```

坐标采用 UCI：a0 为红方左下角，rank 向黑方递增，FEN 从 rank9 向 rank0 排列。红先用 w、黑先用 b。输出规范化 r/n/b/a/k/c/p；解析同时接受 h/e 别名。支持 board+turn 两字段和标准六字段；六字段权利位必须为“- -”。

Position 不可变；play 只接受当前方合法走法，拒绝吃己方、吃将和自陷将军。规则包含马腿、象眼/河界、宫界、炮架、过河兵、将帅照面。将军由攻击判定计算，不能仅凭前一步棋推测。

FEN 解析只验证棋盘形状、符号、计数器和双方各一将，不保证历史可达性或棋子数量/摆放有效性。编辑器后续需独立语义校验，不应将任何可解析FEN直接发送引擎。perft和legalMoves不包含长将、长捉、重复、自然限着等历史裁决；“有合法走法”不意味着实际对局尚未结束。

目前用遍历90格的直接实现，以正确性和清晰度为主；不是高性能搜索引擎，不替代Pikafish。生产UI应缓存当前局面的合法走法，避免在每次绘制中重复计算。

验证：

```sh
cd packages/xiangqi_core
dart pub get
dart analyze
dart test --reporter expanded
cd ../..
python3 tools/verify_xiangqi_perft.py
```

最后一项需要本机已配置官方Pikafish制品（tools/setup_pikafish.py）。测试fixture为本项目手工构造，无网站棋谱资源。
