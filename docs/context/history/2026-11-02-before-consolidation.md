# 状态整理前历史快照

# 当前状态

日期2026-11-02（Asia/Shanghai）。M3-03：本地棋谱分支/保存已实现，正式Pikafish分析已接主App；全站对标尚未完成。

用户要求持续推进至全站对齐，每功能先flutter test/flutter analyze再单独中文Conventional Commit，不提前停下来审查。用户已选在线部分自建可替换后端并提供部署方案；旧的在线/账号“延期”仅表示先后顺序，不再永久排除。许可按要求暂不处理，不阻挡本地开发。

## 当前实现

- d3ba721 macOS棋盘；fd295fa棋谱分支/注释/游标、主线提升/变着删除；9e408b2本地保存/命名搜索/打开/备份恢复。
- 53e4f4f正式EngineGateway/UciEngine/Process运输；本轮AnalysisController与主界面分析面板、cp/mate/bound视角归一化、MultiPV、深度/时间/NPS、推荐/回复箭头、线程/Hash/变化数设置。内容revision、positionRevision和引擎generation分别隔离保存与搜索竞态。
- macOS构建脚本从.local核对hash后复制官方引擎/NNUE/许可到Resources并签名helper；Sandbox开启。不在Git提交二进制。缺少.local时仍能构建棋盘，分析明确不可用。
- 离线规则为纯Dart包；IO与引擎都经端口注入，组件测试使用显式内存/假引擎。

## 最近验证

带PIKAFISH_EXECUTABLE/PIKAFISH_NETWORK环境的根flutter test33/33、flutter analyze无问题；核心32测试及分析通过。macOS原生3/3：双人棋盘、Documents临时目录真实保存/新实例恢复、应用包内官方NNUE搜索/切换MultiPV=2/停止。未授Computer Use权限，不能声称截图/人工视觉验收通过。2026-11-02重查官方latest仍指向2026-09-06。

## 接续

下一项F03本地AI对弈（分析互斥、执方、催招/变招/悔棋）→局面编辑、FEN/棋谱导入导出、自动草稿→整谱复盘/错题→设置/体验→在线后端与五平台。B16仓库当前单窗口快照实现，见ADR-005，不声称SQLite、断电fsync或跨进程写事务通过。历史长将长捉/重复/自然限着、移动FFI、Windows/Linux、正式签名公证仍未完成。

现有用户运行窗口不要自动关闭；测试创建的App与helper已收尾。以git status/git log为准；无需依赖聊天记忆。环境Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。

## M3-03最新

分析功能已提交af25944。EngineSessionController统一分析与AI的单引擎所有权，AI逻辑放在engine_play.dart同库扩展。支持执红/黑/双AI、1/3/10秒和0.05至600秒自定义、催招、基于searchmoves排除的变招、对弈悔棋回到人类回合、AI回合输入锁和分析互斥。旧token/positionRevision结果不落子，变招保留原线路并提升新线路为主线。EngineRequest.fromTree直接使用不可变棋树已验证的缓存局面，不每次重放全部历史。
验证：带官方引擎环境根flutter test41/41、flutter analyze无问题；原生4/4包含实际AI应手、变招及双步悔棋。棋力等级和对弈设置持久化尚未实现，不能标F03/F22全部对齐。下一项局面编辑器，依据E10新审计证据实现清空/先手/互换/校验边界。

## 2026-11-02 / M2-07 / F05,F06 → B05 局面编辑

独立SetupDraft允许不完整局面，复用结构化校验；棋子盒按标准数量禁用、连续放子、拖动/拖出移除/右键移除、红黑先、清空/初始/互换、视图旋转/镜像。取消不改原棋树；脏棋谱可先保存；有效且变化的完成结果创建dirty新根。UI复用BoardSurface，领域不依赖Flutter。
验证：带官方引擎环境根flutter test46/46、flutter analyze无问题；核心dart test37/37、dart analyze无问题；原生macOS5/5通过（新增无效照面拒绝与有效黑先提交）；4组官方Pikafish perft一致（79666/1564/1100/46642）。首次analyze发现一处缺少大括号，修复后重跑通过。识图/FEN导入/编辑历史撤销仍后续切片，不标F06全量完成。

