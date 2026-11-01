# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS与git status/log，再按模块文档恢复。旧交接保存在history/2026-11-02-before-reading-handoff.md，失败/中断/跳过见SESSION_LOG，不依赖聊天记忆。

## 授权及当前基线

持续业务实现直到可确认全站功能对齐；一功能全量flutter test+flutter analyze通过后独立中文Conventional Commit，macOS真实运行已授权。在线自建可替换后端+部署方案；许可决策暂缓不挡功能。完整对齐远未完成，不最终停下给审查。

最近已提交3c59834评级报告（native-wdl-loss-v1，非网站准确率）及e9cf7b1 E16/E17研究；此前ddbcc9b原生WDL，b429166已同步Agent协议实施范围。基线报告根172/原生15，核心49未改；当前F18 WIP如下。

## 当前F18 / M2-13 / B06,B19（已完成，提交见git log）

RecentReading DTO/端口、独立RecentReadingController与文件/内存适配器、RecentReadingDialog、App/main生命周期装配。已保存本地谱ID/documentEpoch绑定，最多50条去重前置/300ms/串行写，根FEN+整条UCI路径恢复，禁止只用节点ID。普通库沿用保存位置，最近阅读入口才用标记；不存未保存分支/新局、不写原谱，草稿独立。库刷新不能重绑外部替换文档，save绑定失效另建ID。dirty确认后再次查文档/位置修订，IO晚到保护保留。

正式main注入ApplicationSupport/chessnext-reading，schema1/2MiB/50条/1999着，备份/坏主归档；双坏禁止自动覆盖，重试合并本轮元数据；失败不挡棋谱保存。详planning/RECENT_READING_SLICE、ADR-017、IMPLEMENTED_MODULES。新增17测试（10应用/3文件/4组件），最终根真NNUE189/189、flutter analyze无问题；macOS完整16/16及双提示修订后最近阅读单项1/1通过。日志/tmp/chessnext-recent-{final,final-analyze,native,native-final}.log，无待等待验证命令。静态初7项大括号/原生夹具getter错误/末1项null-aware已修并如实记录。F18所有文件应已独立feat(library)中文提交，剩E18研究文件/研究文档分开docs提交。

## 研究与下一条

E16存题访客需登录V；E17最近阅读访客空态V，公开《事林广记》3/3只读标题出现但着法未载入/回历史仍空，记录/恢复仍U，不能当打开内容成功。E18按钮帮助和手动重放4步/跳过已观察，AX/截图已在docs/research已登记但待独立提交；与F18功能分开docs提交。说明声明首尾跳到前/后分支点，但本轮未操作验证，不能写V。IAB browser2 tab4停公开只读页已markHandoff；压缩恢复先cua.rewriteDocumentation再fresh AX，不重选browser。截图仅研究，不能作App资源。

下一F29离线按钮说明/使用帮助（单独功能），再手动新手引导、分支跳转、错题训练、文件格式/图片GIF、库完善/布局外观声音、自建后端部署、五平台及完整历史规则；每次一个功能通过再commit，不能到此最终停下。源站准确率/妙手/可接受候选公式仍未知，报告阈值/聚合明确是项目模型。

## 环境与复跑

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0；2026-11-02官方latest仍Pikafish2026-09-06、commit4c17cee，NNUE/SHA见engine/pikafish.lock.json。.local不入Git。root真引擎门槛：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；再flutter analyze，原生flutter test integration_test/local_board_test.dart -d macos。FileReviewCache正式AppSupport注入；详engine/REVIEW_CACHE、ENGINE_IDENTITY/WDL_RESEARCH。

macOS integration_test仅测试内保持framework-resumed，生产无覆盖；真实OS焦点/最小化/人工视觉未验，Computer Use桌面权限未授，不绕过。其它四平台/移动FFI未验。普通用户窗口PID38211/旧run22326曾在，不主动关；原生测试覆盖build入口，最终审查前重建普通main。Fake engine清理需pump_until通过runAsync推进真实zone的subscription.cancel，不能删生产await。

E18研究独立提交见git log：按钮说明实际开关、引导首步重放/跳过已V；分支跳转只有文字O待操作。本轮后续F29先做独立可搜索离线帮助，不把帮助页当自动首次引导完成。当前F18提交5acdeda，根189/原生16+1，无验证命令运行。

