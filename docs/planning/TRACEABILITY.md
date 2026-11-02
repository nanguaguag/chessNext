# 需求追踪

需求→证据与模块见 FEATURE_MATRIX；需求→待办见 BACKLOG；待办→阶段见 MILESTONES。本文件定义验证分组，不代表已通过。

| 测试组 | 需求 | 证据 | 验收方式 |
|---|---|---|---|
| T01 规则/棋盘/编辑 | F01,F04–F06,F23 | E01,E03,E08 | 纯领域用例+组件/触控实测 |
| T02 搜索/对弈/资源 | F02,F03,F22,F24,F25 | E01,E02,E08 | 真实UCI+fake竞态+五平台 |
| T03 文档/格式/仓库 | F07,F08,F10–F13,F16,F18 | E04–E06 | 自制样本往返+事务/迁移 |
| T04 复盘/训练 | F14,F17,F32 | E01,E07,E09 | 评分基准+取消恢复+练习流程 |
| T05 云端/识别/认证 | F09,F15,F30 | E01,E04 | 可替换服务contract+离线/隐私 |
| T06 体验/支持 | F19–F21,F26–F29,F31 | E01,E08 | 明暗/字号/键盘/读屏/平台菜单 |

每次实现新增记录：F-ID、证据版本、ADR、变更提交、测试名称/命令、平台、结果、未解问题。无提交/命令不得填通过。本轮所有 T 组未执行。

## 离线修订

纳入/延期映射见 OFFLINE_SCOPE（覆盖F01–F32）；增量见B13–B20。T02真实引擎通讯子集现已通过Flutter test，日志 docs/engine/evidence/flutter-test-uci.log；它不覆盖对弈业务、领域合法性、FFI或其他平台，其余T组仍未执行。

## M2-01验证记录

F01/F06/F07 → B15首切片 → packages/xiangqi_core → T01规则/FEN子集：dart analyze通过，dart test 11/11通过；python3 tools/verify_xiangqi_perft.py四组逐分支一致，见 engine/evidence/xiangqi-perft.json。平台为macOS上的Dart3.12.2 VM，未声称五平台运行。领域规则不依赖Flutter。终局/历史/编辑语义校验未覆盖，整个F项仍未完成。仓库无提交ID，变更均未提交。

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

## 2026-11-02 / M2-09 / F07,F12,F13 → B19 中文纵线记谱

新增纯Dart中文记谱格式化与合法候选唯一解析；红中文/黑全角数字，前中后/多列叠兵序号、同列士象例外、繁体及数字宽度别名。TextRecord接受编号中文序列及ICCS坐标；中文导出带根FEN和当前路径，不保存分支/注释。UI棋谱/变着显示中文，Tooltip保留UCI；引擎与存储格式不变。
验证：根flutter test50/50（官方引擎环境）与flutter analyze、核心dart test46/46与dart analyze通过。原生macOS6/6通过，含中文导入与中文棋谱显示。测试输入统一显式聚焦并验证EditableText实际值；生命周期trace保留在原生AI测试中。规范出处research/NOTATION_RESEARCH.md，公开示例只作协议测试，自造叠兵/士象局面与固定随机路径验证格式唯一可逆。首次误在Flutter根运行dart test已纠正为核心包目录，不把失败命令记为通过。

## 2026-11-02 / M2-10 / F10,F18本地连续使用 → B16 自动草稿与恢复

新增DraftRepository、FileDraftRepository和DraftController；独立目录active检查点，300ms去抖、不可变快照串行写入/排队更新、初始化提示、dirty替换确认、未保存副本恢复、空新局检查点、失败重试。草稿不清dirty、不写棋谱库、不恢复AI角色。文件适配器重写损坏主文件前保留原件目录，备份机制复用ADR-005。
后台flush与正常退出请求等待；无法保护最新dirty时可返回重试或明确继续退出。ADR-006记录强杀/断电/最后300ms与单窗口边界，不承诺零丢失。
验证：根flutter test58/58（官方引擎环境），flutter analyze无问题；新增串行写入/读取竞态/失败/新局/销毁、真实临时文件备份损坏恢复和隔离、Widget恢复与退出回调失败保护。macOS自动草稿单项1/1通过（真实沙箱Documents新App实例重开）；完整macOS7/7通过。首轮补正AppExitResponse的dart:ui导入与构造器字段、lint大括号及mounted检查，不将失败命令记通过。未做真实断电或OS强制退出。

## 2026-11-02 / M3-04 / F22,F24,F25,F27部分 → B08 设置持久化

AppPreferences/schema1与PreferencesRepository，ApplicationSupport独立文件、备份/损坏原件保留、读取失败默认值/明确重试；主题/线程/Hash/MultiPV/AI用时持久化，旧参数面板更改同样保存。初始化逐字段合并并发编辑，串行最新值写入，退出flush等待初始化，不恢复AI角色。握手后按设备/引擎能力钳制；主题改变不重启搜索。Material3统一设置对话框含200%窄窗/NaN校验。
ADR-007/008记录设置及桌面生命周期：桌面inactive仍可见不取消，hidden取消，移动inactive取消。增加相应回归和原生事件trace，后台持久化照常。
根flutter test67/67（官方引擎环境）与flutter analyze通过；macOS原生8/8通过，交互fixture保持框架resumed，真实OS焦点/最小化不在其验收范围。初轮测试发现dispose期间flush通知已defunct根元素，修正为先移除根监听再flush；补正扩展导入和测试生命周期hidden→inactive→resumed序列，保留失败事实。未新增依赖。语言、字号持久化、资源预设、外观声音等仍未实现，不标设置全量对齐。

## 2026-11-02 / M3-05 / F32前置 → B14/B18 组合搜索预算

