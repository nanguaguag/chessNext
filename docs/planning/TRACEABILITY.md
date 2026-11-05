# 需求追踪

## 2026-11-05 / M4-87 / F27 棋子样式比例、偏移和阴影文案

棋子样式独立大小、位置值、四方向/自动归中语义、阴影预设和参数滑杆说明加入zh/en ARB；不改偏好/绘制逻辑。仍有棋子图片/样式与音效说明、动画/声音、皮肤库/导入导出子对话框等文本未迁移。根Locale固定zh。

验收：定向`flutter test --concurrency=1 test/widgets/board_display_localization_test.dart test/application/piece_skin_shadow_test.dart --reporter expanded`9/9；根`flutter test --concurrency=1 --reporter expanded`631通过/5跳过/0失败；`flutter analyze --no-pub`与`git diff --check`通过。macOS GUI未重启，运行/视觉not run。

## 2026-11-05 / M4-86 / F27,B24 格点与边距本地化

棋盘几何设置中的四边字段、比例、落点旋转、重置和弹窗动作以及BoardGeometryEditor的AX标签/坐标/提示/自定义方向Action加入zh/en ARB。只做本地化，不修改ADR-054项目归一化几何或将其映射到站点未知单位/行为。根Locale保持zh。

验收：定向`flutter test --concurrency=1 test/widgets/board_display_localization_test.dart test/widgets/board_geometry_editor_test.dart --reporter expanded`6/6；根`flutter test --concurrency=1 --reporter expanded`631通过/5跳过/0失败（`/tmp/chessnext-root-test-m4-86.log`）；`flutter analyze --no-pub`和`git diff --check`通过。5项引擎测试仍需官方Pikafish/NNUE。macOS运行/视觉not run，为防止GUI实例增殖没有另行`flutter run`。

## 2026-11-05 / M4-85 / F27 棋盘显示设置基础项本地化

BoardDisplayDialog基础显示项消费M4-84 ARB资源：标题、棋盘/棋子皮肤字段、棋子大小/语义、尺寸帮助、显示坐标、对面一侧棋子旋转与本机应用说明。英文组件测试使用隔离MaterialApp locale，不改变产品根Locale(zh)，避免其它设置仍中文时暴露混合语言。皮肤/动画/声音/阴影/几何等大量设置尚未迁移，F27不关闭。

验证：定向`flutter test --concurrency=1 test/widgets/board_display_localization_test.dart --reporter expanded`1/1；根`flutter test --concurrency=1 --reporter expanded`631通过/5跳过/0失败（`/tmp/chessnext-root-test-m4-85.log`）；`flutter analyze --no-pub`与`git diff --check`通过。5项跳过依赖官方Pikafish/NNUE。未执行`flutter run -d macos`，避免增加GUI实例；本片macOS运行/视觉未验。

## 2026-11-05 / M4-84 / F27 / ADR-114 首个ARB本地化切片

增加Flutter `gen-l10n`/ARB管线及简体中文模板、English资源。把TextSizeDialog的标题、follow系统、当前值、预设、示例、帮助、关闭/重试、slider语义和系统字号百分比全部改为命名资源；默认App根强制简体中文且仅支持简体Locale，避免English系统设备看到混合界面。独立测试以English Localizations包裹同一组件，验证文案/slider语义；保留默认App的简体行为。该English资源只覆盖字号弹窗，尚无生产Locale切换；不代表F27完成。

验证：定向`flutter test --concurrency=1 test/widgets/text_size_test.dart --reporter expanded`7/7；根`flutter test --concurrency=1 --reporter expanded`630通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-84.log`；`flutter analyze --no-pub`、`dart format`和`git diff --check`通过；`flutter build macos --no-pub`成功（113.0MB；flutter_tts SwiftPM提示与objective_c多架构资源警告）。根测试单串行flutter_tester，结束后已退出；实际macOS运行/视觉未验，为避免重复窗口未运行`flutter run`。

## 2026-11-05 / M4-83 / F15,F20 / ADR-113 大师谱授权整局只读预览

自建索引记录增加可选受权PGN。`POST /v1/master-games/query`仍仅返回metadata和`hasRecord`；用户点击结果后由`GET /v1/master-games/records/<id>`按ID懒加载。服务端对PGN限制64,000 UTF-8字节并校验控制字符，未提供/未知ID明确404，详情附dataset/license/attribution和精确查询FEN/完整历史。客户端适配器严格校验响应大小/字段/记录ID；控制器核对当前查询来源/局面/完整历史、主线PGN到目标位置的路径以及可用棋手/赛事标签，并在筛选、文档、位置变化后丢弃迟到结果。独立对话框复制PGN树提供棋盘、主线及着法导航，不改主`BoardSession`。Nginx关闭两个路径的访问日志并应用目录限速。本仓库仍不含棋谱语料；授权真实性、真实自托管部署及源站整局操作语义仍U，F15不关闭。

验收：定向Flutter16/16；根`flutter test --concurrency=1 --reporter expanded`629通过/5跳过/0失败（`/tmp/chessnext-root-test-m4-83-final.log`）；`flutter analyze --no-pub`、格式及diff检查通过；`cd server/skin_catalog && dart test`6/6，`dart analyze`通过；`flutter build macos --no-pub`成功。macOS实际运行/热重启/视觉未验证：既有PID50598无法attach，为避免重复窗口未执行`flutter run`。根测试仅一个串行tester，结束后已退出。

定向`flutter test --concurrency=1 test/server/master_games_server_test.dart test/adapters/network/http_master_games_service_test.dart test/application/master_games_lookup_controller_test.dart test/widgets/cloud_book_panel_test.dart test/widgets/master_game_review_dialog_test.dart --reporter expanded`16/16通过；`flutter analyze --no-pub`通过。随后一致性校验又更新了代码；因此最终根全量、独立服务包测试/analyze、macOS构建/复用实例运行验收须以本条目后续结果为准，尚未将功能提交。

## 2026-11-05 / E72 / F21,B24 棋盘边距stepper单步复核

访客桌面IAB `/settings`→棋盘与棋子→棋盘→既有“我的棋盘”编辑，初始格点50/50、左33/上33/右465/下519、缩放100%。左边距加号一次后左33.5、右465.02；再点减号复原33/465。退出编辑确认丢弃，返回后页面复读默认棋盘/棋子、全局100%、坐标开、对面倒置关，再回原`#/settings`。未保存/使用/导出。该单步补强E44/E64左步进联动，不扩展为其它轴或全局公式；完整几何继续U。证据见REFERENCE_EVIDENCE E72。

## 2026-11-04 / B24 棋盘格点、边距与缩放设计

参考页打开到`https://xiangqiai.com/#/settings/skins/edit/new?type=board`的空白棋盘草稿，格子tab初值仍为左上/右下格点50、四边stepper左33/上33/右465/下519、棋子缩放100%。截图确认两蓝点位于预览棋盘交点；未改动几何，也未触发导出/使用/保存。返回后确认丢弃，最终AX回`#/settings/board`：默认棋子/棋盘、100%、坐标开、对面倒置关。没有棋谱变化。未新增边界证据。

新增ADR-054项目提案P：归一化格网矩形、Square映射统一驱动绘制/标记/命中/坐标、皮肤棋子缩放80–120%与全局面容比例相乘、图片/GIF快照冻结几何，并明确本机草稿保存/应用/取消边界。源站数值单位/范围/联动/成功语义仍U。落点图旋转另切片。本轮仅审计/设计，无业务实现、测试、macOS运行或功能提交。

## 2026-11-04 / M4-18 / F21 → B24 棋盘格网几何

新增`BoardSkinGeometry`纯Dart不可变配置，归一化画布四边并含当前棋盘预设独立棋子面容比例80–120%/1%步进。棋盘两预设各自存储，旧偏好缺字段映射标准9×10网格；坏类型/坏范围拒绝。几何项目边界为四边1%–99%、跨度至少55%、设置滑杆半个百分点步进并可恢复默认（P）。`BoardDisplayScope`向主盘/编辑器/导出预览提供只读值；BoardSurface用统一Translate+Scale变换覆盖棋盘背景、格线、棋子、末步/选子标记、分析箭头和评级，Flutter逆变换命中回原交点；独立棋子比例与现有全局/棋子样式缩放相乘，只改面容。横向坐标轨按相同端点定位；PGN/棋树/规则/搜索不变。BoardImageSnapshot与BoardGifSnapshot冻结活动预设几何和比例。

测试：`flutter test test/application/board_skin_geometry_test.dart test/application/board_image_snapshot_test.dart test/widgets/board_coordinates_test.dart --reporter compact` 14/14通过，覆盖序列化边界、预设迟到读取合并、快照、四方向坐标、变形后交点命中和设置持久化；根`flutter test --reporter compact`473通过/5跳过（官方Pikafish/NNUE环境缺失），`flutter analyze`无问题。`flutter run -d macos`构建、同步并启动PID49586/VM `127.0.0.1:58562`；CUA app窗口读取两次超时，因此实际窗口视觉验收not run。首轮专项widget测试因缺Material祖先失败，补Material后14/14通过；首轮全量输出未完整保留，随后以`/tmp/chessnext-board-geometry-root-test.log`重跑并获exit0。未引入依赖或外部资源。

几何项目P已实现；源站slider真实min/max/step、四边耦合算法、棋子缩放语义和保存/使用/导出仍U。M4-19继续落点标记图旋转，按ADR-054单周完成后静止并遵循现有动画速度/系统减少动画，此时序是P而非源站证据；之后继续F21皮肤列表/导入/阴影等差距。

需求→证据与模块见 FEATURE_MATRIX；需求→待办见 BACKLOG；待办→阶段见 MILESTONES。本文件定义验证分组，不代表已通过。

| 测试组 | 需求 | 证据 | 验收方式 |
|---|---|---|---|
| T01 规则/棋盘/编辑 | F01,F04–F06,F23 | E01,E03,E08 | 纯领域用例+组件/触控实测 |
| T02 搜索/对弈/资源 | F02,F03,F22,F24,F25 | E01,E02,E08 | 真实UCI+fake竞态+五平台 |
| T03 文档/格式/仓库 | F07,F08,F10–F13,F16,F18 | E04–E06 | 自制样本往返+事务/迁移 |
| T04 复盘/训练 | F14,F17,F32 | E01,E07,E09 | 评分基准+取消恢复+练习流程 |
| T05 云端/识别/认证 | F09,F15,F30 | E01,E04 | 可替换服务contract+离线/隐私 |
| T06 体验/支持 | F19–F21,F26–F29,F31 | E01,E08 | 明暗/字号/键盘/读屏/平台菜单 |

M4-36 F19/B26/ADR-071：`lib/app.dart`；`test/widgets/floating_workspace_test.dart`（切换、底部操作、退出往返）。专项通过；根测试510通过/5跳过；analyze通过；macOS现有runner热重载通过，CUA人工点击not run（`noWindowsAvailable`）。仍待四分隔条实现、原生窗口语义与键盘/触屏验收。

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

## 2026-11-02 / M3-23 / F13,F26 → B08,B17,B20 本步编号变着箭头

E25已V双开关共同门控、父局面同级/单项/根无本步/根与设置返回局部重置；一个编号点未导航。项目CurrentMoveArrows纯投影/树对象缓存/最多64保留当前原编号，BoardSession局部非文档状态与旧epoch保护，showVariationArrows可选全局偏好；绿色只读数字层复用几何/样式，不拦落子，编辑器无旧树。ADR-027/VARIATION_ARROWS_SLICE。

新增5应用+4组件+1实际绿色数字像素=10；加旧绘制目标8/8、加旧推荐组件目标9/9。大合法局面超64投影实证保留当前/原编号；运行中Fake实际requests/stops不变、树/修订不变/根重置/新文档/置顶删除/200%/读屏/命中。显式NNUE根首320/320（22549），macOS旧推荐+新变着2/2（71609，00:26）exit0，真实NNUEtoken不变/保存树与内容位置修订不改/全局偏好及新App读取恢复、局部不恢复。

初App设置回调patch多逗号导致format/analyze编译失败，修为正常showDialog语句；随后1大括号info、最后1未用测试import清理。相关widget最终5/5；最后只改超限提示准确措辞（最多64且含当前），最终根320/320 exit0（43252）与analyze0（6777）。原生当前26未全26，上片完整23过；核心未改65沿用。其它平台/真实OS焦点/人工视觉未验。日志/tmp/chessnext-variation-arrows-{projection,widget,widget-final,full,full-final,analyze-initial,analyze-fixed,analyze,analyze-final,analyze-verified,native}.log，全部会话结束。

## 2026-11-02 / M3-24 / F26 → B08,B17,B20 本地模型局势条

E26显隐/空间回收/随旋转方向/停止保留为V，原比例公式未知。纯BoardEvaluation以首PV原生WDL换红方预期得分（2W+D）/半和，不造CP概率；缺失/bound/mate0/预测杀棋/真实领域将死困毙独立，记录Result不裁决。EvaluationBoard只读/无动画/不反复播报，灰态问号、红黑文字与Tooltip，旋转与隐藏回收28dp；最低总宽492/464维持交点约48dp。可选showEvaluationBar默认开，逐字段晚到合并/持久化/错误重试，不改变搜索及谱。ADR-028/EVALUATION_BAR_SLICE。

新增模型5+组件5+真实像素1=11，覆盖两执方/缺失/边界/杀棋/终局/旧字段/晚到/失败重试、停止同位置保留/导航失效、搜索请求不变/翻转/200%/键盘/几何。显式官方NNUE根flutter test331/331（99436）与flutter analyze无问题（55541）exit0；完整macOS27/27（96958，04:53）exit0，含真实NNUEWDL/同令牌/条空间+28/停止翻转/文件偏好新App及完整旧功能回归。fixture raw[]，不等同真实OS生命周期/人工视觉；其它平台未验。核心未改65沿用。

初analyze8项info（3大括号/5插值花括号），限定dart fix两规则修复，最终0问题，运行测试无失败。日志/tmp/chessnext-evaluation-bar-{model,target,full,analyze-initial,analyze,native-full}.log，全部验证进程收尾。下一F21落子与选择样式实测，F26其它标记/B22仍未完成。

## 2026-11-02 / M3-25 / F21 → B08,B20 最后一步落子标记

E28光圈/方框终点与源环、页间记忆已V。AppPreferences.lastMoveMarker可选halo旧默认/box，严格解析/逐字段合并/串行持久化；BoardDisplayDialog即时Dropdown，Scope只读参数。XiangqiBoard传当前move及(epoch,cursorId)，独立LastMoveMarkers只读叠加/IgnorePointer/语义，共用Square几何，根/编辑器无旧标记。600ms单周旋转后静止/系统减少动画中断/初始静止/首落子animateOnMount，方向及评注不重启，卸载dispose。时序为项目P，非原站完全同动画。ADR-029/LAST_MOVE_MARKER_SLICE。

新增应用2+组件4+实际像素1=7，含四方向源点终点/样式不同、无填充中心/200%与200%棋子/命中、根导航换谱编辑隔离、首落子及动画时序/减少动画、失败重试/新App/运行Fake requests和stops不变；加尺寸回归目标12/12（48659）。最终显式官方NNUE根flutter test338/338（78319，00:34）、flutter analyze无问题（82250）均exit0。macOS新用例1/1（59669，00:13）exit0，真实NNUEtoken/文件偏好/几何/保存树/导航翻转与新App恢复；当前28原生未全28，上片完整27已过。核心未改65沿用，真实OS减少动画设置/人工视觉与其它平台未验。

初analyze1大括号info修复，首目标5过2失败：完成帧还有额外调度帧、相同错误文案存在三层route；增加额外帧/稳定时间并限定BoardDisplayDialog查找，未删生产保护。native测试首静态分析session.next不存在，改现有forward；最终全门槛通过。日志/tmp/chessnext-last-move-{analyze-initial,analyze,analyze-final,target,target-final,full,native}.log，无待等待进程。下一选子抬起/框样式，研究E29自制样本已恢复，未改谱。

## 2026-11-02 / M3-26 / F21 → B08,B20 选子样式

SelectionStyle lift/frame可选旧默认lift、严格解析/逐字段晚到合并/串行保存重试，棋盘显示即时Dropdown/Scope/主盘编辑器共用。抬起面容上移格距8%加阴影且transformHitTests=false，固定交点四角框不随尺寸缩放；90格/合法目标/语义/焦点保持，空位不抬起/画框，拖动反馈不带selected。无新增动画/IO/引擎所有者。E29实际功能边界，几何/编辑器为P；ADR-030/SELECTION_STYLE_SLICE。

新增应用2+组件4+实际像素1=7，含四方向×三尺寸×双样式、90交点/命中/selected语义、运行Fake requests/stops不改及同选中保持、失败重试与新App、编辑器镜像旋转/实际拖动反馈与取消、200%字号/键盘Enter和Escape、框中心无填充/四角像素。加旧编辑器/尺寸目标17/17（89701）通过；显式官方NNUE根345/345（46199，00:35）与analyze无问题（37459）exit0；macOS新单项1/1（11998，00:13）exit0，真实NNUEtoken不变/偏好文件新App/交点/保存树/编辑器旋转镜像与拖动取消保护。原生现29未全29，上片完整27过，核心未改65沿用。

本片初及最终analyze无问题，业务/组件/全量/原生无运行失败。日志/tmp/chessnext-selection-{analyze-initial,target,full,analyze,native}.log，全部会话结束。F21素材/原站精确几何/真实OS人工视觉/其它平台仍待；下一B22历史PV与小棋盘预览，E30已取只读点击/步进播放/0边界/Escape证据，尚未提交实现。

