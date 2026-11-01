# 搜索会话资源复用

2026-11-02；F02/F03/F32、B14/B18。当前为macOS Process实现，其他平台另验。

EngineRequest.gameId表示文档epoch，与每次搜索token分离。UciEngine以(gameId,规范根FEN)识别新文档；首次/新文档发ucinewgame，位置导航和同文档变招保留引擎TT。所有请求仍发送完整根+历史，不用仅FEN替代历史。

首次应用Threads/Hash/MultiPV，后续只发送改变的值；资源或文档改变后等readyok才开始go。每次搜索切换仍等待旧bestmove屏障，失败/重新建引擎不继承已应用缓存。资源变更自身可能清TT，是上游行为，不承诺改变Hash后保持缓存。上游依据见REFERENCE_EVIDENCE的2026-11-02批量搜索核查，未修改上游。

## 实测微基准（V）

运行 `dart run tools/benchmark_engine_reuse.dart docs/engine/benchmarks/reuse-2026-11-02.json`，工具先校验官方二进制/NNUE哈希。原始数据[JSON](benchmarks/reuse-2026-11-02.json)，UTC时间2026-11-01 18:05（Asia/Shanghai为11-02）。测于本功能工作树，源码/数据以所属Git提交追溯。

macOS14.4 arm64、10逻辑处理器、1线程/64MB/MultiPV1/深度10，每组独立进程、1次预热、10次交替重复初始与两步后局面。冷对照强制每次重设三项资源并清缓存，暖组同文档保留资源/TT；耗时含适配器验证/设置/搜索。

| 测量组 | 中位墙钟毫秒 | 10次setoption数 | ucinewgame数 |
|---|---:|---:|---:|
| 强制重设冷对照 | 41.021 | 30 | 10 |
| 同文档复用 | 0.920 | 0 | 0 |

这是重复相关局面/暖缓存的局部收益，不代表任意新局面提速比例、棋力、热降频、RSS或相对裸引擎≤5%开销验收。冷对照也不是逐字节复现旧GUI全部时序；保留原始样本供重跑。

## 验证

根flutter test72/72（含官方NNUE与组合限额/5轮停止）、flutter analyze通过。Fake验证同文档不重设、仅发送改变值、epoch/根FEN变化清表、参数变更等待readyok；应用分析/AI均传session.epoch。macOS原生9/9通过（交互受控生命周期前提），真实多PV/AI变招/悔棋/组合节点预算仍正确。
