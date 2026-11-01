# 会话交接

2026-11-02 Asia/Shanghai。先读AGENTS/README/CURRENT_STATE/DECISIONS及git status/log；当前以本文件及磁盘为准，旧交接保存在history/2026-11-02-before-candidates-handoff.md，历史失败/跳过见SESSION_LOG/TRACEABILITY。

用户要求持续业务实现直到所有可确认功能对齐，一功能一中文Conventional Commit，先全量flutter test/flutter analyze；真实macOS运行已授权。在线自建可替换后端+部署方案；许可按要求暂缓不阻挡。尚未完整对齐，不可结束给整站完成审查。

## 当前实现

最近048355e文件复盘缓存、6f79296候选研究；M3-12单步候选/父局面试走本次提交见git log。已有棋盘/规则/编辑/分支/注释/本地保存、FEN/UCI/ICCS/中文、独立自动草稿与偏好、UCI分析/AI、资源复用/组合预算/身份校验、整谱最佳着法队列/曲线/缓存。模块映射IMPLEMENTED_MODULES，ADR005–013。

CandidateRun+engine_candidates.dart+CandidatePanel/Options：普通当前着在父局面计算、根在自身；有限每候选depth/time/nodes，逐次排除已发现合法首着，策略2..256，原始cp/mate/bound/无评分。候选不自动入谱，stop后核验快照再playVariation原子试走；当前/已存节点无多余dirty，旧分支/注释保留。单步导航/编辑过期；整谱纯读谱仍继续。batching统一整谱/候选与分析/AI互斥。ReviewCacheAccess共用IO/合法PV/允许集与2秒失败降级。停止失败代次拒绝试走；取消后late factory失败清掉旧opening future保证下一次重试。

正式main注入FileReviewCacheRepository，ApplicationSupport/chessnext-analysis-cache，schema/checksum/限额2048条32MiB/单条64KiB/串行暂存原子替换/坏缓存删除并重算。键完整历史+已验证引擎/NNUE/ABI+规则/算法/精确预算/资源/允许集；不含epoch/token/节点/游标/注释。详engine/REVIEW_CACHE及ENGINE_IDENTITY。新App/新引擎命中和独立Dart进程协议已验证；不是人工OS重启/断电。

## 最新验证

根flutter test135/135（显式官方NNUE环境）/flutter analyze通过；macOS完整14/14+最终候选单项1/1通过。核心未改沿用49/49及dart analyze。新增13候选应用/真引擎与3组件测试。旧注释导航测试因未滚到按钮先133通过1失败，修ensureVisible+hitTestable后134，最终补无bestmove原因135通过；失败如实记日志。所有本功能应提交，git status核对。无待等待验证命令。

原生integration_test只在测试文件保持framework-resumed，生产无覆盖。真实OS焦点/最小化/人工视觉未验，Computer Use桌面权限未授不绕过；其他四平台未验，移动FFI未落地。普通flutter run旧会话22326曾存活，不自动关闭有可能未保存的窗口；测试覆盖build入口，最终审查前需普通flutter run重建。

## 下一条可执行

整谱多候选模式：先抽出单次有限搜索执行器（纯应用层、共享唯一EngineGateway，缓存/最终PV与bestmove匹配/允许集/无分、临时info订阅和取消清理），让现整谱与单步循环共同复用，避免将startCandidates嵌入startReview（会disable自己的队列）。执行器不拥有第二进程；调用者仍控制job/token/epoch/取消。相应回归通过后整谱配置增加最佳/多候选模式+候选上限，ReviewRun每节点存候选列表和主评分，局面进度与候选进度分开、范围/取消/缓存语义一致，算法mode入键。详planning/CANDIDATE_SLICE初始P和ADR-013。

然后胜率/准确率等级与错题→文件格式/图片GIF→棋谱库完善/最近阅读/工作区/外观声音帮助→自建后端部署→五平台及完整历史规则。每项再拆独立验收，不把本机模型称为网站同公式。

