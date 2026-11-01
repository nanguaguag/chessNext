# ADR-013 父局面候选、共享引擎与原子试走

2026-11-02，F13/F32、B18，E13/E14。实现单步候选与试走；整谱彻底模式随后独立交付。

CandidateRun/EngineCandidates捕获不可变棋树、epoch/内容revision/positionRevision、所选节点及父节点。普通着法分析其父局面替代候选，起始节点分析自身下一着。与整谱队列不同，单步结果在读谱导航或任何文档编辑后过期，禁止将红方父局面的建议误加到当前黑方局面。

分析/AI/整谱/候选共享EngineSessionController唯一EngineGateway，batching整合两个后台任务。新任务先disable并等待stop，generation/job/token过滤迟到消息；停止中禁用按钮，失败保留已完成候选并可重试。候选试走若stop失败不提交；启动factory在旧任务取消后迟到失败，会清掉对应已拒绝opening Future，下一次可直接重试。

候选计算逐次排除已发现合法首着，每个候选有限depth/time/nodes单PV，UI明确每候选预算。默认最多5、策略2..256；这不是源站最大值声明。结果保留原始cp/mate/bound/无评分，不生成胜率。预算会影响发现顺序与分数，不保证是无限算力的精确强弱排序；**源站“可接受”筛选阈值仍未知，本功能不声称复刻该公式**。无bestmove明确原因，无info或最终PV首着不匹配仅列无评分合法着法；非法/重复bestmove停止失败，不伪造多个候选。

ReviewCacheAccess统一整谱/候选缓存访问、完整PV/允许集验证、2秒超时和失败降级；每个请求的searchMoves入键。第一个无约束候选可与相同历史/预算的最佳着法复用，其余允许集不同不混用。只有完成无bound评分写缓存；缓存事件不冒充活动引擎info。

BoardSession.playVariation先在不可变树上构造parent→move，再一次替换/refresh/通知，避免中间导航触发AI。新节点才加内容revision，已有分支直接选择不dirty，当前着为无操作；保留旧分支/注释，不自动提升主线。tryCandidate绑定run/epoch/revision/positionRevision，停止后再核验generation与停止失败代次；等待期间的新操作优先，旧试走失败不覆盖。UI区分当前着法/切换变着/试走，过期禁用。

UI在features/review/CandidatePanel和独立State配置对话框，支持NaN/全0/数量校验、取消、有界结果列表、200%字号和未保存棋谱保留。未把原始网站截图/资源用于产品。

验证命令、数量、失败修正及平台前提见TRACEABILITY/SESSION_LOG。真实OS窗口焦点/断电及其他平台仍待验，不把framework-resumed原生测试当人工视觉验收。

M3-13前置续：FiniteSearchExecutor抽取单次搜索契约，整谱和单步共享最终PV与bestmove匹配/合法性、缓存及临时监听清理；为后续整谱候选模式复用，不新增引擎进程。合法格式但PV不适用于目标局面的缓存经remove失效，避免重复读取毒化条目。
