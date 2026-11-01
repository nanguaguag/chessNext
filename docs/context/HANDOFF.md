# 会话交接 / M3-02

先读AGENTS、README、CURRENT_STATE、DECISIONS与git status/log。任务仍在持续执行：用户要求所有功能对齐后再审查，一功能一commit，先flutter test/flutter analyze。在线后端选自建可替换服务及部署方案，不再永久排除账号/在线；许可暂不处理。

当前提交：fd295fa分支注释，9e408b2保存恢复，53e4f4f正式UCI。本轮分析面板/原生打包独立提交见git log。根33测试（含实际官方引擎，需环境）与分析通过；核心32通过；macOS原生3测试通过，包括包内NNUE、多PV切换和停止。

根main注入FileGameRepository与openBundledEngine；预览ChessNextApp默认内存仓库、无引擎，勿冒充持久化。游戏树schema1、2k节点/4MiB、可恢复bak，库不依赖账号。主App构建从.local打包校验/签名helper，工具tools/setup_pikafish.py准备制品；tools/bundle_pikafish.py限制只写build下Resources/pikafish，缺失制品时棋盘可用分析不可用。Debug稳定identifier，Sandbox始终开启。

重跑bash tools/check.sh；CHECK_MACOS_INTEGRATION=1额外原生窗口测试。根无引擎环境时仅live-adapter测试会skip，不能写成通过；check脚本为本机.local设置环境。普通flutter run -d macos恢复正常入口。不要自动终止用户旧窗口/未保存对局；不把测试构建仍留在磁盘当作已运行普通入口。

下一功能：F03 AI对弈，复用端口并与分析互斥；保留request generation与positionRevision过滤旧结果，所有落子必须走Session合法性校验。随后编辑/FEN导入导出/草稿/复盘，再后端和移动。全站未完成，不要发最终完成声明。