## 2026-11-02 / M3-27 / F02,F13 → B08,B17,B22 当前局面PV历史

AnalysisHistory/PvHistoryEntry纯有界展示样本，64条×128步，深拷贝PV/不可变列表、源Position/epoch/nodeId/内容位置修订/原始info，按各PV最近内容去重time/nps-only，保留深度/评分/bound/WDL/token/PV变化。Controller复用100ms普通分析flush采样，无新流/引擎；停止/同位置重启保留，位置变化清空，显示清空不改搜索/谱，非持久缓存。Panel计数/清空，打开前捕获列表+方色，Dialog虚拟列表/可选择文字/源执方归一score和bound/WDL/杀棋0不判胜/截断说明。ADR-031/PV_HISTORY_SLICE。原站预算清理未知，64/128采样规则明确P；预览播放下一片，没加假入口，AI/复盘流不在本片。

新增纯模型4+控制器1+组件3=8，覆盖不可变拷贝/去重/有界/坏索引/双方评分/WDL边界、停止/迟到/换位置/资料与旋转/清空不改请求、modal固定快照/最新面板继续更新/200%长PV虚拟列表滚到末端/键盘Escape。目标最终8/8（63931）、显式官方NNUE根353/353（19885，00:36）、flutter analyze0问题（10739）exit0；macOS真实NNUE新项1/1（96003，00:12）exit0：同token、固定snapshot/停止保留/旋转资料不清/清空/换位置清。当前native30未全30，上片完整27过，核心未改65沿用。OS人工视觉/其它平台未验。

首3项大括号info限定dart fix修复；Panel patch格式上下文不符原子拒绝后核实际文本重应用；首目标6过2失败为未限定弹窗的最新+30误匹配、滚动500×120不足长谱末端，改限定Dialog及1500×160有界滚动，最终全通过。日志/tmp/chessnext-pv-history-{analyze-initial,target,target-final,analyze,full,native}.log，所有会话结束。下一PvPreview严格有界合法重放/worker只读棋盘与播放，不得把仅文本raw历史直接执行。

## 2026-11-02 / M3-28 / F02,F13 → B08,B17,B22 只读PV预览与播放

PvPreview工作Isolate最多128步整体合法重放/中文记谱/不可变Position序列，非法任一步整体拒绝，纯DTO/中文错误；原更长PV明确截断，不验证省略尾。历史预览入口、源评分/方向快照、loader/generation/mounted/route退场保护/错误重试；独立readonly BoardSurface无主树选择推荐，合并语义/ExcludeFocus，自适应分栏上下/虚拟列表随当前步。初1、0原局面/上一下一/首尾/点着/左右键，800ms播放/暂停/尾自动停/再播从0，失活/手动跳步/关闭停Timer。帮助已更新，无写谱按钮/未实现假入口；ADR-032/PV_PREVIEW_SLICE，具体时序布局为P。

新增模型3（真实worker/非法后缀/black源/128界限）+组件5（真实worker接历史且Fake请求stops与谱不变、计时播放/边界/键盘/失活/卸载、关闭迟到不影响新route、错误重试/内部路径不泄露、200%长PV末端/语义）；加历史回归目标11/11（5249）过。最终显式官方NNUE根361/361（48185，00:37）与analyze无问题（62423）exit0；macOS新项1/1（53828，00:11）exit0，实际NNUE/worker/首步局面/播放暂停/主树与修订/token不变、关闭回历史。现native31未全31，上片完整27过；核心未改65沿用，真实OS失活/人工视觉/其它平台未验。

初4大括号info限定dart fix；首目标7过1失败因新Flutter find.byTooltip返回RawTooltip不能cast IconButton，改按IconButton.tooltip取组件；fixture独立support/pv_history_entry.dart。最终所有门槛通过，日志/tmp/chessnext-pv-preview-{analyze-initial,target,target-final,analyze,full,analyze-final,native}.log，所有进程收尾。E31后续审计已实际只应用2/33前缀并回原点重复应用已有路径，原站跨位置仍保留1368历史；证据待研究commit，当前项目换位置清历史为局部差距，下一应用前缀及跨位置保留/保护。

## 2026-11-02 / M3-29 / F02,F13 → B08,B17,B22 PV所选前缀原子应用

PvPrefixAction/取消与枚举失败，预览打开时新鲜tree/epoch/内容位置revision及entry源node/FEN匹配；同源旧entry重开可绑定现有后续新快照，打开后变化失效。Controller复用disable/stop屏障，核generation/失败/取消后worker全树准备最多128步/2000节点，回来复查再单次commitContinuation；保留原节点/顺序/注释/metadata/epoch与库绑定，新节点内容revision+1，已有路径只位置revision/不dirty，不发布中间草稿。纯planner可注入，Worker闭包只GameTree+复制Moves。预览0/busy/stale禁用/停止播放/Close取消尚未提交，typed成功退出两个仍current/mounted的route，错误留预览，帮助已补。ADR-033/PV_APPLY_SLICE；K09旧手工等入口容量未统一，B16/B19追踪。

新增应用8+组件4=12，加旧预览5目标17/17（59687）；真实worker保留未来/分支评注/单notify/2000边界/已有复用不dirty/非法尾，停止与worker等待中的cancel/source变/新搜索/stop失败/busy；UI双route成功/0/来源即时失效/忙态Close与迟到/200%错误重试。最终显式官方NNUE根373/373（90009，00:39）+flutter analyze无问题（33296）exit0；**完整macOS32/32（36917，06:49）exit0**，包括全部前31项回归和新实际NNUE/stop+worker两步原子新增/保留原后续与资料/原生文件保存/新App完整恢复/旧entry同源重开复用不dirty。核心未改65沿用。fixture raw[]，不等同真实OS焦点/人工视觉/其它平台验收。

首Python UI补丁因format压缩actions断言失败（Preview原子未写，History/Controller先已改），首analyze4 API编译错+8info，补全接口后9 braces限定dart fix，callback改perform formal，最后1测试underscore info修wildcard；运行目标12、16、17/全量/原生均无失败。日志/tmp/chessnext-pv-apply-{analyze-initial,analyze-fixed,target,target-final,target-verified,analyze,full,analyze-final,native-full}.log，全会话收尾。证据清单64项实际字节/SHA/图片尺寸全一致，本地文档链接16项有效；首次临时核验错误假定每图1280×720导致E24一项误报，改按sips实际尺寸后0错误，清单无改。

下一M3-30保留本谱跨位置有界历史/来源标记与旧来源只读保护，修E31已知差距；跨文档原站行为/hover/其它源站深层/平台/后端等仍未完成，不停止给全量审查。

## 2026-11-02 / M3-30 / F02,F13 → B08,B17,B22 本谱跨局面PV历史

ADR-034修ADR-031换位置清历史：独立historyEpoch同文档共享64×128，换谱/新局清空，不改AI_lastSessionEpoch。位置变化仍清latest infos/pending/推荐/局势条，旧token不能进archive。Entry补sourcePly/中文sourceMoveLabel，位置变时算一次，flush复用；每条源Position/score/WDL独立冻结。历史本谱标题/来源、预览旧源只读/M3-29严格应用guard，回源重开可用、删除来源禁提交；帮助已同步。原站AX1368 items不等于确认卡数，已修E31错误表述。

新增应用3+组件2=5（两来源/双执方/WDL/迟到/元资料与flip/回源/新doc、共享预算、删除源readonly拒绝、UI旧源与Main独立/回源重开应用保留旧分支、200%可辨认），加相关模型/历史/预览/前缀目标22/22（51108）。最终显式官方NNUE根378/378（38271，00:40），flutter analyze无问题（44950，最终fixture改后）exit0。macOS相关首批4项（56503）：旧history/preview/prefix三项通过，新增cross-position滚动后tap未命中失败，没将首命令称全过。补ensureVisible后pumpAndSettle+hitTestable验证，新增单项1/1（40288，00:10）exit0。即相关3+重跑1已验；现33原生未全33，上片完整32/32（36917，06:49）过，核心未改65沿用。OS焦点/人工视觉/其它平台未验。

初目标11过2失败：全页score finder匹配主面板+Dialog，限定Dialog；新增source/stale文本下200%棋盘实测81.6px，生产改compact整体滚动（窄/短/大字号）+300px棋盘区域/独立200px虚拟列表，宽高够仍分栏；失败提示自动滚入视区。旧narrow语义测试先实际滚回board再查，没有弱化语义。目标最终22通过且200%棋盘>=240，全部初/最终analyze0问题。日志/tmp/chessnext-pv-archive-{analyze-initial,target,target-final,analyze,full,native,native-final,analyze-final}.log，验证全部会话结束。

E32着法标记审计已操作完成raw证据未提交：快速depth4/线程1完成后徽标出现，结果开关与设置联动，关只去board徽标/评估数据和变着星号仍在；图例9类含常规2/5/10/20%与妙手/绝佳/错失/更快杀法。恢复全局开/原彻底模式/自制原阅读点，保留Quick新增分析数据。下一独立研究commit，再F26只读当前着法评级徽标，源站算法不冒充本机模型。

## 2026-11-02 / M3-31 / F26 → B08,B18 当前着本机评级徽标

ADR-035/MOVE_GRADE_MARKER_SLICE：纯单节点评级复用v1、run+node缓存/源身份保护、固定交点只读角徽与语义、Material原创图标/六类滚动说明、两入口同全局showMoveGrades偏好/保存失败重试/新实例恢复。关只徽标，数字/光圈保留，不改搜索或棋谱。E32 BACKLOG“v1<2等号不同”经原始代码复核为误判，已勘误，不改算法版本。高级四类/原站公式仍U。

目标原报告7+新增应用3/组件4=14/14（81530）exit0；官方NNUE根最终385/385（30612，00:42）与flutter analyze无问题（93098，2.3秒）exit0；新增macOS实际NNUE三局面WDL、徽标/翻转/双入口/真实FilePreferences新App恢复1/1（6123，00:10）exit0。现34未全34，最近完整32/32沿用。core未改65/65+dart analyze沿用，OS人工视觉/其它平台未验。

初analyze3错因缓存字段误放extension，移到Controller；首目标Material fixture漏Material且fake timer不推进卡住，Ctrl-C结束非通过；再编译因删掉extension所在import失败，补import；再目标错误/重试全页finder非唯一，限定MoveGradeControls后目标14过。首根384过1失败为旧text_size_test全页开关非唯一，改限定TextSizeDialog，不改生产字号逻辑；最终全量385通过。初/修正analyze记录和所有目标/根/native日志/tmp/chessnext-grade-{analyze-initial,analyze-final,analyze-corrected,analyze-gate,analyze-final-gate,target,target-final,target-corrected,target-verified,target-pass,full,full-final,native}.log，验证session全部已消费。新增依赖/外部资源为0，git diff --check通过。

下一F32模式选择取消记忆/重新分析skip默认关（E12/E32），继续其它站点缺项，不称全部对齐。

## 2026-11-02 / M3-32 / F32 → B08,B09 复盘配置恢复

ADR-036/REVIEW_CONFIGURATION_SLICE：reviewMode为严格可选枚举/独立晚读合并/串行持久化，方式切换即时保存且取消保留，不启动或停止已有分析；对话框可见失败/重试，真实文件新App恢复。已有部分/完整/stale评分结果重开skip默认关，手动开仍可复用缓存，初次无结果仍默认开；skip不记为全局偏好，API默认和完整缓存键不变。其它预算/范围仍每次默认；源模式页间V/跨App是P。

新增应用2/组件3共5，连既有复盘/多候选目标10/10（93046，00:04）exit0。显式官方NNUE根初390/390（91602，00:44）过，随后补帮助文案再次全量最终390/390（49975，00:42）exit0；最终flutter analyze无问题（15635，2.4秒）exit0。macOS真实NNUE完成后配置重开/取消不重算/模式文件新App恢复1/1（85476，00:11）exit0，现35未全35，最近完整32/32仍M3-29基线。core未改65/65+dart analyze沿用，OS/其它平台未验。

初analyze1条curly info修加括号；首目标9过1失败是缓存复用fixture使用未验证身份FakeEngine，系统正确拒绝复用，改用已有VerifiedFake（不改生产缓存安全策略），最终10过。日志/tmp/chessnext-review-config-{analyze-initial,analyze-final,analyze-gate,target,target-final,full,full-final,native}.log，所有session已结束；无新依赖/资产，git diff --check0。下一K09统一新增入口2000节点容量与可恢复失败，继续其余全部对标缺项。

## 2026-11-02 / M3-33 / F01,F03,F10,F13 → B16,B17,B19 / K09 统一节点容量

ADR-037/DOCUMENT_CAPACITY_SLICE：GameTree.maxNodes=2000含根/复用已有优先/合法新增前类型化GameTreeCapacityException，fromJson/文字PGN/仓库/最近阅读/PV容量消息同源。Session手工/fromEngine/同级捕获MoveRejection.capacity，一次通知不改tree/metadata/epoch/revision/positionRevision/dirty/选子；满谱导航/评注/已有复用/保存可用，删除后ID递增继续。AI容量暂停执方/代次/排程并解锁，保留Gateway可直接分析，不走_failed销毁或循环重搜；CandidateApplyResult明确capacity/过期/stopFailed，旧bool兼容。PV整段原子容量边界回归。K09节点部分解决；独立4MiB编码限制仍K10代码审计待UI超限实测，不能称所有容量风险消除。

新增core2、应用3、组件2共7（根新增5）；目标16/16（78961）过，core最终dart test67/67（90140，00:01）+dart analyze无问题（74714）exit0；显式官方NNUE根最终395/395（88333，00:46）+flutter analyze无问题（2394，2.4秒）exit0。macOS真实2000浅合法树/AI收到bestmove容量暂停后同一NNUE继续WDL分析/FileGameRepository保存新App恢复含评注元资料1/1（57594，00:11）exit0。初全量395（89831）/native1（39381）亦过，末补所有数量常量引用后最终再次全量/core/native确认。现36未全36，最近完整native32/32仍M3-29；真实OS/其它平台未验。

首analyze2条curly info加括号；首目标9过2失败（fixture误假定n1有缺失合法子着、首候选searchMoves为空）；改合法浅树保留一root合法着未录入/首候选允许集合用legalMoves，但替换漏格式化后旧n1仍1失败；定位并改root后11过，新增组件连旧候选/PV目标最终16过。未弱化真实容量或造假树，无测试后门。日志/tmp/chessnext-capacity-{analyze-initial,analyze-fixed,analyze-gate,analyze-final,target,target-fixed,target-final,target-widgets,core,core-final,core-analyze,core-analyze-final,full,full-final,native,native-final}.log，所有session消费结束，git diff --check0。没有新增依赖资源。

下一F05左右镜像视图续审（当前仅O，主盘未实现），然后单功能实现/测试/提交；K10后续，继续全站功能，不能结束全量审查。参考CUA本次仅fresh AX读取，状态未改并markHandoff，E33尚未采集。

## 2026-11-02 / M3-34 / F05,F02 → B05,B08,B22 主盘左右镜像

ADR-038/BOARD_MIRROR_SLICE：session.mirrored与flip独立会话只读方向、主盘按钮/Tooltip/toggled语义，透传既有交点/坐标/箭层/末步/评级几何；不改源谱/metadata/epoch/两revision/dirty/选子或分析token。新局/换谱保留本会话、退出默认为P，Editor草稿视图不继承。AnalysisPanel打开前捕获mirror，History→Preview→BoardSurface传递，打开后不追随Main变更，实际worker来源位置/评分不变。E33 PGN未来线路差距留下一B19。

新增应用2+组件3共5，连历史既有3目标8/8（37532，00:06）exit0；根显式官方NNUE400/400（25411，00:49）与最终flutter analyze无问题（84413，2.4秒）exit0；core未改沿用67/67+dart analyze。macOS新相关真实NNUE不重搜/身份token保持/组合PV真实worker1/1（56475，00:10）exit0，现37未全37，最近完整32/32仍M3-29。OS/其它平台未验。

首目标3过2失败：真实worker预览用pumpAndSettle等待loading导致假时钟超时，改点击后pumpUntil推进真实任务；Editor Piece实例无值相等，改逐90格(side,type)值比较，并使用实际取消Tooltip。次目标7过1失败为把关闭预览误写关闭，按现UI标签改；最后8过。初生产analyze0，新增测试后1 unused import警告移除，最终0；没有修改生产语义来迎合fixture。日志/tmp/chessnext-mirror-{analyze-initial,analyze-final,analyze-gate,target,target-final,target-verified,full,native}.log，全部session消费，git diff --check0，无新依赖资源。

下一M3-35 / F12,B19：E33确认源PGN导出完整所选线路（含阅读点后未来），项目仅根到当前；独立slice补PGN默认范围及可选当前路径/评注/资料/打开时快照、文件和复制一致，非全树RAV。继续整体对标。

## 2026-11-02 / M3-35 / F12 → B11,B19 PGN完整所选线路

ADR-039/PGN_SELECTED_LINE_SLICE：RecordTextExchange.exportText.includeFuture默认true只对PGN，用原source.currentLine末端的goTo只读视图交原PgnCodec.path；含选中非主线的未来，不导出未选兄弟/RAV。显式false根到当前，FEN/普通文字仍原范围。UI后续着法复选框/评注独立，busy禁改/状态重置，打开时tree/metadata捕获；copy与file同rendering。未来评注不支持默认报错禁导出，用户可显式缩范围/省评注，不默删。帮助和引导范围文案同步，结果/未知标签保留。

