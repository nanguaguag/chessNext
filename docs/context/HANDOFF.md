# 会话交接 / M2-03

先读AGENTS/README/CURRENT_STATE/DECISIONS，再查看git status和git log。用户要求每功能独立中文Conventional Commit，必须先跑flutter test、flutter analyze；许可暂不处理，不阻挡离线开发。

基线b3b423a已归档技术研究/引擎/规则与根Flutter测试入口；局面校验9b515d2已提交；本轮将死/困毙功能另行提交，实际哈希见git log。根目录是Flutter包边界，尚无主App界面；核心规则是packages/xiangqi_core纯Dart包。

验证命令：根目录bash tools/check.sh，包含根flutter test/analyze、规则dart test/analyze、真实引擎spike flutter test/analyze。最新7/26/2测试通过，分析均无问题。引擎测试需.local制品（python3 tools/setup_pikafish.py）；本轮也重跑macOS沙箱App和4组perft成功。源码/证据及已知平台边界见docs/engine/COMMUNICATION_VALIDATION.md。

API：Position.fromFen仅结构校验；validateForPlay静态语义检查；boardOutcome拒绝无效局面，返回ongoing/checkmate/stalemate及winner（困毙判负）。历史可达性、重复、长将长捉、自然限着、认输/超时不在当前接口范围，后续会话层处理。

接着做B16：不可变棋树、稳定ID、主线/分支、注释、游标和会话撤销，再接M3棋盘UI。B14移动桥接未做；不要把桌面spike当生产调度器。每新增功能→针对性测试→根Flutter两门槛→独立提交→同步状态。无后台进程；工作树应干净，以git status复查。
