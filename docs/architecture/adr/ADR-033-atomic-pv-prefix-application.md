# ADR-033：所选PV前缀经停止屏障后原子提交

2026-11-02，E31证实所选前缀/保留原变化/已有可见线路不复制/回主棋盘。项目显式暂停所有计算后应用；网站活动AI/分析时行为未知，不冒充同取消策略。

EngineSessionController.createPvPrefixAction在预览打开时捕获新鲜tree对象/epoch/内容和位置revision，检查entry的源epoch/nodeId/FEN匹配。历史entry旧revision本身不作为永久失效条件：同源重开时可以使用当前新增后续或评注的新快照；但打开后内容/游标/换谱任一变化必须重新打开。旋转/显示不影响命令。

PvPrefixAction/PvApplyCancellation及枚举失败模型与UI分离。动作先校验范围/取消/并发，再复用disable及现有stop屏障，保存generation并核停止失败/源；PvPrefixPlan工作Isolate仅捕获纯GameTree/复制前缀，有界128步/既有schema2000节点，保留原节点/分支顺序/评注并复用已有节点。纯planner可注入验证等待阶段。返回后再核cancel/source/generation，不直接执行原始info或做部分提交。

BoardSession.commitContinuation只发布当前确切源树的完整准备结果，校验root/祖先/容量，epoch与metadata/库绑定保持；新增节点内容revision+1，只有游标变化位置revision+1，已有节点导航不改内容dirty。一次notify，草稿/阅读监听看不到中间谱。

预览动作用source Listenable即时禁用过期，0/准备中/忙态禁用，暂停播放，关闭取消尚未提交；已同步原子提交后取消不撤销。typed PvPreviewExit让原历史route在仍mounted/current时关闭，迟到不关新route。错误不透出内部路径，失败留预览。源Action/Widget/Controller不进入worker闭包。

跨位置保留历史下一片修ADR-031策略；本片旧entry可通过重开验证正确源节点。K09：旧手工走棋/其它新增入口尚未统一2000容量策略，不能声称本片解决全部文档容量。其它平台及真实OS验证仍待。
