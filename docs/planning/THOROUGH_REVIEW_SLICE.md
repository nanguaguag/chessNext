# 下一切片：整谱多候选（P）

2026-11-02，F32/B18，基于已验收单步父局面候选和FiniteSearchExecutor。源站E12–E14实际模式/数量/单步已验证，可接受筛选公式仍U；UI应描述有限多候选计算，不冒充源站同阈值或无限算力精确排名。

1. 抽CandidateCollector纯应用服务，接FiniteSearchExecutor、目标Position、requestBuilder（分配共享generation token）、maximum、isCurrent及进度回调。逐次排除合法首着，返回不可变候选列表/命中搜索数/无更多候选原因；控制器仍唯一EngineGateway所有者，不调用startCandidates嵌入startReview。最大1可代表最佳模式，2..256多候选。每次请求预算明确为每候选。
2. ReviewMode=best/candidates；ReviewRun新增mode/maxCandidates、currentCandidate/当前上限、Map<nodeId,ReviewedCandidates>，后者不可变entries+complete标记。CandidateEvaluation移入共用纯模型，避免review_models与candidate_models循环依赖。已有results仍只计完成局面/图形主分；取消期间完成的单次候选保留为partial，不计完整局面、不伪造完成。
3. 默认当前线路/整树、完整根历史、同文档epoch、资源复用不变。每局面收集最多N候选；主评分只用第一个完整最佳请求的info，无分则保持无分，不拿之后较差候选分数当最佳。终局保留terminal无引擎评分。计算/失败/取消/过期语义与旧队列一致。
4. cachedCount继续表示完全复用的局面数，增加cachedSearchCount以区别多候选命中搜索次数，UI不得把8次候选查询写成8个局面。没有整组集合缓存：每单次query的历史/身份/精确预算/允许集独立入键，首候选可与最佳模式复用；max变化不能把部分候选组当完整跳过。collection模式版本可独立记录，不改变已有正确子查询含义。
5. 整谱配置增加方式与最多候选，最佳模式隐藏数量，显示预算按每候选计。结果行增加有界候选详情对话框（raw cp/mate/bound/中文/坐标），partial明确标记；第一步只读详情，不能暗中自动写棋树。单步试走已独立存在；整谱结果直接试走如新增要再做snapshot/stop保护，不可复用错误父节点。
6. 进度区分局面与当前候选。FiniteSearchExecutor.onInfo可经控制器统一100ms合并batchInfo（token+job有效才显示），不再维护两套最终评分捕获；切搜索/取消/销毁清计时器。活动分析原有info合并不变。

验收：line/tree各节点唯一、2候选首着不同且属于目标、第一评分正确、cached局面/搜索计数、模式/预算/max改变命中条件、partial取消保留与0候选/无分、AI/分析抢占及旧epoch、纯读谱不改目标、配置非法与200%字号、详情虚拟列表；真实NNUE分支多局面和macOS配置/取消/缓存。根flutter test+analyze后独立中文feat(review)提交。需要改前验证FiniteSearchExecutor前置当前提交是否已通过，不将本P标实现。

M3-14续：上述有限多候选/partial/双计数/详情已按ADR-014实施验收，具体测试及平台见TRACEABILITY；不把可接受筛选公式未知或所有F32子功能标为完成。
