# M2-14 / F01,F13 / B05,B16：前后分支点导航（P）

2026-11-02，E19已V单中段分支严格前后跳/无其它点到首尾/保留所选变着；嵌套和根多分支站点未验。项目按如下确定行为做增量，保留绝对首尾作为独立入口，不改变旧按钮含义。

分支点=节点有多个子节点。上一目标严格排除当前，沿祖先找最近分支，找不到到root；当前root无上一。下一目标严格排除当前，只沿GameTree.currentLine找最近分支，找不到到所选线路末尾；已在末尾无下一。不同分支上的分叉不截断当前线路。根自身分叉不阻止向后前进；从当前分支点再次前进跳过自己。

纯应用ReadingNavigation从不可变tree算目标；BoardSession按树对象缓存，避免每次engine info/选子重扫长谱。UI增加上一分支点或开始/下一分支点或末尾两按钮，Tooltip/禁用/Tab可用、窄屏Wrap，统一EngineSessionController.navigateToNode暂停AI/阻止旧bestmove，不直接调用领域树或引擎。导航保持内容revision/dirty/注释/子节点与所选线路元数据，不启动搜索以外新角色。

验收：空树/单线/根fork/多层fork/支线不含其它branchfork/严格排除当前/删除和提升后目标/长线；组件往返/绝对首尾仍可用/AI思考中导航及迟到结果/200%字号；原生自制中段分支路径与E19同义。根全量flutter test+analyze，macOS相关原生项通过后独立feat(records)中文commit。领域规则未改不重复核心perft；不把本片称规则/五平台全完成。
