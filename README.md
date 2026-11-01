# chessNext

使用 Flutter Material Design 3 与原生 Pikafish 的开源跨平台中国象棋项目。目标覆盖 xiangqiai.com 可确认功能，优先离线棋盘、棋谱、本地分析，在线能力经可替换接口接入。

**当前已提供独立 Flutter ↔ Pikafish 通信诊断工程，尚无完整业务 App。已开始实施纯 Dart 离线规则核心（packages/xiangqi_core），当前覆盖坐标/FEN/合法走法/将军判定、编辑局面校验及将死/困毙终局。** 登录后与在线服务功能延期，本地主线见 [离线范围](docs/planning/OFFLINE_SCOPE.md)。引擎与NNUE仅存本机忽略目录，不提交制品。

从 [当前状态](docs/context/CURRENT_STATE.md) 和 [交接](docs/context/HANDOFF.md) 恢复工作；Agent 先读 [AGENTS.md](AGENTS.md)。

- [功能矩阵](docs/research/FEATURE_MATRIX.md) / [证据](docs/research/REFERENCE_EVIDENCE.md) / [缺口](docs/research/FEATURE_GAPS.md)
- [架构](docs/architecture/ARCHITECTURE.md) / [引擎](docs/engine/PIKAFISH_RESEARCH.md) / [设计](docs/design/DESIGN_SYSTEM.md)
- [总计划](docs/planning/MASTER_PLAN.md) / [里程碑](docs/planning/MILESTONES.md) / [待办](docs/planning/BACKLOG.md) / [测试](docs/planning/TEST_STRATEGY.md)
- [许可调查](docs/legal/LICENSING.md)

[通信验证与重跑](docs/engine/COMMUNICATION_VALIDATION.md)；诊断工程在 research/spikes/flutter_engine_probe/，不等同生产架构。根目录 lib/、test/ 已有应用边界API和Flutter契约测试；integration_test/、native/ 后续按阶段实现。尚未选择项目许可证；开源发布前必须完成许可决策。

开发验证：根目录提供Flutter包和领域契约测试入口（尚无主App界面），执行`flutter test`、`flutter analyze`；`bash tools/check.sh`还会验证纯Dart规则包和真实引擎诊断工程，后者需先配置.local官方制品。功能通过后按中文Conventional Commits独立提交。