## F29离线帮助完成 / M3-17
features/help/offline_help_dialog.dart原创9主题/标题正文搜索/折叠/空态清空/只读可选文字，AppBar帮助与按钮说明入口。方案OFFLINE_HELP_SLICE，本片不含自动首次/手动分步引导，不标全F29。新增3组件：200%/搜索/开关不改文档、不触引擎和仓储；目标3/3、全根真NNUE192/192、analyze无问题、macOS首测试1/1（00:06）通过。日志/tmp/chessnext-help-{target,full,analyze,native}.log；无待等待验证命令。应已独立feat(help)中文commit，工作树核对。

下一F29手动四步引导+首次提示标记：建议新增guideVersion可选schema1偏好（旧默认0），逐字段晚到合并与错误保护沿用，production main显式启用首次引导，测试宿主可关闭自动弹窗并单独验证启用模式；手动重放永远可用。四步只读/安全教学、前后/跳过/完成/版本记忆，不暗中开AI或改谱。先方案+接口/失败模型后实施，注意设置保存失败要提示且可重试；不把纯说明当网站交互完全一样。随后分支跳转/本地错题/格式与其余所有缺项继续，不能最终停下。

## M3-18最新：四步/首次引导完成（提交见git log）
OnboardingDialog四步只读前后/跳过/完成，guideVersion可选schema1旧0/当前1/未来不降；PreferencesController.markGuideSeen读失败不覆盖原件、逐字段late merge，Settings用当前copyWith保存防清标记。main显式showFirstRunGuide:true，默认宿主不自动弹；成功加载后无用户模态才自动显示，手动从帮助返回HelpAction.guide进App协调。skip/complete才记，Escape不记；写失败Snackbar重试先重读，无开AI/改谱。ONBOARDING_SLICE/ADR-018；不是网站聚光操作闯关，F29该交互差距仍留。

5应用+4组件=9新增，最终根真NNUE201/201、analyze无问题；macOS引导/文件偏好新实例/重放最终1/1（00:04）、相关设置恢复1/1（00:06）通过。上次完整原生16，此片只跑相关项，文件现共17用例，不宣称17全跑。日志/tmp/chessnext-guide-{target,final,final-analyze,native-final,settings-native}.log，无待等待验证命令。首全局错误文字重复匹配、App2项大括号、新慢读测试缺dart:async编译失败均已修并日志留痕。

## 下一条：E19分支导航
E19研究文件/AX/截图已写入docs/research并登记，尚待独立docs提交，不混进引导功能。IAB browser2 tab4自制谱正常方向：炮八平五/马２进３/马八进七/马８进７，回第二着追加炮二进二为选中同级。首端从alt末端到第二着分支点、再到root；末端从root到第二着再到所选炮二进二，均V。站点嵌套/根多分支未验，不编造。markHandoff已做，压缩恢复先rewriteDocumentation/fresh AX。
下一M2-14 F01/F13 B05/B16：BoardSession增加严格前/后最近分支点目标，上一扫描祖先排除当前，下一沿currentLine排除当前，children.length>1算分支，无则root/所选line末尾。保留现有绝对首尾，另加清晰Tooltip的两按钮，经唯一EngineSessionController.navigateToNode暂停AI/旧结果保护，不dirty不写谱。先写验收/计划，再应用/组件/真实macOS导航测试，全根test+analyze后中文独立commit。随后错题训练/文件格式/外观布局/自建后端/五平台等继续，不能最终停下。

## M2-14最新：分支导航完成（提交见git log）
ReadingNavigation纯应用严格祖先/所选currentLine前后分支目标，BoardSession按tree对象缓存，App保留绝对首尾另加两个Tooltip双箭头，捕获epoch/revision/positionRevision阻止旧按钮作用新文档，经engine.navigateToNode暂停AI；离线帮助补语义。5应用+3组件目标8/8，根真NNUE209/209、analyze、macOS读谱相关单项1/1（00:08）通过；核心未改49沿用。首次缺扩展library直接import编译失败已修，日志SESSION_LOG。无待等待验证命令，应独立feat(records)中文提交。

