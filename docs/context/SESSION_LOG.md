# 会话日志

## 2026-11-01 / M0-01

范围：调查、验证设计、文档与 Agent 体系。初始为空仓库，无 AGENTS。

操作：读取 skill-creator；使用 CUA 浏览器实际展开参考站点；官方 release latest 跳转 Pikafish-2026-09-06（短 SHA 4c17cee）；检查固定 tag 的 uci.cpp、engine.cpp、evaluate.h；核对 Flutter FFI/架构/Material 3 官方文档；读取本机 Flutter 缓存。

结果：分析输出已观察；访客棋谱/练习被登录阻挡；原生引擎未运行。GNU 条款页访问超时。生成文档与六个 Skills，保留后续审计与 spike 门槛。没有业务实现或外部提交。

验证：32个 Markdown 文件相对链接检查通过（0失效）；lib 下无业务文件。六个 Skills 的官方 quick_validate.py 均因本机 Python 缺 PyYAML 无法执行，不计通过；使用 Ruby 标准 YAML 解析替代检查，六个 frontmatter 的 name/description 与目录名均通过。未安装新依赖。

## 2026-11-01 / M1-01 离线通信

用户将登录后功能延期，本轮授权Flutter与最新版引擎跑通、架构与计划。读取项目状态与pikafish-engine Skill。GitHub API403限流后用公开latest HTML和git ls-remote确认2026-09-06及完整SHA；下载官方7z，校验macOS二进制/NNUE，保留GPL/AUTHORS/NNUE限制许可。发现权重禁止未经许可商用，制品保持.local不提交。

独立flutter create macOS诊断工程；真实引擎测试NNUE/MultiPV/200ms/100轮stop/quit通过，加缺失引擎负向测试，2/2通过，analyze通过；macOS构建成功。原生App执行仓库外helper被Sandbox拒绝，改为应用内helper继承sandbox并adhoc签名验证。最终状态见COMMUNICATION_VALIDATION与日志，不用构建成功冒充运行成功。

更新AGENTS授权范围、ADR-004、离线范围、架构、M1–M5和B13–B20。未实施业务，无git提交。

最终运行验证：应用内helper继承sandbox、adhoc签名后，真实Flutter macOS进程NNUE/双PV/限时搜索/3轮stop/quit通过，EXIT=0；未关闭Sandbox。日志已存macos-app-uci.log，调试VM服务URL已排除。

交付检查：37份项目Markdown相对链接0失效；两个工具脚本Python语法通过；下载校验脚本对已有制品复验通过；最终flutter analyze无问题；原生运行和100轮测试日志PASS。所有变更未提交，没有残留运行会话。

## 2026-11-01 / M2-01 B15规则核心

用户授权按计划开始实施，要求暂不处理授权问题。使用flutter-feature Skill，读取状态/架构/设计/交互规格后建立独立纯Dart包。实现坐标/FEN/七类棋子规则/将军及合法落子，不包含历史裁决或UI。

首轮测试10通过1失败：手工炮将军fixture缺少炮架，按规则补上e1红兵后11/11通过；并非通过修改规则迎合fixture。dart analyze无问题。4组局面对比本地固定版本Pikafish perft逐分支完全一致，日志及原始stdout存xiangqi-perft.json；初始3层79666，单步中炮2层1564，6步开局2层1100，炮吃马/车回吃3层46642。

本轮未重跑无改动的Flutter通信或移动测试；无引擎运行残留。包有pubspec.lock记录实际test依赖。AGENTS/CURRENT_STATE/HANDOFF和追踪更新范围，不删除既有许可事实。

## 2026-11-01 / 基座复验与首次提交

用户要求每功能flutter test、flutter analyze后中文规范提交。新增根Flutter测试入口（2个契约测试）与tools/check.sh，规则运行时仍纯Dart。复验全部通过：根Flutter2测试及analyze、纯Dart11测试及analyze、引擎spike2测试及analyze；4组perft逐分支一致；macOS沙箱App NNUE/3轮stop/quit成功。仅确认本机macOS技术路径，不宣称移动FFI或Windows/Linux通过。首次基线提交归档现有文档、通信与规则核心；随后新增功能独立提交。

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

M3-04追加验证记录：根67/67与flutter analyze通过，含200%设置表单/NaN和桌面inactive/hidden回归。原生第一次7/8（PV2未出现），后续整套停在AI阶段等待绘制，向该轮Flutter test自有runner发送INT中断，未记通过，测试App/helper随工具收尾。integration_test现通过SystemChannels.lifecycle保持框架resumed作为受控交互前提，记录宿主原始状态；普通main无覆盖。原生OS焦点、可见性、最小化不在这组fixture验收范围，生产策略单独组件测试。初次自建Binding与工具预建Binding冲突，随后用现有binding通道fixture，未更改SDK。最终macOS原生8/8通过（受控framework-resumed前提，原始事件采样为空）；没有据此认定所有旧停滞的具体根因已证实或关闭。

2026-11-02 E12：完成访客自制两步谱快速整谱运行、结果/说明、跳过空队列和取消终态调查，原始AX及截图存research。正式flutter run -d macos从lib/main构建并连接Syncing files，自动置前仍返回1；该轮会话22326是否仍活跃以进程/工具为准，后续原生测试会重建测试入口，最终交付前再次普通入口构建。技术源码核查确认可组合limits及重复资源重设/清Hash风险；下一切片组合限额，随后资源复用，再复盘队列。没有实现复盘业务。

## 2026-11-02 / M3-05 / F32前置 → B14/B18 组合搜索预算

EngineRequest两个工厂均支持depth + moveTimeMs + nodeLimit并存，全部null才无限搜索；UciEngine按组合输出go，searchmoves仍最后。0不是端口无限值，UI后续把0明确映射null。应用策略上限为255深度/24小时/2^53-1节点，非引擎最大有效能力声明；非法值在发送前拒绝。
验证：带官方NNUE环境根flutter test69/69、flutter analyze通过。真实CLI分别用松弛的另两项预算验证深度、时间、节点限额生效；节点按引擎周期检查，可超出精确值，测试不声称硬实时。macOS原生9/9通过，新增应用包内签名helper/NNUE组合预算提前在节点界限结束。原生仍用framework-resumed交互fixture，此轮记录真实宿主hidden/inactive事件，未计作OS生命周期视觉验收。未更改UI或核心规则；整谱队列/曲线仍下一切片。

## 2026-11-02 / M3-06 / F02,F03,F32前置 → B14/B18 会话资源复用

EngineRequest.gameId文档epoch与token分离；(gameId,rootFen)变化才ucinewgame，同文档仅发改变的Threads/Hash/MultiPV。资源/上下文变化保留ready屏障，任何下一搜索仍等旧bestmove。App分析与AI均传epoch，根FEN兜底区分，失败新进程冷启动。
验证：根flutter test72/72（官方引擎环境）与flutter analyze通过，macOS原生9/9通过（交互fixture保持resumed）。新增参数ready屏障、命令数量和分析/AI文档epoch回归；原有实际NNUE/组合限额/stop行为通过。微基准校验官方hash后，1线程64MB深度10、各预热1+10次交替重复局面：强制冷重设41.021ms中位、同文档暖0.920ms；仅特定工作负载，不宣称通用提速/棋力/≤5%裸引擎开销。JSON及重跑工具见engine/RESOURCE_REUSE.md。工具初次analyze相对lib导入/缺大括号已修，未记录成通过。ADR-009固定语义。

