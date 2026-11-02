# 当前模块与依赖（2026-11-02）

本文件描述磁盘上的实现；ARCHITECTURE.md保留原始设计与后续目标。

| 边界 | 当前路径 | 所有权 |
|---|---|---|
| 纯Dart领域 | packages/xiangqi_core | 棋盘规则、FEN、编辑草稿、不可变棋树与文字格式；不依赖Flutter/IO |
| 会话 | lib/application/board_session.dart | 当前文档、游标、选中、dirty/revision/epoch/positionRevision、输入锁 |
| 棋谱用例 | lib/application/library_controller.dart | 保存/打开/导入新文档；读取竞态与保存失败状态 |
| 引擎调度 | lib/application/engine_session_controller.dart + engine_play.dart + engine_review.dart | 单引擎所有权、分析/AI/整谱互斥、取消/迟到结果、资源预算 |
| 端口 | lib/ports | EngineGateway、GameRepository、TextClipboard；UI不实例化进程/文件IO |
| 适配器 | lib/adapters | UCI进程、沙箱资源定位、文件快照仓库、Flutter剪贴板 |
| 表现 | lib/features | board/editor/library/analysis/play/transfer；编辑草稿与导入结果确认前不覆盖会话 |
| 装配 | lib/main.dart + app.dart | 生产仓库/引擎注入、路由与生命周期；测试用内存仓库与显式Fake |

GameTree是文档唯一棋谱真值；Position缓存不可变。文字导入先得到整棵合法新树再一次替换；剪贴板通过端口，失败可手动粘贴/复制。导出FEN不承诺保存分支/注释。在线服务和移动C ABI尚未落地，不能把接口设计算运行验证。

后续扩展：ReviewCoordinator作为可抢占后台任务复用EngineGateway；Auth/Sync/Book/Recognition均提供独立DTO与失败模型，可替换自建后端，部署方案纳入B10；UI不跨端口请求网络。设置/自动草稿应独立于显式棋谱仓库，避免把用户保存文档当临时缓存覆盖。

中文记谱由领域ChineseNotation负责，基于执方/源局面生成，不受UI棋盘旋转影响。中文解析通过合法候选的格式唯一匹配，拒绝歧义；界面显示可变，稳定UCI字段及GameTree schema保持不变。

自动草稿由DraftController/DraftRepository负责，FileDraftRepository只写chessnext-drafts；显式库仍只写chessnext-records。恢复创建未保存副本。正常退出/后台在composition root协调flush，失败选择在Material对话框呈现。设计边界和未验证持久性见ADR-006。

偏好设置由无Flutter的AppPreferences值对象、PreferencesController及独立PreferencesRepository组成；ApplicationSupport文件适配器与棋谱/草稿隔离。EngineSessionController.configureSession一次更新资源与AI用时，主题变动不触发搜索。实际能力限制在握手后再验证；生命周期策略见ADR-008。

整谱队列实际采用EngineSessionController的engine_review.dart扩展，共享单EngineGateway；ReviewRun/ReviewedPosition和预算在review_models.dart，UI为features/review。内容revision使结果失效，读谱不移动队列。当前仅会话内原始评分，没有持久缓存/胜率算法；详ADR-011。

EngineGateway的可空EngineIdentity记录经文件校验的制品身份，name来自实际UCI握手。verifyEngineBundle在工作Isolate校验manifest/可执行文件/NNUE，bundle脚本区分源二进制与签名后hash。详engine/ENGINE_IDENTITY。任意CLI无身份时仍可运行，后续缓存不得猜测。

review_cache_key.dart结合真实身份/历史/预算/规则版本生成缓存键；ReviewCacheRepository与CachedEngineScore提供异步端口，默认MemoryReviewCacheRepository为2048条LRU。候选PV合法性在复用前验证，只有完成、无bound的单路结果可命中。IO失败降级和取消见ADR-012，文件持久化下一切片。

FileReviewCacheRepository由main注入ApplicationSupport/chessnext-analysis-cache，不与用户棋谱/草稿共目录；有界、schema/校验和、串行原子替换，可再生损坏项删除并明确降级。纯Dart跨进程探针与macOS新App/引擎实例验证边界见engine/REVIEW_CACHE。

engine_candidates.dart/CandidateRun处理当前着法的父局面候选，EngineSessionController.batch统一分析/AI/整谱/候选互斥。ReviewCacheAccess抽出共用缓存IO和PV/允许集验证。BoardSession.playVariation原子创建/切换父局面同级着法，控制器等stop并检查完整快照后提交。表现位于CandidatePanel/OptionsDialog；原始cp/mate/bound，不冒充源站可接受筛选或胜率。详ADR-013。

FiniteSearchExecutor是纯应用层单次有限单PV执行器，整谱/单步候选共用；临时订阅只接请求token及允许首着，最终bestmove与完整PV合法性/匹配后才赋分和缓存，取消/错误finally等待清理。不启动进程/不接管新任务。缓存新增remove以清理schema合法但目标PV不合法的条目，仍不触及棋谱目录。

CandidateCollector统一单步与整谱多候选；ReviewRun/ReviewedCandidates区分partial与完成，主图仍用首个最佳请求原始评分。局面与查询复用双计数、100ms token/job进度、ReviewCandidatesDialog有界只读详情见ADR-014。

WdlEstimate与EngineInfo.wdl/EngineRequest.preferWdl支持原生模型统计；UciEngine按check能力与ready同步，解析和缓存都保留可空/旧CP兼容。AnalysisPanel区分胜和负与预期得分，并通过协调器按显示方反转，详ADR-015。