EngineRequest两个工厂均支持depth + moveTimeMs + nodeLimit并存，全部null才无限搜索；UciEngine按组合输出go，searchmoves仍最后。0不是端口无限值，UI后续把0明确映射null。应用策略上限为255深度/24小时/2^53-1节点，非引擎最大有效能力声明；非法值在发送前拒绝。
验证：带官方NNUE环境根flutter test69/69、flutter analyze通过。真实CLI分别用松弛的另两项预算验证深度、时间、节点限额生效；节点按引擎周期检查，可超出精确值，测试不声称硬实时。macOS原生9/9通过，新增应用包内签名helper/NNUE组合预算提前在节点界限结束。原生仍用framework-resumed交互fixture，此轮记录真实宿主hidden/inactive事件，未计作OS生命周期视觉验收。未更改UI或核心规则；整谱队列/曲线仍下一切片。

## 2026-11-02 / M3-06 / F02,F03,F32前置 → B14/B18 会话资源复用

EngineRequest.gameId文档epoch与token分离；(gameId,rootFen)变化才ucinewgame，同文档仅发改变的Threads/Hash/MultiPV。资源/上下文变化保留ready屏障，任何下一搜索仍等旧bestmove。App分析与AI均传epoch，根FEN兜底区分，失败新进程冷启动。
验证：根flutter test72/72（官方引擎环境）与flutter analyze通过，macOS原生9/9通过（交互fixture保持resumed）。新增参数ready屏障、命令数量和分析/AI文档epoch回归；原有实际NNUE/组合限额/stop行为通过。微基准校验官方hash后，1线程64MB深度10、各预热1+10次交替重复局面：强制冷重设41.021ms中位、同文档暖0.920ms；仅特定工作负载，不宣称通用提速/棋力/≤5%裸引擎开销。JSON及重跑工具见engine/RESOURCE_REUSE.md。工具初次analyze相对lib导入/缺大括号已修，未记录成通过。ADR-009固定语义。

## 2026-11-02 / M2-11 / F01,F13 → B05/B16 完整线路读谱

GameTree.currentLine含所选变着与游标之后主线；lineAnchor只读导航元数据，在回退/首尾时保持分支。schema1可选字段兼容旧快照，拒绝缺失节点/跨线路游标等损坏组合，删除锚点安全回退。MoveList可点击/选中、中文语义/坐标/注释标记、自动滚动及虚拟构建。普通读谱导航暂停AI，一步前后与对弈双步悔棋分离；迟到stop不能覆盖后来的人工落子。
验证：根flutter test76/76（官方NNUE环境）与flutter analyze无问题，核心dart test49/49和dart analyze通过；千着在普通与200%字号挂载ListTile<30、选中可见、无布局异常，不作帧率承诺。原生macOS完整10/10通过，最终读谱单项又1/1通过（受控framework-resumed前提）；新增点未来着、回退保持分支、当前线路下一着。初轮3处大括号lint已修并重跑通过。未新增依赖。ADR-010区分项目读谱策略与源站尚未验证细节，未宣称F01/F13全部对齐。

## 2026-11-02 / M2-12 / F13 → B16 当前着分支面板

VariationPanel分开当前着同级与下一着子节点，中文/坐标/选中/主线、提升/删除、有界列表和200%字号。提升已主线为无操作；确认删除绑定文档epoch+内容revision，等待AI停止后再删，迟到落子及新编辑均保护。取消保留原树。
验证：根flutter test81/81（显式官方NNUE环境）、flutter analyze无问题；核心dart test49/49与dart analyze无问题；完整macOS11/11通过，新增同级切换/置顶不跳节点/取消/删除子树。原生保持framework-resumed前提、真实OS焦点/视觉仍未验。日志/tmp/chessnext-variants-{test,analyze,core,native}.log。无新增依赖。建议试走、复盘缓存等仍后续，不标F13完整。

## 2026-11-02 / M3-07 / F32 → B18 单引擎整谱队列

ReviewLimits/ReviewRun/ReviewedPosition与EngineSessionController.engine_review：当前线路含未来/整树唯一节点、子节点先处理、有限组合限额、单路最佳着法、原始cp/mate/bound与执方、进度/结果跳转。分析/AI/设置/后台可抢占，同一引擎停止屏障；取消保留完成部分，stopping期间禁用按钮。内容revision/epoch变更使结果过期并停止，纯读谱不改变队列快照。未取得评分与终局不伪造0，失败可重试。当前只会话内存结果。
根flutter test94/94（显式官方NNUE，含真实四局面分支复盘）、flutter analyze无问题；macOS完整12/12通过，包内NNUE整树四局面、配置/结果跳转与深搜取消。核心未改，沿用上轮49/49。新增11应用/真实引擎测试、2组件测试；NaN/全0/200%字号、迟到结果、停止屏障/文档修订/重用ID/互斥/同步监听取消均覆盖。日志/tmp/chessnext-review-{unit,widget,test,analyze,native}.log。首轮6处lint与测试TextFormField无decoration编译错误已修复，未记为通过；后有1处测试if lint同样修复重跑。原生仍为framework-resumed前提，OS焦点/视觉及其他四平台未验。
ADR-011固定所有权与临时结果边界。曲线、彻底候选、缓存、胜率等级/错题仍后续，不标F32全量完成。

## 2026-11-02 / M3-08 / F32 → B18 红方评分曲线

