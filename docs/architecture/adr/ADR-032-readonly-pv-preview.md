# ADR-032：PV预览先有界验证，再只读播放

2026-11-02，E30验证1/N、步进/点着/播放暂停、0禁上一与提交、Escape保留主谱。此片实现只读预览，走到棋盘上及hover另片，不提供未接通提交按钮。

PvPreview.prepareInWorker只捕获纯PvHistoryEntry，在Isolate合法重放至多128步，生成不可变Position与中文记谱列表；任一非法整体拒绝，不以合法前缀伪装完整PV。原长PV截断明确，只校验已保留前128步。工作结果为纯DTO或有界中文错误，不携带Widget/Controller/原生句柄；UI注入loader并按generation/mounted/route丢弃取消迟到，关闭不假装强杀Isolate。

PvHistoryDialog提供每条预览入口；PvPreviewDialog捕获来源/方向，始于1，独立BoardSurface只读且不传主棋树/推荐或选择，排除多余焦点/90格语义，单组说明当前预览着和执方。评分按源Position与打开方向，bound/mate0不伪造胜方。自适应分栏或上下、固定字号行高虚拟列表跟随当前着；键盘左右、首尾/0边界、点着跳转。

800ms逐步播放是项目P，到末尾自动停，再播放从0起；手动跳步/暂停/退场/失活取消Timer，route非当前也停止，dispose释放Timer/ScrollController。用户主动播放在减少动画下仍可逐步，棋盘既有disableAnimations抑制光圈。帧更新仅预览视图，不变搜索token/会话文档/修订或保存状态。

源站具体播放时序/失活/布局/触控与hover仍U，不称逐交互完整复制。AI流、应用到棋盘前缀需另验原站并加入epoch/revision/位置和取消屏障保护；其它平台及真实OS手工验证待做。
