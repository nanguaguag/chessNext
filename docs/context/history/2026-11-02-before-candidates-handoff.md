# 会话交接

2026-11-02 Asia/Shanghai。先读AGENTS、README、CURRENT_STATE、DECISIONS和git status/log。旧交接存history/2026-11-02-before-review-handoff.md，详细验证/失败在SESSION_LOG与TRACEABILITY；以此文件和磁盘为当前事实。

用户授权持续业务实现直到所有可确认功能对齐，一功能一中文Conventional Commit，先全量flutter test/flutter analyze；真实macOS运行已授权。在线自建可替换后端+部署方案，许可暂缓不阻挡。尚未完整对齐，不能结束给整站完成审查。

## 当前实现与提交

最近09f2f47当前着分支面板（同级/下一着、置顶、确认删除版本保护）；dcc2a4e单引擎整谱队列。红视角曲线f72fe76；引擎身份本次提交见git log。已有棋盘、规则、编辑、分支/注释、显式保存、FEN/UCI/ICCS/中文交换、自动草稿、主题/资源偏好、分析与AI、组合限额及资源/TT复用。路径见architecture/IMPLEMENTED_MODULES。

复盘：EngineSessionController的engine_review.dart扩展共享唯一EngineGateway；ReviewRun快照epoch/revision/范围，当前线路含未来或整树每节点一次，子节点先处理，不移动游标。有限depth/time/nodes至少一项；分析/AI/参数/后台可抢占。stopping等stop屏障、迟到结果丢弃、文档内容变化stale、纯读谱继续。保留原始cp/mate/bound和执方，无评分/终局不伪造0。结果仅内存，没有跨重启缓存/胜率算法。ADR-011。

ReviewChart绘制当前选中线路、红方±10兵封顶图（真实数值在文字）、杀棋三角/上下界箭头/缺失断线，mate0只文字。点击/方向/Home/End/语义增减/滑块导航。初次语义相邻值及单点Slider越界已修，保留失败记录。

## 最新验证

根flutter test119/119（显式PIKAFISH_EXECUTABLE和NETWORK包含真实NNUE）、flutter analyze无问题。核心上一切片49/49与dart analyze，本次未改。macOS上一完整12/12，曲线目标单项1/1通过（整树NNUE、结果/曲线导航、取消）。所有本功能代码应提交，以git status为准。

原生integration_test明确保持framework-resumed，只在测试文件；生产main无覆盖。真实OS焦点/最小化/人工视觉尚未验；Computer Use未授桌面权限，不绕过。Android/iOS/Windows/Linux未验证。普通flutter run旧会话22326以前存活，不自动杀用户窗口；测试会覆盖build内App入口，最终审查前普通flutter run重建。无仍需等待的验证命令。

## 下一条可执行

引擎身份已经完成：Gateway.identity可空，name来自UCI；bundle签名后manifest，工作Isolate校验binary/NNUE并附ABI，见engine/ENGINE_IDENTITY。根104/104、analyze、macOS身份/NNUE单项1/1通过，上一完整12。crypto3.0.8由既有传递改直接依赖。M3-10会话缓存/跳过已完成：ReviewCacheRepository默认2048条LRU、review_cache_key.dart精确历史/身份/预算键，完成无bound才缓存、PV重验、缓存失败降级（ADR-012）。根112/112与analyze、macOS复盘/四局面复用/曲线/取消单项1/1。M3-11文件缓存已完成：正式main注入独立ApplicationSupport目录，schema/checksum/限额/原子替换/损坏重算，详engine/REVIEW_CACHE。根119/119、analyze和macOS完整13/13；独立Dart进程协议fixture通过，新App/引擎真实NNUE复用3局面。宿主Flutter测试进程未OS关开。接下来彻底候选/建议试走；cache key必须完整历史+规则+引擎/NNUE+预算/模式/版本，排除cursor/lineAnchor/注释。未取得评分/partial/失败不冒充完整命中，坏缓存可重算且不损棋谱。接口优先，UI不IO。之后彻底候选/分级/错题→文件格式/图片GIF→工作区/外观声音帮助→自建后端→五平台及完整历史规则。分解独立功能与提交。

E12/E13源站证据已落盘：快速/彻底运行、整树4局面、范围/0队列/取消、同级切换/置顶/回退保持。试走在父局面新建并切同级分支；删除入口仅O未执行。缓存键、候选预算和准确率公式仍U，不能推断。IAB browser2 tab4已markHandoff，可失效，用同浏览器listTabs恢复。截图只研究、不作产品资源。

环境Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。官方latest 2026-11-02复核仍2026-09-06，lock见docs/engine/pikafish.lock.json。工具/重跑命令见MACOS_RUN和COMMUNICATION_VALIDATION。

最新提交见git log，M3-10完成后工作树应干净；所有验证命令已结束，无待等待进程。下一条文件缓存端口可直接实现lib/adapters/storage/FileReviewCacheRepository，注入App/Main，不复用棋谱目录。键和评分DTO已有，序列化需严格schema/尺寸/类型/合法PV/校验和，独立有界可再生缓存；冷启动跨App复用须真实macOS验证，不把本机同实例命中当重启。

M3-11最新：文件缓存功能已通过并独立提交，见git log；所有验证命令已结束，工作树应干净。旧段落“下一条文件适配器”是M3-10当时交接，现已完成。下一条先源站审计彻底候选设置/单步分析/预算和可接受阈值（目前U），再设计候选计算与试走，不把MultiPV若干条伪称网站同筛选算法。可先交付清楚标示本机模型的有限候选排名与父局面试走，评分/准确率需保留算法来源和未知边界。

E14候选研究已落盘：当前IAB tab4访客、自制线路兵七进一/卒３进１/炮八平五，已单步分析，设置0秒/深度4/节点0/最多2；截图/AX见REFERENCE_EVIDENCE E14。源站视图左右镜像，不能直接用像素坐标猜UCI！结果两红方候选兵七进一65%与炮二平五56%，确认在当前红着父局面。源站已有分支不因max2丢失；筛选/预算仍U。下一条实施方案详细写入planning/CANDIDATE_SLICE.md（P），先单步计算+原子父局面试走，再整谱彻底。当前没有未提交业务实现，只有E14研究与计划待本次docs提交。

## M3-12进行中（未提交，不算通过）

候选业务代码已写入工作树：candidate_models/engine_candidates、CandidatePanel/Options、BoardSession.playVariation原子同级试走；EngineSessionController.batch互斥/停止失败代次与迟到factory失败清理；ReviewCacheAccess抽取整谱/候选共用IO逻辑。12项候选应用测试（含实际NNUE）和3组件测试通过，早期refactor目标回归跳过1个未设环境的live测试，不算真实通过。全量测试/静态检查会话31022、原生整套88115正在跑，日志/tmp/chessnext-candidates-{test,analyze,native}.log。不得在结果返回前commit功能。

下一条立即检查这两个会话/日志，修复失败。预期根134，原生14（只是预计，不是结果）；原生新增父局面黑方候选→同级试走→旧分支保留→同预算2候选缓存复用。代码需最终审核stop错误不试走、run快照过期及UI大字号。通过后补ADR-013/CURRENT_STATE/TRACEABILITY/SESSION_LOG，中文feat(review)独立commit，清除此WIP段。再整谱彻底候选/胜率分级/错题等继续，不能结束任务。
