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
