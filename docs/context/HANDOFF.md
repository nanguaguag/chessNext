# 会话交接 / M3-02

先读AGENTS、README、CURRENT_STATE、DECISIONS与git status/log。任务仍在持续执行：用户要求所有功能对齐后再审查，一功能一commit，先flutter test/flutter analyze。在线后端选自建可替换服务及部署方案，不再永久排除账号/在线；许可暂不处理。

当前提交：fd295fa分支注释，9e408b2保存恢复，53e4f4f正式UCI。本轮分析面板/原生打包独立提交见git log。根33测试（含实际官方引擎，需环境）与分析通过；核心32通过；macOS原生3测试通过，包括包内NNUE、多PV切换和停止。

根main注入FileGameRepository与openBundledEngine；预览ChessNextApp默认内存仓库、无引擎，勿冒充持久化。游戏树schema1、2k节点/4MiB、可恢复bak，库不依赖账号。主App构建从.local打包校验/签名helper，工具tools/setup_pikafish.py准备制品；tools/bundle_pikafish.py限制只写build下Resources/pikafish，缺失制品时棋盘可用分析不可用。Debug稳定identifier，Sandbox始终开启。

重跑bash tools/check.sh；CHECK_MACOS_INTEGRATION=1额外原生窗口测试。根无引擎环境时仅live-adapter测试会skip，不能写成通过；check脚本为本机.local设置环境。普通flutter run -d macos恢复正常入口。不要自动终止用户旧窗口/未保存对局；不把测试构建仍留在磁盘当作已运行普通入口。

下一功能：F03 AI对弈，复用端口并与分析互斥；保留request generation与positionRevision过滤旧结果，所有落子必须走Session合法性校验。随后编辑/FEN导入导出/草稿/复盘，再后端和移动。全站未完成，不要发最终完成声明。

## M3-03接续

分析控制器已重命名为EngineSessionController，分析与AI共用单实例；旧analysis_controller.dart路径不再有效。AI功能41根测试和4原生测试通过；先完成本功能commit再继续编辑器。已审计站点E10：清空保留先手并留下黑将d9/红帅e0；初始局面重置红先；红黑互换为纵向映射rank=9-rank并换色、换先手；将帅照面显示提示，Done仍可点但拒绝提交。证据docs/research/editor-*-2026-11-02*。复制FEN toast出现但浏览器剪贴板API返回空，未把导出值算验证成功。后续编辑草稿必须独立，取消不改原文档，确认替换需保护dirty。
