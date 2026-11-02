# M3-28 / F02,F13 / B08,B17,B22：只读PV小棋盘与播放（P）

E30验证预览1/N、逐步/点着跳转/播放暂停、0边界及Escape不改谱。接现有历史列表“预览”，捕获entry/方色，初始第1步；应用到棋盘/hover另片，不提供假提交按钮。

纯PvPreview在Isolate准备最多128步：每步合法重放/中文记谱/不可变Position序列，非法任一步整体失败不显示不完整假线；原长PV截断说明沿history。worker只捕获纯entry，返回DTO或有界中文错误。UI注入loader，loading/error/retry/close，generation+route防关闭/重试迟到，worker不直接操作Widget或会话。

独立readonly BoardSurface，不带主棋树/选择/引擎，排除交互与冗余棋盘语义，单组语义说明当前预览着/执方。方向在打开时捕获；按宽度棋盘/列表分栏或上下，列表有界虚拟化/字号行高/跟随当前着。0原局面、上一/下一/首尾、方向键、点着；800ms逐步播放、暂停、到末尾自动停止，再播放从0起，手动跳步/退场/失活停计时。系统减少动画沿棋盘既有能力，不禁用户明确启动的逐步播放。具体频率/布局均项目P。

验收：实际worker合法/非法/不可变/边界与源black记谱；组件加载取消退场/错误重试/快照不改谱或token/逐步播放时钟与末尾/键盘/200%/生命周期暂停/卸载无timer/虚拟列表；根真实NNUEflutter test+analyze，macOS真实worker/NNUE同token/快照及播放后独立中文commit。其它平台/OS人工行为未验。
