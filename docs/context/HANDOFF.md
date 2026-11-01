# 会话交接 / M2-01

先读AGENTS、README、CURRENT_STATE、DECISIONS，git status确认实际状态。用户已授权按计划实现离线业务，旧的“只调查/只诊断”限制不再适用；登录后功能延期；许可事项暂不处理、不阻挡本地开发。

本轮B15首切片完成：packages/xiangqi_core（无Flutter/IO），入口lib/xiangqi_core.dart。先读该包README，了解UCI坐标、FEN格式、语义校验与历史裁决边界。不要将legalMoves作为完整对局裁决，不将可解析FEN直接当作适合native搜索的合法局面。

重跑：packages/xiangqi_core目录执行 dart pub get、dart analyze、dart test；根目录 python3 tools/verify_xiangqi_perft.py（需要.local中官方制品）。11测试通过，4组perft逐分支与Pikafish一致，证据docs/engine/evidence/xiangqi-perft.json。

下一切片：B15局面语义校验、终局与历史裁决接口→B16棋树/会话，再棋盘UI。B14生产引擎端口和移动C ABI仍待做。不要照搬诊断适配器作为生产实现。

已有通信重跑：根目录 python3 tools/setup_pikafish.py 校验/获取固定版本；python3 tools/run_macos_probe.py 做应用内helper继承sandbox签名验证。日志及manifest见docs/engine/COMMUNICATION_VALIDATION.md。Flutter test与macOS App已跑通；外部helper被Sandbox拒绝，应用内签名成功，不关闭Sandbox。

本轮未做：完整业务UI/持久化、完整终局/重复裁决、移动FFI、Windows/Linux、正式签名、公证、性能热测。无后台进程，无git提交，main仍无历史基线。Skills官方校验器此前缺PyYAML，尚未补跑，Ruby YAML替代校验曾通过。
