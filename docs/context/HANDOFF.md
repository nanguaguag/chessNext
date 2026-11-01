# 会话交接

2026-11-02（Asia/Shanghai）。先读AGENTS、README、CURRENT_STATE、DECISIONS，再git status/log。历史详细经过见SESSION_LOG与history/2026-11-02-before-consolidation.md。

用户要求持续业务实现，一功能一中文Conventional Commit，先flutter test/flutter analyze，所有可确认功能对齐后再停给审查。在线选自建可替换后端+部署方案，许可暂缓。不得将计划/接口/单平台通过当完整对标。

最近提交a7a9bc2局面编辑、cb5eb93FEN/UCI、636e993中文纵线；自动草稿增量本次提交见git log。完成提交后工作树应干净，以git status为准。根58、核心上一切片46、原生7测试及静态分析通过。输入焦点辅助函数和生命周期trace保留；AI原生曾偶发停止，最终完整复跑通过，历史失败见SESSION_LOG/KNOWN_ISSUES。

自动草稿DraftRepository/Controller与FileDraftRepository已实现。独立chessnext-drafts目录复用版本化快照，300ms去抖、串行队列、备份、损坏原件归档、恢复为新dirty副本；不覆盖显式棋谱库，不恢复AI角色。后台/正常退出flush，失败可取消退出；退出回调在Widget测试中验证，真实OS强制关闭/断电未测。ADR-006记录边界。

下一条可执行工作：设置持久化。定义版本化AppPreferences（主题、引擎线程/Hash/MultiPV、AI用时、后续显示/声音配置），独立PreferencesRepository；初始化失败使用安全默认但保留坏文件并提示，保存失败/竞态/非法参数校验先于UI。不得持久化AI角色并在恢复后自动走棋。硬件变化要钳制资源参数。之后整谱复盘和评分曲线、导入文件等功能。

模块实际映射见architecture/IMPLEMENTED_MODULES.md。UCI生命周期/搜索generation/positionRevision保留；UI不访问进程/文件/网络。中文显示基于父局面和执方，领域不依赖Flutter，存储schema1仍是UCI。

重跑bash tools/check.sh；CHECK_MACOS_INTEGRATION=1额外原生窗口测试。普通flutter run -d macos可运行。没有引擎环境的根test会skip live测试，不能记全通过。单独核心cd packages/xiangqi_core && dart test && dart analyze，不在Flutter根直接dart test。

普通用户旧窗口不要自动关闭；测试创建的App由Flutter测试工具收尾，没有本功能仍需等待的后台命令。IAB tab只作研究证据，不依赖它恢复代码任务；截图不作产品资产。新的测试启动可能使用build内测试入口，最终审查前需flutter run重建普通入口。