下一项F07/F12：FEN与UCI着法文字导入导出，合法性/非法输入定位/取消/脏数据保护；然后中文记谱与文件格式。工作树和提交以git为准。

## 2026-11-02 / M2-08 / F07,F12 → B19 FEN/UCI文字交换

领域TextRecord支持裸FEN（2/6字段）、position fen、startpos、moves着法；逐步合法性校验并定位错误步数，64k字符/1999步限制；失败不改会话。导入新树一次替换并标dirty；当前未保存棋谱可取消/替换/先保存。导出当前局面FEN或根至游标路径，明确不含其他分支/注释/后续；Clipboard独立端口，可选文字手动复制，权限失败不冒充成功。
验证：根flutter test48/48（带官方引擎环境）和flutter analyze、核心dart test40/40和dart analyze通过。原生macOS完整6/6通过。原生文字单项1/1已通过，AI变招曾一次等待超时，单项与最终完整6项复跑通过，保留偶发记录；修复测试重复输入前需显式重新聚焦文本框的问题；首轮失败保留记录，不认为格式解析成功即可冒充交互通过。中文/PGN/ICCS文件/URL/识图后续，不标F07/F12全量对齐。E11实际参考站点接受同一份自制两步FEN+着法。

下一项中文纵线记谱与文字导入：先读原作者xqbase着法规范，处理前中后/多兵编号/士象例外和合法候选唯一匹配；纯领域格式，不修改UCI存储和引擎通信。然后自动草稿与设置持久化。

## 2026-11-02 / M2-09 / F07,F12,F13 → B19 中文纵线记谱

新增纯Dart中文记谱格式化与合法候选唯一解析；红中文/黑全角数字，前中后/多列叠兵序号、同列士象例外、繁体及数字宽度别名。TextRecord接受编号中文序列及ICCS坐标；中文导出带根FEN和当前路径，不保存分支/注释。UI棋谱/变着显示中文，Tooltip保留UCI；引擎与存储格式不变。
验证：根flutter test50/50（官方引擎环境）与flutter analyze、核心dart test46/46与dart analyze通过。原生macOS6/6通过，含中文导入与中文棋谱显示。测试输入统一显式聚焦并验证EditableText实际值；生命周期trace保留在原生AI测试中。规范出处research/NOTATION_RESEARCH.md，公开示例只作协议测试，自造叠兵/士象局面与固定随机路径验证格式唯一可逆。首次误在Flutter根运行dart test已纠正为核心包目录，不把失败命令记为通过。


# 会话交接 / M3-02

先读AGENTS、README、CURRENT_STATE、DECISIONS与git status/log。任务仍在持续执行：用户要求所有功能对齐后再审查，一功能一commit，先flutter test/flutter analyze。在线后端选自建可替换服务及部署方案，不再永久排除账号/在线；许可暂不处理。

当前提交：fd295fa分支注释，9e408b2保存恢复，53e4f4f正式UCI。本轮分析面板/原生打包独立提交见git log。根33测试（含实际官方引擎，需环境）与分析通过；核心32通过；macOS原生3测试通过，包括包内NNUE、多PV切换和停止。

根main注入FileGameRepository与openBundledEngine；预览ChessNextApp默认内存仓库、无引擎，勿冒充持久化。游戏树schema1、2k节点/4MiB、可恢复bak，库不依赖账号。主App构建从.local打包校验/签名helper，工具tools/setup_pikafish.py准备制品；tools/bundle_pikafish.py限制只写build下Resources/pikafish，缺失制品时棋盘可用分析不可用。Debug稳定identifier，Sandbox始终开启。

重跑bash tools/check.sh；CHECK_MACOS_INTEGRATION=1额外原生窗口测试。根无引擎环境时仅live-adapter测试会skip，不能写成通过；check脚本为本机.local设置环境。普通flutter run -d macos恢复正常入口。不要自动终止用户旧窗口/未保存对局；不把测试构建仍留在磁盘当作已运行普通入口。

下一功能：F03 AI对弈，复用端口并与分析互斥；保留request generation与positionRevision过滤旧结果，所有落子必须走Session合法性校验。随后编辑/FEN导入导出/草稿/复盘，再后端和移动。全站未完成，不要发最终完成声明。