新增应用2+组件2=4，连文字交换与文件目标14/14（80555，00:03）exit0；显式官方NNUE根404/404（98447，00:50）+最终flutter analyze无问题（78476，1.5秒）exit0；core未改沿用67/67+dart analyze。macOS新PGN完整所选线路ICCS+显式当前路径中文、实际Foundation文件读回/测试剪贴板一致/源后来变动不追随1/1（5512，00:09）exit0。系统chooser注入与MemoryClipboard，未称OS保存面板/系统剪贴板通过。现38未全38，最近完整32/32仍M3-29。

无测试失败；初analyze仅新增测试unused import warning移除，最终0。日志/tmp/chessnext-pgn-line-{target,analyze-initial,analyze-gate,full,native}.log，所有session已消费；git diff --check0，无新依赖资源。E33自制PGN夹具验证读取到3着默认导出5着，不读取站点内部状态或借用户棋谱。

下一F11静态局面图片导出续审E34，先确认公开选项/生成结果/导出范围，再实现本机原创棋盘PNG与可替换文件端口；GIF/OCR/在线云库等继续，不能停称全部对齐。

## 2026-11-02 / M4-02 / F11 → B11,B19 原创棋盘PNG与macOS文件保存

ADR-040/BOARD_PNG_SLICE：BoardImageSnapshot冻结Position/末步/可靠评级/有效箭头/双方向与显示偏好，不保留Controller或IO；选中/目标/焦点不导出。BoardImageDialog固定450×500逻辑预览、2倍900×1000 PNG、主题/字号/动画Scope冻结、只读单组语义，生成缓存/错误重试/关闭取消迟到操作。PngImage独立8MB/4096边长/400万像素不可变门槛，PngFileExporter与文字UTF8协议分离。macOS chooser+writePngAtomic经ImageIO实际解码、regular目标检查及Foundation atomic；main只在macOS注入。图片复制/GIF/其它平台writer未实现。

新增端口2+适配器5+快照3+组件5=15个目标通过；首次及直接`flutter_tester`真实栅格PNG测试各卡住，均SIGINT结束并明确不计通过，改由macOS生产渲染/原生桥验证。最终显式官方NNUE根flutter test **419/419**（session7987，00:55）与flutter analyze无问题（2.1秒）exit0；macOS真实900×1000 PNG、开窗快照后台变化冻结且同局面字节一致、镜像字节变化、ImageIO解码/原子文件、坏PNG/目录/符号链接不覆盖 **1/1**（最终00:06）exit0。现39原生未全39，最近完整32/32仍M3-29；core未改沿用67/67+dart analyze。系统保存面板/外部沙箱授权/人工视觉、其它平台未验；无新依赖或产品素材。

## 2026-11-02 / M4-03 / F11 → B11,B19 棋盘PNG复制

ADR-041/BOARD_PNG_CLIPBOARD_SLICE：新增ImageClipboard/ImageCopyCancellation，与文字TextClipboard和文件端口分离；BoardImageDialog保存/复制共享首次PngImage缓存，busy互斥、关闭可取消迟到生成、平台失败重试不重画。MacOsImageClipboard经独立通道调用ImageClipboardBridge，ImageIO实际解码后声明`.png`、写NSPasteboard并读回字节核对；生产general，native测试固定命名pasteboard保护用户数据。无能力平台禁用并解释，GIF未实现。

新增适配器4+组件2=6，连相关目标11/11通过；macOS真实Flutter渲染900×1000、命名NSPasteboard写入读回、正常/镜像字节变化及坏PNG拒绝1/1（00:04）exit0。最终显式官方NNUE根flutter test **425/425**（session85147，00:55）与flutter analyze无问题（2.0秒）exit0；现40原生未全40，完整32/32仍M3-29，core67沿用。命名pasteboard验证不等于人工跨应用general粘贴，其它平台未验，无新依赖或素材。

## 2026-11-03 / M4-04 / F11 → B11,B19 棋谱GIF预览与macOS保存

ADR-042/BOARD_GIF_SLICE：`BoardGifSnapshot`冻结根到`currentLine`末端（含阅读点后未来）、不含兄弟变化，并冻结方向/显示偏好；最多64帧，超限不截断。`BoardGifSettings`以0.1秒整数保存，步时0.2–10秒、首尾0.2–30秒，首末分别替代对应帧时长；标题最多60字符。逐帧捕获450×540原创Flutter棋盘，`image 4.12.0`在独立Isolate编码；`GifFileExporter`与PNG/文字分离。macOS `writeGifAtomic`限12MiB/64帧/1024边长，用ImageIO逐帧解码并核时长后Foundation atomic。系统分享/其它平台未实现。

新目标10/10，显式官方NNUE根`flutter test --reporter expanded` **435/435**（约01:08）及`flutter analyze` **0问题**（2.4秒）exit0。macOS原生单项1/1（00:05）：实际450×540双帧渲染、2/3秒替代时长、ImageIO逐帧解码/原子保存、坏GIF拒绝且原文件不变。`flutter run -d macos`普通main构建并启动，PID20951/VM service可达；桌面工具前台报`open returned 1`，未能实际点按普通窗口。core未改沿用67/67。系统保存面板人工交互、其他平台未验；依赖image 4.12.0等登记于LICENSING。

## 2026-11-03 / M4-05 / F28 → B23 动画速度本机偏好

E36 确认参考设置选项存在并恢复标准。实现AnimationSpeed兼容schema1偏好、晚读字段合并/序列化和设置Controller；Material3分段控件提供关/快/标准/慢，按项目提案0/300/600/1200ms控制既有末步光圈，下一个位置变化生效，系统减少动画优先。不影响棋谱、搜索。测试覆盖旧设置默认、四值typed round-trip、非法枚举、读设置竞态、Mac测试器UI关闭不旋转及写回。其余棋子动效/声音/朗读仍B23，F28未完成。

## 2026-11-03 / M4-06 / F28 → B23 本机选子与走棋音效

E36/E37确认默认走棋、选子开关和走棋方案选择器边界；原站音源未采集。项目使用pub.dev audioplayers 6.8.1（MIT）平台适配器，通过AssetSource读取本项目生成器创建的两段短PCM WAV；原生端口不暴露给Widget，应用监听BoardSession选择/位置修订并按版本化本机开关播放。新文档根替换静音，读取/对弈落子/导航的位置变化可播放；非法/选择取消不播放；音频异常捕获，不阻止合法棋步。WAV源代码tool/generate_sound_assets.dart，可重复生成；资产SHA见docs/legal/LICENSING.md。

目标：纯Dart PCM头及确定字节/开关类型往返/异步音效失败隔离/新谱静音；组件验证app→port连接与设置保存；macOS integration_test/audio_feedback_test.dart使用真实plugin加载bundle资产并成功启动两类短音，1/1。后续未验Android/iOS/Windows/Linux/网页音频、听觉可接受度；内容仍属合成tone，不代表原站音效。F28余将军/吃子/绝杀音效/方案、自定义文件、系统朗读及声音时序仍未齐。

## 2026-11-03 / M4-07 / F28 → B23 事件提示音分类

新增吃子/将军/将死本机开关、独立WAV及播放器，五种音效偏好保持旧schema默认兼容。BoardFeedbackController基于提交后父子局面分类，互斥优先级将死>将军>吃子>普通落子；特殊开关关闭回退普通走棋开关；选子独立。优先级是P，E38只确认参考站逐事件更换器独立，源站组合语义仍U。音效全部原创合成，不复制网站资源。

专项 `flutter test test/application/board_feedback_test.dart test/widgets/last_move_markers_test.dart` 13/13；macOS `flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded` 1/1实际加载并启动五条WAV；根 `flutter test --reporter compact` 440 passed/5 skipped（缺官方引擎环境），`flutter analyze` 无问题。普通 `flutter run -d macos` 构建启动PID16653，VM Service 127.0.0.1:49641。根首轮曾被既有piece-size键盘测试Tab上限挡住，新增三个可访问开关后将有限遍历数从10调整到16，单项和全量复测均通过；失败已保留在本轮日志。移动/Windows/Linux/Web、将死实局声音、听感未验；试听/自定义导入/系统朗读未实现。

## 2026-11-03 / M4-08 / F28 → B23 系统语音朗读着法

E39五个音效开关各自关开状态独立并恢复原值，未触发棋步；站点语音仍off。实现默认false的`speakMoves` schema1偏好、PreferencesController、独立Material开关与MoveSpeechPort。提交节点的父局面生成ChineseNotation，独立于声音偏好；flutter_tts 4.2.5平台适配器过滤Android联网voice，仅在存在已装中文voice时串行朗读，无voice/API异常不影响落子。插件未声明Linux，Web不启用；系统语言包依OS预先安装和设置，不能保证全部机型都可用。E39只是开关验证，源站实际播报触发/音色和历史导航读法仍未知。

专项应用/组件测试14/14；macOS集成音效/TTS端口1/1（尝试查询voice并请求中文着法，若系统无voice静默返回）；根 `flutter test --reporter compact` 441 pass/5 skipped（Pikafish环境未配置），`flutter analyze` no issues。普通 `flutter run -d macos` PID19009，VM Service `127.0.0.1:50874`。插件警告：暂不支持Swift Package Manager且可能在未来Flutter升级成为error；AVSpeechSynth枚举future cases warning。无人工听感或其它OS验证；依赖/归档许可在LICENSING。
## 2026-11-03 / M4-09 / F28 → B23 本机自定义音效

E37/E38实测参考站声明五类音效可各自试听/本机导入 WAV、MP3，限制512 KiB/5秒；导入点击未观察到文件选择器，成功边界仍U，未复制站点音频或外观。项目新增独立 `AudioFilePicker`/`AudioOverrideRepository` 端口及 `AudioLibraryController`。各事件使用本机应用支持目录和schema 1清单独立替换/预览/恢复默认；文件先阶段写、移至受控目录，再替换清单，删除旧文件。播放遇缺失/损坏清单回退原创asset。UI只触发Controller。

导入边界为512 KiB、5秒；结构验证支持PCM/IEEE-float WAV及MPEG Layer III，文件读取流也有界，取消不更改配置。清单文件名严格限制，拒绝路径穿越。`test/audio_library_test.dart` 5项覆盖WAV/MP3有效及边界、无效/过大、隔离本机持久化、污染清单、取消/试听/恢复及Material对话框。macOS集成测试新增真实临时 WAV `DeviceFileSource` 加载；integration 2/2通过（既有内置音效和新增自定义路径）。`flutter test --reporter compact` 446 passed / 5 skipped；5项依赖未设置的官方 Pikafish环境；`flutter analyze` 无问题。`flutter run -d macos` 构建启动PID21638，VM Service `127.0.0.1:52467`。

该功能提供项目自己的默认/自定义切换，不实现参考站音效1/2/随皮肤预设；其它OS系统文件选择器/实际解码、试听听感未验，不关闭F28/B23。无新依赖；沿用已登记file_selector/audioplayers，原创素材登记见LICENSING。ADR-045。

## 2026-11-03 / M4-10 / F28 → B23 走棋音效方案

E40 V证据：源站走棋事件可选音效1/2/随棋子皮肤且分别试听；音效2选择在关闭并重开弹层后仍selected，最后恢复音效1。源站吃子更换器仅显示默认音效/试听。项目新增持久化`MoveSoundChoice`、原创音效2bundle和`AudioSoundPreviewPort`；走棋事件按照本机选择播放对应资源，坏偏好退回音效1，三个方案可单项试听。其他四事件不共享走棋方案。项目暂未实现皮肤资源，随皮肤映射现用的默认音效1；UI明确此范围。自定义文件存在时覆盖内置选择并锁定方案选择直至恢复默认，防止设置显示与实际播放不一致。ADR-046。

单元 `flutter test test/audio_library_test.dart --reporter expanded` 5/5（原测试扩展，覆盖持久化重开/损坏默认、方案切换/试听及自定义边界）；macOS集成 `flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded` 3/3（5事件、三种走棋预览、自定义路径和实际持久化sound2资源加载）；根 `flutter test --reporter compact` 446通过/5跳过；`flutter analyze` 无问题；普通 `flutter run -d macos`成功启动PID24870，VM Service `127.0.0.1:54576`。五项跳过需官方Pikafish执行文件和NNUE环境。无新增依赖；新增音效2由既有生成器创建，SHA登记LICENSING。

剩余：F21完整棋子皮肤并接入对应声音、项目素材声学可接受性、源站试听听感/导入结果、Linux/Web语音能力与棋子位移动画映射；F28未完整对齐。

## 2026-11-03 / M4-11 / F21 → B08,B20,B24 对面棋子朝向

E41观察棋盘设置的对面一方棋子倒置开关，初始关闭，说明上方一方旋转180°；并审计到棋子/棋盘皮肤库和新建编辑入口。项目新增默认关闭的`rotateOppositePieces`偏好，向主棋盘、局面编辑器和PNG/GIF快照传播。依视觉上方阵营翻转字形，不变换框、命中区或其它标记。覆盖旧schema1、坏类型、持久化、延迟读取合并及正反棋盘视图Widget测试。

其余皮肤列表/导入/编辑器/在线库仍在B24，不能由此关闭F21。全量测试、analyze及`flutter run -d macos`结果按本次实际终端记录。

## 2026-11-03 / M4-12 / F21 → B08,B20,B24 本机棋盘配色

E41/E42确认棋盘皮肤库、显式搜索提交及排序选项；本机导入入口声明支持压缩包、图片多选和文件夹，但尚未实测文件选择成功。项目提供原创宣纸木色（默认）与松石青两项BoardSkin配色，schema1兼容持久化、异步读取合并；通过BoardDisplayScope传递至主盘/局面编辑，BoardImageSnapshot/BoardGifSnapshot冻结配色，使导出预览不随后改偏好变化。Material3选择即时应用，保持规则/棋谱状态独立。

测试：偏好类型与往返/旧值/坏值、延迟加载合并；应用设置选配色后底板真实颜色即时变化、新App实例恢复；PNG/GIF快照捕获。根全量`flutter test --reporter compact`456通过/5跳过（缺官方Pikafish测试环境变量），`flutter analyze`无问题；macOS音频集成`flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded`3/3通过；`flutter run -d macos`构建启动成功，VM `127.0.0.1:60040`（PID29670）。F21其余图片皮肤/导入/编辑/在线后端仍未完成，详ADR-048/B24。

## 2026-11-03 / M4-13 / F21,F28 → B08,B20,B23,B24 本机棋子预设与跟随走棋音

E41/E42审计确认源站棋盘/棋子皮肤库与各自编辑入口；E37/E40确认走棋音效有随棋子皮肤预设和试听。新增原创PieceSkin本机偏好`roundSeal/squareInk`，默认圆章；Material3设置选择，BoardDisplayScope作用主盘/编辑器，BoardImageSnapshot/BoardGifSnapshot冻结当前皮肤。圆章沿用圆形外观，方章显示柔角方形，选中/目标/焦点/对面旋转语义保持。

应用层读取持久化`MoveSoundChoice`；followPieceSkin + roundSeal解析sound1、squareInk解析sound2，再经AudioFeedbackPort传递已解析值，Audioplayers适配器优先检查自定义路径。试听层解析相同关系，弹窗当前状态摘要显示具体预设。显式sound1/sound2不跟皮肤变化。

验证：偏好旧schema/未知类型/延迟设置读取合并；界面切换和棋子外观形状、重开恢复；图片/GIF快照捕获；BoardFeedbackController跟随sound2；预览映射测试。macOS音频集成 `flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded` 3/3通过；根全量测试、analyze、macOS `flutter run -d macos`结果追加本记录。图片级自定义皮肤、导入、编辑器、在线服务仍待，F21未完成。

## 2026-11-03 / M4-14 / F21 → B24 单棋子图片替换

根据E41可观察到的14个红黑棋子替换入口，先交付本机单图替换切片；E41未验证网页选择器导入成功，故此处格式/容量是项目设计P，不写成源站边界。新增独立图片选择器/仓库端口、扩展名与PNG/JPEG签名/解码校验，限512 KiB、1024边长及1MP，清单文件名受限、拒绝符号链接目录；用户取消不改原图，损坏本机素材在加载时忽略。按棋子槽位Material3预览、替换和恢复默认。用户图只在本机应用支持目录，不上传或复制源站素材。应用展示及PNG/GIF快照均采用已冻结的所选棋子皮肤图。

验证：`test/application/piece_image_library_test.dart` 4项覆盖格式/尺寸拒绝、替换失败保留旧图、恢复默认、本机仓库往返；`test/widgets/piece_skin_images_test.dart`验证只替换黑车槽位。根 `flutter test --reporter compact` 461通过/5跳过（5项依赖显式官方Pikafish与NNUE环境）；`flutter analyze`无问题；`flutter run -d macos`构建启动成功，VM Service `127.0.0.1:61522`（PID31311）。无新增依赖或外部资源。ZIP/文件夹、多选导入、图片编辑几何、棋盘背景图片/编辑和跨平台真实选择器仍待实现与验证；不能关闭F21。提交见git log。

## 2026-11-03 / M4-15 / F21 → B24 本机预设专属棋子大小

