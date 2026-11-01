# chessNext

使用 Flutter Material Design 3 与原生 Pikafish 的开源跨平台中国象棋项目。目标覆盖 xiangqiai.com 可确认功能，优先离线棋盘、棋谱、本地分析，在线能力经可替换接口接入。

**已提供可运行的 macOS Material 3 离线双人棋盘。** 支持合法落子、悔棋、翻转、新局确认、将死/困毙提示、明暗主题及键盘操作。根目录运行 `flutter pub get`、`flutter run -d macos`，详见 [macOS运行说明](docs/planning/MACOS_RUN.md)。

Pikafish通信已在独立诊断工程验证，分析面板尚未接入主App；棋谱保存与恢复、分支注释和AI对弈继续增量推进。登录后与在线服务延期，引擎/NNUE仅在本机忽略目录，不提交制品。

从 [当前状态](docs/context/CURRENT_STATE.md) 和 [交接](docs/context/HANDOFF.md) 恢复工作；Agent 先读 [AGENTS.md](AGENTS.md)。

- [功能矩阵](docs/research/FEATURE_MATRIX.md) / [证据](docs/research/REFERENCE_EVIDENCE.md) / [缺口](docs/research/FEATURE_GAPS.md)
- [架构](docs/architecture/ARCHITECTURE.md) / [引擎](docs/engine/PIKAFISH_RESEARCH.md) / [设计](docs/design/DESIGN_SYSTEM.md)
- [总计划](docs/planning/MASTER_PLAN.md) / [里程碑](docs/planning/MILESTONES.md) / [待办](docs/planning/BACKLOG.md) / [测试](docs/planning/TEST_STRATEGY.md)
- [许可调查](docs/legal/LICENSING.md)

[通信验证与重跑](docs/engine/COMMUNICATION_VALIDATION.md)；诊断工程在 research/spikes/flutter_engine_probe/，不等同生产架构。根目录 lib/、test/ 已有应用边界API和Flutter契约测试；integration_test/、native/ 后续按阶段实现。尚未选择项目许可证；开源发布前必须完成许可决策。

开发验证：根目录提供Flutter应用、领域契约与组件测试，执行`flutter test`、`flutter analyze`；`bash tools/check.sh`还会验证纯Dart规则包和真实引擎诊断工程，后者需先配置.local官方制品。功能通过后按中文Conventional Commits独立提交。