ReviewChart显示所选完整线路、原始cp归一红视角/±10兵绘图封顶、mate三角、bound箭头、缺失断线；mate0仅文字不画成普通0分。点击最近节点、方向/Home/End、语义增减与Material滑块跳转，显示真实未截断数值；过期结果不提供曲线导航。原始数据不变，不使用伪胜率或准确率。
根flutter test97/97（官方NNUE环境）、flutter analyze无问题；macOS整谱复盘/曲线键盘/取消目标单项1/1通过，上一切片完整12/12。核心未改沿用49。新增3图表数据/交互/200%字号测试。首轮发现语义increase/decrease必须声明相邻值、单点Slider语义越界，已修并复跑通过；初轮lint/多余非空断言亦修复。日志/tmp/chessnext-chart-{widget,test,analyze,native}.log。真实OS键盘焦点/视觉未人工验收，不把fixture等同系统焦点。
下一条引擎/NNUE可追溯身份→独立复盘缓存与跳过已有，再彻底候选、等级与错题；其余对标继续。

## 2026-11-02 / M3-09 / F24,F25,F32前置 → B14/B18 引擎身份

EngineIdentity与可空Gateway.identity/name；UCI名称仅来自握手。bundle脚本验证源制品后在helper签名完成时写identity.json，区分源与实际执行文件hash。verifyEngineBundle在工作Isolate流式校验实际二进制/NNUE，附运行ABI，再启动进程；缺失/损坏明确失败。任意外部UCI默认无已验证身份，仍可分析，不猜测缓存身份。
根flutter test104/104（官方NNUE环境）、flutter analyze无问题；macOS包内身份/实际NNUE组合预算单项1/1通过（上一完整12/12）。新增6身份/文件校验测试、1握手名称测试；损坏二进制/权重、manifest缺失/超限/类型和schema覆盖。tools/bundle_pikafish.py编译通过。运行实际签名hash3d122594479220cfb2fd85771e3f48b89d5316edc4326adb05ed5825cd8a7338，与源3a11f9…区分，NNUE未改。初轮6条大括号lint修复重跑，不记初轮为通过。
crypto3.0.8经官方pub页核实，由既有传递依赖改直接依赖，版本不变；SHA/许可登记legal/LICENSING。无引擎源码更改。日志/tmp/chessnext-identity-{test,analyze,native}.log。身份不是完整缓存功能，下一条独立复盘缓存/跳过已有。

## 2026-11-02 / M3-10 / F32 → B18 会话缓存与跳过已有

ReviewCacheRepository/2048条内存LRU、稳定完整历史/身份/预算/规则版本SHA256键；仅完成且无bound评分可复用，PV全路径重验，剔除token/节点/文档/导航/注释。队列完成握手后钳制资源，支持跳过开关及强制重算；identity未知不复用。缓存IO限2秒、失败后本任务停用并继续真实计算，取消/文档变化丢弃迟到读取；无评分/终局/部分结果不伪造命中。
根flutter test112/112（官方NNUE环境）、flutter analyze无问题；macOS整谱/缓存/曲线/取消单项1/1通过，同一四局面棋树重算cachedCount4且info.token0证实复用（上一完整12/12，不算本功能完整套件重跑）。核心未改沿用49。新增7缓存条件/失败/LRU测试和1跳过开关组件测试；初次测试fixture函数与getter同名编译错误、对话框缺第三参数及lint修正后通过，失败未记通过。早期目标回归未设置引擎环境所以跳过1项，其结果不计真实NNUE通过；最终全量显式环境全112通过。日志/tmp/chessnext-cache-{unit,regression,test,analyze,native}.log。
ADR-012固定缓存语义，本切片退出仍丢失；下一条独立文件缓存适配器/重开复用，不能宣传跨重启已完成。

## 2026-11-02 / M3-11 / F32 → B18 复盘文件缓存

FileReviewCacheRepository正式main注入ApplicationSupport/chessnext-analysis-cache。schema1/SHA256 envelope/key/类型数值/PV大小/单条64KiB、2048条/32MiB、当前实例LRU与重开写入时间近似恢复；串行暂存flush+rename、遗留暂存清理、坏项删除后明确降级。文件缓存与用户棋谱/草稿/偏好隔离，应用层重验完整PV；未知身份/不完整评分仍不持久命中。
根flutter test119/119（显式官方NNUE）、flutter analyze无问题；macOS完整13/13通过。新增真实ApplicationSupport下新App/Controller/Repository/Engine实例复用3个NNUE局面，损坏一条后继续真实重算且棋谱节点保持；这是新应用对象和新引擎进程，宿主Flutter测试进程未退出。独立Dart进程write/read协议探针PID49478/49527通过，fixture仅验证存储协议，原始结果engine/validation/cache-process-2026-11-02.jsonl。未做人工OS关开/断电。
新增7文件缓存测试覆盖重开、checksum/UTF8/schema/key/partial/数字/PV、容量/LRU、串行/写入障碍、暂存、路径/符号链接。首次测试漏EngineInfo导入、原生漏dart:io导致编译失败，修复后全量门槛重跑通过，不记初轮为通过。日志/tmp/chessnext-file-cache-{unit,test,analyze,native,process}.log。核心未改沿用49/49与dart analyze。无新依赖。
详engine/REVIEW_CACHE与ADR-012续记。下一条F32彻底候选/建议试走，需补证可接受阈值和候选预算；胜率/准确率算法仍未知，不自造同公式声明。

## 2026-11-02 / M3-12 / F13,F32 → B18 单步父局面候选与试走