E12/E13/E14源站证据落盘，IAB browser2 tab4已markHandoff（可失效，同浏览器listTabs恢复）。访客当前自制线路兵七进一/卒３进１/炮八平五；视图继承左右镜像，不用像素猜UCI！单步0秒/深度4/节点0/最多2成功，红方父局面建议兵七进一65%/炮二平五56%，未自动入谱。E13试走已验证在父局面新增同级。删除仅O未执行；可接受阈值/累计预算/评分公式仍U。截图只研究。

环境Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0；2026-11-02官方latest仍2026-09-06，lock见engine/pikafish.lock.json。.local不提交，crypto3.0.8由既有传递改直接依赖，无新增其他依赖。重跑命令见COMMUNICATION_VALIDATION/MACOS_RUN。

## M3-13最新（完成，提交见git log）
FiniteSearchExecutor已统一单次有限请求、最终bestmove/PV/完整合法性、缓存与取消/流错误finally清理；两套后台info捕获已移除，仍唯一EngineGateway。坏PV缓存有remove，只删派生缓存。根142/142+analyze、macOS完整14/14通过；6执行器+文件套8目标及6组件目标通过。核心未改49。最后所有验证命令已结束，无待等待进程，工作树提交后应干净。
Fake Widget异步清理经历首轮2失败/停滞并INT自有进程52684、有限pump4失败；TRACE定位subscription.cancel Future在真实zone，pumpUntil需要runAsync推进真实异步+模拟帧。TRACE完全移除；最终全量142与analyze通过。别删除生产finally await来迎合Fake时钟。旧段135为上一切片，当前142。
下一条按planning/THOROUGH_REVIEW_SLICE.md实施整谱多候选模式，方案仍P；不要调用startCandidates嵌startReview（会停掉自己）。抽CandidateCollector纯应用服务共用FiniteSearchExecutor，再扩ReviewRun模式/候选集合与partial、局面/搜索缓存双计数、配置与详情/进度。完成完整门槛再独立feat(review)中文commit；随后胜率/错题等所有功能继续，不能最终停下审查。

## M3-14最新（完成，提交见git log）
CandidateCollector已共用单步/整谱，ReviewMode最佳/多候选，完整与partial集合/主分只用首请求、局面与候选查询复用双计数、100ms batchInfo和只读候选详情。根151/151+analyze、macOS完整15/15通过（四局面每节点2候选、重跑4局面/8搜索命中），核心49未改。没有待等待验证命令；提交后工作树应干净。ADR-014、THOROUGH_REVIEW_SLICE尾部与TRACEABILITY说明范围；旧段142是前一重构切片。
下一条原生UCI_ShowWDL：固定官方tag uci.cpp已在线查证输出win/draw/loss三整数（和1000），不要自己由cp编造概率；先做实际CLI通信probe再加EngineInfo/解析/请求选项和缓存metadata/键/能力处理，之后UI/复盘损失与分类。原始CP可保留，mate/bound/无WDL不能冒充普通概率。源站准确率公式仍未知，需继续审计而非假称相同。
官方指南2026-11-02重读出现标准（推荐）与题库声明，但当前实际UI此前只操作快速/彻底；这是D与V差异，待新增E15证据并续审题库/标准入口，不能只按文档标运行成功。https://xiangqiai.com/guide/ 与固定源码 https://raw.githubusercontent.com/official-pikafish/Pikafish/Pikafish-2026-09-06/src/uci.cpp 。当前IAB browser2 tab4仍markHandoff，访客自制棋谱。

E15/WDL调查已完成，提交见git log。F33题库仅指南D、B21待核；当前访客实际模式只有快速/彻底，不能猜标准参数。IAB tab4现在模式选择器打开（快速505/彻底508/取消511是当次索引，必须fresh AX再用），已markHandoff。WDL实际CLI8行/总和1000/quit0，见engine/WDL_RESEARCH与validation/wdl-protocol-2026-11-02.txt、tools/probe_wdl.py；App还未启用/解析。最后样本black raw -36,8/896/96。下一按该文档实施类型/请求/选项/解析/缓存/视角展示，先端口与失败模型，逐增量测试commit。没有待等待验证命令。