源站证据E43观察编辑新棋子皮肤的大小滑杆初值50，最右70；靠左一次为20.5，故不声明最小精确端点或对应单位。项目提供两套PieceSkin各自一个本机缩放比例，80–120%、步进1%、默认100%，M3既有全局棋子大小乘上该比例后作用于面容；格子与命中区域不变。比例在Material3棋子皮肤选择下面独立控制，切换皮肤分别载入。设置通过偏好schema1的可选字段兼容旧值和异步读竞态；图片/GIF快照捕获当前皮肤比例。

测试覆盖边界/roundtrip、旧偏好默认、独立存储、异步读不覆盖用户修改、样式切换渲染乘积及PNG/GIF快照。定向测试通过；全量`flutter test --reporter compact`464通过/5跳过，跳过项需要明确设置的官方Pikafish/NNUE环境；`flutter analyze`零问题。`flutter run -d macos`构建并启动，VM `127.0.0.1:63024`，PID32670。首次定向测试漏导入PieceSkin、analyze指出一条unused import，补正后定向/最终analyze通过，过程见SESSION_LOG。E43仅录观察/实操作，保存/使用/导出成功仍U；位置和阴影编辑、文件导入、皮肤清单仍待办。无新增依赖和资源。

## 2026-11-03 / M4-16 / F21 → B24 本机棋子预设位置微调

E43观察到上/下/左/右步进、自动对正、偏移后归零可用；按一次右键可见“右1”，未验证网页实际步长单位及边界。项目为每种PieceSkin分别增加横/纵偏移本机偏好，单位为棋格宽百分比，默认0、每按钮1%、范围±8%（P）。Material3方向键在边界禁用；中心自动对正把两轴归零。对所有棋子面容作视觉平移，`transformHitTests:false`保持逻辑格、点击与拖放不变；PNG/GIF快照冻结两轴值。

专项偏好/边界/延迟读取、位置按钮即时持久化/归零、平移命中测试、PNG/GIF捕获通过。全量`flutter test --reporter compact`466通过/5跳过；`flutter analyze`0问题；`flutter run -d macos`成功构建启动，VM `127.0.0.1:64032` PID33743。首次`dart format`因assert条件语法错误中止，修正为组合断言后格式与专项通过，见SESSION_LOG。此处不代表完成源站位置单位/视觉精确度；棋子阴影和棋盘编辑仍待。


## 2026-11-04 / M4-17 / F21 → B24 本机棋盘图片图层

按E44新建四种 `BoardSkinImageSlot`：棋盘背景、起点标记、落点标记、选中框。独立应用端口/控制器/文件仓库支持逐槽替换与恢复；重用既有PNG/JPEG有界读取/尺寸解码校验规则（512 KiB、1024边长、1MP），图片在本机应用支持目录存储。文件仓库限制manifest schema/文件名，并检查符号链接目录；损坏清单/图片不阻断默认棋盘加载。Material 3棋盘显示设置增加编辑图片入口，图片预览/错误态/逐槽恢复；取消选择不更改现有值。主盘和编辑器从BoardDisplayScope绘制同一套图层；自定义起点/落点覆盖对应默认末步记号。PNG/GIF快照捕获本机图像字节。

定向 `flutter test test/application/board_skin_image_library_test.dart test/widgets/board_skin_image_layers_test.dart --reporter expanded` 3/3通过。第一次全量测试 468通过/5跳过/1失败，失败为现有键盘遍历测试Tab预算20不足；新入口添加了焦点节点后将该用例遍历预算扩至40，专项通过。最终根 `flutter test --reporter compact` 469通过/5跳过（5项需配置官方Pikafish/NNUE环境），`flutter analyze`无问题，`git diff --check`通过。`flutter run -d macos` Build成功并同步、VM Service `127.0.0.1:50487`（PID44785）；Flutter报告`Failed to foreground app; open returned 1`，但app已构建、同步且VM可连接，前台人工视觉未验证。插件 `flutter_tts`仍有Swift Package Manager兼容警告。

本片为本机项目设计P，不证明网页替换、保存、应用成功，E44旋转与几何边界仍U。无新依赖或外部资源；F21未完成。


## 2026-11-04 / M4-19 / F21,B24 自定义落点图片旋转

E45只验证棋盘皮肤图片页的开关AX从0变为1，没有自定义落点图片，故项目不据此声明源站动效或时序。按ADR-055实现BoardSkin独立布尔偏好；新末步身份时仅自定义落点图绕目标交点线性旋转一周，首次挂载静止，同身份重建不重播。全局AnimationSpeed控制时长/关闭，MediaQuery Reduce Motion立即静止；不改变棋盘命中/布局、起点图、规则、引擎或静态PNG/GIF快照。模型旧值兼容与Widget行为/速度测试已定向通过5项。完整根测试、analyze、macOS run待执行；可视验收待完成。该切片独立提交后继续B24其它皮肤能力及全站审计，不能关闭F21或全站。


## 2026-11-04 / M4-20 / F21,B24 棋子皮肤阴影

E43可见阴影档位无/柔和/明显，以及方向、距离、模糊、浓淡；柔和时看到138°/6.7%/2.4%/50%单例。数值范围、单位和算法未知，不能泛化。ADR-056定义本机项目范围P，并为两套PieceSkin独立持久化；同一shadow值投影到棋盘预览/编辑器及图片/GIF冻结快照。关闭阴影禁用相关滑杆；不触碰棋谱/规则/命中/引擎。模型roundtrip/值域/延迟合并、PNG/GIF冻结、UI持久化和渲染定向测试通过；根478通过/5跳过、analyze无问题，macOS Build/Sync成功PID54316/VM `127.0.0.1:51653`。CUA窗口视觉验收not run。

## 2026-11-04 / M4-23 / F21 → B24 用户皮肤独立大小与位置

E43观察新建皮肤编辑页含大小/位置控件，右移一次显示1%、滑杆可观察20.5–70；精确端点、步进全域、保存/使用/导出均未验证。按ADR-059做本机P：用户皮肤定义分别存比例80–120%（1%步进）与X/Y偏移±8%（1%格宽步进），创建复制当前设置。棋子设置选择自定义项时滑杆/方向键直接改本机皮肤目录，忙写期间禁用避免丢更新；内置预设继续使用原偏好字段。BoardDisplayScope主盘/编辑共享ID参数，交点命中保持不变；PNG/GIF从App读取自定义参数并在捕获时冻结，与所选用户图片一致。

定向`flutter test test/application/piece_skin_library_test.dart test/application/board_image_snapshot_test.dart test/application/board_gif_test.dart test/widgets/piece_skin_images_test.dart --reporter compact`19/19；最终根`flutter test --reporter compact`488通过/5跳过（5项需官方Pikafish/NNUE环境）；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync成功，PID63084、VM `127.0.0.1:64399`。`flutter_tts`SwiftPM兼容warning；未做窗口人工视觉检查。F21/全站仍不完整；逐用户阴影与库搜索/排序/导出/ZIP/文件夹/在线目录继续B24。

## 2026-11-04 / M4-22 / F21 → B24 本机用户棋子皮肤目录

根据E41/E42/E48观察到的皮肤库/多套导入入口，建立用户本机皮肤ID，避免未来多套ZIP只能覆盖两种内置`PieceSkin`。网页只观察说明和入口；ZIP/文件夹实际操作成功与格式仍U。ADR-058标注本片项目提案P：最多64套、名称最多32码点；基础风格引用内置圆章/方章，复制当前图片覆盖并保留源格式，ID隔离图片；支持选择、新建、重命名、删除，内置项不可改；删除当前皮肤切回其基底。目录、选择偏好独立持久化，不依赖登录/网络。自定义皮肤目前沿用基础预设的大小/位置/阴影参数，未实现逐皮肤编辑。

定向`flutter test test/application/piece_skin_library_test.dart` 3/3；既有棋子图片/页面专项`flutter test test/application/piece_image_library_test.dart test/widgets/piece_skin_images_test.dart --reporter compact` 10/10；棋盘偏好界面回归`flutter test test/widgets/board_coordinates_test.dart --reporter expanded` 9/9。最终根`flutter test --reporter compact` 484通过/5跳过（5项需官方Pikafish/NNUE本机环境）；`flutter analyze --no-pub`无问题；`flutter run -d macos` Build/Sync成功PID59671、VM `127.0.0.1:59146`。`flutter_tts`打印SwiftPM兼容warning；未做窗口人工视觉验收。无新增依赖/外部素材。创建/删除失败恢复、重复清单拒绝、选择偏好跨实例恢复由定向测试覆盖。

## 2026-11-04 / M4-21 / F21 → B24 本机多选棋子图片导入

E42仅观察到ZIP、图片多选、文件夹三个导入入口，没有选文件或操作导入；格式、目录结构、覆盖和成功语义全部U。M4-21复用PieceImagePicker/ImageRepository既有端口及file_selector，无新增依赖。多选上限14张、总量7 MiB（P），每图沿用512 KiB、PNG/JPEG、1024边长、1MP与真实解码验证。Material3预览后映射至不重复槽位，名称只做建议。整批校验在任一写入前完成；写入仍逐槽原子，跨槽不是事务；故障显示部分成功，保留成功项并支持跳过已成功槽重试。

最终专项 `flutter test test/application/piece_image_library_test.dart test/widgets/piece_skin_images_test.dart --reporter compact` 10/10通过；根`flutter test --reporter compact` 481通过/5跳过(exit0，5项需官方引擎/NNUE环境)；`flutter analyze`无问题；`flutter run -d macos` Build/Sync成功PID56134、VM `127.0.0.1:53841`。`git diff --check`通过。CUA窗口视觉和macOS文件选择器人工交互not run。ZIP、文件夹、库管理、跨平台选择器及网页实际导入边界仍未验。
| M4-24 | F21/B24 本机皮肤库搜索、排序和选择 | `flutter test --reporter compact` 488通过/5跳过；`flutter analyze --no-pub` 无问题；`flutter run -d macos` PID64446/VM 127.0.0.1:49993 | E42源站显式回车搜索/五类排序可追溯；本机实现默认/名称/最近创建。点赞/作者需在线元数据；人工视觉验收未做 |
| M4-25 | F21/B24 用户皮肤独立阴影 | `flutter test --reporter compact` 488通过/5跳过；`flutter analyze --no-pub` 无问题；`flutter run -d macos` PID65664/VM 127.0.0.1:51711 | 控件值域沿用ADR-056项目P；E43源站精确端点和算法U；人工视觉验收未做 |
| M4-26 | F21/B24 用户皮肤ZIP导出 | `flutter test --reporter compact` 492通过/5跳过；`flutter analyze --no-pub` 无问题；`flutter run -d macos` PID67175/VM 127.0.0.1:54273 | 原子二进制原生端口编译通过；E43导出入口仅O，源站格式/成功仍U；未人工选文件验收 |
| M4-27 | F21/B24 项目格式皮肤包安全导入 | `flutter test --reporter compact` 496通过/5跳过；`flutter analyze --no-pub` 无问题；`flutter run -d macos` PID69107/VM 127.0.0.1:56731 | 项目ZIP schema1，不支持通用站点包；路径/条目/字节/图片校验及用户确认有测试；系统选择面板未人工操作；E42/E48源站成功仍U |
| M4-28 | F21/B24 项目格式皮肤包文件夹导入 | 专项2/2；根498通过/5跳过；`flutter analyze --no-pub`无问题；macOS PID71234/VM 127.0.0.1:59893 | 固定解压布局项目P；目录条目/链接/大小限制；系统目录面板未人工操作；首轮compact有未复现失败；E42/E48源站格式/成功仍U |
| M4-29 | F28/B23 主棋盘棋子移动动画 | `flutter test test/widgets/board_piece_move_animation_test.dart --reporter compact`5/5；根503通过/5跳过；`flutter analyze --no-pub`无问题；macOS PID74615/VM 127.0.0.1:64108 | 慢/快档中间位置/结束、连续新步替代、动画关及运行中Reduce Motion验证；CUA窗口读取超时；源站范围/速度映射U，项目行为ADR-064 |

## 2026-11-04 / M4-30 / F20,B25 本机侧栏重排

`AppPreferences.sidePanelOrder`为四项完整且唯一的`SidePanel`排列；省略字段兼容当前默认顺序，未知/重复/缺失解码失败。`PreferencesController`提供即时持久化并将初始化中的编辑合并进迟到读取。Material3拖动列表写入偏好，主界面实时按偏好顺序构造Play/Analysis/Review/Candidate卡片。项目映射属P，不改文档或分析状态；不实现源站其余操作选项。专项`flutter test test/application/preferences_controller_test.dart test/widgets/side_panel_order_test.dart --reporter expanded`7/7；根`flutter test --reporter compact`505通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync PID77791、VM `127.0.0.1:51219`。CUA `getApp("chessNext")`超时，人工窗口视觉验收未做。

## 2026-11-04 / M4-31 / F20,B25 本机侧栏显隐

`AppPreferences.visibleSidePanels`保存四种本机侧栏卡片的可见子集，缺字段默认全开，空集合允许，重复/未知值拒绝。设置页同一个拖动列表中提供独立Switch，PreferencesController实时写入，App按启用集合不构造隐藏卡片；顶层AppBar设置入口保持可用。异步读取字段合并覆盖已测。源站E50项目面板映射仍P/U。专项`flutter test test/application/preferences_controller_test.dart test/widgets/side_panel_order_test.dart --reporter expanded`7/7；根`flutter test --reporter compact`505通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync PID78894、VM `127.0.0.1:51984`。CUA窗口超时，人工视觉验收未做。

## 2026-11-04 / M4-32 / F20,B25 棋谱定时播放与步时

`AppPreferences.recordPlaybackIntervalMs`严格限制500–30000ms、100ms步进，旧偏好默认2000ms；设置预设0.5/1/2/3秒及自定义滑杆即时持久化。`RecordPlaybackController`由单次Timer驱动，沿当前选定线路导航，末尾自动停止；外部游标/内容/epoch变化停止，播放导航不改内容revision/dirty。专项与根测试、分析、macOS实际运行结果见CURRENT_STATE/SESSION_LOG；E50具体源站起点、循环、自定义范围仍U，项目行为P。

## 2026-11-04 / M4-33 / F20,B25 棋谱栏和播放按钮显隐

`AppPreferences.showMoveList/showRecordPlaybackButton`独立持久化，旧偏好默认可见，设置开关即时生效。隐藏棋谱栏时只收起标题、空态和着法列表；保留其它导航控制。隐藏播放按钮立即停播，并从导航行移除播放入口。专项/根测试、分析与macOS实际运行证据见CURRENT_STATE/SESSION_LOG；源站开关联动及“棋谱栏”准确覆盖范围仍U，项目语义P。

## 2026-11-04 / M4-35 / F20,B25 棋盘快捷菜单

`AppPreferences.boardContextActions`保存唯一动作白名单，默认仅包含项目已有能力；设置编辑器用复选框调整。主棋盘长按/右键打开菜单，复制FEN和当前线路中文着法走TextClipboard，文字导入/导出及本地保存复用既有用例。定向10/10；根`flutter test --reporter compact`509通过/5跳过；`flutter analyze --no-pub`无问题；macOS Build/Sync成功PID87104/VM `127.0.0.1:60069`。CUA未做菜单人工验收；网站专有UBB/链接/搜索仍未实现或U。

## 2026-11-04 / M4-34 / F20,B25 本机侧栏面板切换栏

新增`showPanelSwitchBar`及`activeSidePanel`本机设置。打开时在四个启用侧栏中显示分段选择器，并仅挂载当前选择面板；关闭时恢复原来的排序堆叠。全隐藏时提示从设置恢复，选择被隐藏时临时回落首个可见面板。功能定向/根测试、分析和macOS实际运行详见CURRENT_STATE/SESSION_LOG；项目分组与选择语义为P，站点对应关系U。

## 2026-11-04 / E51 / F19 显示模式入口补审

在访客桌面IAB从设置返回主棋盘后打开菜单“显示模式”，AX/截图列出分析（引擎面板+着法列表）和悬浮窗（棋盘+一行分数）。仅观察弹层，未选择。页面返回后URL仍显示`#/settings/language`，与可见主棋盘不一致；以可见页面为准并标记路由U。源站效果没有验证。


## 2026-11-04 / M4-37 / F20,B26,ADR-072 四处分隔桌面工作区

实现：`lib/app.dart`拆分控制与记录区域并适配900–1279dp双栏、≥1280dp三栏；`lib/features/workspace/resizable_workspace.dart`提供左栏宽/棋盘宽/左上下/右上下4个48dp可交互分隔区、可用宽度约束、方向键及Slider增减语义和22/70/55/55重置；`test/widgets/resizable_workspace_test.dart`覆盖三栏装配、拖动改变实际面板大小、重置及语义动作。范围为项目P，站点边界仍U。

专项`flutter test test/widgets/resizable_workspace_test.dart --reporter expanded`2/2通过；根`flutter test --reporter compact`512通过/5跳过（本机未配置官方Pikafish/NNUE）；`flutter analyze --no-pub`无问题。复用现存`flutter run -d macos`runner PID86855热重载3/1736库、2231ms，运行App PID87104保持唯一。没有新增启动。最初布局试验曾使1120dp/200%字号用例溢出、草稿状态条不在视口；提高三栏断点、恢复状态条顶部后通过。另有测试夹具Semantics API编译/释放问题，改为检查SemanticsData增减动作后通过。

未做CUA现场交互验收；三栏阈值/项目值域不宣称复刻源站；触屏、其它显示器、重启持久化、源站完整几何和F19 OS置顶/独立窗仍未验证。