## M3-03接续

分析控制器已重命名为EngineSessionController，分析与AI共用单实例；旧analysis_controller.dart路径不再有效。AI功能41根测试和4原生测试通过；先完成本功能commit再继续编辑器。已审计站点E10：清空保留先手并留下黑将d9/红帅e0；初始局面重置红先；红黑互换为纵向映射rank=9-rank并换色、换先手；将帅照面显示提示，Done仍可点但拒绝提交。证据docs/research/editor-*-2026-11-02*。复制FEN toast出现但浏览器剪贴板API返回空，未把导出值算验证成功。后续编辑草稿必须独立，取消不改原文档，确认替换需保护dirty。

## 2026-11-02 / M2-07 / F05,F06 → B05 局面编辑

独立SetupDraft允许不完整局面，复用结构化校验；棋子盒按标准数量禁用、连续放子、拖动/拖出移除/右键移除、红黑先、清空/初始/互换、视图旋转/镜像。取消不改原棋树；脏棋谱可先保存；有效且变化的完成结果创建dirty新根。UI复用BoardSurface，领域不依赖Flutter。
验证：带官方引擎环境根flutter test46/46、flutter analyze无问题；核心dart test37/37、dart analyze无问题；原生macOS5/5通过（新增无效照面拒绝与有效黑先提交）；4组官方Pikafish perft一致（79666/1564/1100/46642）。首次analyze发现一处缺少大括号，修复后重跑通过。识图/FEN导入/编辑历史撤销仍后续切片，不标F06全量完成。

下一项F07/F12：FEN与UCI着法文字导入导出，合法性/非法输入定位/取消/脏数据保护；然后中文记谱与文件格式。工作树和提交以git为准。

## 2026-11-02 / M2-08 / F07,F12 → B19 FEN/UCI文字交换

领域TextRecord支持裸FEN（2/6字段）、position fen、startpos、moves着法；逐步合法性校验并定位错误步数，64k字符/1999步限制；失败不改会话。导入新树一次替换并标dirty；当前未保存棋谱可取消/替换/先保存。导出当前局面FEN或根至游标路径，明确不含其他分支/注释/后续；Clipboard独立端口，可选文字手动复制，权限失败不冒充成功。
验证：根flutter test48/48（带官方引擎环境）和flutter analyze、核心dart test40/40和dart analyze通过。原生macOS完整6/6通过。原生文字单项1/1已通过，AI变招曾一次等待超时，单项与最终完整6项复跑通过，保留偶发记录；修复测试重复输入前需显式重新聚焦文本框的问题；首轮失败保留记录，不认为格式解析成功即可冒充交互通过。中文/PGN/ICCS文件/URL/识图后续，不标F07/F12全量对齐。E11实际参考站点接受同一份自制两步FEN+着法。

下一项中文纵线记谱与文字导入：先读原作者xqbase着法规范，处理前中后/多兵编号/士象例外和合法候选唯一匹配；纯领域格式，不修改UCI存储和引擎通信。然后自动草稿与设置持久化。

## 2026-11-02 / M2-09 / F07,F12,F13 → B19 中文纵线记谱

新增纯Dart中文记谱格式化与合法候选唯一解析；红中文/黑全角数字，前中后/多列叠兵序号、同列士象例外、繁体及数字宽度别名。TextRecord接受编号中文序列及ICCS坐标；中文导出带根FEN和当前路径，不保存分支/注释。UI棋谱/变着显示中文，Tooltip保留UCI；引擎与存储格式不变。
验证：根flutter test50/50（官方引擎环境）与flutter analyze、核心dart test46/46与dart analyze通过。原生macOS6/6通过，含中文导入与中文棋谱显示。测试输入统一显式聚焦并验证EditableText实际值；生命周期trace保留在原生AI测试中。规范出处research/NOTATION_RESEARCH.md，公开示例只作协议测试，自造叠兵/士象局面与固定随机路径验证格式唯一可逆。首次误在Flutter根运行dart test已纠正为核心包目录，不把失败命令记为通过。