## 2026-11-02 / M2-11 / F01,F13 → B05/B16 完整线路读谱

GameTree.currentLine含所选变着与游标之后主线；lineAnchor只读导航元数据，在回退/首尾时保持分支。schema1可选字段兼容旧快照，拒绝缺失节点/跨线路游标等损坏组合，删除锚点安全回退。MoveList可点击/选中、中文语义/坐标/注释标记、自动滚动及虚拟构建。普通读谱导航暂停AI，一步前后与对弈双步悔棋分离；迟到stop不能覆盖后来的人工落子。
验证：根flutter test76/76（官方NNUE环境）与flutter analyze无问题，核心dart test49/49和dart analyze通过；千着在普通与200%字号挂载ListTile<30、选中可见、无布局异常，不作帧率承诺。原生macOS完整10/10通过，最终读谱单项又1/1通过（受控framework-resumed前提）；新增点未来着、回退保持分支、当前线路下一着。初轮3处大括号lint已修并重跑通过。未新增依赖。ADR-010区分项目读谱策略与源站尚未验证细节，未宣称F01/F13全部对齐。

### E13续审（2026-11-02）
源站自制四局面棋树完成彻底分析；范围/同级切换/置顶/建议试走见REFERENCE_EVIDENCE E13。建议试走在父局面新增并切换分支已验证；未执行站点删除。当前只有研究文档与截图变化，不将其记为业务实现。下一条F13当前着同级分支面板，之后F32共享单引擎队列。

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

### E14 / 2026-11-02候选续审
源站最多候选5减至2禁用，0秒/深度4/节点0/当前2局面运行完成；新自制线路追加中文卒３进１/炮八平五，单步父局面候选执行成功。既有视图左右镜像，日志只记录可见中文与实际结果，不凭屏幕坐标写FEN。详情REFERENCE_EVIDENCE E14；下一实现方案CANDIDATE_SLICE为P非业务完成。未再执行源站试走/删除/登录。

### M3-12 WIP / 2026-11-02
候选调度/父局面试走与UI已实现未提交，应用12（含真实NNUE）/组件3目标测试通过；全量及原生整套仍待结果。共用缓存访问抽取时18个目标回归有1live因无环境跳过；最终全量显式环境会覆盖。首次静态检查11处大括号lint已修，暂无最终整套结论。详HANDOFF WIP，不能标本功能已交付。

## 2026-11-02 / M3-12 / F13,F32 → B18 单步父局面候选与试走

CandidateRun/engine_candidates/CandidatePanel及配置：当前着父局面（根节点自身）、有限每候选预算、逐次排除合法首着、2..256候选策略、原始cp/mate/bound/无评分、进度/取消/失败/过期和缓存复用。源站可接受阈值仍U，不宣称同筛选/胜率算法。共享单引擎batching互斥；无bestmove保留真实原因，PV首着不匹配不赋分，非法/重复bestmove失败。
BoardSession.playVariation原子创建/切换同级，已有节点/当前着不产生多余dirty，保留旧分支与注释；控制器等stop后重新验epoch/revision/positionRevision/generation，停止失败或新操作不试走。清理取消后迟到失败的opening Future，下一次启动可重试。ReviewCacheAccess抽取整谱/候选共用缓存IO与允许集/PV校验。
根flutter test135/135（显式官方NNUE环境）、flutter analyze无问题；macOS完整14/14以及最终候选单项1/1通过。新增13应用/真实NNUE测试+3组件测试，含父历史/唯一候选/无分/停止/互斥/旧ID/缓存迟到、原子通知、当前着无操作、stop失败/late factory失败重试/0候选原因、NaN/全0/数量/200%字号。真实包内NNUE黑方父局面候选→试走同级→旧分支保留→重算复用2候选。核心未改，沿用49/49及dart analyze。
首次全量133通过1失败：旧注释导航测试直接点击被AppBar遮挡的按钮，hit-test告警后未导航；修为ensureVisible/pumpAndSettle并断言hitTestable，复跑134通过；最后增加无bestmove原因回归后135通过。早期目标缓存回归17通过/1live未设环境跳过，不算真引擎通过；最终显式环境覆盖。最初11条lint已修，失败均保留。日志/tmp/chessnext-candidates-{unit,widget,test,analyze,native,native-target}.log。ADR-013。
下一条整谱多候选模式，先把单次有限搜索/缓存/最终PV校验抽成可复用执行器，防止队列与单步各维护一套循环；仍单引擎所有权。胜率/准确率/错题及其他功能继续，不标整站对齐。

### M3-13前置WIP / 2026-11-02
FiniteSearchExecutor抽取与非法PV缓存remove已写未提交。原有应用31（含真实NNUE）目标回归通过，新执行器6+文件套8通过。最初fixture误把h2e2后a9a8当非法，已纠正为黑方轮到时红马b0c2；不是领域规则缺陷。8条大括号lint已修；全量/原生最终结果待HANDOFF会话，不写成已通过。

## 2026-11-02 / M3-13 / F32前置 → B18 有限搜索执行器

FiniteSearchExecutor统一整谱与单步候选的单次有限单PV、缓存、token/允许集/最终bestmove-PV匹配和完整PV合法性，临时订阅在finally等待清理；取消/流异常不泄漏。移除控制器两套后台info捕获。ReviewCacheRepository.remove使格式正确但PV不适用的缓存失效，只删派生缓存key，不碰棋谱。未新增整谱多候选UI，下一切片THOROUGH_REVIEW_SLICE仍P。
根flutter test142/142（显式官方NNUE环境）、flutter analyze无问题；macOS完整14/14通过。原有31项应用/真实NNUE回归通过，新增6执行器契约和1文件失效测试（文件目标套8、合计14目标）。非法最终着法/排除集、PV不匹配/非法、流错误/取消监听清理/坏PV移除覆盖。核心未改沿用49/49。
初轮固定Widget帧等待出现2失败并停滞，INT自有根测试进程52684（非用户run），未记通过；有限pump仍4失败。临时TRACE定位等待subscription.cancel，Fake网关来自真实zone，单推进模拟时钟无法收尾。pumpUntil增加有界真实runAsync与模拟帧后6组件通过，最终全量142通过。临时TRACE已恢复移除。首次fixture把黑车a9a8误认非法已纠正；8条lint及1无用测试import修复，最后analyze通过。日志/tmp/chessnext-finite-{regression,unit,widget,test,first-test,zone-trace,analyze,native}.log。
本次为整谱多候选的复用基座，不把重构当新产品功能或全量F32完成。下一步按THOROUGH_REVIEW_SLICE推进模式/节点候选集合/部分结果/计数与详情。

### M3-14 WIP / 2026-11-02
整谱多候选与详情代码已写未提交，初6应用/真NNUE、2组件、旧31回归通过。增补空搜索计数边界后全量/原生仍跑，具体会话HANDOFF；初次静态2问题（模型移出后unused import/大括号）已修，不能将最终门槛预先写通过。ADR-014固定集合/缓存语义，不宣称源站可接受公式相同。

## 2026-11-02 / M3-14 / F32 → B18 整谱多候选模式

