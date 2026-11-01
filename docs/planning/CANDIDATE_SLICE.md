# F13/F32下一增量：父局面候选与试走（P）

2026-11-02，B18。证据E13/E14。单步入口已验证在当前着法的父局面计算建议；试走在父局面添加/切换同级分支，非当前盘面追加。根节点候选针对根自身。可接受筛选/预算算法仍未知，先交付明确说明的有限候选计算，不宣称复制源站公式；整体F32保持部分完成。

实现切片：共享单引擎的单局面候选计算+列表+父局面原子试走；整树彻底候选随后再单独增量。每候选使用有限depth/time/nodes，默认最多5、范围2..256是项目策略（源站最小2已见，最大未知）。逐次排除已发现合法首着来取得不同候选，每次单PV预算；UI明确“每候选”用时和预算影响，不称确定排序/所有可接受。不可一开始就生成整树新框架。

建议纯DTO CandidateRun捕获epoch/内容revision/positionRevision、不可变tree、原选中节点/parent节点、limits/max、结果列表/进度/缓存数/notice和running/stopping/cancelled/completed/failed/stale。CandidateEvaluation存move及可空EngineInfo，保持cp/mate/bound/无评分差异。结果不自动写GameTree。导航或文档编辑使单步结果过期（与纯读谱仍继续的整谱队列区别）；UI标父局面和原着法，禁止错误试走。

EngineSessionController增加engine_candidates.dart part与独立job/token/info字段，仍唯一EngineGateway。统一batching=reviewing或候选计算；enable/AI/configure/startReview/disable/后台等均正确抢占。disable两个任务都同步失效、stopping等待stop屏障、迟到info/bestmove丢弃；失败保留已有候选并明确failed。_changed先检测候选快照，_onInfo先路由候选token，不能落入活动分析。监听重入在_notify后检查job有效。

每次请求targetTree=tree.goTo(parent)，完整历史和同文档gameId。第一个候选searchMoves=null，后续为剩余合法首着；bestmove必须合法且属于允许集、不得重复。无bestmove/无info/最终PV首着不匹配不得伪造0分或错误评分；无info但有合法bestmove可以列无评分候选并继续排除，重复/非法引擎结果要失败停止。实际引擎历史终局与领域无历史裁决不一致时明确无可评估结果，不能猜胜负。

缓存复用现ReviewCacheRepository，第一候选同预算最佳着法可复用，后续searchMoves入键，不混同不同允许集。可抽出纯应用ReviewCacheAccess，统一key/完整PV校验/2秒超时/失败本任务停用/notice/完成无bound保存，复用整谱与候选而不复制两套30行IO逻辑。取消检查包围所有异步缓存读写。

原子试走：BoardSession新增playVariation(parentId,move)，先由不可变tree.goTo(parent).play生成结果，再一次替换/refresh/notify；不能先navigate再play导致AI在中间局面重启。已有节点复用不增加内容dirty，新节点才增加revision；当前着本身为无操作。协调器绑定run epoch/revision/positionRevision/父节点/候选move，disable等待后再次验证generation与快照，再原子提交；否则返回失败不改树。试走暂停AI/候选，保留旧分支/注释，不自动置顶。UI当前着禁用、已存其他候选为切换、新候选为试走。

验收：核心/会话原子新分支与已有分支/no-op；候选首着唯一/完整父历史/有限预算/无评分/非法和重复bestmove；取消/抢占/文档与导航变化/监听重入/缓存迟到；试走父子执方不同仍正确、停止期间新操作保护。组件配置NaN/全0/候选数、200%字号、列表/状态/试走。真实NNUE两种执方/至少2个不同合法候选，macOS包内引擎单步→试走入同级→旧分支保留。每增量flutter test/analyze后中文commit。胜率/准确率/彻底整谱仍后续，不以入口完成全量。
