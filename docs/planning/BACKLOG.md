# 待办

原始清单保留；最新状态以末尾各轮进度为准。B13通信已验证，B15规则首切片已实现，其余按阶段推进；B04按用户要求暂缓。

| ID | 内容 | 阶段 | 需求 | 验收 |
|---|---|---|---|---|
| B01 | 续审深层设置/账号/手机/格式与边界 | M0 | F01–F32 | FEATURE_GAPS每项有证据或明确阻碍 |
| B02 | 固定工具链、引擎与NNUE并做最小集成spike | M1 | F02,F24,F25 | 完整SHA/校验；CLI和移动FFI原始日志；无UI业务 |
| B03 | 规则与棋谱语义验证 | M1 | F01,F06,F23 | 规则profile、长将长捉用例、领域与引擎差异表 |
| B04 | 许可与iOS分发决策 | M1 | 全部 | 项目许可、权重来源、商店方案ADR可审查 |
| B05 | 棋盘/编辑增量 | M2 | F01,F04,F05,F06 | 合法性/取消/脏数据/无障碍测试 |
| B06 | 棋树与离线仓库 | M2 | F07,F10,F13,F18 | 分支注释草稿事务与迁移恢复测试 |
| B07 | 引擎调度与对弈 | M3 | F02,F03,F22–F25 | stop竞态、终局、变招、崩溃恢复通过 |
| B08 | Material3与设置工作区 | M3 | F19–F29 | 明暗/200%字号/布局/键盘/持久化验收 |
| B09 | 局势与整谱复盘 | M3 | F14,F32 | 取消重启、分析版本记录和评分视角一致 |
| B10 | 在线端口与认证/同步 | M4 | F09,F15–F17,F30 | 替换实现、断网/限流/冲突契约测试 |
| B11 | 格式导出与分享 | M4 | F08,F11,F12,F31 | 自制授权样本round-trip与损失提示 |
| B12 | 五平台发行矩阵 | M5 | 全部 | 源码包/SBOM/许可/安装升级和实机报告 |

## 2026-11-01 调整与新增（旧ID不重排）

B01仅续审离线边界，登录后审计延期；B02桌面通信部分已验证，移动/其他桌面未完成；B04新增NNUE非商用门槛；B10整体延期。B05–B09/B11/B12按新版离线范围执行。

| ID | 交付与依赖 | 可执行切片及验收 |
|---|---|---|
| B13 | 最小Flutter通信（B02子项，本轮） | 官方制品校验→真实UCI/NNUE/MultiPV→100轮stop/quit；日志可重跑；诊断工程不充当生产适配器 |
| B14 | 生产引擎端口/移动FFI（依赖B13） | 类型化option/info事件→串行命令与epoch→超时重启→Android/iOS最小原生构建；内存所有权和销毁实测 |
| B15 | 领域与规则（B03/B05） | 坐标/FEN→合法走法/将军→终局/重复裁决；手工规则fixture与perft交叉核验；别把bestmove正则当合法性验证 |
| B16 | 文档和存储（B06） | 稳定棋树ID/分支注释→SQLite事务/迁移→自动草稿/显式保存→重启恢复；断电与磁盘失败测试 |
| B17 | 对弈与分析（B07/B08） | 单局分析/多PV→执方与双AI→催招/变招→参数预算；模式互斥/迟到结果/候选耗尽可恢复 |
| B18 | 离线整谱复盘（B09） | 按节点队列→可取消/续算→前后分数/损失→局势曲线/错题收藏；缓存key含引擎/权重/规则/预算 |
| B19 | 文件及本地库（B11） | PGN/FEN/中文→XQF→CBR/CBL/东萍逐项→图片/GIF→检索/最近阅读；格式有损显式告知 |
| B20 | 五平台体验（B12） | M3/明暗/字号/键盘→文件/菜单/生命周期→安装升级/迁移；平台逐项打勾，未测不算通过 |

优先次序：B13→B14移动spike与B15设计→B15/B16→B17→B18/B19→B20。许可证B04贯穿，发行前必须关闭。每个实现切片先写验收，再最小实现和针对性测试。

