# ADR-015 原生WDL、能力降级与概率语义

2026-11-02，F02/F26/F32、B14/B18。采用官方2026-09-06原生UCI_ShowWDL，不在App内由cp随意映射概率。协议证据见engine/WDL_RESEARCH及validation/wdl-protocol-2026-11-02.txt。

WdlEstimate为纯端口不可变值，wins/draws/losses为0..1000整数且总和1000；交换视角只对调胜负。expectedScore=(wins+draws/2)/1000，不把和棋半分称为获胜概率。EngineInfo.wdl可空，坏的可选WDL不丢弃有效CP，缺失不补0；CP整数超界解析失败也不向上抛出整行异常。

EngineRequest.preferWdl默认false为向后兼容，App各类搜索优先请求true。UciEngine只对握手check能力发选项，缺能力仍正常分析；初始默认状态及已应用值分开记录，仅变化才发true/false，ready屏障确认后记状态，不清同文档TT。未确认不得go，失败走既有生命周期。该偏好不是承诺不支持的引擎也会产生WDL。

缓存payload可选wdl数组、旧CP-only仍可读；preferWdl=true新增独立native-v1子键，false保持旧CP命名空间。若引擎声明check能力，缺请求WDL的条目不算完整命中、移除并重算，缺统计的新结果不写为完整WDL缓存。无该能力引擎可缓存CP，不伪造统计。完整性/允许集/PV与原有失败保护继续执行。

分析面板按红/黑视角显示模型的胜/和/负与单独预期得分。bound和mate保留原评分语义，不附普通概率文本；原始WDL仍在数据层保留。标签说明这是引擎模型，不宣称对应网站准确率公式或已在用户群校准。复盘预期损失、等级、准确率/错题属于后续增量。

测试/真实NNUE/文件重开/原生展示与失败修正记录见TRACEABILITY、SESSION_LOG。没有修改引擎/NNUE或引入新App依赖。
