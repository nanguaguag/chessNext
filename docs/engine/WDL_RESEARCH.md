# Pikafish原生胜和负估计（2026-11-02）

固定2026-09-06：[官方UCI输出实现](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/uci.cpp)声明UCI_ShowWDL控制三项输出；原始胜/和/负为千分数且和为1000。此为引擎自身模型结果，不由App对cp临时套一个未校准公式，也不证明与参考网站百分比/准确率公式相同。

V：`python3 tools/probe_wdl.py`先按pikafish.lock校验官方原始二进制/NNUE，再握手启用check选项，分别初始及h2e2后搜索depth4。收到8行WDL、每行三整数0..1000且总和1000，合法bestmove并quit退出0；[原始协议](validation/wdl-protocol-2026-11-02.txt)含制品身份。它只验证原生CLI能力，目前App尚未解析/启用/缓存WDL。

末次黑方轮到时cp -36、原始WDL 8/896/96仅单次样本。后续展示切到红视角需交换胜负、保持和；胜率与含和棋半分的预期得分必须区分，不能将有利局面的和棋概率算成获胜概率。无WDL、mate和bound要分别处理，不能以0填补。模型是否符合用户群实际胜率尚未校准。

建议下一增量：WdlEstimate严格三项/总量校验→EngineInfo可空wdl/解析→EngineRequest偏好输出标志（缺能力仍可普通分析）→UciEngine只在check选项可用时变更、ready屏障/同值不重设→缓存保留WDL并将实际请求偏好与选项纳入键，旧CP-only不伪造WDL→Material3原始胜和负展示与红黑视角。然后再做复盘损失/等级，算法版本清晰且不宣称网站同准确率公式。

初版临时Python probe用TextIO缓冲配select，等待uciok超时；这是探针读取策略问题，已改二进制buffer/os.read保留余行，最终0.2秒内正常结束，不当作引擎故障或性能基准。工具协议超时15秒、清理自有子进程，不改上游引擎。
