# M3-33 / F01,F03,F10,F13 → B16,B17,B19 / K09：统一文档容量

项目现schema1最多2000局面（含根），非参考站点上限证据。之前仅反序列化/PV应用保护，手工/AI/候选新增可突破上限，形成不能恢复的文档。以GameTree.maxNodes为唯一数量真值，纯Dart GameTree.play已有子着复用优先，新增合法着才检查容量并抛类型化异常，不发布新树；解析限额同源。无上限测试后门。

BoardSession捕获容量并给MoveRejection.capacity与可恢复notice，保持树/元资料/epoch/两revision/dirty/选子不变，仅一次通知；手工、候选同级与fromEngine共用。满容量可导航/复用已有/注释/保存导出；删除释放空间后可新增，ID不复用。PV worker捕获同异常映射已有capacity结果，整个前缀原子拒绝。

AI收到合法但不能新增的bestmove时暂停所有自动执方、解锁/取消排程、保留原引擎可再分析，不进入引擎失败/销毁，不自动删谱或继续搜。候选提供typed apply结果，兼容旧bool包装；UI明确容量原因而不误称源变化/停止失败。一般非法/stop失败仍各自保护，不把容量变成伪成功。

验收：真实2000节点纯规则生成的浅树、1999→2000→拒绝2001、旧树不变/JSON往返/既有边复用、删枝释放且ID递增；应用点选/同级/fromEngine/取消与dirty/一次通知，AI拒绝后无续搜且原实例可分析，候选typed失败/旧分支仍可用，PV既有原子边界回归；200%可读提示/棋盘操作及保存重开。core dart test+analyze，根真实NNUE flutter test+analyze，macOS真实2000节点文件保存/新App恢复/NNUE容量后可分析。其它平台/网站容量未知保留。
