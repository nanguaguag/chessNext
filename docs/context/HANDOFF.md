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
