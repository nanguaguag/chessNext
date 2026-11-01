# 会话交接 / M2-04

读取AGENTS、README、CURRENT_STATE、DECISIONS，再看git status/git log。用户要求每功能先flutter test/flutter analyze，通过后单独中文Conventional Commit；许可暂不处理；在线/账号延期。

当前已实现macOS主App：根目录flutter pub get、flutter run -d macos。不是引擎诊断界面，当前为本地双人棋盘，无AI分析/持久化。可走棋、悔棋、翻转、新局确认、主题/键盘/终局提示；关闭后不保留，界面明确提示。BoardSession线性内存历史不是完整棋树。

本轮flutter test11/11、flutter analyze无问题；bash tools/check.sh额外验证规则26/26、引擎2/2及各自analyze；flutter test integration_test/local_board_test.dart -d macos原生测试1/1。可用CHECK_MACOS_INTEGRATION=1 bash tools/check.sh全套验证。原生测试构建App后需再flutter run -d macos回到正常入口。

macOS构建修复：加入SDK官方Podfile及xcconfig的Pods引用。默认adhoc签名cdhash随重建变化，曾在沙箱初始化挂起；Debug设为稳定dev.chessnext.app要求，Sandbox仍开启，未删除旧容器/改系统权限，Release签名单独处理。详见planning/MACOS_RUN.md。Computer Use未授权，截图/人工点击未验收；用Flutter原生测试验证交互，自动置前失败不影响启动或测试。

普通App已重新用flutter run启动并保留开发会话。尝试detach后该环境终端关闭会导致App退出，因此未再detach。不要自动终止用户对局。其他诊断进程已收尾；/tmp诊断日志不提交，不记录临时VM服务凭证。

下一步B16稳定ID棋树/分支注释/游标/保存恢复，再B14生产引擎/分析UI。尚未实现移动FFI/Windows/Linux/完整历史裁决。基线b3b423a、校验9b515d2、终局6e7fd77已提交，本轮UI提交见git log。

## M2-05接续

GameTree分支/注释/导航已实现，根13测试和core30测试及分析通过。后退现在移动游标，保留子树；新局需检查hasContent而非canUndo。下一步磁盘保存与恢复（包括分支/注释/游标），再引擎主UI。用户要求持续推进至全站对齐，不提前将对标视为完成。

## M2-06接续

本地保存/搜索/打开与备份恢复已实现，核心32、根23、原生2测试及分析通过。注入path_provider Documents目录，不使用shell HOME猜测沙箱路径；现有用户App不要自动终止。GameRepository隔离IO，FileGameRepository目前逐文档JSON（schema1、4MiB/2000节点），SQLite候选仍未选。目录结构/并发语义见ADR-005。下一个增量为FEN/文字导入导出及自动草稿，再生产引擎分析；每功能先测试分析再commit。

## M3-01接续

正式UCI端口已实现且带真实官方引擎的根29测试/分析通过。下一步将EngineGateway注入AnalysisController，接主界面分析/多PV和资源参数；macOS构建时将.local制品打包签名，缺失时明确不可用，不提交二进制。请求token/positionRevision隔离旧结果；停止要等待bestmove后才启动下一任务。
在线后端用户明确选择自建可替换服务及部署方案。该部分不阻挡离线实现。
