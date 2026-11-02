# chessNext

使用 Flutter Material Design 3 与原生 Pikafish 的开源跨平台中国象棋项目。目标覆盖 xiangqiai.com 可确认功能，优先离线棋盘、棋谱、本地分析，在线能力经可替换接口接入。

**已提供可运行的 macOS Material 3 离线双人棋盘。** 支持合法落子、悔棋、翻转、新局确认、将死/困毙提示、明暗主题及键盘操作。根目录运行 `flutter pub get`、`flutter run -d macos`，详见 [macOS运行说明](docs/planning/MACOS_RUN.md)。

主App现已接入本地棋谱保存恢复、同级分支切换/提升/删除与注释、完整线路与前后分支点导航、长谱虚拟列表、Pikafish分析与多路变化、评分箭头、原生胜和负模型估计、着法预期损失评级报告和引擎参数；支持当前线路/整树的可取消的最佳/多候选离线整谱复盘、候选详情与红方评分曲线与结果跳转及跳过已有，正式macOS应用使用独立有界文件缓存；单步候选可从父局面试走为同级分支。内置可搜索的离线使用帮助与按钮说明，提供可重放的四步引导和首次使用版本记忆。棋谱资料支持编辑赛事、棋手和记录结果，并随本地保存及草稿恢复保留未知标签。本机最近阅读独立记录已保存谱的位置并校验路径恢复。支持本地AI对弈（催招/变招/悔棋）、独立局面编辑及FEN/UCI/ICCS/中文及单局PGN文字导入导出（含资料和评注）；自动草稿独立保存并可恢复为未保存副本。主题、引擎资源和AI用时可在本机持久化。其余功能继续增量推进；在线部分按用户选择自建可替换后端，引擎/NNUE仅在本机忽略目录，不提交制品。

从 [当前状态](docs/context/CURRENT_STATE.md) 和 [交接](docs/context/HANDOFF.md) 恢复工作；Agent 先读 [AGENTS.md](AGENTS.md)。

- [功能矩阵](docs/research/FEATURE_MATRIX.md) / [证据](docs/research/REFERENCE_EVIDENCE.md) / [缺口](docs/research/FEATURE_GAPS.md)
- [架构](docs/architecture/ARCHITECTURE.md) / [引擎](docs/engine/PIKAFISH_RESEARCH.md) / [设计](docs/design/DESIGN_SYSTEM.md)
- [总计划](docs/planning/MASTER_PLAN.md) / [里程碑](docs/planning/MILESTONES.md) / [待办](docs/planning/BACKLOG.md) / [测试](docs/planning/TEST_STRATEGY.md)
- [许可调查](docs/legal/LICENSING.md)

[通信验证与重跑](docs/engine/COMMUNICATION_VALIDATION.md)；诊断工程在 research/spikes/flutter_engine_probe/，不等同生产架构。根目录 lib/、test/ 已有应用边界API和Flutter契约测试；integration_test/已有macOS实际引擎/存储/编辑验证；native/后续补移动集成。尚未选择项目许可证；开源发布前必须完成许可决策。

开发验证：根目录提供Flutter应用、领域契约与组件测试，执行`flutter test`、`flutter analyze`；`bash tools/check.sh`还会验证纯Dart规则包和真实引擎诊断工程，后者需先配置.local官方制品。功能通过后按中文Conventional Commits独立提交。

单局PGN（ICCS/中文）已接入文字/剪贴板交换，后台解析并保留资料与评注。导出仅所选路径，可显式省略评注；已提供单个UTF8文字棋谱文件选择入口（有界读取与预览确认）；系统面板人工选择尚未验证。拖放、多局、GBK、括号变着和WXF仍待独立实现。

macOS文字导出窗口可将上述五格式保存为UTF8文件，原生原子替换，导出不清除当前谱的未保存状态。系统保存面板实际交互/外部沙箱授权仍待人工验证，其它平台文件写入待各自适配。

应用设置内提供实时界面字号：跟随系统，或标准100%/大115%/特大130%，独立本机记忆。系统模式保留非线性缩放，手动模式覆盖系统比例。

“应用设置 → 棋盘显示”可即时开关路数坐标，主棋盘和局面编辑器共用，翻转/镜像后仍对应逻辑路数；选择保存在本机。

棋盘显示还可调棋子大小（10%–200%，步进5%）并恢复默认100%；只改变显示，点击区域保持在交点，主棋盘与编辑器及拖动反馈共用。

“应用设置 → 分析标记”可开关整组引擎推荐/预计应着箭头，并选择尖、标准、宽头部；显示变化不重启分析，重新显示使用最新PV。

本步变着面板提供会话内“棋盘箭头”，需同时启用分析标记中的全局变着开关；绿色编号对应当前着的同级列表。根/换文档/打开设置会清局部状态，完整棋树和分析保持。