CandidateCollector共用FiniteSearchExecutor，单步/整谱不再维护两套逐次排除循环。ReviewMode最佳/多候选、2..256策略/每候选有限预算；line/tree不变。ReviewRun.candidateResults保存不可变complete/partial集合，results仅含收尾局面；第一无约束候选无分则主分无分，不取后续受限分数替代。局面复用数与候选查询命中数分开，命中后又实际空搜索不算整个局面全复用。统一100ms batchInfo只显示合法job/token，结束/取消/失败清计时器。只读候选详情和partial大字滚动，不自动落子。
根flutter test151/151（显式官方NNUE）和flutter analyze无问题；macOS完整15/15通过。新增7多候选应用/真NNUE及2组件测试；实际四分支局面×2候选、详情、再次命中4局面/8搜索。旧31应用/NNUE回归通过，partial取消、缓存模式/上限变更、首评分、读谱/编辑、空搜索、数量/200%验证。核心未改沿用49/49。初期2条静态问题（模型移出后unused import、单条大括号）修复后通过，无最终失败。原生运行中持续info会更新帧，局部tapVisible在batching期间用有界pump，静态表单仍settle；不是更改生产生命周期或OS焦点。日志/tmp/chessnext-multi-{regression,unit,widget,test,analyze,native}.log。
ADR-014解释子查询缓存与集合完成条件；源站可接受阈值/准确率公式仍未知，不标F32全部完成。下一条原生WDL胜和负数据链路，再复盘损失/分类/错题等。

### E15/WDL调查 / 2026-11-02
指南D与实际访客菜单/模式O差异记录E15，新增F33/B21待核。WDL官方check/三项字段已由原生CLI8行验证，总和1000、quit0，App尚未实现。临时TextIO+select探针uciok超时已纠正为二进制余行缓冲（不是Pikafish故障），最终tools/probe_wdl.py通过，原始带SHA协议入engine/validation。下一做WDL数据链路，独立业务门槛。

### M3-15 WIP / 2026-11-02
原生WDL/缓存/分析面板已写未提交。目标32（含实际NNUE）、根162/162与analyze通过；原生整套仍待结果。序列化optional wdl不应混入整数统计字段，初次静态复核时已纠正并由roundtrip/实际数据目标验证。Skills协议纯文档修改另行提交，初次validator缺yaml未执行，临时环境校验待取结果，不算成功。

## 2026-11-02 / M3-15 / F02,F26,F32 → B14/B18 原生WDL

WdlEstimate严格胜/和/负三整数总1000、视角反转/预期得分；EngineInfo可空、坏可选统计保留CP。EngineRequest.preferWdl向后默认false，App各搜索请求true偏好，UciEngine能力check/只变更/ready确认/不支持回退。缓存optional元数据和独立偏好键、CP旧格式兼容，支持WDL但缺请求数据不算完整命中；文件重开保留。分析面板显示模型胜和负，单独标和棋半分的预期得分，bound/mate不附普通概率文本。
根flutter test162/162（显式官方NNUE）与flutter analyze无问题；macOS完整15/15通过，真实包内MultiPV及WDL展示、缓存/整谱等回归。新增5类型/解析/视角/缓存测试、3UCI选项/缺能力/ready超时测试、1真NNUE双先手、1文件重开和1组件视角/200%/bound测试；目标32/32通过。初轮1处lint修复；序列化wdl误混整数统计字段在静态复核纠正后roundtrip通过，未有最终失败。日志/tmp/chessnext-wdl-{unit,target,test,analyze,native}.log。核心未改沿用49。
ADR-015。原生探针8行总1000/quit0另见协议归档；此功能只提供引擎模型数据，不声称网站胜率/准确率同公式或完整F32。下一预期损失/等级与错题；所有其他缺项继续。

### 2026-11-02 Agent协议维护
按skill-creator做窄范围更新：AGENTS同步既有持续实现/自建后端授权，project-onboarding与pikafish-engine去掉硬编码研究阶段，不扩大外部操作权限。首quick_validate系统Python缺yaml未成功；临时venv从官方PyPI装PyYAML6.0.3后两个Skill均通过，环境清理且产品依赖不变，记录context/validation/skills-2026-11-02.json。只改协议/文档，不宣称新业务功能；业务门槛沿最新WDL根162/原生15。

2026-11-02 M3-16开始：新增原生WDL预期损失/分级报告，明确非源站准确率。首次flutter analyze失败6项（ReviewRun?捕获及大括号）；已修待重跑，尚未运行新报告测试。工作树保留WIP，不提交为完成。

