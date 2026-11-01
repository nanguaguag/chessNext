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