CandidateRun/engine_candidates/CandidatePanel及配置：当前着父局面（根节点自身）、有限每候选预算、逐次排除合法首着、2..256候选策略、原始cp/mate/bound/无评分、进度/取消/失败/过期和缓存复用。源站可接受阈值仍U，不宣称同筛选/胜率算法。共享单引擎batching互斥；无bestmove保留真实原因，PV首着不匹配不赋分，非法/重复bestmove失败。
BoardSession.playVariation原子创建/切换同级，已有节点/当前着不产生多余dirty，保留旧分支与注释；控制器等stop后重新验epoch/revision/positionRevision/generation，停止失败或新操作不试走。清理取消后迟到失败的opening Future，下一次启动可重试。ReviewCacheAccess抽取整谱/候选共用缓存IO与允许集/PV校验。
根flutter test135/135（显式官方NNUE环境）、flutter analyze无问题；macOS完整14/14以及最终候选单项1/1通过。新增13应用/真实NNUE测试+3组件测试，含父历史/唯一候选/无分/停止/互斥/旧ID/缓存迟到、原子通知、当前着无操作、stop失败/late factory失败重试/0候选原因、NaN/全0/数量/200%字号。真实包内NNUE黑方父局面候选→试走同级→旧分支保留→重算复用2候选。核心未改，沿用49/49及dart analyze。
首次全量133通过1失败：旧注释导航测试直接点击被AppBar遮挡的按钮，hit-test告警后未导航；修为ensureVisible/pumpAndSettle并断言hitTestable，复跑134通过；最后增加无bestmove原因回归后135通过。早期目标缓存回归17通过/1live未设环境跳过，不算真引擎通过；最终显式环境覆盖。最初11条lint已修，失败均保留。日志/tmp/chessnext-candidates-{unit,widget,test,analyze,native,native-target}.log。ADR-013。
下一条整谱多候选模式，先把单次有限搜索/缓存/最终PV校验抽成可复用执行器，防止队列与单步各维护一套循环；仍单引擎所有权。胜率/准确率/错题及其他功能继续，不标整站对齐。

## 2026-11-02 / M3-13 / F32前置 → B18 有限搜索执行器

FiniteSearchExecutor统一整谱与单步候选的单次有限单PV、缓存、token/允许集/最终bestmove-PV匹配和完整PV合法性，临时订阅在finally等待清理；取消/流异常不泄漏。移除控制器两套后台info捕获。ReviewCacheRepository.remove使格式正确但PV不适用的缓存失效，只删派生缓存key，不碰棋谱。未新增整谱多候选UI，下一切片THOROUGH_REVIEW_SLICE仍P。
根flutter test142/142（显式官方NNUE环境）、flutter analyze无问题；macOS完整14/14通过。原有31项应用/真实NNUE回归通过，新增6执行器契约和1文件失效测试（文件目标套8、合计14目标）。非法最终着法/排除集、PV不匹配/非法、流错误/取消监听清理/坏PV移除覆盖。核心未改沿用49/49。
初轮固定Widget帧等待出现2失败并停滞，INT自有根测试进程52684（非用户run），未记通过；有限pump仍4失败。临时TRACE定位等待subscription.cancel，Fake网关来自真实zone，单推进模拟时钟无法收尾。pumpUntil增加有界真实runAsync与模拟帧后6组件通过，最终全量142通过。临时TRACE已恢复移除。首次fixture把黑车a9a8误认非法已纠正；8条lint及1无用测试import修复，最后analyze通过。日志/tmp/chessnext-finite-{regression,unit,widget,test,first-test,zone-trace,analyze,native}.log。
本次为整谱多候选的复用基座，不把重构当新产品功能或全量F32完成。下一步按THOROUGH_REVIEW_SLICE推进模式/节点候选集合/部分结果/计数与详情。

## 2026-11-02 / M3-14 / F32 → B18 整谱多候选模式

CandidateCollector共用FiniteSearchExecutor，单步/整谱不再维护两套逐次排除循环。ReviewMode最佳/多候选、2..256策略/每候选有限预算；line/tree不变。ReviewRun.candidateResults保存不可变complete/partial集合，results仅含收尾局面；第一无约束候选无分则主分无分，不取后续受限分数替代。局面复用数与候选查询命中数分开，命中后又实际空搜索不算整个局面全复用。统一100ms batchInfo只显示合法job/token，结束/取消/失败清计时器。只读候选详情和partial大字滚动，不自动落子。
根flutter test151/151（显式官方NNUE）和flutter analyze无问题；macOS完整15/15通过。新增7多候选应用/真NNUE及2组件测试；实际四分支局面×2候选、详情、再次命中4局面/8搜索。旧31应用/NNUE回归通过，partial取消、缓存模式/上限变更、首评分、读谱/编辑、空搜索、数量/200%验证。核心未改沿用49/49。初期2条静态问题（模型移出后unused import、单条大括号）修复后通过，无最终失败。原生运行中持续info会更新帧，局部tapVisible在batching期间用有界pump，静态表单仍settle；不是更改生产生命周期或OS焦点。日志/tmp/chessnext-multi-{regression,unit,widget,test,analyze,native}.log。
ADR-014解释子查询缓存与集合完成条件；源站可接受阈值/准确率公式仍未知，不标F32全部完成。下一条原生WDL胜和负数据链路，再复盘损失/分类/错题等。

## 2026-11-02 / M3-15 / F02,F26,F32 → B14/B18 原生WDL

WdlEstimate严格胜/和/负三整数总1000、视角反转/预期得分；EngineInfo可空、坏可选统计保留CP。EngineRequest.preferWdl向后默认false，App各搜索请求true偏好，UciEngine能力check/只变更/ready确认/不支持回退。缓存optional元数据和独立偏好键、CP旧格式兼容，支持WDL但缺请求数据不算完整命中；文件重开保留。分析面板显示模型胜和负，单独标和棋半分的预期得分，bound/mate不附普通概率文本。
根flutter test162/162（显式官方NNUE）与flutter analyze无问题；macOS完整15/15通过，真实包内MultiPV及WDL展示、缓存/整谱等回归。新增5类型/解析/视角/缓存测试、3UCI选项/缺能力/ready超时测试、1真NNUE双先手、1文件重开和1组件视角/200%/bound测试；目标32/32通过。初轮1处lint修复；序列化wdl误混整数统计字段在静态复核纠正后roundtrip通过，未有最终失败。日志/tmp/chessnext-wdl-{unit,target,test,analyze,native}.log。核心未改沿用49。
ADR-015。原生探针8行总1000/quit0另见协议归档；此功能只提供引擎模型数据，不声称网站胜率/准确率同公式或完整F32。下一预期损失/等级与错题；所有其他缺项继续。