下一E20 PGN研究：浏览器从本轮自制谱导出PGN，下载路径/Users/huzongyao/Downloads/xiangqiai_2026_11-02_05_38_47.pgn（仅本Agent自制样本，不是站点棋谱库）；151字节UTF8无BOM，SHA256 6f19538be1cb55cf50bc62f958f6ee842a9d39c0f0d4f9e3b5811d4f67b6e5f5。四标签Game Chinese Chess / Result * / FEN双字段初始w / Format ICCS，正文1.B2-E2 B9-C7、2.H2-H4 *，只导出根到当前alt路径，原另一分支和未来不在样本；不由此推断所有PGN模式。E20截图已在docs/research/screenshots/E20-pgn-export.png，其它样本/证据尚未登记，独立docs提交，不混产品。
已web查官方xqbase原始规范 https://www.xqbase.com/protocol/cchess_pgn.htm （2006修订）：Game首标签/标签-着法/默认Chinese、可ICCS/WXF/花括号评注/结果终止/多局；不可直接套国际象棋SAN。不要复制规范例谱或第三方parser代码，仅原创解析。另打开pgnfen2是国际象棋译文，不拿其50步等当中国象棋规则。下一先落研究及PGN增量计划，再实现有限单局ICCS/中文PGN交换、元数据/注释/变着损失提示与合法性原子校验；若完整头/分支需新文档模型则独立拆片，不一次假称全部格式支持。用户持续推进约束不变，不能最终停下。
IAB browser2 tab4保留本轮自制炮八平五/马２进３/炮二进二选中分支末端，刚导出后面板已收起，markHandoff；压缩先rewriteDocumentation/fresh AX。
E20样本与manifest/PGN_RESEARCH/REFERENCE_EVIDENCE现已落盘登记，下载SHA已再次核对；仅研究，无PGN业务实现。准备独立docs提交后按纯Dart codec→App资料与文字交换→文件端口分片推进，研究限制在PGN_RESEARCH。主来源xqbase规范不复制例谱/代码。

## M4-01a最新：PGN codec完成（提交见git log）
packages/xiangqi_core/lib/src/pgn_record.dart+export：PgnRecord规范化四基础标签/其它标签不可变保留；单局ICCS/Chinese/根及逐着和结果后评注/回合结果校验、PGN红r别名限定/输入输出限额；拒绝WXF/括号变着/多局/NAG。path只当前路径，评注花括号报错或明确includeComments:false；输入侧标签预算/输出逐段预算，不先分配超长结果。PGN_CODEC_SLICE。尚未接App，不宣称可导入PGN文件。
新增核心12+根E20互操作1；核心完整61/61+dart analyze、根真NNUE210/210+flutter analyze通过，无待等待命令。日志/tmp/chessnext-pgn-{target,reference,core-final,core-final-analyze,root-full,root-analyze}.log；首核心全套60+1失败是测试未指定Chinese导致默认ICCS Format差异，修测试显式格式后过，严格全Map断言保留。无UI/引擎改动，本片没空跑macOS。

## 下一功能：棋谱资料与存储（PGN接App前置）
建议独立M4-01b F10/F12/B16/B19：GameMetadata纯Dart有界不可变opaque标签（最多64、key64/值4096/无控制字符、Result可选4值），四PGN派生标签由codec校验，不让BoardSession依赖PGN解析器。BoardSession持有metadata、updateMetadata仅内容revision/dirty（不positionRevision），replaceTree可选metadata一次原子提交/newGame清空；编辑表单只改已变的赛事/地点/日期/轮次/红黑/结果，未知/派生标签保留，无操作不dirty。
SavedGame新增可选GameMetadata默认empty（可const empty），FileGameRepository schema1可选metadata字段/旧文件无字段默认empty/坏metadata转FormatException走有效备份/损坏原件保护；同包FileDraftRepository.save必须转传metadata，DraftController的_DraftKey加入metadata，恢复importTree也传它，避免只改资料不自动保存或恢复丢标签。LibraryController.save捕获metadata，同epoch晚编辑仍dirty；open/recover/importTree一次带metadata。最近阅读身份仍根/路径，不复制内容。
再加Material3棋谱资料编辑入口与200%字号/错误/旧文档确认保护，测试未知标签/metadata-only dirty与草稿/新实例保存恢复/坏文件备份/延迟保存/分析不重启。根test+analyze、核心新增对应测试+analyze、相关macOS保存/草稿验证后独立中文commit。之后M4-01c接PGN文字交换和文件端口，明确导出路径/评注/未支持特性。别直接让PGN标签被GameTree导入丢掉或把codec当全功能。
当前基线f7d2bb9分支导航，ec69d78研究，PGN提交见git log；IAB tab4自制谱alt末端已markHandoff，下载原文件与SHA见前段及E20manifest。用户持续推进全站/每功能门槛后提交的约束不变，未全部对齐不能最终停下。

## M4-01b最新：棋谱资料完成（提交见git log）
GameMetadata有界不可变/内容相等/JSON，PGN复用；BoardSession并列metadata与内容修订，SavedGame可选field/旧文件默认empty，FileGameRepository坏资料转FormatException走备份并保留原件；FileDraftRepository转传、Draft key加入metadata、恢复带资料。Library.save/open/import转传。MetadataEditor epoch+revision保护（导航不失效），Material3表单只提交已改字段/未知只读查看/结果声明不裁决/noop不dirty。清空最后字段仍dirty，覆盖保护统一dirty判断；命名空草稿可恢复。普通分析/AI不重启，整谱/候选仍按内容revision过期。

