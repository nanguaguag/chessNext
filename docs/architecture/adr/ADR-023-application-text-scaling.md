# ADR-023：独立字号偏好与全路由TextScaler

2026-11-02，状态：当前Flutter/macOS切片接受，实际其它平台OS字号变化待验。

AppPreferences可选textSize枚举system/standard/large/extraLarge，旧schema1缺字段默认system，非法值沿备份/坏读保护；不用两个字段组成矛盾状态。系统→关回standard，手选自动成为manual，符合E21当前100%系统下实测，网站其它系统比例规则仍未知。

MaterialApp.builder中AppTextScaling在Navigator外统一MediaQuery；系统模式保留原始TextScaler对象，避免把非线性变成单一系数。手动1/1.15/1.3显式覆盖系统，不能叠乘。独立InheritedWidget保留源系统scaler供预览，不影响窗口几何/棋盘命中；棋子原FittedBox处理缩放空间。

字号独立对话框实时应用，普通参数表单仍确认后应用且copyWith保留最新字号。PreferencesController继续逐字段迟到合并、串行最新写、写失败当前仍生效；retryPersistence对未读坏文件重新读取，对明确未持久化选择重新保存，不因打开面板就覆盖坏文件。大小变更不重配相同引擎参数/重启搜索/改棋谱dirty。

只覆盖F27字号部分，不包含语言、字体资源或工作区布局。系统200%/模拟非线性与OS变化为组件验证，原生新App文件恢复验证不扩大为真实OS系统设置操作。
