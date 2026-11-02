# ADR-034：同谱跨位置历史与当前结果分离

2026-11-02，E31确认原站前缀应用及读谱回退仍保留旧卡。本ADR修订ADR-031的“位置变化清历史”，不改写先前已实施和验证记录。原站AX1368 items不是已确认卡数/容量，跨文档策略未知。

Controller独立_historyEpoch管文档边界，保持原_lastSessionEpoch AI逻辑。位置变仅清latest infos/pending/箭头和局势条的数据，历史在同一epoch跨位置保留，共享64条×128步；新局/导入/打开文档epoch变清历史，显式清空也仅展示。有效token与positionRevision仍在采样前校验，旧事件不得被重新标成当前来源。

PvHistoryEntry保存sourcePly与中文sourceMoveLabel；Controller在位置变时计算一次，flush复用。Position/epoch/node/revisions/原始score/WDL各自冻结，历史显示/预览归一用源Position，根显示起始局面。旧来源可只读预览；M3-29提交仍须相同源节点/epoch/FEN并在重新打开时捕获新快照，删除来源或换谱不能误提交。历史非持久缓存，不写用户棋谱或资料。

本谱历史标题/说明/清空语义相应调整。200%来源提示下旧弹性布局实测棋盘仅81.6px高，现窄窗/短窗/大字号预览整体滚动，棋盘固定300px区域与200px独立虚拟步表，宽高足够分栏；错误提示自动滚入视区。数值为项目P，目标可辨认棋盘至少240px，0/键盘/播放/退出逻辑沿既有契约。

尚不推断原站跨文档、hover与内部来源绑定/容量；其它平台与真实OS行为待验。K09统一容量继续另片，不能关闭整个B22或全部对标。
