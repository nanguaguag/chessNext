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

编辑确认前调用`position.validateForPlay()`，返回不可变PositionValidation/PositionIssue，包含错误code、方色和相关坐标。检查数量上限、将士象位置、兵卒初始/未过河路径与同路重复、将帅照面及非行棋方被将军。允许当前行棋方被将军；这些静态条件不构成历史可达性证明，语义不合法的Position仍可用于编辑草稿，但不能直接启动业务对弈/分析。

`position.boardOutcome()` 对通过静态校验的局面返回ongoing/checkmate/stalemate及winner；中国象棋困毙同样判负，不是和棋。无效编辑草稿抛StateError，避免误判为终局。此接口只检查当前棋盘，长将、长捉、重复、自然限着及认输/超时由后续会话裁决层处理。
