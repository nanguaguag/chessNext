# 会话交接

2026-11-02（Asia/Shanghai）。先读AGENTS、README、CURRENT_STATE、DECISIONS，再git status/log。历史详细经过见SESSION_LOG与history/2026-11-02-before-consolidation.md。

用户要求持续业务实现，一功能一中文Conventional Commit，先flutter test/flutter analyze，所有可确认功能对齐后再停给审查。在线选自建可替换后端+部署方案，许可暂缓。不得将计划/接口/单平台通过当完整对标。

最近提交a7a9bc2局面编辑、cb5eb93FEN/UCI交换；中文纵线增量本次提交见git log。当前待提交文件只应属于中文格式/列表及相关测试文档，以git status为准。根50、核心46、原生6测试及两套静态分析通过；原生经历输入焦点失败已修测试helper，AI偶发停止保留trace和记录。

下一条可执行工作：自动草稿与恢复。设计独立DraftRepository，不覆盖用户显式棋谱；300ms去抖、串行写入不可变快照、备份恢复、初始化恢复提示、忽略/取消/脏状态保护、失败重试与生命周期flush。主App注入磁盘适配器，测试显式内存/临时Documents。恢复应创建未保存副本以保护原文档；不恢复AI自动落子。先写接口/失败模型/验收，再最小实现。

模块实际映射见architecture/IMPLEMENTED_MODULES.md。UCI生命周期/搜索generation/positionRevision保留；UI不访问进程/文件/网络。中文显示基于父局面和执方，领域不依赖Flutter，存储schema1仍是UCI。

重跑bash tools/check.sh；CHECK_MACOS_INTEGRATION=1额外原生窗口测试。普通flutter run -d macos可运行。没有引擎环境的根test会skip live测试，不能记全通过。单独核心cd packages/xiangqi_core && dart test && dart analyze，不在Flutter根直接dart test。

普通用户旧窗口不要自动关闭；测试创建的App由Flutter测试工具收尾，没有本功能仍需等待的后台命令。IAB tab只作研究证据，不依赖它恢复代码任务；截图不作产品资产。新的测试启动可能使用build内测试入口，最终审查前需flutter run重建普通入口。
