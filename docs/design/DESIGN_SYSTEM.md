# Material Design 3 设计规范（提案）

使用 ColorScheme、语义 typography、Material 3 导航/按钮/菜单/滑块/对话框；[Flutter Material 3 API](https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html) 当前默认启用 M3。棋盘为独立绘制与命中测试组件，提供 Semantics，不能仅画 Canvas 丢掉可访问性。

色彩用 primary/onPrimary、surface/onSurface、error 等角色；红黑棋子与正负分数保留文字标识，推荐箭头同时用形状/标签区分。自绘资源必须原创或许可明确；暗色模式保证棋盘与棋子可辨。

布局按可用宽度而非 OS 判断：<600dp 棋盘+底部 NavigationBar/分页面板，600–839dp NavigationRail，≥840dp 双/三栏分析工作区。断点为待验证初值。分隔条键盘可调、最小宽度防溢出，重置恢复默认。棋盘保持9×10交点比例，触点扩展到可操作区域；最小触控目标48dp。200%文字仍可滚动且不遮棋盘操作。

Android 支持系统返回/预测返回和边到边安全区；iOS 支持安全区、返回手势和系统分享/文件选择；macOS 使用 Cmd 快捷键和窗口菜单；Windows/Linux 使用 Ctrl、焦点导航和标准窗口行为。M3 保持统一，系统对话框由平台适配器提供。

键盘：方向键移动棋盘焦点，Enter/Space 选子/落子，Escape 取消选中/关闭浮层。快捷键通过 Shortcuts/Actions 注册，避开文字输入；撤销和新局不得悄悄删除未保存棋谱。读屏播报方色、棋子、坐标、选中、非法原因与轮到谁。

分析页提供 idle/loading/running/stopping/failed；云库有 loading/empty/offline/unauthorized；库有空草稿/加载/失败/迁移失败。尊重减少动画、系统字号、音量；后台停止高耗能搜索。视觉验收包含明暗、字体放大、横竖屏、鼠标/键盘/触屏和读屏。

M3-19已实现TextSizeDialog：标准100/大115/特大130和系统开关，实时生效/错误重试/本机记忆。AppTextScaling在所有Navigator路由统一MediaQuery，系统TextScaler原对象保留，手动线性覆盖而非叠乘。200%系统下窄窗滚动/语义/键盘滑块已组件验证，棋盘命中几何不因字号改变；其它平台真实OS行为待验。