## 2026-11-04 / E54 / F27 英文切换即时翻译

参考证据见`REFERENCE_EVIDENCE.md#e54--2026-11-04-显示语言切换实际效果访客桌面iab`。访客临时标签将简体中文切到English后，当前显示设置页和示例棋谱说明/着法即时变为英文；返回设置首页再进入显示页仍为英文；切回简体中文后中文恢复。验证范围仅当前会话内的页面切换，不含刷新、重启、其他语言或所有页面覆盖。F27完整本地化仍待审计与实现。

## 2026-11-04 / E55 / F20 操作设置谱库来源

参考证据见`REFERENCE_EVIDENCE.md` E55。操作页默认选中云库；点大师谱改变AX选中态并在同标签导航后保留，主界面大师谱面板出现筛选入口和过滤弹层；之后已恢复云库。查询请求/结果和刷新后持久化仍U。

## 2026-11-04 / E56 / F27 重载持久化与语言样页

参考证据见`REFERENCE_EVIDENCE.md` E56。English在显示设置页reload后保持；繁體当前页部分翻译但混用简体，越南语当前页有可见译文及拉丁示例着法。其他页面及跨进程持久化仍未知；F27本地完整资源未实现。

## 2026-11-04 / E57 / F27 显示布局预设

参考证据见`REFERENCE_EVIDENCE.md` E57。访客1280×720实际切换靠左/居中，观察到真实列顺序和AX分隔结构变化；恢复居中默认。源站断点/尺寸算法仍U。

## 2026-11-04 / M4-38 / F27,B25,ADR-073 棋盘布局预设

`AppPreferences.boardLayoutPreset`兼容旧值并参加复制、相等、严格JSON解码及初始化迟到读取合并。偏好对话框可选“棋盘居中/棋盘靠左”并在应用时保存。`ResizableWorkspace`靠左预设仅在宽屏三栏路径排列棋盘/记录操作/侧栏，提供棋盘宽度拖动、键盘及Slider语义和重置；项目宽度508–556dp、记录区/右区至少220dp是P。测试覆盖编码/旧偏好、异步编辑、列顺序、尺寸调整、偏好入口与持久化。

专项`flutter test test/application/preferences_controller_test.dart test/widgets/resizable_workspace_test.dart --reporter expanded`10/10；根`flutter test --reporter compact`514通过/5跳过（缺官方Pikafish/NNUE配置）；`flutter analyze --no-pub`无问题；`git diff --check`通过。macOS `flutter run -d macos --no-pub` Build/Sync成功，VM `127.0.0.1:49754`；`open returned 1`且Mac锁定，无法置前，人工窗口视觉交互not verified。期间仅一条Debug runner会话；根Flutter测试使用flutter_tester，没有创建chessNext应用实例。源站其它视口、语言覆盖与F27其余功能继续开放。

## 2026-11-04 / M4-39 / F21,B24,ADR-074 自建皮肤目录服务端

新增独立纯Dart `server/skin_catalog`，通过只读HTTP契约提供health、分页/排序/搜索列表、条目许可详情和有界skin ZIP；启动加载schema1元数据，固定slug到package路径，拒绝软链接/非法输入，SHA-256与不可变ETag保护包。默认目录为空；运营者需只发布有授权/署名的内容。不实现账户、上传、点赞写入，也未接入Flutter端口或用户可配置服务器URL。部署说明覆盖单文件Dart编译、非root本机监听、HTTPS反代、只读目录与原子切换重启，见`server/skin_catalog/README.md`和ADR-074。

定向`flutter test test/server/skin_catalog_server_test.dart --reporter expanded`5/5；根`flutter test --reporter compact`519通过/5跳过（缺官方Pikafish/NNUE配置）；`flutter analyze --no-pub`无问题。首轮定向测试因测试用例请求唯一搜索结果的第2页而失败，改为第1页后5/5；首次analyze提示一个if语句需加大括号，修复后通过；服务子包分析配置最初将strict选项放在不支持的键位，移入analyzer.language后复跑无问题。`flutter pub get --offline`成功；`dart pub get --offline`成功；`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server`成功。在macOS以临时空目录启动最终编译版服务，`curl -fsS http://127.0.0.1:18088/healthz`返回`{"status":"ok"}`，目录列表返回schema1空items；完成后停止服务并清理临时目录/可执行文件。此服务首片没有改变Flutter macOS客户端，因此未另启/重启`flutter run`；原runner PID2226/App PID2479继续保留，无测试启动App。

客户端接入、断网/超时/缓存/许可展示、服务URL偏好及真实远程包导入仍后续任务；公开点赞排序目前是运营者静态元数据，不表示访客投票。源站用户上传/点赞实际结果仍U，B24/F21与全站未对齐。


## 2026-11-04 / M4-40 / F21,B24,ADR-075 自建皮肤目录客户端传输层

通过可替换`PieceSkinCatalog`端口和Dart IO HTTP适配器读取公开分页目录，支持搜索、默认/点赞/名称/作者/最新排序；严格解析作品ID、文本、点赞数、日期、许可证、署名和SHA-256。8秒请求/流超时，页码≤10000、每页≤100、查询≤120 Unicode码点、响应≤2MiB；远程必须HTTPS，HTTP仅限loopback。超时/断网、非200和无效响应分为类型化错误。没有UI、用户服务器URL偏好、缓存、包下载、包校验/导入或点赞写接口，M4-40只是客户端传输端口。

`flutter test test/adapters/network/http_piece_skin_catalog_test.dart --reporter expanded`3/3通过（首次断网测试因关闭服务后读取port而失败，保存port后复跑通过）；根`flutter test --reporter compact`522通过/5跳过（缺官方Pikafish/NNUE）；`flutter analyze --no-pub`无问题（首次报告单行if风格，修复后通过）。macOS复用现有runner PID2226与App PID2479；先终止旧runner/app后仅启动一组新实例：`flutter run -d macos --no-pub`构建/Sync成功，App PID5725、VM Service `127.0.0.1:52805`；系统前台打开返回1，未完成人工视觉验收。此前attach因认证URL未连接；测试宿主完成loopback HTTP请求。


## 2026-11-04 / M4-41 / F21,B24,ADR-076 自建皮肤目录浏览

AppPreferences schema1增加可选`skinCatalogBaseUrl`，旧配置默认空；PreferencesController校验并限制远程HTTPS，仅loopback可HTTP，异步旧设置载入按编辑字段合并。皮肤库设置处可保存服务地址并连接；支持默认/点赞/名称/作者/最新排序，复用回车提交搜索与分页，条目展示作者/点赞/许可/署名/描述。详情明确当前不会自动写入本机。网络失败、HTTP失败、协议错误及空目录有独立文案。没有目录缓存、包下载/摘要校验/导入。

专项`flutter test test/application/preferences_controller_test.dart test/widgets/piece_skin_catalog_dialog_test.dart --reporter expanded`8/8；根`flutter test --reporter compact`524通过/5跳过；`flutter analyze --no-pub`无问题。初次widget发现目录区渲染溢出并漏显许可，改为可滚动布局后通过；测试查找分行许可文本改用包含匹配。macOS使用唯一runner交互会话热启动，`flutter run -d macos --no-pub`Build/Sync成功、App PID6847、VM `127.0.0.1:53684`；`open returned 1`，未人工视觉验收。仅保留该一组runner/app。


## 2026-11-04 / M4-42 / F21,B24,ADR-077 在线皮肤包下载与安全导入

目录HTTP端口仅接受合法slug和SHA-256，单包≤8MiB，流式累积到边界后比对真实SHA-256才返回。详情点击下载后复用M4-27项目schema1皮肤包codec校验固定ZIP结构、SHA和PNG/JPEG内容；包内皮肤名称必须匹配在线条目。显示许可及署名，显式按“接受许可并导入”后才写入本机库；取消不写，导入自动创建新ID并选用。下载失败/服务拒绝/摘要或格式失败均显示本机未更改。用户皮肤定义新增可选license/attribution字段，文件和包格式兼容旧schema1，创建衍生皮肤时保留来源许可，导出继续携带元数据。

专项`flutter test test/application/piece_skin_library_test.dart test/adapters/network/http_piece_skin_catalog_test.dart test/widgets/piece_skin_catalog_dialog_test.dart --reporter expanded`12/12；根`flutter test --reporter compact`525通过/5跳过；`flutter analyze --no-pub`无问题。首轮widget对确认弹窗里许可文案预期计数错误，改为精确双匹配后通过；首轮文件改动曾有重复/错位import修正。macOS复用交互runner PID6602，`r`热重载明确回报Reloaded 39 of 1738 libraries；App PID6847、VM `127.0.0.1:53684`保持单实例。系统先前`open returned 1`，未人工视觉验收。

## 2026-11-04 / M4-43 / F21,B24 自建目录loopback导入链路集成验证

新增`test/server/skin_catalog_client_roundtrip_test.dart`。测试自行构造schema1皮肤ZIP与临时schema1目录元数据，在ephemeral loopback端口启动`SkinCatalogHttpServer`，由`HttpPieceSkinCatalog`搜索并下载，再验证SHA/项目codec、经`PieceSkinLibraryController`导入，断言条目、选中ID及许可证/署名元数据已保存。样包完全自制，不含参考站资源。该证据只证明本机服务与客户端/本机库契约互通；真实托管部署及人工UI点击未验证。

专项`flutter test test/server/skin_catalog_client_roundtrip_test.dart --reporter expanded`1/1；根`flutter test --reporter compact`526通过/5跳过（5项需要官方Pikafish/NNUE环境）；`flutter analyze --no-pub`无问题。测试使用Flutter测试宿主，不启动`chessNext.app`；复核唯一runner PID6602/App PID6847仍在运行。

## 2026-11-04 / M4-44 / F21,B24,ADR-078 自建目录查询页离线缓存

新增`PieceSkinCatalogCache`端口与`FilePieceSkinCatalogCache`。只保存HTTP成功且JSON schema已完整校验的列表页，key由endpoint、query、sort、page和pageSize组成，文件名为key的SHA-256；每页≤2MiB，最多24页，临时文件写后替换。每次操作先在线；只对请求超时/Socket或传输`HttpException`不可达时按精确key回退，页面显示“离线缓存”和原抓取时间。HTTP非200或远程格式错误不回退；离线页不会自动安装，下载包继续走SHA-256、codec和许可证二次确认。

专项`flutter test test/adapters/network/http_piece_skin_catalog_test.dart test/adapters/storage/file_piece_skin_catalog_cache_test.dart test/widgets/piece_skin_catalog_dialog_test.dart --reporter expanded`9/9；根`flutter test --reporter compact`529通过/5跳过（依赖官方Pikafish/NNUE环境）；`flutter analyze --no-pub`无问题；`git diff --check`通过。复用`flutter run -d macos --no-pub`runner PID6602按`r`热重载成功（Reloaded 8 of 1739 libraries，2161ms），App PID6847仍是唯一实例。根测试使用flutter_tester，未启动App。未做人工作业现场UI验收，也未验证真实托管服务部署。

## 2026-11-04 / E59 / F21,B24 新建棋盘草稿入口与退出确认

参考站证据见`REFERENCE_EVIDENCE.md#e59--2026-11-04-新建棋盘皮肤控制与未修改草稿退出`。独立IAB临时标签10只读进入`#/settings/skins/edit/new?type=board`：确认格点/边距/棋子缩放初值和重命名、导出、使用、保存按钮存在（O），未操作它们。未改控件点返回后确实要求确认放弃，确认回`#/settings/board`且默认设置保留（V）。空新草稿为何提示未保存及保存/使用/导出结果仍U；没有用户/账号或棋谱改动。用户原标签1保持在`#/settings`未触碰；临时标签10留在已恢复的棋盘设置页。

## 2026-11-04 / M4-45 / F21,B24,ADR-079 项目多皮肤集合ZIP

新增`PieceSkinCollectionPackageCodec`项目格式：2–16个嵌套的既有schema1单皮肤ZIP，总压缩文件≤8MiB；外层和内层逐一验证包路径/条目/声明身份/SHA/图片。皮肤库为本机用户皮肤提供勾选多项导出；导入先全包预检，再选择子集，条目显示许可证/署名，已有同名和目录容量外条目不可选。Controller逐项写图暂存后一次保存定义列表，失败回滚所有已暂存图片；成功分配新ID、保留元数据并选中集合中的第一项。此项目包不声称兼容源站未知ZIP格式。

定向`flutter test test/application/piece_skin_collection_package_codec_test.dart test/application/piece_skin_library_test.dart test/widgets/piece_skin_catalog_dialog_test.dart --reporter expanded`14/14；根`flutter test --reporter compact`535通过/5跳过（官方Pikafish/NNUE未配置）；`flutter analyze --no-pub`无问题；`git diff --check`通过。复用唯一macOS runner PID6602热重载成功（Reloaded 7 of 1740 libraries，2498ms），App PID6847不变。根测试未启动App。CUA人工视觉验收未做；参考站多套ZIP格式未知，项目格式不称兼容。

## 2026-11-05 / M4-46 / F21,B24,ADR-080 本机用户棋盘皮肤库

新增`BoardSkinDefinition`/`BoardSkinLibraryRepository`应用端口与schema1文件适配器，最多64个用户项；`BoardSkinLibraryController`提供创建、选择、改名、几何更新、删除。创建复制当前内置或用户棋盘的基底、几何与四类图层图片后持久化并即时应用；删除活动用户皮肤回退其基底，图片按ID隔离。`selectedBoardSkinId`进入偏好序列化与迟到设置合并。设置对话框集成皮肤选择/库管理；自定义几何及图片贯穿主盘、编辑器、PNG/GIF快照。项目P，不宣称源站编辑草稿/保存/使用语义、任意站点包格式或在线棋盘目录已对齐。

定向`flutter test test/application/board_skin_library_test.dart test/application/board_skin_image_library_test.dart test/application/board_skin_geometry_test.dart test/widgets/board_skin_library_dialog_test.dart test/widgets/board_coordinates_test.dart --reporter expanded`尚未单独执行；功能用例由根全量覆盖。根首轮`flutter test --reporter compact`539通过/5跳过/1失败，原因是旧测试对String下拉框使用不唯一查找器；改用控件key后定向`flutter test test/widgets/piece_skin_images_test.dart --reporter expanded`6/6。其后根`flutter test --reporter compact`541通过/5跳过；`flutter analyze --no-pub`无问题。`git diff --check`通过。测试宿主仅为flutter_tester，未启动chessNext App。`flutter run -d macos --no-pub` Build/Sync成功，唯一App PID50598、VM `127.0.0.1:61589`；`open returned 1`，窗口人工视觉验收未完成。保留该runner复用，不重叠启动。

源站自定义棋盘皮肤的几何保存内容/重载恢复、导入导出包、草稿脏态语义及落点图旋转效果仍U；全站功能仍开放。后续B24继续棋盘皮肤项目包与保存/应用边界，然后按差距矩阵继续全站功能/设置审计。

## 2026-11-05 / M4-47 / F21,B24,ADR-081 本机棋盘皮肤ZIP导入导出

新增`BoardSkinPackageCodec`项目schema1 ZIP：`board-skin.json`、内置棋盘基底/名称/独立几何、四种棋盘图片槽、SHA-256和图片真实内容校验；压缩包≤8MiB、图片合计≤7MiB、单图沿用512KiB限制，拒绝未知路径/目录/链接/重复或未引用条目。管理库可导出单个用户棋盘皮肤；导入先解码预览并二次确认，名称冲突/容量不足拒绝，创建新ID，图片安全写入后保存定义并即时选中，失败清除暂存图层。

专项`flutter test test/application/board_skin_package_codec_test.dart test/application/board_skin_library_test.dart test/application/board_skin_image_library_test.dart test/widgets/board_skin_library_dialog_test.dart test/widgets/board_coordinates_test.dart --reporter expanded`20/20；根`flutter test --reporter compact`544通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。macOS沿用M4-46唯一App PID50598/VM `127.0.0.1:61589`，`flutter attach --debug-url=...`后热重载，再热重启907ms成功，无新App实例；`flutter run`此前Build/Sync成功但`open returned 1`，窗口人工视觉验收not run。测试宿主是flutter_tester，没有生成App实例。

项目ZIP不声称兼容站点“主流格式”或任意ZIP/文件夹；源站包结构、冲突、保存/应用差异与重新加载持久性继续U。F21及全站未完成，下一审计/实现按BACKLOG继续B24和矩阵的其它缺口。

## 2026-11-05 / E62 / F21,B24 棋盘编辑器缩放语义

参考站访客临时标签2只读页面语义，初值棋子缩放100%，滑杆AX声明min60/max140（O）。对该控件尝试End和ArrowRight后AX仍100，因此没有验证端点/步进交互；格点拖柄为两个role=slider、value50但无可访问范围值，边距stepper的全范围/耦合仍U。未改动任何参数或保存/使用；浏览器返回仍弹弃草稿确认，确认后默认棋盘/棋子、100%、坐标开、对面倒置关复原（V）。证据与限制见`REFERENCE_EVIDENCE.md#e62--2026-11-05-棋盘编辑器棋子缩放可访问边界访客桌面iab`。下一步以站点可观察操作补证，而不把AX声明直接当已实现边界。

## 2026-11-05 / E63 / F21,B24 棋子缩放拖动端点实测