2026-11-02 M3-16：预期损失报告实现，ADR-016/TRACEABILITY。首目标编译失败（测试误用GameTree/WdlEstimate构造API）修复；后8通过2失败，定位n2夹具b2e2撞己炮被FiniteSearchExecutor正确拒绝，改合法b0c2后目标10/10。根真NNUE172/172；analyze余1个无效!删后无问题。macOS完整15/15（01:55），含新报告筛选/跳转不dirty；raw生命周期[]，不冒充人工OS焦点。核心未改49/49沿用。提交前最终根回归日志/tmp/chessnext-report-final.log，待命令结束确认；其它日志/tmp/chessnext-report-{target,full,analyze,native}.log。当前普通用户窗口PID38211仍在，不关闭。
M3-16提交前最终根回归172/172通过，静态分析无问题及原生15结果不变；无待等待验证命令。下一研究证据分开提交，然后继续功能。
2026-11-02 E16/E17浏览器实际审计：存题登录提示/最近阅读访客空态/公开只读页标题但着法未加载/返回历史仍空；证据登记REFERENCE_EVIDENCE，不标历史生成成功。研究资源仅docs，未入App资产，无产品代码更改，不重复业务测试。下一独立F18离线历史P。
2026-11-02 F18开始：最近阅读接口/控制器/文件存储/对话框和装配WIP，先方案/失败模型，未测试，analyze在/tmp/chessnext-recent-analyze.log，恢复以HANDOFF末尾为准。
F18中间验证：目标15/15、根真NNUE187/187通过；首analyze7项大括号，用dart fix限指定规则修7处，后新增force条件换行补大括号。原生测试夹具误读AnalysisPanel.engine（实际analysis）2编译错误及测试无用import修复；随后analyze无问题。发现库刷新可重绑外部替换文档，补documentEpoch及另存ID保护/回归测试，最终根回归进行中。未将首轮静态失败或原生未跑算通过。
F18最终阶段：macOS完整16/16（02:07）通过，新App/Repository与文件保存位置独立恢复；raw生命周期[]。补同现备份/路径失效时两条提示都保留，新增1应用测试；根真NNUE189/189，随后analyze发现1项use_null_aware_elements，改?error语法后重新全根/analyze进行中。该修订不改变存储或恢复算法，最终加原生最近阅读单项。
F18提交门槛最终：根真NNUE189/189、flutter analyze无问题、完整原生16/16及最后最近阅读单项1/1通过。无待等待验证命令。HANDOFF历史归档并缩短当前恢复路径，CurrentState更新；工作树功能提交后只剩E18研究文档/截图，后续独立docs提交再做F29离线帮助。
E18补审已独立登记：按钮说明15组可见/关闭，手动引导1/4可重放和跳过；未开启引擎，未宣称分支跳转已操作。研究文档/截图单独docs提交，产品基线5acdeda不变，后续F29离线帮助。
2026-11-02 F29离线帮助开始：9原创主题与实际控件说明/搜索折叠，AppBar入口，无IO或引擎调用。先方案，目标3组件及原生首测试补充；首analyze无问题，新增测试后待复验，目标/tmp/chessnext-help-target.log。尚未提交。
F29 M3-17门槛：目标3/3，全根真NNUE192/192、flutter analyze无问题，macOS首项1/1（00:06）通过。无失败/跳过，日志/tmp/chessnext-help-{target,full,analyze,native}.log。核心/引擎未改不重复其未变原生全16；下一手动分步/首次提示版本记忆。
2026-11-02 F29第二片开始：ONBOARDING_SLICE/ADR018提案，guideVersion可选字段/Preferences.markGuideSeen/Settings copyWith保留标记、App生产firstRun开关+帮助返回动作+四步只读dialog。代码阶段analyze无问题，新增5应用/3组件目标后待结果/tmp/chessnext-guide-target.log；新原生尚未写，不计完成。
F29第二片目标首轮7通过1失败：错误提示同时存在状态栏与Snackbar，测试全局find匹配过宽；改限Snackbar验证后8/8通过。App集成后analyze2项大括号已修，最终全根真NNUE200/200、analyze无问题；macOS新首次引导/文件偏好重建/手动重放单项1/1（00:04）通过。额外复验相关原生设置恢复项进行中，不重复无变化的引擎全套。E19新自制谱分支跳转已操作，证据AX/截图待登记独立docs提交。
F29引导相关macOS设置恢复单项1/1（00:06）通过。补慢读时不盖住已开用户对话框/手动仍可用，第4组件测试首轮忘导入dart:async导致Completer未定义、全根加载失败1/analyze2项；补必要import后重新全量与analyze，未计失败轮为通过。最终日志/tmp/chessnext-guide-final{,-analyze}.log，尚待末尾确认。
M3-18提交门槛最终：根真NNUE201/201、analyze无问题、原生引导末轮1/1（00:04）、设置恢复相关项1/1（00:06）均通过，无待等待验证命令。产品本切片独立中文feat(help)提交；E19研究已登记但独立docs提交，下一分支导航。未标聚光闯关/五平台/人工OS已完成。
E19研究独立提交：自制单中段分支首尾图标实际先到严格前后分支点，无其它点到首尾并保留所选变着；嵌套/根多分支仍U。新增AX与截图只docs，参考功能矩阵子项更新V，产品927c45a不变。
2026-11-02 M2-14开始：E19已V，纯应用分支目标/会话缓存/独立双箭头/epoch与修订回调保护；初代码analyze无问题。目标首加载失败（Dart扩展setAiSide/playing未显式import所属library），修import后重跑；AI夹具用有限pump避免无限进度条settle，尚未全根/原生，不计完成。
M2-14最终：目标8/8，根真NNUE209/209、analyze无问题、macOS读谱单项1/1（00:08）通过，无待等待命令。提交后下一E20自制PGN样本研究独立提交；本片无规则或依赖变更。
E20调查完成：参考真实导出Agent自制PGN151字节，download事件确认及SHA复核，研究副本+manifest/截图/主规范链接落docs；没有复制站点棋谱库或代码。纯文档/自制夹具，不重复业务测试。下一PGN纯Dart有限codec独立增量，App未支持PGN不能标实现。
2026-11-02 M4-01a：纯DartPgnRecord/PgnCodec和有限profile计划，11核心+1根E20互操作测试已写；目标执行中/tmp/chessnext-pgn-{target,reference}.log，未完成全量门槛/未提交。App无PGN入口不能标可用。原始规范/样本独立登记ec69d78。
M4-01a初目标核心11/11与根E20互操作1/1通过；加输入侧标签预算和邻接转义/64标签上限第12测试后，核心全量60通过1失败：比较Chinese元数据却用默认ICCS输出，差异正是Format字段；改测试明确指定Chinese导出（保留严格全Map比较）。同轮根真NNUE210/210、flutter analyze与core dart analyze通过。核心最终全套重跑中，不将60+1失败写通过。
M4-01a最终门槛：核心dart test61/61、dart analyze无问题；根显式NNUEflutter test210/210、flutter analyze无问题。无待等待验证命令，无UI/原生改动不空跑macOS。只codec，下一GameMetadata/保存草稿前置，再PGN交换界面，不误称App支持PGN。所有新增实现原创，未引依赖。
2026-11-02 M4-01b开始：GameMetadata/会话/显式保存及独立草稿转传、可选schema字段/元数据only dirty。初flutter analyze无问题，4核心+6应用+4文件测试已写，根存储目标执行中/tmp/chessnext-metadata-storage-target.log，尚无UI/全量/原生门槛，不计完成。
M4-01b中间：存储首10/10、表单加入后目标15/15，再补Editor限额纠错；根真NNUE226/226、flutter analyze无问题，核心65/65；核心analyze首1条测试空List类型推断警告，补Object?后无问题。覆盖保护以dirty判断修复清空最后资料未提示，已命名空草稿可恢复。macOS完整18执行中/tmp/chessnext-metadata-native.log，无完成声明。
M4-01b原生首完整18项：17通过1失败，新增用例库打开时find.text同名匹配草稿标题和库条目导致Too many elements。改限定ListTile并等该行；首次替换漏savedRow声明导致单项原生构建编译失败，补声明后重验。均不是通过，不隐去；生产源未改。原生修后日志/tmp/chessnext-metadata-native-final.log，flutter analyze复验中。
M4-01b提交门槛：根真NNUE226/226、flutter analyze无问题；核心65/65、最终dart analyze无问题。原生完整首18项17通过1失败/测试定位修订一次漏变量编译失败已如实记，最终资料单项1/1（00:09）通过，源未改，覆盖18用例但非最后一条18/18。无待等待验证命令。下一PGN文字交换（非filepicker），模型与草稿资料已经可用。
2026-11-02 M4-01c：RecordTextExchange真实Isolate传输初5/5；接typed导入/资料/评注、取消代次/route保护、App确认后复验、快照导出/五格式及评注选择。初UI analyze5项大括号已限定dart fix，旧3组件更新worker等待/Dropdown选择，目标执行中，尚无全量/新原生，不计完成。
M4-01c中间：目标15/15通过；全根首真NNUE238/238。flutter analyze余1项use_build_context_synchronously（自定义active getter已含mounted但flow不识别），Navigator前补显式mounted后全根/analyze复验。原生新PGN已写，未跑，不计完成。取消PopScope/代次/active+alive区分防晚结果关其它窗口与控件永久busy。
M4-01c最终：根真NNUE238/238、flutter analyze无问题，旧文字原生1/1（00:05）、新PGN原生1/1（00:11）通过且exit0确认。真实worker+实际完整文件保存/新App恢复，剪贴板端口注入不触系统；尚无系统filepicker。没有核心变更，沿用65/65。当前无待等待验证，准备独立中文feat(notation)提交。

### 2026-11-02 / M4-01d 文件导入

按持续授权实现只读单UTF8文字棋谱文件导入，方案先RECORD_FILE_IMPORT_SLICE，ADR-021；pub add file_selector:1.1.0成功，lock/平台注册/Pod嵌入真实更新，依赖hash已登记。系统文件面板未通过OS自动化操作，没有绕过桌面权限。