## M2-01实际进度

用户已授权开始离线业务实现，B04按要求暂缓处理，不阻挡本地开发。B13已验证，B14待实施；B15首切片已实现并通过11个测试/4组perft对照，其余终局、语义校验、历史裁决仍待做。没有把整个B15或M2标为完成。下一切片为局面语义校验→终局与历史接口→B16棋树/会话。

## M2-02 / F06 → B15 编辑局面校验

基线b3b423a已提交。新增validateForPlay结构化错误、坐标定位和不可变结果；检查数量、将士象落点、兵卒初始路径与未过河同路重复、将帅照面、非行棋方被将军。新增9个纯Dart测试及3个Flutter契约测试。bash tools/check.sh：根Flutter5/5与analyze通过，纯Dart20/20与analyze通过，引擎2/2与analyze通过。规则包新增独立analysis_options，避免继承Flutter lint依赖。完整历史可达性/长将长捉未实现；不把B15整项标完成。

## M2-03 / F01 → B15 将死与困毙

编辑局面校验已提交9b515d2。本切片新增boardOutcome：进行中/将死/困毙和胜方，拒绝无效编辑局面；困毙同样判负。新增6个纯Dart与2个Flutter契约测试，验证红黑困毙、将死、被将但可逃、无效局面和正常开局。bash tools/check.sh通过：根flutter test7/7与flutter analyze无问题；规则dart test26/26与dart analyze无问题；引擎flutter test2/2与flutter analyze无问题。历史裁决未实现，B15整体仍未完成。下一切片B16棋树/会话。每个功能单独中文规范提交，不在未测试平台标记通过。

## 2026-11-01 / M2-04 / F01,F04,F05 → B05 macOS棋盘

用户要求实际flutter run -d macos，优先落地Material3主App与线性内存会话：选子/合法落点/非法提示、轮换、单步悔棋、翻转、新局确认、UCI记录、终局、主题、键盘/语义和窄屏大字。非B16完整棋树，不含持久化或AI界面。

验证：flutter test11/11、flutter analyze无问题；规则26/26及分析、引擎2/2及分析通过；macOS原生集成测试1/1通过；普通flutter run -d macos首次及从测试重建回普通入口后均成功。Computer Use无权限，截图/人工检查未做；自动置前失败，但Flutter连接及App进程工作正常。尝试detach后终端关闭导致App退出，随后重新flutter run并保留开发会话。

修复过程：首轮测试暴露测试API误用与非法落点fixture误选己方棋子，修正后通过；集成测试要求Podfile，补SDK模板与Pods配置引用；后续重建在_libsecinit_appsandbox等待，确认为本地adhoc cdhash签名变化，Debug使用独立稳定identifier dev.chessnext.app后测试/普通启动均通过。Sandbox始终开启，未更改系统隐私权限或删除用户容器。详细运行指南planning/MACOS_RUN.md。

## M2-05 / F13 → B16 棋谱分支与注释

不可变GameTree、稳定ID、路径/游标、重走复用、主线提升、删除子树；session和UI实现分支选择/注释/前后首尾导航。导航不增加内容revision；新局保护独立于游标。根flutter test13/13、flutter analyze无问题；核心dart test30/30、dart analyze无问题。独立提交后继续磁盘保存。未宣称格式、存储或全站对标已完成。

## M2-06 / F10,F16本地部分 → B16 保存与恢复

新增版本化棋树JSON及损坏/重复/循环/非法着法校验；路径受限的文件仓库、同FS快照提交和旧版备份、可替换内存仓库、并发dirty/epoch/positionRevision保护。本地库可保存命名、搜索和重新打开分支/注释/游标。新增path_provider2.1.6及锁文件。
验证通过：根flutter test23/23与flutter analyze；核心dart test32/32与dart analyze；macOS原生集成2/2含真实Documents子目录保存与新App实例恢复。测试发现并修复弹窗initState通知父树造成build期setState，以及序列化节点顺序不稳定。ADR-005记录单窗口/文件大小/节点限制及未验证的持久性边界；不是网站账号同步，不宣称F16全量完成。