在同一访客临时编辑页用屏幕拖动实测最低60%、最高140%，从60%拖动约4px得到61%；右边缘先观察139%，拖过轨道末端后得到140%。棋子大小变化但格线/边距值稳定。未保存，确认丢弃后默认设置恢复。完整鼠标位置映射仍U；E63详情见`REFERENCE_EVIDENCE.md`。

## 2026-11-05 / M4-48 / F21,B24,ADR-082 棋盘皮肤缩放范围对齐

依E63将`BoardSkinGeometry`本机棋子皮肤专属缩放从ADR-054原80–120%提案值改为60–140%整数范围，UI各整数刻度可达；旧用户数据范围为新范围子集，仍有效。独立于全局棋子显示倍率，继续只缩放面容/快照几何，交点命中与网格边界不变。新增60/140接受及59/141拒绝测试。格点拖柄边界、边距stepper完整范围/映射仍U，F21开放。

## 2026-11-05 / E64 / F21,B24 边距stepper与格点联动样本

访客临时编辑草稿四边stepper各加一次均为+0.5；左边距从33增加三次到34.5时，右边距465联动至约465.06。恢复后拖左上点约50屏幕像素，读数左/上/右/下为86/32.5/465.12/519.04，预览格网移动、两个格点AX仍50。返回并确认丢弃，默认设置恢复；未保存/使用。AX范围为声明而非操作边界，完整映射公式和边界仍U。证据详见REFERENCE_EVIDENCE E64。

## 2026-11-05 / E65 / F21,B24 边距数值框键盘观察

空白棋盘皮肤草稿左边距初值33.00；读取数值框value/aria-valuenow，未发现DOM min/max/step。聚焦左边距并按ArrowDown后仍33.00；只代表这次输入/按键未改变值，其他键与字段编辑行为未知。误触重命名入口后取消，浏览器返回并确认放弃；默认皮肤/100%/坐标开/对面倒置关复原。无保存或应用操作，详见REFERENCE_EVIDENCE E65。

## 2026-11-05 / M4-49 / F21,B24,ADR-083 自建只读棋盘皮肤目录服务端

扩展既有`server/skin_catalog`，可选`SKIN_BOARD_CATALOG_ROOT`从独立根目录装载`board-catalog.json`及`board-packages/`，复用同一有界metadata、查询/排序/分页、许可/署名、SHA绑定与包读取防符号链接规则；新增`/v1/board-catalog`、详情及ZIP端点。未启用新根时既有`/v1/catalog`棋子目录保持兼容。部署README记录新根目录和路由；服务仍无写API/用户认证。根Flutter测试545通过/5跳过；服务定向6/6；服务端dart analyze与根`flutter analyze --no-pub`无问题；格式化完成、`git diff --check`待复核。未运行macOS客户端，因为本增量仅改独立Dart服务协议，既有唯一App PID50598/runner PID50125未变。客户端目录与缓存仍待M4-50。

## 2026-11-05 / M4-50 / F21,B24,ADR-083 棋盘皮肤在线目录客户端

`HttpPieceSkinCatalog.forBoards`按独立`/v1/board-catalog` route复用既有HTTPS/loopback、超时、≤2MiB响应、≤8MiB包、SHA异常模型和`FilePieceSkinCatalogCache`；完整path作为key区分棋子与棋盘目录。棋盘皮肤库共享本机自建服务地址偏好，提供远程搜索、五种排序、分页和离线缓存时间标记。详情展示许可署名；下载校验SHA，解包由`BoardSkinPackageCodec`校验格式/图片并核对名称；用户确认许可后以新ID加入并选用。定义和schema1 ZIP可选持久化许可署名，旧数据空值兼容。

定向HTTP/应用/设置弹层14/14；根`flutter test --reporter compact`548通过/5跳过；`flutter analyze --no-pub`无问题。macOS复用PID50598/runner PID50125，attach sync约1.1s，热重载0库/450ms后热重启953ms成功，无第二实例。Mac锁屏，窗口人工验收未做；服务实服配置/远程manifest尚未验。源站格式/素材没有复用，不宣称站点兼容。

## 2026-11-05 / E66–E67 / F21,B24 几何值域与保存/应用分离

E66在参考站访客临时棋盘皮肤草稿上用实际按钮/输入操作验证：左字段可减至0；左字段输入999后移焦显示500并使加号禁用、配对右字段显示500；上字段同操作移焦显示550、配对下字段显示550。仅覆盖左下界、左/上输入上限和两次联动样本，右/下独立边界与全局约束仍U。E67把左值33→33.5后点保存，设置仍选默认棋盘；选择器另点“使用这套”后当前项才变“我的棋盘”。编辑同皮肤后修改上值33→33.5再保存，退出仍为默认；回到编辑页可读到本会话保存的四边数值。此为参考站V，不作为本机验证。

测试样本已恢复默认选中，但“我的棋盘”仍保留；因删除弹窗说明不可恢复，已取消等待用户明确确认。源站reload/重启持久性与dirty语义仍U。文档审计不运行Flutter门槛；证据、矩阵、缺口、交互规格、ADR-054、BACKLOG及context待`git diff --check`后中文docs提交。

## 2026-11-05 / M4-51 / F20,B25,ADR-067 棋谱自定义步时对齐

按E68将`RecordPlaybackSettingsDialog`滑块建模为121级索引：0对应0.1秒，1–120按0.5秒步进映射到60秒；原0.5/1/2/3秒预设不变。偏好校验与`RecordPlaybackController`共用`AppPreferences.isValidRecordPlaybackInterval`：接受100ms特殊值、500ms格点至60秒，以及旧配置兼容的≤30秒100ms粒度值，拒绝不在集合中的数字。Slider语义格式器播报实际映射时间；设置文案解释下限例外。

定向`flutter test test/application/preferences_controller_test.dart test/widgets/record_playback_test.dart --reporter expanded`11/11；第一次回归发现通知触发的运行时RecordPlaybackController旧值域校验失败，修复后定向重跑通过。根`flutter test --reporter compact`549通过/5跳过（官方Pikafish/NNUE未配置）；`flutter analyze --no-pub`无问题；`git diff --check`通过。macOS复用PID50598/runner PID50125，attach sync 1,053ms、热重启1,026ms；结束attach后`ps`仍确认一个App和原runner，无额外GUI实例。Mac锁屏，未做人工窗口视觉验收。源站播放启动/循环/执行时序仍U。

## 2026-11-05 / E68 / F20,B25 棋谱自定义播放时间边界

`#/settings/operations`初始预设2秒、其它页内显示项维持观察时默认。自定义控件标注0.1–60秒；stepper从2秒连续减至1.5/1/0.5/0.1，最小处减号禁用；从2秒连续增加116步到60秒，最大处加号禁用，常规步距0.5秒（V）。未执行棋谱播放，实际播放起点/间隔时序不作结论。将预设2秒重新选中恢复该设置；长按/右键动作只读枚举，未切换。证据确认项目M4-32原0.5–30秒/0.1秒配置差异，由M4-51修正。文档-only审计待`git diff --check`和单独中文docs commit，不运行Flutter验证或macOS。


## E69 / F24 高级分析设置联动（2026-11-05）

访客参考页默认5线程/320MB，解限开关页面推荐最大值10/512→1024/1984，线程5→6时自动内存320→384并复原。仅控件操作验证，不证明真实资源上限；手动内存范围和生命周期持久性U。见REFERENCE_EVIDENCE E69与FEATURE_MATRIX F24。项目仍须使用EngineCapabilities/platform硬上限，不复制网站的1024线程提案。


## M4-52 / F24,B25 / ADR-084 自动Hash内存

改动`AppPreferences.autoHash`、PreferencesController资源钳制/并发字段合并、Material3应用设置自动/手动模式。默认维持原手动Hash，旧schema1缺字段按手动解码。自动线程×64MB受设备与真实UCI选项限制；分析面板显式改资源经PreferencesController同步持久化并退出自动模式。codec、自动公式、能力钳制、旧值、应用设置与面板切回手动均有测试。专项`flutter test test/application/preferences_controller_test.dart test/widgets/preferences_test.dart --reporter expanded`10/10；根`flutter test --concurrency=1 --reporter compact`551通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。复用macOS PID50598/runner50125 attach同步1086ms/热重启1055ms，锁屏未视觉验收。E69只证网页联动，不是源站实引擎能力。


## E70 / F31 关于与支持入口（2026-11-05）

参考访客`#/settings/about`可见版本/构建号929、hash样式短版本，以及检查更新、更新日志、问题反馈、版权与投诉和讨论群QQ群号。入口O；AX单击更新日志后页面未观察到变化，实际结果、数据发送与外链目的地U；未提交反馈/投诉或触发更新检查。详REFERENCE_EVIDENCE E70。

## E71 / F22,F23 AI走棋设置（2026-11-05）

`#/settings/play`明确描述分析界面AI走棋设置，不影响人机对弈/分析。难度当前20（四级标签可见）、步时默认1秒、开局库默认最佳着法、残局云库开（O）；开局库菜单还可选关闭或分差内随机（O，随机差值/算法U）。高级页深度60、离库10步（O）。离库步数减至1后按钮禁用，增回9次复核10（V）。难度预算映射、其余值域、实际搜索/云库行为及持久性U；审计时没有发起搜索或联网。详REFERENCE_EVIDENCE E71。

E71追加：难度Home/End操作验证0/20端点；自定义步时从1秒经0.5秒到0（不限时），不限时才显示最大深度60；切回预设1秒并复核默认状态。自定义上限、实际搜索效果仍U。

## M4-53 / F22 / ADR-085 分析界面AI单步

按E71把站点AI走棋与人机对弈/只读分析的区分落实为本机独立一步动作（项目P）：1秒EngineRequest，绑定epoch/positionRevision/tree身份，过期/非法结果丢弃；停止、导航、切新文档时释放输入锁；原持续分析状态在新着法后恢复。棋谱容量失败不当作引擎故障。专项`flutter test --concurrency=1 test/application/engine_play_test.dart test/widgets/analysis_panel_test.dart --reporter expanded`16/16；最终根`flutter test --concurrency=1 --reporter compact`557通过/5跳过，`flutter analyze --no-pub`通过。macOS复用PID50598/runner50125，Flutter attach文件同步1,062ms、热重启1,003ms；锁屏未作视觉验收。站点完整难度、步时设置、最大深度和云库仍未实现/验证。

## M4-54 / F22,F23 / ADR-086 AI走棋设置

设置单独记忆AI走棋难度、时长、无限时最大深度；单步请求将难度转换为有限节点预算，不修改普通分析/人机对弈参数。项目的预算映射为P；E71只验证页面值域与预设，不证明对应棋力。开局/残局BookService及真实站点搜索行为仍缺实现/证据。

专项`flutter test --concurrency=1 test/application/engine_play_test.dart test/application/preferences_controller_test.dart test/widgets/preferences_test.dart --reporter expanded`24/24；根串行`flutter test --concurrency=1 --reporter compact`558通过/5跳过；`flutter analyze --no-pub`通过。复用macOS PID50598/runner50125，attach同步1,090ms、热重启1,042ms；锁屏未人工视觉验收。

## M4-55 / F15,F22,F23 / ADR-087 自建云库服务端首片

`CHESSNEXT_BOOK_ROOT`可选装载operator-supplied schema1开局/残局库；`POST /v1/book/query`以FEN+完整历史精确匹配，返回候选/明确miss和许可署名。客户端必须再次校验着法合法性，不将服务端候选直接视作棋步。服务器专项`flutter test --concurrency=1 test/server/book_catalog_server_test.dart test/server/skin_catalog_server_test.dart --reporter expanded`12/12。独立Dart服务未运行，真实部署/运营数据和端到端客户端未验。

## M4-56 / F15,F22,F23 / ADR-088 云库客户端传输首片

新增`BookService`精确局面查询端口和`HttpBookService` HTTP POST适配器；公网HTTPS、本机loopback HTTP，5秒超时，32KiB请求/响应边界。严格核对schema、kind/FEN/history回显、候选格式/唯一性及license/attribution，网络不可达/服务拒绝/无效协议分开类型化。调用方须显式提供endpoint，未接composition root，当前不会联网。专项`flutter test --concurrency=1 test/adapters/network/http_book_service_test.dart --reporter expanded`4/4；根串行`flutter test --concurrency=1 --reporter compact`568通过/5跳过；`flutter analyze --no-pub`通过。未改App/UI/平台代码，未运行macOS。

## M4-57 / F15,F22,F23 / ADR-089 AI单步云库策略

分析AI单步可独立配置服务地址、关闭/最佳/分差内随机、残局库开关、离库回合数；初始策略为开局最佳、残局开、离库10。服务地址留空时绝不请求网络，并明确说明单步查询会发送当前局面/完整历史至指定端点。云候选必须匹配当前合法着法并绑定现有epoch/局面/棋树身份，miss/服务异常/无合法候选回退本机引擎。随机≤100cp、残局≤8个非将棋子、离库上界255均为项目P，源站E71均U。定向`flutter test --concurrency=1 test/application/engine_play_test.dart test/application/preferences_controller_test.dart test/widgets/preferences_test.dart test/adapters/network/http_book_service_test.dart --reporter expanded`32/32；根串行`flutter test --concurrency=1 --reporter compact`572通过/5跳过；`flutter analyze --no-pub`无问题；复用PID50598/runner50125 attach同步1047ms、热重启993ms。系统锁屏，人工视觉验收未做。

## M4-58 / F21,B24 / ADR-090 棋盘双格点拖动校准

在棋盘显示设置添加独立校准对话框和9列×10行预览，拖左上/右下手柄按画布宽高比例改对应格网边；遵守`BoardSkinGeometry`的1–99%边界与至少55%跨度。四边滑杆仍可作精调，既有表单高度不增加。映射是项目P，不套用源站33/465数字或未知公式。

专项`flutter test --concurrency=1 test/widgets/piece_skin_images_test.dart test/widgets/board_geometry_editor_test.dart --reporter expanded`8/8；根串行`flutter test --concurrency=1 --reporter compact`574通过/5跳过；`flutter analyze --no-pub`无问题。首次根测试发现预览内联使原PieceSkin控件滚出视口，修复为单独对话框后根测试全通过。复用macOS PID50598/runner50125，attach同步1060ms、热重启1020ms；进程审计始终一个App及单测试宿主。系统锁屏，未人工视觉验收。浏览器坐标真实算法仍U。

## 2026-11-05 / E73 / F21,B24 右下格点映射样本

在已存“我的棋盘”编辑页拖右下点约10视口像素向右下，右465→475、下519→530.52；同距离反拖后右464.04/下519.54。通过数值框恢复右465/下519后确认丢弃，棋盘显示设置的选择/100%/坐标/倒置均回默认。证据只支持一次正向及一次近似反向样本，完整像素映射及不可逆原因仍U；未保存/使用/导出。无Flutter验证（只读审计）。

## E74 / F31 关于、反馈与投诉边界（2026-11-05）

检查更新和更新日志AX操作后无可见反馈（不能推断未请求）；反馈页字段含≤2000字、联系方式、可选≤3图，默认附设备/版本JSON，可见platform、version、build、bundleSeq、bundleId、channel、os、model、UA、locale、screen尺寸。版权页含公开邮箱和权属/流程说明，投诉表单要求投诉人/邮箱、作品/权属、内容、真实性确认、可选附件。未填/提交/复制/上传。实际网络去向与保留策略U。

## M4-59 / F31 / ADR-091 离线About与开源许可

应用设置新增本机AboutDialog：应用名chessNext、当前pubspec版本0.1.0+1、离线/服务状态说明及Flutter依赖许可导航。未配更新/反馈服务明确说明无后台请求/设备信息外发。在线检查更新/日志/反馈/版权流程仍待实现，F31不关闭。

专项`flutter test --concurrency=1 test/widgets/about_support_test.dart --reporter expanded`1/1；根串行`flutter test --concurrency=1 --reporter compact`575通过/5跳过；`flutter analyze --no-pub`无问题，`git diff --check`通过。复用PID50598/runner50125，VM attach同步1201ms、热重启1061ms；脱离后进程仍唯一。Mac锁屏，视觉验收not run。测试首次因应用名同时显示于对话框标题/副标题而调整为非唯一finder；再根据`MaterialLocalizations.viewLicensesButtonLabel`读取许可按钮标签，避免固定语言假设。浏览许可未改变PreferencesRepository。

## M4-60 / F31 / ADR-092 自建只读版本清单服务端

新增operator-only `ReleaseManifest`从可选`CHESSNEXT_RELEASE_ROOT/releases.json`加载schema1 newest-first发布清单；最多100条、单文件1MiB、SemVer/正build/UTC时间/4000字符说明，拒绝未知字段、控制字符、重复身份、乱序及畸形数据。`GET /v1/releases/latest`提供当前条目和历史，未配置时404；POST不允许。仅发公共元数据、不接收用户/设备标识、不分发binary。

专项`flutter test --concurrency=1 test/server/release_manifest_test.dart test/server/skin_catalog_server_test.dart --reporter expanded`10/10；服务`dart analyze server/skin_catalog/lib server/skin_catalog/bin`通过；`dart compile exe server/skin_catalog/bin/skin_catalog_server.dart -o /tmp/chessnext-release-server`成功；根`flutter analyze --no-pub`通过；根`flutter test --concurrency=1 --reporter compact`579通过/5跳过；`git diff --check`通过。服务端无Flutter/UI/原生代码变化，不需Mac重启；进程检查仅见既有PID50598/runner50125，无额外chessNext。

## M4-61 / F31 / ADR-093 自建版本信息客户端

