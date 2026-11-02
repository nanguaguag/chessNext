# ADR-035：当前着单节点评级与只读棋盘徽标

2026-11-02。E32确认复盘评级徽标和共享开关；关仅去棋盘徽标，数值、光圈、变着最佳星号保留。网站高级识别与概率公式仍未知；项目沿用ADR-016 native-wdl-loss-v1六类，无cp到概率的臆测，不复制参考资源。

ReviewReport.assess(run,nodeId)抽取原报告逐着规则，报告本身调用它，无阈值变化；Controller.currentMoveAssessment先校验epoch、内容revision、非stale，用不可变run身份+cursorId缓存单着结果，根/未知/未评级返回空。无全树报告随普通分析info重复分配，UI不读进程、存储或网络。

BoardSurface接受只读MoveAssessment，按lastMove.to显示独立IgnorePointer+ExcludeSemantics角徽层；语义附加到真实交点。沿共用boardSquarePoint映射翻转/镜像，尺寸固定为格距34%，中心位移(+28%,-28%)，不随棋子10–200%缩放；Material原创图标+文字图例不单靠颜色。无新增ticker，编辑器不传旧评级。

showMoveGrades为schema1可选bool默认true，PreferencesController提供晚到逐字段合并、串行写和失败重试；BoardDisplayScope只读。整谱面板与分析标记设置共享控制器与说明组件，关闭只画层，预期损失数字仍显示，不改引擎或棋谱。图例滚动适配200%并明确预期得分百分点、缺失/上下界/杀棋不画普通评级。

E32待办误称本机v1在2%端点不同；复核原始code已<40 half-per-mille，即<2%，勘误而不改模型版本。5/10/20源站等号文字歧义仍U。妙手/绝佳/错失/更快杀法仍B18，不因本片称F26或全部对标完成。