## M3-01 / F02,F24,F25 → B14 正式UCI适配器

新增EngineGateway、EngineRequest/Info/Option/Search、异步Process运输与UCI协议状态机。串行命令、旧搜索stop/bestmove屏障、参数能力检查、EOF/超时、stderr排空和销毁；区分原始侧分cp/mate/bound，不直接让UI调用进程。新增5个可控假引擎/解析测试与1个真实官方NNUE测试。显式设置引擎路径后根flutter test29/29、flutter analyze无问题；真实搜索深度8/多PV/5轮停止验证通过。主UI接入仍下一切片，不标整个F02完成。
用户回复：在线能力采用自建可替换后端并提供部署方案，后续纳入主计划。

## 2026-11-02 / M3-02 / F02,F24,F25,F26 → B17 主界面本地分析

AnalysisController/EngineFactory隔离UI与进程；100ms合并分析更新，150ms局面导航去抖，generation/positionRevision丢弃过期结果，后台停搜。面板支持原始cp/mate/bound到红/黑视角归一化、深度/秒/NPS、多路PV、参数与棋盘推荐/回复箭头，宽屏棋盘和侧栏独立滚动。参数暂为内存配置，不冒充设置持久化。
macOS构建从.local校验制品hash、复制资源并签名继承沙箱helper；不将二进制/NNUE提交Git。带实际引擎环境根flutter test33/33、flutter analyze无问题；macOS原生3/3（包内NNUE、PV2、停止验证）；helper脚本Python语法和pbxproj语法通过。2026-11-02官方latest仍为2026-09-06。F02历史/复制等子功能仍未全验收；下一AI对弈，整体对标继续。

## 2026-11-02 / M3-03 / F03 → B17 AI对弈

单引擎EngineSessionController统一模式，新增执方/双AI、用时、催招/变招、双步悔棋、回合输入锁和旧结果过滤；searchmoves子集通过Fake及实际Pikafish验证。EngineRequest.fromTree减少UI重复重放历史。根flutter test41/41（官方引擎环境）、flutter analyze无问题；macOS原生4/4通过含真实AI回复/换着/悔棋/停止。此增量不含棋力等级、设置持久化和云库下棋，不标整站完成。

## 2026-11-02 / M2-07 / F05,F06 → B05 局面编辑

独立SetupDraft允许不完整局面，复用结构化校验；棋子盒按标准数量禁用、连续放子、拖动/拖出移除/右键移除、红黑先、清空/初始/互换、视图旋转/镜像。取消不改原棋树；脏棋谱可先保存；有效且变化的完成结果创建dirty新根。UI复用BoardSurface，领域不依赖Flutter。
验证：带官方引擎环境根flutter test46/46、flutter analyze无问题；核心dart test37/37、dart analyze无问题；原生macOS5/5通过（新增无效照面拒绝与有效黑先提交）；4组官方Pikafish perft一致（79666/1564/1100/46642）。首次analyze发现一处缺少大括号，修复后重跑通过。识图/FEN导入/编辑历史撤销仍后续切片，不标F06全量完成。

## 2026-11-02 / M2-08 / F07,F12 → B19 FEN/UCI文字交换

领域TextRecord支持裸FEN（2/6字段）、position fen、startpos、moves着法；逐步合法性校验并定位错误步数，64k字符/1999步限制；失败不改会话。导入新树一次替换并标dirty；当前未保存棋谱可取消/替换/先保存。导出当前局面FEN或根至游标路径，明确不含其他分支/注释/后续；Clipboard独立端口，可选文字手动复制，权限失败不冒充成功。
验证：根flutter test48/48（带官方引擎环境）和flutter analyze、核心dart test40/40和dart analyze通过。原生macOS完整6/6通过。原生文字单项1/1已通过，AI变招曾一次等待超时，单项与最终完整6项复跑通过，保留偶发记录；修复测试重复输入前需显式重新聚焦文本框的问题；首轮失败保留记录，不认为格式解析成功即可冒充交互通过。中文/PGN/ICCS文件/URL/识图后续，不标F07/F12全量对齐。E11实际参考站点接受同一份自制两步FEN+着法。