## 2026-11-02 / M3-16 / F32 → B18 模型着法评级报告

实现：ReviewReport纯应用层快照，原生2*wins+draws整数预期损失；完成同父候选优先/后续换视角/真实终局，缺失/bound/mate/视角不匹配不评级；双方面板/均值分母/筛选/来源Tooltip、虚拟列表与epoch+revision跳转保护。ADR-016，项目明确版本，不宣称源站准确率或完整F32。

验收：7模型测试（阈值等号/非法值/双方视角/候选优先与partial/零损失/缺失与无WDL/mate/bound/错视角/困毙），3组件测试（筛选跳转不dirty、复用节点ID过期保护、200%字号与空分母）；目标10/10通过。根全量显式官方NNUE `flutter test --reporter expanded`172/172；`flutter analyze`无问题。macOS完整 `flutter test integration_test/local_board_test.dart -d macos`15/15，扩展真实多候选流程：打开评级/关问题筛选/跳n1，revision不变。其它平台未验；OS焦点人工测试未验。

首analyze6项nullable/大括号、后1项多余!警告，修复后无问题；首目标测试因API构造错误未编译，修后8通过2失败（夹具n2的b2e2落到己方炮），换合法b0c2后10通过，未削弱执行器。详细会话日志见SESSION_LOG。核心未改沿用49/49，不重复宣称本次新跑。

## 2026-11-02 / M2-13 / F18 → B06,B19 本地最近阅读

RecentReading纯元数据/根+整条路径恢复，独立控制器绑定已保存库ID+documentEpoch、50条去重前置/300ms/晚到加载合并/失败禁止覆盖/串行重试；文件schema1/2MiB/有效备份/坏主归档与独立目录，App生命周期flush。列表空/错/重试/dirty确认再核验版本/虚拟化/200%字号。普通库打开沿用保存位置，最近阅读使用标记；不存未保存内容，不改原谱modifiedAt/内容dirty。

首目标15/15（8应用+3文件+4组件），补库刷新文档绑定/另存ID保护后根全量真NNUE188/188；flutter analyze无问题。macOS完整测试含新实例阅读位置用例进行中，结果补末尾。ADR-017；E17只确认参考空态，本实现为离线设计，不称同网站内部算法或五平台已验。

M2-13补记：新增库刷新不能重绑旧ID与备份/路径双提示，最终10应用+3文件+4组件=17新增；根真NNUE189/189。macOS完整16/16（02:07），含新App/Repository实例从n2保存位置独立恢复n0，原棋谱n2不变；这不是实际OS进程重启。最终提示聚合修订后再跑原生最近阅读单项，结果见后续。初原生未编译/静态问题记录SESSION_LOG；核心未改49沿用，不标其它平台已验。
M2-13最终：提示聚合采用Dart当前null-aware语法后，根真NNUE189/189、flutter analyze无问题，原生最近阅读单项1/1（00:07）通过。完整16在此前已过；无待等待验证命令。未解决网站/其它平台/人工OS门槛继续保留。

## 2026-11-02 / M3-17 / F29 → B08 离线使用帮助

AppBar帮助入口与独立OfflineHelpDialog，原创实际控件说明/9主题/标题和正文大小写无关搜索/清空/空结果/折叠/可选文字/有界列表/键盘关闭。没有仓储、引擎或网络依赖；不把尚未实现格式、网站公式或在线能力写成已可用。方案OFFLINE_HELP_SLICE；手动分步引导和首次提示另片，未标全F29。

新增3组件测试：正文搜索/空态/清空、折叠/Escape与重复打开/文档对象和revision不变/零引擎初始化和棋谱仓储调用、520×700与200%字号滚动。目标3/3，全根真NNUE192/192，flutter analyze无问题。macOS原生首测试增加实际窗口入口/搜索/关闭后树对象不变，结果补末尾。核心无改动沿用49；不重复未改引擎的全原生16，最近阅读切片已完整验证。
M3-17最终原生macOS首测试1/1（00:06）通过；帮助入口/最近阅读搜索/关闭后GameTree对象完全相同。无待等待验证命令，不等于人工OS视觉或其它平台验证。

## 2026-11-02 / M3-18 / F29 → B08 四步引导与首次记忆

Material3四步只读教学/前后/跳过/完成/手动重放，App/main生产显式启用首次；等偏好成功加载、版本未确认且无用户模态才自动打开，完成或明确跳过才记；Escape中断不记。可选schema1 guideVersion旧0/当前1/未来不降，DTO/equality/copy及逐字段晚到合并；普通设置当前copyWith保存不清标记。坏读不因教学覆盖原件，写失败Snackbar重试。不会启动引擎/改棋谱/AI资源。ADR-018与ONBOARDING_SLICE。

5应用+4组件=9新增：旧码/非法值/未来版本/资源不变/晚到字段/读写失败，四步前后/完成/重建不弹/重放保留dirty、普通设置不清标记、Escape不记/200%字号、错误重试与坏读禁止自动、慢读不盖已开模态。首目标8/8通过后增慢读；最终全根显式官方NNUE201/201、flutter analyze无问题。原生首次引导文件偏好/新实例/重放1/1（00:04）和相关设置恢复1/1（00:06）通过；末模态保护后引导单项最终复验进行中。未改引擎不重复完整16；不标真实OS焦点/其它平台。

