# ADR-024：棋盘显示数据与独立路数边框

2026-11-02。当前Flutter/macOS坐标切片，站点全方向映射仍U。

AppPreferences.showCoordinates可选布尔默认true，Controller沿逐字段迟到合并/串行写/失败重试，字号/guide/引擎资源互不覆盖。棋盘显示对话框即时应用；不把显示选项写入棋谱，不因偏好改动重启搜索。

BoardDisplayScope只携只读呈现值，放在Navigator外，主棋盘/局面编辑器的BoardSurface共用。独立BoardSurface可显式override，无宿主scope默认不显示。它不持有Controller或读文件，领域无Flutter依赖。

BoardFileCoordinates在90格外增加上下路数边框。黑方1–9，红方九–一，由逻辑file以及flipped/mirrored统一映射，翻转交换显示上下方色，镜像只逆横向。边框/内部棋盘整体9:10，内部相同格距始终用于绘制和命中；开关可改变格距，不能用旧屏幕坐标定位。只读分组语义、标签缩放以适应空间，不遮格子/抢触点。此专用边框是项目P，站点E22只验证当前顶部数字2显隐，并不证明相同布局。

取舍：保留Square稳定逻辑与棋盘/编辑统一组件，不为坐标增加另一套落子路径；用户OS字号不改变棋盘规则或方向。棋子尺寸、选择/落子样式、素材及声音为后续独立功能。