## M3-15最新（完成，提交见git log）
原生WDL已贯通请求/选项/解析/缓存与分析面板，详ADR-015。端口preferWdl默认false，App请求true；check不支持回退，toggle等ready且只变更，不清TT。原始三项总1000，视角交换胜负；expectedScore=(wins+draws/2)/1000，UI分开展示。无WDL/坏统计不补0，bound/mate不附普通概率。独立WDL子键，旧CP缓存可读；声明能力却缺请求字段不能完整命中。
根162/162（真NNUE）+analyze、macOS完整15/15通过，目标32/32；所有验证已结束。核心49未改。代码应已提交；AGENTS及onboarding/pikafish两个Skill的纯协议更改已在独立chore同步，提交见git log。Skill-creator已读，系统Python首缺yaml不算验证，临时venv PyYAML6.0.3后两个quick_validate都Skill is valid；无全局/产品依赖更改，临时环境已清理，日志/tmp/chessnext-skill-validation.log。下一继续复盘预期损失/等级/错题及其它功能，不能最终停下。
原生WDL数据不是网站准确率公式：下一可计算明确标示模型的预期得分损失（按走子方，raw半分千单位可用2*wins+draws整数避免阈值浮点），先before/after同预算/身份/无bound数据配对；不要凭cp造“准确率”。妙手/唯一守招和错失良机需多候选/杀棋语义另验。源站阈值2/5/10/20仅有UI证据，等号边界/聚合准确率仍未知，研究缺口保留。

协议维护补记：AGENTS现明确初始调查限制已按用户授权扩展，离线优先与后续自建后端是顺序不是删范围；onboarding/pikafish Skills移除硬编码仅研究/spike措辞，保留实际状态核验与质量门槛。两个quick_validate在临时PyYAML6.0.3环境通过，证据context/validation/skills-2026-11-02.json。未改产品依赖或全局Python，纯文档维护不重复跑业务测试。业务最近ddbcc9b，根162/原生15不变；提交后工作树应干净。

## M3-16进行中：模型着法评级（未提交/未验收）
新增application/review_report.dart、features/review/review_report_dialog.dart，修改ReviewPanel入口；F32/B18复盘子项，native-wdl-loss-v1（2*wins+draws整数，父局面实际候选优先/否则后续局面换视角，缺失/mate/bound不评级），不是源站准确率公式。正在补单元/组件/真实macOS测试与ADR-016。首次flutter analyze失败6项（nullable run捕获和大括号），已修改但尚未重跑；不视作通过。工作树此功能WIP，无已知仍运行验证。最近已提交基线根162/原生15；恢复先git status与日志再继续测试。

M3-16续：7模型+3组件10目标通过；全根真NNUE172/172、analyze无问题；真实macOS15/15含报告筛选/跳n1不dirty已过。ADR-016和追踪已写；最后移除无效!后最终根回归session52308待结束/log/tmp/chessnext-report-final.log，确认后再commit feat(review)中文。初编译测试构造API误用/后n2夹具非法bestmove导致2fail均如实记录，生产执行器不改。报告是自有native-wdl-loss-v1，不冒充网站准确率。docs/research/screenshots/E16/E17及E16/E17 AX是后续审计证据，尚未登记/提交；与报告分开docs提交。IAB tab4在官方古谱事林广记加载中，若继续先fresh AX；E16存题访客需登录已V、E17最近阅读访客空列表已V，恢复/持久化U。

M3-16最终根回归已172/172通过，无待等待验证命令。所有本功能文件应独立feat(review)提交，工作树剩E16/E17研究截图/AX待下一docs登记。下一可审计最近阅读的打开/恢复边界并实现本地阅读历史，或拆本地错题收集与训练；不最终停下审查，尚有大量缺项。

E16/E17研究已登记：存题需登录V，最近阅读访客空态V，公开《事林广记》3/3只读标题出现但实际着法未载入、回历史仍空，记录/恢复语义U。IAB tab4停最近阅读空页已markHandoff；不要把目录6回合当加载完成。下一F18离线阅读历史作为明确P：独立本机元数据，已保存谱ID+根/路径身份校验的游标、按最近阅读排序/有界，打开仍保护dirty，坏历史不影响棋谱；不得把未保存新分支位置恢复到同ID旧节点。先写验收再实施。评级已提交3c59834，基线172/原生15；无待等待验证命令。