失败留痕：首目标7+1因全局错误文字重复匹配（状态栏+Snackbar），改Snackbar限定后过；App集成2项大括号修；新增慢读测试漏dart:async导致全根加载失败/analyze2项，补import后最终201/201。没有降低业务断言或绕过保存失败。聚光跟随真实控件/操作闯关未实现，不把本只读四步视为参考交互完全一致。
M3-18最终：模态让位后根真NNUE201/201、analyze通过；原生引导最终单项1/1（00:04）再次通过，相关设置恢复1/1结果保留。无待等待验证命令。production main已启用首次引导，默认测试宿主不自动弹出；启用模式已独立验证。

## 2026-11-02 / M2-14 / F01,F13 → B05,B16 分支点导航

ReadingNavigation纯应用目标：严格祖先/所选currentLine最近分支点（多子节点），无则到绝对开始/所选末尾，当前点排除、其它支线分叉不截断。BoardSession按不可变树对象缓存，选子/info不重扫。App保留绝对首尾，增加双箭头Tooltip/窄屏Wrap/禁用状态；闭包捕获目标+epoch/revision/positionRevision，旧UI不能作用复用ID的新文档，统一引擎协调器暂停AI和迟到结果保护；帮助补语义。

5应用+3组件=8新增：空/单线/根及嵌套fork/所选短支线/删除提升/千步迭代；200%字号往返与绝对首尾、AI思考stop返回bestmove丢弃、旧按钮新文档保护。目标8/8，全根显式官方NNUE209/209、flutter analyze无问题；macOS读谱用例补中段两子分支，往返根/分支/所选末端且nodeCount/revision/clean不变，单项1/1（00:08）通过。领域无改动沿用核心49，不称其它平台已验。

首目标因未直接导入扩展所属engine_session_controller library而编译失败，补import后过；AI夹具预先改有限pump避免思考进度条settle，未改生产异步收尾。E19单中段参考已V，嵌套/根fork是明确项目扩展验收，未冒充参考全部边界。

## 2026-11-02 / M4-01a / F08,F12 → B19 单局PGN格式层

纯Dart PgnRecord/PgnCodec：四基础标签规范化与其它不可变元数据、ICCS/默认中文、PGN红r别名限定、2/6字段FEN、根/逐着/结果后评注、回合和结果一致性，统一既有合法着法；拒绝WXF/括号变着/多局/NAG/非法根及着法。64000字符/64规范化标签/4096标签值/1999着/10000单节点评注，输入与逐段输出预算。导出仅所选路径，元数据/评注语义保留；花括号评注明确报错或显式省略，不偷偷修复。

核心新增12测试：格式/侧/计数/根/标签转义与Unicode/注释/范围/声明结果、30余非法输入和各项限额/上界1999着、邻接转义与64标签；核心完整dart test61/61、dart analyze无问题。根E20原始151字节互操作新增1测试，全根显式官方NNUEflutter test210/210、flutter analyze无问题。核心首全套60+1失败为测试未指定Chinese而默认ICCS输出、Format标签断言不一致，改显式格式后61；未放宽严格元数据Map比较。

本片只格式层，无App入口或资料持久化，不能标F08/F12完成或UI支持PGN。无App/引擎/原生修改，macOS不空跑；下一资料模型/文档存储，再接文字与文件接口。PGN_CODEC_SLICE/PGN_RESEARCH/E20及源码测试可追溯，未复制第三方parser/例谱。

## 2026-11-02 / M4-01b / F10,F12 → B16,B19 棋谱资料及本机保留

GameMetadata纯Dart不可变有界/内容相等/JSON，未知字段保留，PGN复用校验；BoardSession原子tree+metadata，metadata-only内容dirty/不改位置，Library/SavedGame可选资料/旧schema兼容；FileGameRepository坏资料走备份且保留原件，FileDraftRepository转传、Draft key加入metadata、纯资料及命名空草稿恢复。覆盖保护以dirty为准，清掉最后字段仍提示。资料结果仅声明，不强制规则终局；普通分析/AI不重启，批处理沿原revision规则过期。

Material3资料表单/六常用字段和记录结果、只提交改动、未知/派生字段只读查看、取消/noop/旧epoch和内容保护、200%字号。8应用+4文件+4组件=16新增根测试，根真NNUE完整226/226与flutter analyze通过；核心新增4，完整65/65，dart analyze无问题（首测试空List推断1警告已补Object?）。目标存储初10/10、UI首15/15，再新增编辑器纠错后完整门槛。

macOS完整18项首轮17通过1失败，新资料用例库条目与草稿同名文本匹配歧义；修ListTile限定/等待行时漏声明又一次构建失败，补后资料单项1/1（00:09）通过。生产源未因测试修订改变；原生覆盖包括完整保存资料/新App打开原保存/恢复独立metadata-only草稿/原谱保持不变，不虚构最后一条命令18/18。raw生命周期[]，不当人工OS焦点；其它平台未验。日志SESSION_LOG。

ADR-019/RECORD_METADATA_SLICE；仍未接PGN交换UI和文件端口，不能标F08/F12全完成。没有新增依赖或第三方资产。

## 2026-11-02 / M4-01c / F07,F12 → B19 PGN文字交换

RecordTextExchange/ImportedRecord纯应用接口，静态Isolate.run真实领域DTO与错误字符串传输，识别PGN或旧文字并保留完整资料/根与逐着评注；只起始BOM处理，中间资料BOM保留。ImportTextDialog忙态/取消/Clipboard晚到保护，PopScope+代次+route拦退场尚mounted时的旧回调；App解析/确认/先保存后核epoch+内容/位置修订。导出捕获开窗快照，五格式Dropdown/PGN评注选择/无损失败禁复制/明确范围，派生标签根据实际根和格式重算。

