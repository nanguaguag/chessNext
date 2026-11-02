# ADR-029：最后一步标记为独立只读呈现

2026-11-02；E28证实光圈/方框终点与源圆环，与未知F26评级标记分开。

XiangqiBoard从GameTree.current.move与(epoch,cursorId)传入LastMoveMarkers，BoardSurface/BoardDisplayScope只提供显示参数。根无move即无画层，编辑器不传lastMove；导航/换谱使用当前树，评注/旋转/搜索info不重启动画。绘制共用boardSquarePoint，叠于棋子上、IgnorePointer和独立最后一步语义；交点/棋子尺寸不变，双描边维持背景辨识，不复制参考资源。

LastMoveMarkerStyle halo/box是稳定偏好值；可选旧默认halo，严格解析、Controller逐字段晚到合并、串行持久化与retry，普通设置copyWith保留。即改即存，不改棋谱修订或引擎预算。

600ms单周旋转后静止是项目P，非原站时序声明。初始恢复静止，已挂载棋盘收到新move/身份（含首次落子）或改光圈时旋转；方向变化不重启。系统disableAnimations会中断为静态，释放页面dispose ticker；无重复持续帧，也不因测试环境改变生产行为。F28全局动效偏好后续独立扩展。

其它F21选子/素材和F26评级标记仍后续；真正OS减少动画设置/人工视觉及其它四平台未验。
