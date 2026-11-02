# M3-20 / F21 / B15：棋盘路数坐标（P）

2026-11-02，E22只证站点坐标开关/页间记忆与数字显隐。全路数方向/编辑器/系统重启未在站点验证，不推断相同。

项目设计：本机showCoordinates布尔默认true，schema1可选字段/严格类型，迟到读取逐字段合并与串行持久化/错误重试；不写棋谱、不重启引擎。从独立即时“棋盘显示”对话框开关，普通设置表单保留最新值。

表现层BoardDisplayScope在Navigator外注入只读显示数据，主棋盘和局面编辑BoardSurface共用，无UI数据库或IO。BoardFileCoordinates独立上下路数边框：黑方Arabic1至9，红方中文九至一，按逻辑file、flipped/mirrored映射；标签只读语义，不遮90个交点。坐标框与内部棋盘保持9:10整体比例，开关可改变内部格距但不改变Square逻辑；标注FittedBox适配小窗口/200%字号。独立BoardSurface无scope默认不显示，宿主可显式override。

验收：旧/坏偏好、晚到合并/最新写和读写失败、运行分析请求数/文档不变；正常/翻转/镜像/组合方向、坐标/交点对应、无拦截落子/键盘和编辑拖放、两个路由共用/本机恢复、200%窄窗/语义。根flutter test+flutter analyze及相关macOS原生通过后单功能中文commit。其它平台人工视觉仍待验。未包括棋子尺寸/素材/落子光圈等其它F21功能。