实际命令flutter test test/adapters/record_file_picker_test.dart首11/11；widget首编译失败测试接口名错，修后6过1因夹具缺PGN Game首标签导致错误文本不符，补Game后合并目标18/18。初flutter analyze两冗余import删除，最终无问题。显式PIKAFISH_EXECUTABLE/PIKAFISH_NETWORK根flutter test256/256 exit0（68069）、flutter analyze exit0（69041）；macOS native file import目标1/1 exit0（74082），实际文件读取+worker+保存及原文件字节校验，chooser注入。codesign -d --entitlements核实实际Debug只读/sandbox；Release仅配置，未构建验。核心未改不重复，其他原生19未重跑。日志/tmp/chessnext-file-import-*.log，全部验证会话已结束。下一独立写文件出口先做技术验证，不扩大当前读取授权。

### 2026-11-02 / M4-01e UTF8文字文件导出

官方Apple .atomic与sandbox.md经urllib读取原站正文（web工具不支持text/markdown），Dart rename官方契约不作安全覆盖承诺。先自有Foundation探针，新建/替换/目录失败/文件父路径失败保留原内容；首Swift precondition自动闭包不可throw编译失败，调整为先读取再断言后exit0。无OS权限自动化/绕过。

实现端口/typed失败和取消令牌、macOS保存选择适配器、Swift私有通道utility原子写、五格式UI快照保存；Debug/Release由read-only改read-write+sandbox，对应真实新用途。适配器11/11；widget首测试API setComment误用编译失败修annotate后5/5；初analyze业务1后测试2大括号info修复。全量显式官方NNUE flutter test先272/272（25846），最后测试括号后完整272/272（49290）exit0；flutter analyze最终47048 exit0无问题；macOS原生导出目标80542 1/1 exit0（00:04），实际writer覆盖/新建与失败不破坏/符号链接/超限及UI快照；实际Debug签名含read-write和sandbox。核心不变沿用65/65；其它20原生没重跑，实际Open/Save面板与外部授权/精确scope回收/Release/其余平台未验。日志/tmp/chessnext-file-export-*.log与atomic-probe-*.log。所有验证session已结束。下一字号外观审计及单功能增量，完整对标仍未完成。

### 2026-11-02 / E21 字号审计

实际IAB browser2/tab4访客操作设置：手动0/1/2=100/115/130，follow重置、手调退出follow，115%离开回访保留；恢复原follow100返回自制棋谱。截图/AX落docs/research，commentary嵌图。没有登录、上传、复制库素材、OS桌面权限操作。非100系统与重载未知，接F27单功能开发。

### 2026-11-02 / M3-19 全局字号

按TEXT_SIZE_SLICE/E21，AppPreferences新增可选枚举/迟到逐字段合并/错误重试，AppTextScaling在Navigator上保留系统TextScaler或显式手动比例，不叠乘；独立即时字号Dialog，原参数表单保留最新字段。应用6/6；widget首4过2失败：触摸tap不获取键盘焦点与SemanticsHandle在addTearDown太晚，改测试实际Tab遍历后Right及body finally dispose，生产无迎合测试的焦点修改，最终6/6。初及最终analyze无问题。

根显式PIKAFISH_EXECUTABLE/PIKAFISH_NETWORK flutter test284/284 exit0（52844）；最终flutter analyze exit0（1360）。macOS字号目标56302 1/1 exit0（00:07），实际偏好文件/新App恢复与棋谱不变；旧设置/资源恢复86147 1/1 exit0（00:06），不自动开AI。原生当前22项未全跑22；核心不变65沿用。系统200与变动为组件模拟、非线性是自制对象验证保留identity，不当实际OS设置操作证据。所有命令收尾；日志/tmp/chessnext-text-size-*.log。下一F21坐标/外观，完整对标仍缺多项不停止工作。

### 2026-11-02 / E22 与 M3-20 坐标

IAB访客实际坐标开关/导航记忆与顶部2显隐，恢复原开启返回E19自制棋谱，AX/截图证据已嵌commentary。无站点资源/库复制进产品。实现BoardDisplayScope、独立路数边框/方向/几何、布尔偏好/晚到合并/即时对话框，主棋盘/编辑器共用，不影响棋谱与搜索。

初apply_patch上下文不符时工具原子拒绝，无文件改动；修定位后正常。初新组件测试多一括号格式/加载失败，修后15过3失败为夹具两处缺Material与dirty编辑确认遗漏，补夹具和继续编辑后目标18/18；同时改晚到测试为相反存储值避免无效断言。初analyze1大括号info补齐。根显式NNUE293/293（72677）与analyze0（22995）exit0；完整macOS23/23（34715，03:29）exit0，fixture raw[]，生产无生命周期覆盖。

最后整理普通设置两个显示入口为主题下Wrap、保留连续资源参数，最终显式NNUE根293/293（37551）、analyze无问题（27849）、macOS旧设置+新坐标相关2/2（65239，00:21）均exit0。所有命令结束，核心不变65沿用，真实OS焦点/人工视觉及其它平台未验。日志/tmp/chessnext-coordinates-*.log。ADR-024/TEXT_SIZE及BOARD_COORDINATES_SLICE、E21/E22 DISPLAY_EVIDENCE_MANIFEST可追溯。下一棋子尺寸，继续不停止对标。

### 2026-11-02 / E23 与 M3-21 棋子尺寸

IAB参考站点已显示slider只读DOM min10/max200/step5，AX设置两端/回棋盘实际截图证实点状/重叠裁切，回访记忆；恢复100返回自制棋谱，截图已commentary嵌图，无谱/账号/资源复制进产品。最小棋子时顶部1–9/底部九–一全可见，补E22正常方向V，旋转/命中仍U。

按PIECE_SIZE_SLICE/ADR-025扩展偏好/显示Scope/即时滑块重置，棋子face Transform.scale且不变hit test；范围/步长校验，两个路由和drag feedback共用。首次patch格式化上下文不符原子拒绝后核文本应用，未有部分修改。应用3/3、含坐标回归目标14/14；补拖动中Overlay实际存在+缩放断言后组件5/5。全量显式NNUE根flutter test301/301 exit0（84139）、flutter analyze0问题exit0（43285）；原生坐标+新尺寸2/2 exit0（71222，00:21），源/UI业务与测试无运行失败。上片完整23/23，本片新增24未全跑24；核心未改65沿用。所有session已结束，日志/tmp/chessnext-piece-size-*.log。下一F26箭头显示补审计，继续推进。

### 2026-11-02 / E24 与追踪校正

实际参考本地分析验证推荐开关同时控蓝/粉箭头，变着关不去掉预计应着；尖/标准/宽头可见。恢复两开关与标准，明确checkbox0后结束，完整E19自制谱未落子。PW checkbox locator无匹配改fresh AX成功，失败不算停止。PV历史/小棋盘截图O新增B22。

核BACKLOG发现前三个显示切片错引用B15（它仍是领域规则），仅校正需求映射为B08/B20，不重排或改变旧ID含义；计划/追踪/进度行已同步，历史归档保留原记录。没有业务源码变更，无需空跑门槛，下一推荐组合开关/头部样式实现计划。

### 2026-11-02 / M3-22 推荐箭头组合与样式

ANALYSIS_ARROWS_SLICE/ADR-026；可选偏好/迟到独立字段合并/即时AnalysisMarkersDialog，Scope注入只读显隐/样式，BoardArrowsPainter拆离静态网格（临时TextPainter及时dispose）。严格按E24推荐组合控制两支，未把“变着”当预计应着独立开关。

