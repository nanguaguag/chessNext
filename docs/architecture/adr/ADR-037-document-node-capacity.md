# ADR-037：可恢复文档的统一节点预算

2026-11-02。K09发现仅反序列化/PV有2000节点上限，普通新增能造出无法重开的棋谱。容量是项目存储约束，非中国象棋规则或参考站点算法；继续使用schema1的2000（含根），不静默增大制品限制。

GameTree.maxNodes为同一真值；GameTree.play先复用已有子节点，其余先验证着法再在分配新节点前抛GameTreeCapacityException。异常是StateError子类，与非法着ArgumentError区分；纯Dart不依赖UI/IO。fromJson数量与单路径文字/PGN最大步数同源。无部分树、无文档自动截断或删谱。删除可释放空间且ID继续递增；满容量仍可导航、评注、保存与导出。

BoardSession的playMove（含fromEngine）与playVariation捕获并设置MoveRejection.capacity/notice，一次通知不改文档、metadata、revision/positionRevision/epoch/dirty或选子；正常操作清除旧拒绝。PV worker映射已有PvApplyResult.capacity，整个前缀原子失败不发布。

AI合法bestmove不能新增时清执方/排程和旧代次，解锁、提示自动对弈暂停；不调用引擎失败销毁路径，不循环重搜，用户可直接分析或删枝后主动恢复。CandidateApplyResult提供applied/stale/stopFailed/capacity，保留tryCandidate bool兼容包装；候选UI显示容量原因，完成结果仍可读与选已有分支。

使用真实2000节点浅合法树（保留一个未记录root合法着），避免NNUE重复裁决影响容量验证。纯模型/JSON往返/删枝ID、应用事务/AI保持实例、候选类型/200%UI保存恢复、PV原子边界各有验证；真实macOSFileGameRepository/NNUE单独验收。网站容量及其它平台未验证。

独立边界：仓库原有4MiB编码总大小门槛保持；大量长评注可能先达到该字节门槛，当前显式保存失败/保留已有文件，尚未在所有编辑入口提前预算字节。K10记录为代码审计待验，不以节点预算声称消除所有容量失败。