M3-16：application/review_report.dart纯快照报告与期望损失整数阈值，ReviewPanel只在开窗计算，review_report_dialog.dart红黑摘要/筛选/有界列表/来源解释与安全跳转；ADR-016。没有新的IO或引擎所有者；网站准确率/妙手公式未确认，不标相同算法。

F18：ports/recent_reading_repository.dart独立元数据/恢复接口；application/recent_reading_controller.dart监听库和会话、epoch绑定/300ms合并/晚到合并/串行写；adapters/storage/file_recent_reading_repository.dart版本JSON/备份；features/library/recent_reading_dialog.dart最近阅读和dirty确认；App/main装配及生命周期flush。LibraryController.documentEpoch与open可选标记保护ID重用。ADR-017，不写棋谱内容。

F29首片：features/help/offline_help_dialog.dart只读展示层，原创9主题/搜索/折叠/选中文字；AppBar装配入口，无应用IO或引擎依赖。手动分步/首次提示仍后续独立增量，验证TRACEABILITY。

F29第二片：OnboardingDialog纯展示四步/类型化GuideExit，OfflineHelpDialog返回HelpAction由App协调；AppPreferences可选guideVersion与PreferencesController.markGuideSeen处理错误/初始化合并/保存，App/main显式firstRun开关和安全导航。Settings保存copyWith保留非表单字段。ADR-018，真实控件聚光操作闯关尚未实现。

M2-14：application/reading_navigation.dart纯目标计算；BoardSession按tree对象缓存；App双箭头保留绝对首尾并绑定epoch/内容与位置修订回调，经现有EngineSessionController.navigateToNode。E19/BRANCH_NAVIGATION_SLICE与TRACEABILITY说明范围，无规则修改。

M4-01a：packages/xiangqi_core/lib/src/pgn_record.dart纯Dart有限单局PGN codec和不可变标签包装，不拥有应用会话/IO；原始规范与自制样本E20，根互操作fixture验证。尚未接App/文档资料持久化，UI仍只有原文字格式，不能因export声明而冒称完整PGN功能。

M4-01b：core GameMetadata与PGN共用有界验证；BoardSession并列文档资料/修订，MetadataEditor快照应用；RecordMetadataDialog只字段编辑/未知只读保留。SavedGame可选metadata、FileGame/Draft转传，Draft key和恢复带资料；dirty覆盖保护不再依赖实际hasContent，命名空草稿可恢复。ADR-019。引擎普通分析/AI保持，复盘按既有内容修订策略过期。

M4-01c：application/record_text_exchange.dart无Flutter/IO的格式协调+静态Isolate.run，ImportedRecord携tree/metadata/source；ImportTextDialog TextImporter注入与PopScope/代次/route收尾；App导入确认/保存后复验并原子入库会话，导出开窗快照。ExportTextDialog五格式/PGN评注选项/不可无损错误禁复制。ADR-020；系统文件入口仍后续。

M4-01d：ports/record_file_picker.dart返回有界UTF8文字，FileSelectorRecordPicker独占插件/流/路径；ImportFileDialog预览确认、错误重试/退场代次，App共用文字导入保护；main注入，macOS只读用户选择权限且保留sandbox。ADR-021/RECORD_FILE_IMPORT_SLICE；系统面板人工选择与其它平台未验。

M4-01e：RecordFileExporter与MacOsRecordFileExporter分离外部导出/内部保存；ExportTextDialog五格式文件保存/取消令牌、快照不改dirty；macOS/Runner/RecordFileWriter.swift仅负责有界UTF8通道校验及utility串行Foundation atomic写入。main只在macOS注入；Debug/Release权限按新写入用途升级user-selected.read-write，继续sandbox。ADR-022，实际OS保存面板/作用域释放/其它平台待验。

M3-19：AppPreferences可选textSize枚举/Controller合并与retryPersistence，AppTextScaling全路由MediaQuery保留系统非线性与显式manual1/1.15/1.3；TextSizeDialog从原PreferencesDialog独立实时操作/错误重试，旧参数表单copyWith保留它。无新IO/引擎所有者；ADR-023，F27语言/字体资源仍后续。

M3-20：BoardDisplayScope在Navigator外持只读显示bool，BoardSurface统一使用/可override，BoardFileCoordinates独立上下路数边框；翻转/镜像和格距沿同一逻辑Square，坐标不拦截落子。AppPreferences可选showCoordinates与Controller合并/串行持久化，BoardDisplayDialog独立即改即存/失败重试；普通设置保留最新字段。ADR-024，棋子大小/素材与其它外观后续。

M3-21：既有显示Scope/偏好增加有界pieceSizePercent，BoardDisplayDialog离散滑块/重置即改即存。BoardSurface只对实际piece face做Transform.scale（不变hit test），空交点、路数和90格几何保持，拖动feedback共用face。ADR-025/PIECE_SIZE_SLICE。

M3-22：纯board_appearance.ArrowHeadStyle存储枚举、AppPreferences/Controller可选字段与合并；AnalysisMarkersDialog即时偏好、BoardDisplayScope注入。BoardArrowsPainter与静态网格分离，组合显隐只撤视觉/语义不丢PV，IgnorePointer不抢交点；三头宽/恒定杆/四方向真实绘制测试。ADR-026。变着树箭头及其它F26后续。
