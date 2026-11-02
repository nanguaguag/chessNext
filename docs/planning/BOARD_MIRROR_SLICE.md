# M3-34 / F05,F02 → B05,B08,B22：主盘左右镜像

E33已V主盘镜像及与旋转组合、棋子/坐标/落子与评级标记方向、PGN内容不变、PV小盘跟随两方向。主盘镜像走棋/活动AI/换文档或重载仍U，项目对应行为需自身验证，不冒充参考边界。

BoardSession增加mirrored会话视图，与flipped独立可组合；不属于GameTree/metadata/dirty/revisions/epoch，不改变选子或分析token，不重建棋盘FocusNode，按钮遵循正常焦点导航。与既有flip一致，新局/替换谱保留会话方向，退出后不持久化（P）。主盘独立48dp左右翻转按钮和toggled语义/说明；XiangqiBoard向现有BoardSurface几何透传，坐标/箭头/末步/角徽与90格命中共用映射。编辑器镜像仍独立局面编辑，不让主盘状态污染编辑文档。

AnalysisPanel打开历史前capture mirrored，PvHistoryDialog与PvPreviewDialog只读透传到小盘；与已capture flipped一致，打开后主盘方向变化不改该快照，重新打开取新方向。PV源位置、评分与动作来源保护不变。

验收：视图两次可逆/四组合/选子/内容与引擎身份不变、新局与换谱方向P；200%及10/200%棋子、实际像素点交点命中/键盘左右、所有只读层方向、Editor无主盘旧状态。历史和实际worker预览捕获组合方向，主盘后改不追随，关闭不改谱。根官方NNUE全量test+analyze，macOS真实引擎下mirror不重搜与preview组合方向后单独中文commit。

E33顺带发现PGN所选线路含未来差距留B19下一片，不与镜像混合实现。