新增2应用+3实际Canvas像素+4组件全通过：头面积顺序/恒定杆/方向/两色与重绘，实时Fake requests/stops不变/隐藏期间最新PV/重开/语义/点击/200%/存储重试。初analyze1大括号info补齐，测试无失败。首显式NNUE根310/310（72644）、analyze0（49420）、真实NNUE native1/1（3744）过；补临时绘图资源清理后最终根310/310（32031）、analyze0（45893）、native1/1（36716，00:13）exit0。native验证活动token/引擎身份不变及新App文件偏好恢复，当前25未全跑，上片完整23过。核心未改65沿用，实际OS视觉/其它平台未验。日志/tmp/chessnext-arrows-*.log；所有会话已结束。下一变着箭头局部开关联动调查，持续推进。

### 2026-11-02 / E25 本步变着箭头审计

实际访客自制树测试局部/全局双开关矩阵：都开才画上一局面本步同级绿箭头/编号；global关local可开但不画且不写global。设置返回局部关，不能据此把global当强制修改局部。单项也画，根无本步，回第一步局部关；点编号1中央一次未换步。恢复原支线末端/默认显示/分析0，无棋谱内容操作，证据及未知见E25。业务未改，无门槛空跑，下一M3-23实现全局偏好+会话局部标记与纯投影。

### 2026-11-02 / M3-23 本步编号箭头

按E25/VARIATION_ARROWS_SLICE/ADR-027，局部非文档flag默认关/根新文档设置清除、全局独立偏好；父局面稳定投影/缓存/最多64含当前原编号，绿色只读数字层复用几何，不拦90交点，列表完整。新业务未引资源/依赖。

初patch App设置showDialog回调多逗号导致format/analyze失败修复，随后大括号info和未用测试import修复。应用5+旧绘制3目标8过；组件/像素5+旧推荐4目标9过。显式官方NNUE根320/320（22549）和原生旧推荐+新变着2/2（71609，00:26）exit0。真实NNUEtoken未变、文档位置/内容修订及保存树不变，全局跨新App恢复局部关；根/换谱/旧回调/置顶删除/读屏/200%/大合法>64投影均验证。

清unused import后相关widget5/5（50684）；复核超限提示改为“最多64且保留当前”（原“前63及当前”在当前已在前63时不准确），最终显式NNUE根320/320（43252）、analyze无问题（6777）exit0。原生之后仅提示文案变动未重复，当前26未全跑，上次完整23过。核心未改65沿用，真实OS视觉及其它平台未验。日志/tmp/chessnext-variation-arrows-*.log，所有验证进程结束。下一局势条实际开关/缺数据与视角补审计。

### 2026-11-02 / E26 局势条调查

实际访客已停分析状态开关条/布局空间70↔68、旋转红黑方向交换，恢复原朝向/全局开/分析0。首点翻转只是菜单，截图按真实内容改名flip-menu，再点旋转后才记V。原站公式/完全空态未知，方案不凭CP造概率。纯调查无业务改动；下一本地原生WDL条。

## 2026-11-02 / M3-24 / F26 → B08,B17,B20 本地模型局势条

E26显隐/空间回收/随旋转方向/停止保留为V，原比例公式未知。纯BoardEvaluation以首PV原生WDL换红方预期得分（2W+D）/半和，不造CP概率；缺失/bound/mate0/预测杀棋/真实领域将死困毙独立，记录Result不裁决。EvaluationBoard只读/无动画/不反复播报，灰态问号、红黑文字与Tooltip，旋转与隐藏回收28dp；最低总宽492/464维持交点约48dp。可选showEvaluationBar默认开，逐字段晚到合并/持久化/错误重试，不改变搜索及谱。ADR-028/EVALUATION_BAR_SLICE。

新增模型5+组件5+真实像素1=11，覆盖两执方/缺失/边界/杀棋/终局/旧字段/晚到/失败重试、停止同位置保留/导航失效、搜索请求不变/翻转/200%/键盘/几何。显式官方NNUE根flutter test331/331（99436）与flutter analyze无问题（55541）exit0；完整macOS27/27（96958，04:53）exit0，含真实NNUEWDL/同令牌/条空间+28/停止翻转/文件偏好新App及完整旧功能回归。fixture raw[]，不等同真实OS生命周期/人工视觉；其它平台未验。核心未改65沿用。

初analyze8项info（3大括号/5插值花括号），限定dart fix两规则修复，最终0问题，运行测试无失败。日志/tmp/chessnext-evaluation-bar-{model,target,full,analyze-initial,analyze,native-full}.log，全部验证进程收尾。下一F21落子与选择样式实测，F26其它标记/B22仍未完成。

### 2026-11-02 / E27,E28 与证据元数据修正

着法标记开关V但当前图无确认差异，恢复开不猜对象。落子光圈/方框终点实际切换及源圆环/页间记忆V，恢复光圈，未改谱。PIL未安装，改标准库按JPEG SOF实际读取；发现E21–26截图扩展名.png但字节JPEG，此前清单把JPEG当PNG偏移，尺寸65536等错误，现全部据实际签名修mime/宽高，SHA不变，文件名保留兼容链接。不安装工具，不把原站动画时序未知当已验。下一F21独立落子标记切片。

## 2026-11-02 / M3-25 / F21 → B08,B20 最后一步落子标记

E28光圈/方框终点与源环、页间记忆已V。AppPreferences.lastMoveMarker可选halo旧默认/box，严格解析/逐字段合并/串行持久化；BoardDisplayDialog即时Dropdown，Scope只读参数。XiangqiBoard传当前move及(epoch,cursorId)，独立LastMoveMarkers只读叠加/IgnorePointer/语义，共用Square几何，根/编辑器无旧标记。600ms单周旋转后静止/系统减少动画中断/初始静止/首落子animateOnMount，方向及评注不重启，卸载dispose。时序为项目P，非原站完全同动画。ADR-029/LAST_MOVE_MARKER_SLICE。

新增应用2+组件4+实际像素1=7，含四方向源点终点/样式不同、无填充中心/200%与200%棋子/命中、根导航换谱编辑隔离、首落子及动画时序/减少动画、失败重试/新App/运行Fake requests和stops不变；加尺寸回归目标12/12（48659）。最终显式官方NNUE根flutter test338/338（78319，00:34）、flutter analyze无问题（82250）均exit0。macOS新用例1/1（59669，00:13）exit0，真实NNUEtoken/文件偏好/几何/保存树/导航翻转与新App恢复；当前28原生未全28，上片完整27已过。核心未改65沿用，真实OS减少动画设置/人工视觉与其它平台未验。

初analyze1大括号info修复，首目标5过2失败：完成帧还有额外调度帧、相同错误文案存在三层route；增加额外帧/稳定时间并限定BoardDisplayDialog查找，未删生产保护。native测试首静态分析session.next不存在，改现有forward；最终全门槛通过。日志/tmp/chessnext-last-move-{analyze-initial,analyze,analyze-final,target,target-final,full,native}.log，无待等待进程。下一选子抬起/框样式，研究E29自制样本已恢复，未改谱。

### 2026-11-02 / E29选子审计

IAB同自制谱只选黑马c7并再点取消，抬起上移阴影/绿色选择框实际V；设置回访记忆V，恢复抬起及未选子，未落子/改谱/启动分析。截图与AX摘要可追溯；仅研究无业务变更，下一F21选子样式。