新增5应用+7组件（及更新旧文字3），目标15/15；真实worker/Unicode/错误/旧格式、PGN资料评注、快照、不支持不改文档、Cancel及Escape退场防关新route、Clipboard晚到、确认/先保存期间文档变化、200%评注错误与显式省略。根真NNUE238/238、flutter analyze无问题；初5项大括号限定修，后1项mounted flow lint补显式guard后最终回归。核心未改沿用65/65+dart analyze。

macOS旧文字传输相关单项1/1（00:05）通过；新PGN真实worker/注入剪贴板端口/实际文件全树保存+新App恢复进行中，结果后补。不会触系统剪贴板，不将该端口注入称系统clipboard验收。其它平台/OS人工视觉仍未验；系统文件选择/拖放与多方言不在此片完成范围。ADR-020/PGN_EXCHANGE_SLICE。
M4-01c原生最终：新PGN单项1/1（00:11）通过：真实worker导入标签/评注，建立另一根分支并选中中途节点；PGN只复制所选两步，而完整本地存谱保留5节点/未来评注/未知资料，新App文件适配器重开仍完整。复制为注入MemoryClipboard端口，未触系统剪贴板。旧文字单项1/1（00:05）已过；最终root/analyze和两原生命令exit0确认，无待等待验证。

## 2026-11-02 / M4-01d / F07,F12 → B19 只读文字棋谱文件导入

RecordFilePicker端口、官方file_selector1.1.0适配器，stat/实际字节/字符双限与严格UTF8、绝对读取期限及订阅清理、路径隔离/名称清理；PGN真实worker与资料/评注、Material3预览确认/取消/重试/200%字号/路由退场和共享文档保护。生产main已注入；Debug/Release为user-selected.read-only并保留sandbox。ADR-021、RECORD_FILE_IMPORT_SLICE与依赖登记可追溯。

11适配器+7组件目标18/18、显式官方NNUE环境根flutter test256/256与flutter analyze无问题均exit0。macOS原生新文件单项1/1 exit0（实际UTF8文件流、工作Isolate、预览不改谱/确认、资料评注保存、源字节不变），plugin/Pod注册编译通过，codesign实际Debug包含sandbox和user-selected.read-only。系统chooser为注入，不宣称NSOpenPanel实际选文件已验；Release实际构建签名、其它平台、GBK/二进制/拖放/多局仍未验/未做。核心未变沿用65/65。

初widget编译失败因测试误用LibrarySnapshot.single及session.navigateTo，改为games.single/navigate；第二次6过1失败因WXF测试缺Game首标签，修夹具后目标18全过。初analyze两项冗余import清理，最终全量通过。日志/tmp/chessnext-file-import-{adapter,widget,widget-final,target,full,analyze-initial,analyze,native}.log；没有待等待验证命令。

## 2026-11-02 / M4-01e / F12 → B11,B19 UTF8文字文件导出

RecordFileExporter纯端口与取消令牌，MacOsRecordFileExporter官方保存面板+原生私有通道；ExportTextDialog五格式/评注沿开窗快照、状态/重试/迟到选择丢弃，不清dirty、不改本地库绑定。原生RecordFileWriter utility串行Foundation atomic写入、有界UTF8/路径校验/拒绝目录与符号链接、错误不传路径。权限因实际写入用途升级user-selected.read-write，sandbox保留。ADR-022/RECORD_FILE_EXPORT_SLICE。F08单UTF8文件导入由M4-01d覆盖，之前该片标题F07,F12漏列F08，在此补追踪，不把全F08关闭。

技术探针swift research/spikes/atomic_file_probe.swift通过四边界；11适配器+5组件新增，根flutter test272/272（显式官方NNUE）最终exit0与flutter analyze无问题；macOS导出目标1/1 exit0，真实通道替换/新建/失败保留/符号链接/超限拒绝与UI快照保存；codesign实际Debug含sandbox+user-selected.read-write。核心未改沿用65；native文件现21项，未全跑21。系统保存面板选择注入，实际外部授权/作用域撤销/网络云盘/断电/Release签名/其它平台未验。

探针首Swift precondition中throw表达式编译失败改先读再断言；widget首错误调用setComment改实际annotate，修后5/5。初analyze业务1及随后测试2项大括号info补齐，最终analyze0问题；根首272全过，最后修纯测试大括号后再完整272过。日志/tmp/chessnext-{atomic-probe,atomic-probe-final,file-export-adapter,file-export-widget,file-export-widget-final,file-export-full,file-export-full-final,file-export-analyze-initial,file-export-analyze,file-export-analyze-final,file-export-native,file-export-entitlements}.log。无后台验证未收尾。

## 2026-11-02 / M3-19 / F27 → B08,B20 全局字号

E21三档100/115/130与系统/手动切换、同会话页间记忆为V；本地AppPreferences可选textSize/旧字段兼容与严格坏值、逐字段晚到合并/串行最新值/重试，TextSizeDialog即时全路由生效，普通设置表单保留字段。AppTextScaling保留系统TextScaler原对象/非线性，手动不乘系统；不改棋谱/dirty、搜索请求数不变。ADR-023/TEXT_SIZE_SLICE。

新增6应用+6组件均通过，含OS200与变化模拟/自制非线性对象/键盘Tab到滑块/语义/窄窗/写失败重试/新App恢复；根显式官方NNUE flutter test284/284 exit0（52844）与flutter analyze无问题exit0（1360）。macOS字号真实偏好文件新App目标1/1（56302，00:07）及旧设置/资源恢复目标1/1（86147，00:06）均exit0。原生文件22用例，未全跑22；核心未改沿用65。真实OS系统设置操作/其它平台/语言与字体资源未验/未做。

