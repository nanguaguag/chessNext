# ADR-026：推荐箭头组合与独立绘制层

2026-11-02。E24实际证实推荐开关同时控制本步/预计应着，“变着箭头”另有对象，不将后者误称预计应着独立开关。本片只组合开关和头部三样式。

showAnalysisArrows/arrowHead为可选偏好，旧true/standard；样式enum存储值在纯Dart board_appearance，不把绘图几何放入领域。Controller逐字段合并/串行写，设置即生效，不重配相同引擎资源、不改文档修订。

BoardDisplayScope注入只读显示值，BoardSurface分离静态网格和BoardArrowsPainter。组合关闭仅撤绘制/只读语义层，实际PV继续更新，开启取最新合法Move。IgnorePointer不截获格子，图层在棋子下；head sharp/standard/wide只变头部半宽（项目.07/.12/.19格），杆宽4与端点避让沿旧实现，flipped/mirrored与90格同一逻辑映射。棋子尺寸不影响箭头几何。静态网格的临时TextPainter及时dispose。

像素参数是P，未复制源站代码或声称相同像素算法。变着树箭头、着法标记/局势条和PV历史B22另片；该层可供后续共享样式，不能以设置入口替代功能成功验证。