App偏好新增可选发布服务根地址，默认空；设置输入仅允许HTTPS公网/loopback HTTP，最大2048字符。关于页只响应用户显式点击检查；HTTP适配器5秒超时/2MiB边界，检查schema、当前/首条一致、UTC日期、唯一版本身份与降序历史；不发送账号、设备或棋谱信息。展示当前版本比较和历史说明，按不可达/无效响应/HTTP拒绝区分失败。无包下载/安装。UI用Fake验证仅显式触发；loopback HTTP适配器专项验证请求和协议。

专项`flutter test --concurrency=1 test/application/preferences_controller_test.dart test/adapters/network/http_release_service_test.dart test/widgets/about_support_test.dart --reporter expanded`13/13；根串行`flutter test --concurrency=1 --reporter compact`584通过/5跳过；`flutter analyze --no-pub`和`git diff --check`通过。macOS复用PID50598/runner50125：`flutter attach --debug-uri=http://127.0.0.1:61579/4bLZ1MhsyEk=/`同步1066ms，热重启1052ms；Ctrl-C脱离后PID50598仍存活唯一。测试只用一个根目录flutter_tester；进程盘点另见PID70890的tuner_flutter实例/其它测试宿主，不属于本仓库。本机锁屏，视觉人工验收not run。根测试5项跳过为官方Pikafish/NNUE未配置，不是失败。

## E76 / F21,B24 边距极值与局部联动审计

新建编辑草稿DOM声明四个字段min0、左右max500、上下max550（O）。实操左500将右推至500，左0后右保持500，右输入0移焦显示8；上输入550将下带至550，下输入0移焦后上保持550（V）。按默认33/33/465/519复原，放弃草稿，复核设置页默认皮肤/棋子、100%、坐标开、倒置关。该不对称局部结果不能用于推断全局公式、单位或有效最小格距，继续U。证据见REFERENCE_EVIDENCE E76。

## E77 / F21,B24 余下边距端点审计

右字段输入并验证max500；上字段min0；下字段输入550后显示549.96，stepper加至550且按钮禁用（V）。按默认值复原并丢弃空白草稿，设置状态复核无变化。与E76合并后覆盖每字段至少一个端点，但多个端点还属于ARIA声明而非各自实操；完整约束/公式仍U。详REFERENCE_EVIDENCE E77。

## M4-62 / F21,B24 / ADR-094 校准点可访问调整

本机校准把手支持焦点方向键，各自沿水平/垂直每次调整1个百分点；Semantics暴露当前边距、操作提示和四个方向的读屏自定义动作。拖动总位移从pointer-down坐标计算，避免pan识别阈值造成首段位移损失；始终从pointer-down几何计算，不累积中间精度误差。仍遵循项目BoardSkinGeometry范围/最小跨度，不代表参考站键盘/读屏语义或坐标单位。

专项`flutter test --concurrency=1 test/widgets/board_geometry_editor_test.dart --reporter expanded`4/4；根串行`flutter test --concurrency=1 --reporter compact`586通过/5跳过；`flutter analyze --no-pub`与`git diff --check`通过。专项初次发现Pan在slop后首个delta遗漏指针起始距离（实际仅移动剩余位移），改用Listener pointer-down捕获后测试严格比较总位移。macOS复用PID50598/runner50125 `flutter attach --debug-uri=http://127.0.0.1:61579/4bLZ1MhsyEk=/`同步1648ms、热重启2103ms，Ctrl-C脱离后PID50598唯一存活。全量根测试只一个本项目flutter_tester；5跳过仍为未配置官方Pikafish/NNUE。屏幕锁定，视觉人工not run。

## M4-63 / F31 / ADR-095 自建反馈与显式审阅后提交（2026-11-05）

新增`FeedbackService`端口、HTTPS/loopback HTTP适配器与问题/建议表单。只可选发送类别、用户填写的描述和可选联系方式；必须先预览完整字段与地址再明确确认。默认地址空时离线/入口禁用；超时/HTTP拒绝/无效确认不自动重试，提示送达状态不确定，不传设备/浏览器/系统/棋谱/诊断数据。附件和版权投诉不在本片。

自建Dart服务在设置`CHESSNEXT_FEEDBACK_ROOT`后启用`POST /v1/feedback`；严格JSON字段/schema/长度，16KiB请求和5,000记录上限；文件随机名exclusive创建，仅成功写入后返回accepted；无公开读取路由，Dart服务不记录请求IP/提交内容。部署要求先创建service-owned 0700目录并给systemd增加对应`ReadWritePaths`，Nginx样例关闭access log并限制每IP每分钟6次、突发5次；服务/托管层仍可看到来源IP，运营者控制error log。无自动删除/保留期限：由服务运营者本地制定与执行，用户提交界面明确告知。

定向`flutter test --concurrency=1 test/adapters/network/http_feedback_service_test.dart test/widgets/feedback_dialog_test.dart test/widgets/about_support_test.dart --reporter expanded`7/7；server `dart test --reporter expanded`2/2、`dart analyze lib bin test`无问题、`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server`成功。根`flutter test --concurrency=1 --reporter compact`591通过/5跳过/0失败；5跳过因未配置官方Pikafish/NNUE，不是本片失败。`flutter analyze --no-pub`及`git diff --check`通过。调试中曾修正Widget重复文本finder断言及Dart exclusive创建接口误用；最终专项、根测试通过。

macOS以`flutter attach --debug-uri=http://127.0.0.1:61589/dTmglI9Y_pk=/`连原Runner，文件同步1,054ms、热重启1,114ms；Ctrl-C脱离后原app PID50598仍存活。测试全程`--concurrency=1`单个flutter_tester；没有调用`flutter run`或启动新chessNext。屏幕锁定，实际视觉验收not run；未连接真实自建服务/部署收件目录，生产投递与运营流程not run。F31仍开放。

## E78 / F27 显示与语言菜单/色调选择审计

来源`REFERENCE_EVIDENCE.md#e78--2026-11-05-显示与语言设置菜单及色调选择访客桌面iab`。显示页观察五种色调、夜间棋盘开关说明及四种语言（O）；选中青玉再复原晴蓝、打开语言菜单后取消均验证（V）。未触碰主题/夜间开关。色调色值与作用范围、夜间皮肤变换/条件、偏好持久性和多语言其余路由仍U。下项按B25检查本机主题/棋盘外观架构并设计独立色调偏好；语言完整覆盖先盘点资源后另案实现。

## M4-64 / F27 / ADR-096 本机显示色调

新增`DisplayTone`五选项偏好，在应用设置选色并点击“应用设置”提交；Material 3 light/dark theme共用所选seed。配色seed属项目P，不改变棋盘皮肤、最后着标记、棋子及引擎。新偏好默认晴蓝，schema1旧数据缺字段兼容映射晴蓝；异步读取时保留用户先选值。E78源站五色具体值/作用域、夜间棋盘真实行为仍U，本切片不宣称像素/全页对标。

专项`flutter test --concurrency=1 test/application/preferences_controller_test.dart test/widgets/preferences_test.dart --reporter expanded`10/10。专项首轮有一项测试代码编译失败（`MaterialApp.theme`可空访问）；添加non-null断言后重跑10/10。根`flutter test --concurrency=1 --reporter compact`591通过/5跳过/0失败；`flutter analyze --no-pub`与`git diff --check`通过。macOS复用PID50598/runner50125：`flutter attach --debug-url=http://127.0.0.1:61589/dTmglI9Y_pk=/ --no-dds`同步1,035ms、TTY热重启1,082ms，Ctrl-C脱离后原PID50598仍存活。测试串行单flutter_tester，无新chessNext。屏幕锁定，人工视觉验收not run。

## E79 / F27 夜间棋盘实际效果审计

参考证据见`REFERENCE_EVIDENCE.md` E79：深色模式下同一默认棋盘开关关闭呈浅米、开启呈深棕（V）；然后复原跟随系统、开关开、晴蓝和简中。F27本机开关及深色/默认皮肤限制可实现；非默认皮肤实际效果及精确色值仍U。

## E80 / F27 English多页面抽样

将访客语言临时切English后查看显示页/设置目录、棋盘/棋子与目录选择器、分析、标记、声音与音效选择器、操作及展开快捷动作、关于和主页面/菜单。以上抽样常用页面文字转English，主局记谱转拉丁ICCS；动态皮肤标题/作者、品牌/备案链接保留中文或专名。没有操作执行/页面数据修改。切回简体中文并复读系统主题、晴蓝/夜间开关值（V）。未覆盖所有错误/弹窗、编辑/导入导出、题库/训练及外链；不宣称English全站完整。参考证据见`REFERENCE_EVIDENCE.md` E80。

## M4-65 / F27 / ADR-097 默认夜间棋盘

新增偏好开关并限定仅深色+`parchment`内置默认皮肤身份应用原创夜间调色；浅色/用户皮肤/ jade和关选项不变。BoardDisplayScope将偏好/皮肤身份供BoardSurface使用；PNG/GIF快照捕获该设置和当前选择的皮肤ID。seed颜色/夜间色值均P，不等于参考站像素或跨页面完全一致。

专项`flutter test --concurrency=1 test/widgets/night_board_test.dart test/application/preferences_controller_test.dart test/widgets/preferences_test.dart test/application/board_image_snapshot_test.dart test/application/board_gif_test.dart --reporter expanded`首次运行19通过/1失败（Light Theme切换测试组件未重置；调整测试使用唯一MaterialApp key）。随后`flutter test --concurrency=1 test/widgets/night_board_test.dart --reporter expanded`2/2通过；设置及快照其它18项首轮同轮通过。根`flutter test --concurrency=1 --reporter compact`593通过/5跳过/0失败；`flutter analyze --no-pub`与`git diff --check`通过。macOS复用PID50598/runner50125：attach sync1,022ms、hot restart1,039ms，Ctrl-C后原PID50598仍存活。全量根测试单串行flutter_tester，结束无残留；未开新chessNext。Mac锁屏，人工视觉验收not run。

## M4-66 / F21,B24 / ADR-098 本机格网边距数字输入

在四边百分比滑杆旁新增文本输入，支持一位小数；提交解析后按该边当前合法动态区间钳制，并调用原棋盘皮肤/偏好控制器即时保存。新增自定义皮肤集成断言验证越界左值夹至最小跨度边界、有效小数20.5持久化。

专项`flutter test --concurrency=1 test/widgets/board_skin_library_dialog_test.dart test/widgets/piece_skin_images_test.dart --reporter expanded`8/8通过。数字输入专项首轮因格式器预先拒绝三位数而失败；允许暂时三位整数后由模型统一钳制，复跑通过。首轮根`flutter test --concurrency=1 --reporter compact`591通过/5跳过/2失败；日志`/tmp/chessnext-root-test-m4-66.log`确认两项是`piece_skin_images_test`未把新增字段增高后的按钮滚入可视区。补`ensureVisible`后定向通过。最终根`flutter test --concurrency=1 --reporter expanded`593通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-66-final.log`；5跳过需官方Pikafish/NNUE环境。`flutter analyze --no-pub`、`git diff --check`通过。macOS复用PID50598/runner50125；`flutter attach --debug-url=http://127.0.0.1:61579/4bLZ1MhsyEk=/ --no-dds`同步1012ms、热重启8613ms，脱离后原App存活；全程未运行`flutter run`，测试单一串行flutter_tester并无残留。锁屏，视觉not run。

## E81 / F27,F31 英文反馈/投诉表单翻译抽查

英语样本中About、Feedback及Copyright/complaint页面主要文案可见英文，附件按钮“选择文件”仍为中文；反馈表默认勾设备/版本、未勾棋谱。未展开设备明细、填表、上传或提交。切回简中并复核主题系统/晴蓝/夜间开。全站English和其它语言未覆盖，不关闭F27。

## M4-67 / F31 / ADR-099 版权投诉文字表单与隔离收件

关于页复用用户显式配置的自建发布服务地址，新增版权投诉入口。必填投诉人、邮箱、作品/权利、权属说明及涉及内容链接，可选补充说明；要求真实性勾选。预览阶段零请求，显示准确地址和全部字段，只有再次明确确认后才POST `/v1/copyright/complaints`。附件上传暂不支持；测试未用真实个人数据。公网HTTPS/loopback HTTP、超时与接受响应沿用反馈HTTP适配器。

自建Dart服务仅在`CHESSNEXT_COPYRIGHT_ROOT`配置私有收件目录后启用；schema1拒绝未知字段/越界和无效邮箱，请求最多16KiB、最多1,000条；与反馈目录隔离，无公开读取/列举/删除、邮件转发、附件或自动清理。部署文档要求运营者先设置私有目录、访问授权和删除/保留流程；Nginx关闭access log并限制每IP每分钟2次。托管层仍能看到来源IP等连接信息。

定向`flutter test --concurrency=1 test/widgets/copyright_complaint_dialog_test.dart test/widgets/about_support_test.dart test/adapters/network/http_feedback_service_test.dart --reporter expanded`7/7；`server/skin_catalog`的`dart test --reporter expanded`4/4、`dart analyze lib bin test`无问题、`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server-m4-67`通过。根全量/analyze/macOS attach结果待补。首轮定向测试发现可选字段漏required参数、composition root误加到_boardPage、滚动测试未ensureVisible和重复字段断言，逐项修正后定向通过；服务端测试通过。macOS视觉/实际自建部署/真实投诉投递not run。附件与运营实务未交付，F31开放。

M4-67门槛复核（最终）：根`flutter test --concurrency=1 --reporter expanded`完成595通过/5跳过/0失败，根`flutter analyze --no-pub`与`git diff --check`通过。macOS在原PID50598上attach同步953ms、热重启1085ms；attach CLI及frontend_server短暂残留已退出/清理。未启动额外App。

## M4-68 / F31 / ADR-100 问题反馈图片附件

用户选择PNG/JPEG后，界面显示附件缩略图、名称、大小，可移除；发送预览列出目标地址、文字字段及每个附件，预览/取消不发请求，只有明确确认才提交。项目上限为3张、每张256KiB、合计512KiB。平台文件选择经`FeedbackAttachmentPicker`端口注入；无法打开、读取失败、格式/大小超限均显示可恢复状态。传输附件采用base64，客户端序列化请求上限768KiB。自建反馈服务仅接受严格结构、验证文件名/MIME/PNG或JPEG签名/尺寸和总量，并与文本写入私有有界收件记录，无附件读取接口；Nginx反馈路径设1MiB body限额。

定向Flutter`flutter test --concurrency=1 test/widgets/feedback_dialog_test.dart test/adapters/network/http_feedback_service_test.dart test/adapters/platform/file_selector_feedback_attachment_picker_test.dart --reporter expanded`9/9通过；服务端`cd server/skin_catalog && dart test --reporter expanded`6/6通过。服务端`dart analyze lib bin test`、`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server-m4-68`通过；根`flutter analyze --no-pub`及`git diff --check`通过。最终根`flutter test --concurrency=1 --reporter expanded`598通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-68.log`；5跳过因未配置官方Pikafish/NNUE。macOS复用原App PID50598/runner50125，VM Service `61579/4bLZ1MhsyEk=` attach同步1,191ms、热重启1,494ms成功；Ctrl-C脱离后PID50598存活。根测试期间仅一个`flutter_tester`，完成后无残留；全程未运行`flutter run`，未打开新App。屏幕锁定，人工视觉not run；未部署服务或进行实际外发。

该切片仅解决普通反馈的可选附件。版权投诉附件、生产运营者访问/删除/保留流程、邮件/群等外部联系入口及实际部署仍待交付，F31开放。

## E82 / F21,B24 审计样本删除及设置恢复

访客IAB中，棋盘设置皮肤库只看到一个“我的棋盘”本次审计样本，其余为站点在线项。删除确认框明确称不可恢复，用户就该样本确认后执行删除；复读皮肤库该本地条目消失，取消选择器，主设置回到默认棋子/棋盘、全局大小100%、坐标开、对面倒置关。V。只证明删除与状态恢复，不说明几何值或reload行为。操作截图通过本轮UI记录展示，未把站点素材复制到仓库。

## E83 / F21,B24 上边距单步与配对读数

空白未保存棋盘皮肤草稿中，上33点击“上”减号变32.5，下519显示519.04；左33/右465、两个格点50/50、缩放100%未变。点击上加号回33后下恢复519。V/O。未保存、未应用或导出，按放弃确认离开并确认原棋盘设置值恢复。该单点样本只扩展配对联动观察，精度/公式/其它控制交叉影响仍U。

## E84 / F21,B24 水平拖动格点与边距读数

参考站访客`https://xiangqiai.com/#/settings/skins/edit/new?type=board`在新建未保存棋盘草稿、格点50/50、四边33/33/465/519时，左上把手约从(185,88)水平拖至(205,88)，AX变为左53.50/上32.50/右465.18/下519.04；右下把手约从(584,536)水平拖至(604,536)，左/上保持、右/下变为487.02/519.49。位置从截图估计，未作设备像素标定。属于局部O/V，不能确认跨轴小值来自真实映射还是pointer/显示精度。没有保存、使用、导出；返回确认丢弃后核对默认设置恢复。未改变线上既有皮肤和棋谱。全站几何公式及跨reload语义继续U。

此为只读证据记录/可撤销草稿审计，不改业务代码，无根Flutter测试或macOS重启门槛。后续开发应检视自身editor在不同宽高和平台上的单轴响应，独立标P。

## M4-69 / F31 / ADR-101 版权投诉显式证明图片

