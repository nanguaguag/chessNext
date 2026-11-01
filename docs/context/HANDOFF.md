# 会话交接

2026-11-02（Asia/Shanghai）。先读AGENTS、README、CURRENT_STATE、DECISIONS，再git status/log。历史详细经过见SESSION_LOG与history/2026-11-02-before-consolidation.md。

用户要求持续业务实现，一功能一中文Conventional Commit，先flutter test/flutter analyze，所有可确认功能对齐后再停给审查。在线选自建可替换后端+部署方案，许可暂缓。不得将计划/接口/单平台通过当完整对标。

最近提交a7a9bc2局面编辑、cb5eb93FEN/UCI、636e993中文纵线；自动草稿增量本次提交见git log。完成提交后工作树应干净，以git status为准。根58、核心上一切片46、原生7测试及静态分析通过。输入焦点辅助函数和生命周期trace保留；AI原生曾偶发停止，最终完整复跑通过，历史失败见SESSION_LOG/KNOWN_ISSUES。

自动草稿DraftRepository/Controller与FileDraftRepository已实现。独立chessnext-drafts目录复用版本化快照，300ms去抖、串行队列、备份、损坏原件归档、恢复为新dirty副本；不覆盖显式棋谱库，不恢复AI角色。后台/正常退出flush，失败可取消退出；退出回调在Widget测试中验证，真实OS强制关闭/断电未测。ADR-006记录边界。

下一条可执行工作：续审F32整谱分析/复盘，再拆可取消的单引擎队列→评分曲线→复盘结果持久化/错题等功能增量。先使用IAB可操作工具审计实际入口/默认值/范围/取消/结果阈值；记录E12，不能凭指南推断运行成功。复盘必须与AI/当前局面分析共享EngineSessionController单引擎所有权，AI/分析优先，旧epoch/文档变化不写错节点；评分统一红方视角，未经校准不标准确率。

模块实际映射见architecture/IMPLEMENTED_MODULES.md。UCI生命周期/搜索generation/positionRevision保留；UI不访问进程/文件/网络。中文显示基于父局面和执方，领域不依赖Flutter，存储schema1仍是UCI。

重跑bash tools/check.sh；CHECK_MACOS_INTEGRATION=1额外原生窗口测试。普通flutter run -d macos可运行。没有引擎环境的根test会skip live测试，不能记全通过。单独核心cd packages/xiangqi_core && dart test && dart analyze，不在Flutter根直接dart test。

普通用户旧窗口不要自动关闭；测试创建的App由Flutter测试工具收尾，没有本功能仍需等待的后台命令。IAB tab只作研究证据，不依赖它恢复代码任务；截图不作产品资产。新的测试启动可能使用build内测试入口，最终审查前需flutter run重建普通入口。

## M3-04最新

设置增量提交见git log：AppPreferences/schema1、PreferencesController/Repository、ApplicationSupport文件适配器、Material3设置、逐字段加载合并、保存失败与备份、Engine.configureSession和能力钳制。现有参数面板更改会保存，主题不重启搜索，不保存AI角色。根67/67和flutter analyze通过；纯核心仍上轮46未改。

macOS8/8通过，integration_test/local_board_test.dart使用现有binding和SystemChannels.lifecycle保持framework-resumed交互前提；仅测试文件内生效，普通main不覆盖。真实OS焦点/最小化/隐藏不在该原生fixture验收范围；生产策略由独立TargetPlatformVariant组件测试，详ADR-008。原生初轮7/8后一次停滞被INT中断，尝试自定义Binding与工具预建binding冲突，已移除；最终8/8通过，原始事件采样[]，不声称旧停滞根因全关闭。没有更改OS权限或SDK。

完成本功能提交后工作树应干净。测试App/helper由Flutter工具收尾，没有仍需等待的验证命令。下一项F32先审计；不要把原生fixture成功算人工视觉验收。

E12研究追加：docs/research/review-*-2026-11-02*记录快速执行、配置、0队列及取消终态，REFERENCES见REFERENCE_EVIDENCE E12。下一条先扩展EngineRequest/UCiEngine支持depth+movetime+nodes并测试组合先到界限，不能先写完整复盘。再单独优化相同资源与同文档Hash复用（官方源码已确认重复setoption/ucinewgame会重分配/清除），然后队列。当前只有E12研究文档/截图待提交，业务代码已在678a811全部提交。

## M3-05最新

组合限额即将提交见git log。EngineRequest.nodeLimit可与depth/time并存，策略边界与0/null区别见COMMUNICATION_VALIDATION；go的searchmoves保持最后。根69/69、flutter analyze无问题，真实CLI和macOS包内NNUE验证先到上限结束；原生9/9。本轮fixture采样包含hidden/inactive，不当作OS真实生命周期验收。

下一条：相同资源与同文档搜索复用。当前UciEngine每次start仍三项setoption + ucinewgame；固定官方源码证实同值也触发线程/Hash回调和清表。分别记录已应用资源及(gameId,rootFen)，同文档只发送改变的参数、新文档才ucinewgame，保留stop/bestmove和ready屏障。EngineSessionController分析/AI请求传session.epoch，新Engine默认冷状态。命令Fake与实际NNUE验证，基准若测只报条件和数值、不空称提速百分比；独立commit后才做整谱队列。