## 2026-11-02 / M3-26 / F21 → B08,B20 选子样式

SelectionStyle lift/frame可选旧默认lift、严格解析/逐字段晚到合并/串行保存重试，棋盘显示即时Dropdown/Scope/主盘编辑器共用。抬起面容上移格距8%加阴影且transformHitTests=false，固定交点四角框不随尺寸缩放；90格/合法目标/语义/焦点保持，空位不抬起/画框，拖动反馈不带selected。无新增动画/IO/引擎所有者。E29实际功能边界，几何/编辑器为P；ADR-030/SELECTION_STYLE_SLICE。

新增应用2+组件4+实际像素1=7，含四方向×三尺寸×双样式、90交点/命中/selected语义、运行Fake requests/stops不改及同选中保持、失败重试与新App、编辑器镜像旋转/实际拖动反馈与取消、200%字号/键盘Enter和Escape、框中心无填充/四角像素。加旧编辑器/尺寸目标17/17（89701）通过；显式官方NNUE根345/345（46199，00:35）与analyze无问题（37459）exit0；macOS新单项1/1（11998，00:13）exit0，真实NNUEtoken不变/偏好文件新App/交点/保存树/编辑器旋转镜像与拖动取消保护。原生现29未全29，上片完整27过，核心未改65沿用。

本片初及最终analyze无问题，业务/组件/全量/原生无运行失败。日志/tmp/chessnext-selection-{analyze-initial,target,full,analyze,native}.log，全部会话结束。F21素材/原站精确几何/真实OS人工视觉/其它平台仍待；下一B22历史PV与小棋盘预览，E30已取只读点击/步进播放/0边界/Escape证据，尚未提交实现。

### 2026-11-02 / E30 PV历史预览

实际点击首卡PV开1/33、下一2、播放实际推进/暂停13、点首着/回0禁上一与提交，Escape后fresh AX确认主三着不变。未提交到棋盘，写谱仍U。先读只读rendered DOM定位span，无运行时/源码探测。恢复原自制谱/分析0，截图已嵌图。下一有界快照历史及只读预览。

## 2026-11-02 / M3-27 / F02,F13 → B08,B17,B22 当前局面PV历史

AnalysisHistory/PvHistoryEntry纯有界展示样本，64条×128步，深拷贝PV/不可变列表、源Position/epoch/nodeId/内容位置修订/原始info，按各PV最近内容去重time/nps-only，保留深度/评分/bound/WDL/token/PV变化。Controller复用100ms普通分析flush采样，无新流/引擎；停止/同位置重启保留，位置变化清空，显示清空不改搜索/谱，非持久缓存。Panel计数/清空，打开前捕获列表+方色，Dialog虚拟列表/可选择文字/源执方归一score和bound/WDL/杀棋0不判胜/截断说明。ADR-031/PV_HISTORY_SLICE。原站预算清理未知，64/128采样规则明确P；预览播放下一片，没加假入口，AI/复盘流不在本片。

新增纯模型4+控制器1+组件3=8，覆盖不可变拷贝/去重/有界/坏索引/双方评分/WDL边界、停止/迟到/换位置/资料与旋转/清空不改请求、modal固定快照/最新面板继续更新/200%长PV虚拟列表滚到末端/键盘Escape。目标最终8/8（63931）、显式官方NNUE根353/353（19885，00:36）、flutter analyze0问题（10739）exit0；macOS真实NNUE新项1/1（96003，00:12）exit0：同token、固定snapshot/停止保留/旋转资料不清/清空/换位置清。当前native30未全30，上片完整27过，核心未改65沿用。OS人工视觉/其它平台未验。

首3项大括号info限定dart fix修复；Panel patch格式上下文不符原子拒绝后核实际文本重应用；首目标6过2失败为未限定弹窗的最新+30误匹配、滚动500×120不足长谱末端，改限定Dialog及1500×160有界滚动，最终全通过。日志/tmp/chessnext-pv-history-{analyze-initial,target,target-final,analyze,full,native}.log，所有会话结束。下一PvPreview严格有界合法重放/worker只读棋盘与播放，不得把仅文本raw历史直接执行。

## 2026-11-02 / M3-28 / F02,F13 → B08,B17,B22 只读PV预览与播放

PvPreview工作Isolate最多128步整体合法重放/中文记谱/不可变Position序列，非法任一步整体拒绝，纯DTO/中文错误；原更长PV明确截断，不验证省略尾。历史预览入口、源评分/方向快照、loader/generation/mounted/route退场保护/错误重试；独立readonly BoardSurface无主树选择推荐，合并语义/ExcludeFocus，自适应分栏上下/虚拟列表随当前步。初1、0原局面/上一下一/首尾/点着/左右键，800ms播放/暂停/尾自动停/再播从0，失活/手动跳步/关闭停Timer。帮助已更新，无写谱按钮/未实现假入口；ADR-032/PV_PREVIEW_SLICE，具体时序布局为P。

新增模型3（真实worker/非法后缀/black源/128界限）+组件5（真实worker接历史且Fake请求stops与谱不变、计时播放/边界/键盘/失活/卸载、关闭迟到不影响新route、错误重试/内部路径不泄露、200%长PV末端/语义）；加历史回归目标11/11（5249）过。最终显式官方NNUE根361/361（48185，00:37）与analyze无问题（62423）exit0；macOS新项1/1（53828，00:11）exit0，实际NNUE/worker/首步局面/播放暂停/主树与修订/token不变、关闭回历史。现native31未全31，上片完整27过；核心未改65沿用，真实OS失活/人工视觉/其它平台未验。

初4大括号info限定dart fix；首目标7过1失败因新Flutter find.byTooltip返回RawTooltip不能cast IconButton，改按IconButton.tooltip取组件；fixture独立support/pv_history_entry.dart。最终所有门槛通过，日志/tmp/chessnext-pv-preview-{analyze-initial,target,target-final,analyze,full,analyze-final,native}.log，所有进程收尾。E31后续审计已实际只应用2/33前缀并回原点重复应用已有路径，原站跨位置仍保留1368历史；证据待研究commit，当前项目换位置清历史为局部差距，下一应用前缀及跨位置保留/保护。

### 2026-11-02 / E31前缀应用与历史补证

只用E19自制谱实测2/33追加两步、原分支保留，回源点重复相同前缀不见重复、最终回原阅读点但保留新增后续。历史1368跨该位置变与回退保留V，项目清空已转已知差距。全页文本first误命中新主谱后续，只导航，freshAX后限定engine-pv正确打开，不造成功。截图已嵌图，原站分析/AI0，无删除。下一前缀原子应用+停止/取消屏障，再跨位置历史。

## 2026-11-02 / M3-29 / F02,F13 → B08,B17,B22 PV所选前缀原子应用

PvPrefixAction/取消与枚举失败，预览打开时新鲜tree/epoch/内容位置revision及entry源node/FEN匹配；同源旧entry重开可绑定现有后续新快照，打开后变化失效。Controller复用disable/stop屏障，核generation/失败/取消后worker全树准备最多128步/2000节点，回来复查再单次commitContinuation；保留原节点/顺序/注释/metadata/epoch与库绑定，新节点内容revision+1，已有路径只位置revision/不dirty，不发布中间草稿。纯planner可注入，Worker闭包只GameTree+复制Moves。预览0/busy/stale禁用/停止播放/Close取消尚未提交，typed成功退出两个仍current/mounted的route，错误留预览，帮助已补。ADR-033/PV_APPLY_SLICE；K09旧手工等入口容量未统一，B16/B19追踪。

