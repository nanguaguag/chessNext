# M3-19 / F27 / B08,B20：全局字号与本机记忆（P）

2026-11-02，参考E21。独立实时字号对话框从应用设置进入；跟随系统及标准100/大115/特大130。手动滑块自动退出系统模式，开启系统再关闭回标准，与已验证网站行为一致。其它设置仍保留原有“应用设置”表单语义；保存旧表单不得覆盖后来即时生效的字号。

AppPreferences增加可选textSize枚举（system/standard/large/extraLarge），schema1旧文件无字段默认system，坏类型/枚举拒绝并沿既有备份。Controller逐字段迟到合并、串行写/错误可重试，更新字号不改引擎资源/搜索/AI，也不改棋谱资料/dirty。只读取坏文件时不自动覆盖。

MaterialApp.builder在Navigator外统一MediaQuery，系统模式原样传递原TextScaler对象（保留非线性），手动显式TextScaler.linear覆盖而非再乘系统比例。保留源系统scaler给字号预览/状态；窗口/OS字号变动即时响应。棋子FittedBox继续保持棋盘交点/命中尺寸，棋盘绘制文字不借字号设置改变几何。系统200%可正常滚动读谱/操作对话框，手动三档不叠加200%。参考系统非100行为未实测，上述非线性为项目P/官方API D。

验收：schema旧/新/坏字段、迟到加载合并/失败重试/最新写获胜、字体修改不重启引擎/不改谱；实际App路由/弹窗/重建与OS200、独立非线性scaler单测、窄窗/键盘滑块/Escape/语义；macOS真实偏好文件新App恢复；全量flutter test+flutter analyze后单功能中文commit。其它平台/真实OS系统设置切换仍待各平台验收。

官方API：[TextScaler](https://api.flutter.dev/flutter/painting/TextScaler-class.html)、[MaterialApp.builder](https://api.flutter.dev/flutter/material/MaterialApp/builder.html)。不使用弃用textScaleFactor推导系统非线性行为。