初组件4过2失败：touch tap不保证键盘焦点，改用实际Tab遍历到滑块再Right，不改生产焦点逻辑；SemanticsHandle需在test body finally dispose（addTearDown晚于framework校验），修测试后6/6、完整根全过。日志/tmp/chessnext-text-size-{application,widget,widget-final,full,analyze-initial,analyze,analyze-final,native,native-settings}.log，所有session结束。

## 2026-11-02 / M3-20 / F21 → B08,B20 棋盘路数坐标

E22实测参考显示坐标开关/数字2显隐/导航记忆并恢复原设置。项目BoardFileCoordinates提供独立上下红黑方路数边框/四种方向，BoardDisplayScope在Navigator外覆盖主棋盘与编辑器；showCoordinates可选旧默认true/严格坏值、逐字段晚到合并/持久化/重试，普通设置保留新值，不改谱/重启分析。上下边框和90格统一比例/内部格距，不拦截落子/拖放。ADR-024/BOARD_COORDINATES_SLICE。原站完整方向/编辑器/重载仍U，边框为项目P。

新增3应用+6组件，加原棋盘/编辑器目标18/18通过；根显式官方NNUE flutter test293/293与flutter analyze无问题exit0。完整macOS23/23通过（03:29，34715），含实际NNUE/AI/缓存/复盘与文件交换、偏好恢复/坐标新例。之后仅把两个显示入口归到主题下Wrap、资源字段连续，最终根293/293 exit0（37551）、analyze0（27849）、原生相关旧设置+新坐标2/2（00:21，65239）通过。核心未改65沿用；真实OS焦点/人工视觉、其它平台仍未验，fixture raw[]不改变该边界。

首测试文件多一括号导致格式/加载失败；修后15过3失败为两独立BoardSurface夹具缺Material、脏文档编辑漏继续编辑确认；补夹具/流程后18过，没有改生产保护。晚到测试改为存储值与显式选择相反，以实证合并。初analyze1项大括号info补齐；所有最终门槛通过。日志/tmp/chessnext-coordinates-{target,target-final,target-retry,full,full-final,analyze-initial,analyze,analyze-final,native-full,native-settings-final}.log，所有命令收尾。E21/E22证据来源/校验清单DISPLAY_EVIDENCE_MANIFEST。

## 2026-11-02 / M3-21 / F21 → B08,B20 棋子大小

E23实际10–200/步5与最小点状/最大重叠裁切、页间记忆并恢复100；正常方向上下完整路数可见补E22。AppPreferences/Controller/Scope增加pieceSizePercent，可选旧100/严格范围与步长/晚到合并/持久化；BoardDisplayDialog即时滑块/默认重置/错误重试，BoardSurface只缩放实际棋子面容和拖动反馈、transformHitTests=false，90格/空位/箭头/路数几何保持，两个路由共用。ADR-025/PIECE_SIZE_SLICE。

新增3应用+5组件；加坐标回归目标14/14通过，后强化拖动中真实Overlay反馈存在/同200%断言，最终组件5/5。根显式官方NNUE flutter test301/301 exit0（84139），flutter analyze无问题exit0（43285）；macOS坐标旧例+尺寸新例2/2 exit0（71222，00:21），真实偏好文件新App恢复200、点击重叠面容仍落正确交点、重置100保留其它字段/原棋谱。原生现24项，本片未全跑24；上片完整23/23已过。核心未改65沿用；OS人工视觉/其它平台未验。

本片analyze初/最终无问题，目标和最终根/原生无失败；首次apply_patch缺格式化后上下文原子拒绝，无文件改动，核实际文本后应用。截图/AX来源与摘要在DISPLAY_EVIDENCE_MANIFEST，无复制产品资源。日志/tmp/chessnext-piece-size-{application,target,widget-final,analyze-initial,analyze,analyze-final,full,native}.log，所有session收尾。

## 2026-11-02 / M3-22 / F26 → B08,B17,B20 推荐箭头显示

E24实测推荐同时控本步/预计应着两支、变着开关另有对象、三种头部实际可见；恢复默认并停参考引擎。AppPreferences可选showAnalysisArrows/arrowHead与Controller逐字段合并/串行写；AnalysisMarkersDialog独立即时，BoardDisplayScope到BoardSurface；独立BoardArrowsPainter、只读语义/IgnorePointer，关闭不丢PV/不重启引擎，重开最新PV；三头宽仅头部变化。ADR-026/ANALYSIS_ARROWS_SLICE。

新增2应用+3真实像素绘制+4组件通过（9）；像素确认头面积顺序/恒定杆、四方向/无PV、两色；组件确认运行中Fake实际requests/stops不变、隐藏期间最新PV/恢复、命中/语义/200%与读写重试/新App。显式NNUE根310/310与analyze0，原生真实NNUE单项1/1先过；之后加网格临时TextPainter.dispose，最终根310/310 exit0（32031）+analyze0（45893）+原生同项1/1（36716，00:13）均过。真实NNUE活动令牌/身份未变、显示用最新PV，文件偏好新App恢复。原生当前25未全25，上次完整23/23；核心未改65沿用。

初analyze1大括号info修复，业务/组件/绘制/全量/原生运行无失败；没有待等待进程。日志/tmp/chessnext-arrows-{painter,widget,analyze-initial,full,full-final,analyze,analyze-final,native,native-final}.log。其它F26/变着树与PV历史B22仍缺，不能关闭F26整项；真实OS焦点/人工视觉/其它平台未验。