RECORD_METADATA_SLICE/ADR-019，8应用+4文件+4组件=16新增根测试，全根真NNUE226/226、flutter analyze通过；核心4新增全65/65+dart analyze（首测试空List推断警告补Object?后过）。macOS完整18首轮17通过1失败（新资料用例草稿/库同名定位），修测试漏savedRow声明又一次构建失败，补后资料单项1/1（00:09）通过；生产源未变，不把末命令说成18/18。覆盖保存/新App原谱打开/独立metadata-only草稿恢复/原谱不变。日志/tmp/chessnext-metadata-{target,root-full,analyze,core-full,core-analyze,native,native-final}.log；无待等待验证命令，应独立feat(records)中文提交。

下一M4-01c PGN文字交换（不是文件picker）：application/record_text_exchange.dart定义ImportedRecord(tree,metadata,sourceFormat)和TextExportFormat；文本以[开头自动走PgnCodec，否则TextRecord，PGN标签用GameMetadata全部保留。建议把解析放顶层/静态Isolate.run worker，只捕获String、返回纯Domain DTO/错误字符串，避免闭包捕获WidgetState；加实际worker传输与取消/旧回调测试。ImportTextDialog返回typed DTO，App保留现有epoch/revision/dirty/stop保护并library.importTree(...metadata)；旧格式metadata.empty新文档。
导出捕获打开时tree+metadata快照，保留旧3格式并加PGN ICCS/中文；用可适应200%字号的格式选择器，PGN评注checkbox默认true，花括号不能无损写时明确错误+禁复制，用户可显式省略。输出PGN派生Game/FEN/Format按当前根和所选格式重算，结果按记录保留，不裁决。非PGN格式明确资料/注释/分支损失；PGN也仅所选路径，不含未来/其它支线。不要由格式层已完成推断App文件导入可用。
先写PGN_EXCHANGE_SLICE/接口失败模型，再实现和测试；旧ImportDialog测试若typed result变化要更新语义断言，worker真实异步用pump_until/runAsync等待，不删生产await。之后文件端口/格式扩展、错题/训练、布局外观声音、自建后端部署、五平台等持续推进；未全部对齐不能最终停下。

## M4-01c PGN文字交换WIP（未提交/未验收）
方案PGN_EXCHANGE_SLICE。新增RecordTextExchange/ImportedRecord/导出enum及静态Isolate.run（纯String→领域DTO/错误字符串），首应用真实worker5/5通过，后补Unicode中间BOM保留检查，未再验全门槛。ImportTextDialog改typed DTO/解析忙态可取消、PopScope+代次/当前route防取消晚结果关其它窗口；剪贴板仍可编辑/防晚到。App导入新增确认/先保存后epoch+内容/位置复验，一次library.importTree带metadata；导出捕获tree+metadata快照。五格式Dropdown+PGN评注checkbox/错误禁复制/损失说明，旧3格式保留。
首UI代码analyze5项大括号已dart fix限定修，未宣称通过；旧文字3组件已改真实异步pump_until/Dropdown选择，当前目标session待看/tmp/chessnext-pgn-exchange-legacy-target.log。应用初5日志/tmp/chessnext-pgn-exchange-application.log。尚未写新PGN交互/取消/200%/stale组件或原生PGN，尚无根全量/analyze门槛，不计完成；无核心修改沿用65。下一看目标失败，再补场景和原生旧文字+新PGN资料保存互操作，通过后中文独立feat(notation)提交。普通用户窗口不关；IAB E20 tab4保留自制谱，markHandoff。
M4-01c续：应用5+旧组件3+新PGN组件7=15目标全通过，含实际worker/BOM中间保留、资料注释、快照、取消与Escape在未dispose时防关其它route、剪贴板晚到、确认/先保存后新内容保护、200%评注错误禁复制与明确省略。全根首238/238；analyze余1项自定义active getter已含mounted但lint不识别，补Navigator前显式mounted后正在复验（/tmp/chessnext-pgn-exchange-{analyze,full-final}.log）。新原生PGN用例已写（内存剪贴板端口+真实worker/保存/新App资料及完整分支恢复；不触系统剪贴板），尚未跑；旧原生文字format下拉操作已适配。核心无改沿用65。下一等最终root/analyze，再原生旧文字和新PGN两项，补追踪/交接后独立feat(notation)中文提交。不是系统filepicker，不标所有PGN格式支持。