版权投诉表将`FeedbackAttachmentPicker`端口注入到About的投诉流程。用户可显式选择PNG/JPEG最多3张、每张256KiB/合计512KiB，表单显示缩略图、文件名/大小和移除操作；完整预览列投诉字段、已配置目标、每份附件元数据，预览/取消不发送，仅二次确认后才发送。投诉payload仍与一般反馈分离，进入`/v1/copyright/complaints`及独立`CHESSNEXT_COPYRIGHT_ROOT`私有目录；服务器复用严格附件格式/尺寸校验和768KiB JSON请求限制，Nginx location body limit 1MiB，投诉inbox仍最多1,000条且没有公开读取/下载。投诉附件可能含个人/权属证明，运营者必须设置私有目录访问和留存删除流程；项目未部署或代用户真实发送。

定向`flutter test --concurrency=1 test/widgets/copyright_complaint_dialog_test.dart test/adapters/network/http_feedback_service_test.dart test/widgets/about_support_test.dart --reporter expanded`9/9；`cd server/skin_catalog && dart test --reporter expanded`6/6；server `dart analyze lib bin test`与exe编译通过；root `flutter analyze --no-pub`、`git diff --check`通过；最终root `flutter test --concurrency=1 --reporter expanded`599通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-69.log`（5跳过仍缺本地官方Pikafish/NNUE）。macOS复用PID50598/runner50125，VM Service `61579/4bLZ1MhsyEk=` attach sync1,174ms、hot restart1,248ms，脱离后原PID不变。全量根测试期间一个串行`flutter_tester`，结束无残留；未运行`flutter run`，无额外ChessNext。屏幕锁定，人工视觉not run。外发、生产部署、实际运营收件未做；F31开放。

## M4-70 / F21,B24 / ADR-102 自定义棋盘几何写入串行合并

验收：用户连续拖动自定义棋盘格点或调整边距时，存储目录短暂忙碌也不能静默丢掉最终几何值；中间值可以合并，控件最终值与重载值保持一致。`BoardSkinLibraryController.updateGeometry`为每个用户皮肤保留最新待写几何并串行冲刷，等正在进行的目录写操作完成后保存，避免`_save`因`loading`直接返回false造成拖动尾值丢失。内置皮肤仍走偏好仓储。

测试`test/application/board_skin_library_test.dart`以延迟仓储阻塞首写入，在等待期间连续提交三次几何值，确认所有调用得到成功、仓储最终值及controller状态均为最后一次几何。定向命令`flutter test --concurrency=1 test/application/board_skin_library_test.dart test/widgets/board_geometry_editor_test.dart test/widgets/board_skin_library_dialog_test.dart --reporter expanded`13/13。根`flutter test --concurrency=1 --reporter expanded`600通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-70.log`；5跳过依赖未配置的官方Pikafish/NNUE。根`flutter analyze --no-pub`及`git diff --check`通过。

macOS复用PID50598/runner50125，`flutter attach --debug-url=http://127.0.0.1:61579/4bLZ1MhsyEk=/ --no-dds`同步1,186ms、热重启1,027ms；Ctrl-C脱离后PID50598仍存活。测试用单并发单tester，结束无残留；未使用`flutter run`或另开GUI。屏幕锁定，人工窗口视觉验收not run。该提交仅修复本机持久化竞态，不证明源站边距/格点映射公式；F21/B24与登录外全站对齐仍开放。


## M4-71 / F21,B24 / ADR-103 拖动预览不被旧父值覆盖

`BoardGeometryEditor.didUpdateWidget`原先无条件以父级属性重置本地geometry。自定义皮肤controller保存时先发loading通知，父级可能以旧profiles重新构建，导致拖动预览瞬间回跳。现仅在父级geometry实际改变且不处于拖动时同步。验收测试让`StatefulBuilder`在每次`onChanged`后以同一个旧geometry重建，并确认最终状态与格点屏幕位置继续前进。定向`flutter test --concurrency=1 test/widgets/board_geometry_editor_test.dart --reporter expanded`5/5。根`flutter test --concurrency=1 --reporter expanded`601通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-71.log`；五项需官方Pikafish/NNUE。`flutter analyze --no-pub`与`git diff --check`通过。macOS复用PID50598/runner50125，attach同步1,053.6ms、热重启1,158ms，脱离后原App存活且无tester/attach残留。该交互时序修复不改变项目几何映射P，也不验证源站公式。


## M4-72 / F21,B24 / ADR-104 当前棋盘皮肤删除失败原子性

删除当前用户皮肤原先先写入内置皮肤偏好，再保存定义列表；若列表写入失败，方法返回false但活动皮肤已改变。现在先提交清单变更，成功后才更新运行时目录、回退当前选择和清理图片。失败注入测试验证false时所选profile ID、完整定义及图片均保留。定向`flutter test --concurrency=1 test/application/board_skin_library_test.dart --reporter expanded`8/8。根`flutter test --concurrency=1 --reporter expanded`602通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-72.log`；五项需官方Pikafish/NNUE。`flutter analyze --no-pub`和`git diff --check`通过。macOS复用PID50598/runner50125，attach同步1,188ms、热重启1,060ms，脱离后原App存活且无测试/attach残留。此为项目失败策略P；源站实际失败/部分提交与重载仍U。


## M4-73 / F21,B24 / ADR-105 棋盘皮肤保存与应用分离

E67操作验证：源站空白编辑页“保存”后仍在编辑页，当前设置保持默认，选择器出现“我的棋盘”；稍后单独选择“使用这套”才应用；编辑已存皮肤改值再次保存也不自动应用。站点仅在当前会话重新进入可读回几何，reload/重启U。

本机`BoardSkinLibraryController.create`增加`apply`意图；皮肤库新增“仅保存”与“新建并使用”，两者从当前皮肤复制几何及图层并保存独立定义。仅保存不改变偏好选择，已存未选中项可由列表独立使用；保留原创建即使用流程兼容。Widget测试验证仅保存新增profile且当前ID和BoardDisplayScope仍为默认内置棋盘；原“新建并使用”测试继续验证新ID被选中。定向`flutter test --concurrency=1 test/application/board_skin_library_test.dart test/widgets/board_skin_library_dialog_test.dart --reporter expanded`11/11。首轮根`flutter test --concurrency=1 --reporter expanded`603项中遇到一项既有`engine_candidates_test.dart`并发抢占用例30秒间歇超时（602完成、1失败）；该用例单独重跑1/1通过，完整根测试复跑`flutter test --concurrency=1 --reporter expanded`603通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-73-final.log`。根`flutter analyze --no-pub`通过。macOS复用PID50598/runner50125，attach同步984ms、热重启2,045ms；脱离后原App存活，测试/attach无残留。源站跨reload/重启仍U；项目ZIP导入另有显式导入并使用协议。


## M4-74 / F21,B24 / ADR-106 已保存棋盘几何草稿编辑

为对照E67“编辑已存皮肤并保存但不应用”，用户棋盘列表新增独立“编辑”入口。`BoardSkinGeometryDraftDialog`在局部草稿上提供9×10双把手、四边滑杆、皮肤棋子缩放、落点旋转和恢复默认；“取消”直接退场不调用写接口，“保存”将geometry一次提交到目标ID且不选择该ID，保存失败保留表单并允许重试。列表“使用”仍是唯一应用目标皮肤的入口。范围不包括图片层草稿/单张文件修改协议。

定向`flutter test --concurrency=1 test/widgets/board_skin_library_dialog_test.dart --reporter expanded`3/3；测试确保取消前后manifest值不变、保存更新值但selected ID仍内置、随后使用使BoardDisplayScope显示保存几何。定向`flutter test --concurrency=1 test/widgets/board_skin_library_dialog_test.dart --reporter expanded`3/3；根`flutter test --concurrency=1 --reporter expanded`603通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-74.log`（5跳过需官方Pikafish/NNUE）；`flutter analyze --no-pub`和`git diff --check`通过。macOS复用PID50598/runner50125，attach同步978ms、热重启1,171ms，脱离后PID50598存活，无tester/attach残留和新App。源站刷新/重启和跨进程语义仍U。

## M4-75 / F21,B24 / ADR-080,105 file-backed 保存/重开生命周期回归

新增集成测试使用实际`FilePreferencesRepository`、`FileBoardSkinLibraryRepository`与`FileBoardSkinImageRepository`，而非Memory仓储。先设定内置jade为当前皮肤，保存一套不应用的用户定义，修改六项几何属性并写入落点PNG；关闭全部controller后新建全套controller，验证profile几何与图片恢复且当前仍为jade。随后单独“使用”用户皮肤，再次重建controller，验证选中ID和定义几何均恢复。专项`flutter test --concurrency=1 test/application/board_skin_library_test.dart --reporter expanded`9/9；根`flutter test --concurrency=1 --reporter expanded`604通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-75.log`；`flutter analyze --no-pub`和diff-check通过。macOS复用PID50598/runner50125，attach同步984ms、热重启1,278ms；脱离后App存活且无tester/attach残留。此为项目真实文件适配器验证，不证明源站reload行为；目录图片在manifest、清单提交分阶段失败之间的孤儿清理仍另行处理。


## M4-76 / F21,B24 / ADR-107 自定义棋盘图像孤儿目录恢复

`BoardSkinImageRepository`增加`pruneCustomSkins(retainedIds)`端口。文件适配器扫描受控棋盘图片根目录，仅删除格式正确且未被成功加载profile列表登记的`custom-*`目录；保留内置ID及仍登记皮肤，包括空资源。`BoardSkinImageLibraryController`同步移除已清理缓存。`BoardSkinLibraryController.initialize`将清理置于定义load成功之后；load/解析失败绝不运行清理，清理失败则提示错误并保留数据，不改用户当前选择/列表。用于收敛创建、删除在两仓储间崩溃产生的孤儿，不是多文件事务原子性保证。

专项`flutter test --concurrency=1 test/application/board_skin_image_library_test.dart test/application/board_skin_library_test.dart --reporter expanded`14/14；覆盖含图/空孤儿、保留profile/内置项，以及损坏清单时图像不清理。根`flutter test --concurrency=1 --reporter expanded`606通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-76.log`；`flutter analyze --no-pub`和`git diff --check`通过。macOS复用PID50598/runner50125，attach同步1,083ms、热重启1,194ms；脱离后原App存活且无tester/attach残留。


## M4-77 / F21,B24 / ADR-108 单槽图片替换中断恢复

文件保存顺序为写入临时目录、移动唯一图片文件、最后原子替换槽manifest。已知崩溃窗口会留下未引用`slot-timestamp.(png|jpg|jpeg)`或`.slot-pending-*`。`FileBoardSkinImageRepository.load`仅在slot manifest不存在，或manifest/image均合法且解码验证成功时对该槽回收项目命名格式的剩余文件/临时目录；保留当前引用、所有未知内容及损坏/缺失引用情况下的整槽数据。实体需是普通file/directory且禁跟随symlink。专项`flutter test --concurrency=1 test/application/board_skin_image_library_test.dart --reporter expanded`5/5；根`flutter test --concurrency=1 --reporter expanded`607通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-77.log`；`flutter analyze --no-pub`和`git diff --check`通过。macOS复用PID50598/runner50125，attach同步1,067ms、热重启1,112ms；脱离后原App存活且无tester/attach残留。规则不能保证多文件原子性。

## M4-78 / F15 / ADR-109 主界面手动云库查询

主工作区增加独立“云库”只读卡片，显式选择opening/endgame、显式查询当前节点。`BookLookupController`只依赖`BoardSession`和`BookService`端口，将当前FEN及根到当前游标完整线路（上限512步）提交到当前偏好中的自建服务地址；空地址不会请求。返回命中时逐候选以当前合法着集合复核，非法命中不暴露；有效候选显示UCI、scoreCp、weight及服务响应许可/署名，不自动落子、不写棋树。HTTP拒绝、不可达、无效响应及有效miss分别投影。位置/新局/库类型改变使在途任务token失效并清空旧数据。

专项`flutter test --concurrency=1 test/application/book_lookup_controller_test.dart --reporter expanded`6/6；根`flutter test --concurrency=1 --reporter expanded`613通过/5跳过/0失败（日志`/tmp/chessnext-root-test-m4-78-final.log`，5项需官方Pikafish/NNUE）；`flutter analyze --no-pub`无问题；`git diff --check`通过。macOS复用PID50598/runner50125，早期attach同步1,480ms但非TTY未能发送热重启；最终代码的TTY attach同步1,266ms、热重启787ms，Ctrl-C脱离后原PID50598仍在，无测试/attach/chessNext副本。锁屏人工视觉检查未做。首次定向测试暴露测试断言使用`isEmpty`/`hasLength`匹配int的错误；更正后专项通过。首次analyze有两条花括号info，修正后无问题。


## M4-79 / F15 / ADR-109 云库候选中文记谱

主界面云库候选不再仅显示UCI：`BookLookupController`在查询响应通过合法着校验后，使用查询时的局面生成中文记谱并作为主标签；UCI、scoreCp与weight保留为辅助信息。记谱只是本地展示，不额外发网络请求、不自动走棋。

定向`flutter test --concurrency=1 test/application/book_lookup_controller_test.dart --reporter expanded`6/6；根`flutter test --concurrency=1 --reporter expanded`613通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-79.log`；`flutter analyze --no-pub`无问题，`git diff --check`通过。macOS使用既有PID50598/runner50125，TTY attach同步1,611ms、热重启2,148ms；Ctrl-C后复核原PID50598存活，未发现tester/attach进程或第二个chessNext GUI。测试期间仅一个串行`flutter_tester`。未做人工视觉验收；5项跳过仍需官方Pikafish/NNUE环境。


## M4-80 / F15,F20 / ADR-110 自建大师谱索引查询服务端

新增独立可选`MasterGameDatabase`和`POST /v1/master-games/query`。运营者通过`CHESSNEXT_MASTER_GAMES_ROOT`装载自有/授权的索引；按精确FEN+完整history定位候选，并支持all/game/chessbook、玩家/赛事不区分大小写子串、年份闭区间、胜和负集合及有界分页。响应有数据集许可/署名、总量和索引元数据，保留清单顺序；没有第三方样本，也未实现Flutter筛选面板或完整棋局读取。该查询策略是依据可见字段的项目提案P，E87 DOM边界不解释为站点真实执行语义。服务请求体有32KiB上限、不落盘不记录；Nginx示例对此路由关闭access log并限速。

专项`flutter test --concurrency=1 test/server/master_games_server_test.dart --reporter expanded`3/3；服务包`dart test`6/6、`dart analyze`无问题；根`flutter test --concurrency=1 --reporter expanded`616通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-80.log`；`flutter analyze --no-pub`无问题，`git diff --check`通过。5项跳过需官方Pikafish/NNUE环境。macOS复用PID50598/runner50125，TTY attach同步1,640ms、热重启2,180ms；Ctrl-C后核验PID50598存活，无tester/attach副本或第二个GUI。未做UI视觉验收，因本片仅服务端。

## M4-81 / F15,F20 / ADR-111 大师谱筛选客户端

`MasterGamesService`与`HttpMasterGamesService`独立于UI；显式自建endpoint、HTTPS远端/loopback HTTP、8秒超时、请求32KiB/响应2MiB上限；严格校验schema、页码、数据集许可/署名与metadata字段。`MasterGamesLookupController`仅在显式查询时捕获FEN/完整线路和过滤器；输入字段、云库/大师谱切换不请求；空endpoint离线；筛选和位置变化废弃旧响应；结果不改树且只返回metadata。UI支持全部/对局/棋书、棋手/赛事、年范围、结果chips和前后分页。

专项`flutter test --concurrency=1 test/widgets/cloud_book_panel_test.dart test/adapters/network/http_master_games_service_test.dart test/application/master_games_lookup_controller_test.dart --reporter expanded`7/7；根`flutter test --concurrency=1 --reporter expanded`623通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-81-final.log`；5跳过需官方Pikafish/NNUE。`flutter analyze --no-pub`与`git diff --check`通过；`flutter build macos --no-pub`最终源码构建成功，伴随既有插件SwiftPM及未来Swift兼容警告。macOS复用既有PID50598/runner50125：历史及当前URL附着失败；自动发现也等待连接。未执行`flutter run`、未开第二个GUI。macOS app运行/热重启未验证。根测试只有一个串行flutter_tester，GUI始终唯一PID50598。

源站筛选匹配/分页/排序与实际键盘年份边界、运营者授权语料及完整棋局读取仍U；本片不宣称F15或全站对齐。

## M4-82 / F15,F20 / ADR-112 来源选择记忆

新增`BookLookupSource {cloud, masterGames}`偏好，旧schema缺字段默认为cloud；应用设置和主工作区SegmentedButton共享选择。PreferencesController为编辑字段合并异步加载，实际选择通过统一偏好端口保存，切换源不自动网络请求。E55只V验证同标签路由保留；本机跨重启属于P。

专项`flutter test --concurrency=1 test/application/preferences_controller_test.dart test/widgets/cloud_book_panel_test.dart --reporter expanded`8/8；覆盖schema round-trip、延迟读取期间用户切换不被旧值覆盖、写入以及面板选择不触发大师谱查询。根`flutter test --concurrency=1 --reporter expanded`623通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-82.log`；`flutter analyze --no-pub`和`git diff --check`通过；`flutter build macos --no-pub`构建通过，提示flutter_tts SwiftPM warning。既有PID50598的VM attach本轮未重新尝试，故macOS实际运行/视觉仍未验；无新App。