新增应用8+组件4=12，加旧预览5目标17/17（59687）；真实worker保留未来/分支评注/单notify/2000边界/已有复用不dirty/非法尾，停止与worker等待中的cancel/source变/新搜索/stop失败/busy；UI双route成功/0/来源即时失效/忙态Close与迟到/200%错误重试。最终显式官方NNUE根373/373（90009，00:39）+flutter analyze无问题（33296）exit0；**完整macOS32/32（36917，06:49）exit0**，包括全部前31项回归和新实际NNUE/stop+worker两步原子新增/保留原后续与资料/原生文件保存/新App完整恢复/旧entry同源重开复用不dirty。核心未改65沿用。fixture raw[]，不等同真实OS焦点/人工视觉/其它平台验收。

首Python UI补丁因format压缩actions断言失败（Preview原子未写，History/Controller先已改），首analyze4 API编译错+8info，补全接口后9 braces限定dart fix，callback改perform formal，最后1测试underscore info修wildcard；运行目标12、16、17/全量/原生均无失败。日志/tmp/chessnext-pv-apply-{analyze-initial,analyze-fixed,target,target-final,target-verified,analyze,full,analyze-final,native-full}.log，全会话收尾。证据清单64项实际字节/SHA/图片尺寸全一致，本地文档链接16项有效；首次临时核验错误假定每图1280×720导致E24一项误报，改按sips实际尺寸后0错误，清单无改。

下一M3-30保留本谱跨位置有界历史/来源标记与旧来源只读保护，修E31已知差距；跨文档原站行为/hover/其它源站深层/平台/后端等仍未完成，不停止给全量审查。

### 2026-11-02 / M3-30进行中

ADR-034修同谱跨位置保留，源Ply/着法标签/latest隔离；初目标score全页finder误匹配、200%棋盘81.6px实测失败，限定finder并紧凑布局整体滚动/300px棋盘区/200px步表，目标最终22（51108）及analyze0（35376）过。根显式NNUE38271仍跑，原生四项待跑，不能声明最终过。CURRENT_STATE/HANDOFF记进程和下一命令。

## 2026-11-02 / M3-30 / F02,F13 → B08,B17,B22 本谱跨局面PV历史

ADR-034修ADR-031换位置清历史：独立historyEpoch同文档共享64×128，换谱/新局清空，不改AI_lastSessionEpoch。位置变化仍清latest infos/pending/推荐/局势条，旧token不能进archive。Entry补sourcePly/中文sourceMoveLabel，位置变时算一次，flush复用；每条源Position/score/WDL独立冻结。历史本谱标题/来源、预览旧源只读/M3-29严格应用guard，回源重开可用、删除来源禁提交；帮助已同步。原站AX1368 items不等于确认卡数，已修E31错误表述。

新增应用3+组件2=5（两来源/双执方/WDL/迟到/元资料与flip/回源/新doc、共享预算、删除源readonly拒绝、UI旧源与Main独立/回源重开应用保留旧分支、200%可辨认），加相关模型/历史/预览/前缀目标22/22（51108）。最终显式官方NNUE根378/378（38271，00:40），flutter analyze无问题（44950，最终fixture改后）exit0。macOS相关首批4项（56503）：旧history/preview/prefix三项通过，新增cross-position滚动后tap未命中失败，没将首命令称全过。补ensureVisible后pumpAndSettle+hitTestable验证，新增单项1/1（40288，00:10）exit0。即相关3+重跑1已验；现33原生未全33，上片完整32/32（36917，06:49）过，核心未改65沿用。OS焦点/人工视觉/其它平台未验。

初目标11过2失败：全页score finder匹配主面板+Dialog，限定Dialog；新增source/stale文本下200%棋盘实测81.6px，生产改compact整体滚动（窄/短/大字号）+300px棋盘区域/独立200px虚拟列表，宽高够仍分栏；失败提示自动滚入视区。旧narrow语义测试先实际滚回board再查，没有弱化语义。目标最终22通过且200%棋盘>=240，全部初/最终analyze0问题。日志/tmp/chessnext-pv-archive-{analyze-initial,target,target-final,analyze,full,native,native-final,analyze-final}.log，验证全部会话结束。

E32着法标记审计已操作完成raw证据未提交：快速depth4/线程1完成后徽标出现，结果开关与设置联动，关只去board徽标/评估数据和变着星号仍在；图例9类含常规2/5/10/20%与妙手/绝佳/错失/更快杀法。恢复全局开/原彻底模式/自制原阅读点，保留Quick新增分析数据。下一独立研究commit，再F26只读当前着法评级徽标，源站算法不冒充本机模型。

### 2026-11-02 / E32着法标记补审计

自制谱Quick D4/线程1，出现绿色好着勾；结果/设置同值，关只去棋盘徽标不去最后落子光圈/胜率变化/变着最佳星号。图例10类上下滚动V，常规阈值文字/O声明，高级公式仍U。恢复标记开/原彻底模式，最后skip1取消，重开分析默认skip0V单独记录；无弹窗、AI分析0，保留Quick新增评估但没改棋树。图片已commentary嵌图，下一F26本机评级徽标。研究无业务变更，未空跑Flutter门槛。

## 2026-11-02 / M3-31 / F26 → B08,B18 当前着本机评级徽标

ADR-035/MOVE_GRADE_MARKER_SLICE：纯单节点评级复用v1、run+node缓存/源身份保护、固定交点只读角徽与语义、Material原创图标/六类滚动说明、两入口同全局showMoveGrades偏好/保存失败重试/新实例恢复。关只徽标，数字/光圈保留，不改搜索或棋谱。E32 BACKLOG“v1<2等号不同”经原始代码复核为误判，已勘误，不改算法版本。高级四类/原站公式仍U。

目标原报告7+新增应用3/组件4=14/14（81530）exit0；官方NNUE根最终385/385（30612，00:42）与flutter analyze无问题（93098，2.3秒）exit0；新增macOS实际NNUE三局面WDL、徽标/翻转/双入口/真实FilePreferences新App恢复1/1（6123，00:10）exit0。现34未全34，最近完整32/32沿用。core未改65/65+dart analyze沿用，OS人工视觉/其它平台未验。

初analyze3错因缓存字段误放extension，移到Controller；首目标Material fixture漏Material且fake timer不推进卡住，Ctrl-C结束非通过；再编译因删掉extension所在import失败，补import；再目标错误/重试全页finder非唯一，限定MoveGradeControls后目标14过。首根384过1失败为旧text_size_test全页开关非唯一，改限定TextSizeDialog，不改生产字号逻辑；最终全量385通过。初/修正analyze记录和所有目标/根/native日志/tmp/chessnext-grade-{analyze-initial,analyze-final,analyze-corrected,analyze-gate,analyze-final-gate,target,target-final,target-corrected,target-verified,target-pass,full,full-final,native}.log，验证session全部已消费。新增依赖/外部资源为0，git diff --check通过。

下一F32模式选择取消记忆/重新分析skip默认关（E12/E32），继续其它站点缺项，不称全部对齐。
