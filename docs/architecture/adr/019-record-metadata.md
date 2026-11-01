# ADR-019：资料与棋树分离、可选文档字段和草稿一致性

2026-11-02，F10/F12，当前实现，验收见TRACEABILITY。PgnRecord格式层保留标签，App要有明确文档承载才能接入。

选择纯Dart GameMetadata不可变有界标签对象，作为BoardSession文档内容与GameTree并列；tree负责位置、线路、注释，metadata负责棋谱资料和声明结果，均不拥有存储/Flutter。PGN解析器解释FEN/Format等，应用会话不调用文件格式解析器校验一般资料。未知标签有界保留。

SavedGame/FileGameRepository schema1可选metadata字段，旧文件默认empty；自动草稿同一资料模型，观测key加入metadata，不因资料编辑没有位置变化漏存。根/资料替换一次notify，内容修订和位置修订分开。修改资料不重新开引擎；读取坏字段保留主文件并走已有备份。

资料编辑界面使用快照epoch+revision，实际修改才提交；结果是记录声明，不等于规则终局。新局/新根不继承旧标签，普通走棋/分支/注释保留资料。当前单窗口本机设计，不宣称跨设备冲突合并或旧版本降级再保存无损。具体门槛见RECORD_METADATA_SLICE与TRACEABILITY。

实现边界补充：分析/AI由positionRevision驱动，单独资料修改不重启；整谱/单步候选仍遵循既有内容revision快照策略过期。清空最后资料仍dirty，覆盖保护不能依赖hasContent；有名称的空草稿保留恢复入口。其它平台/跨进程/旧版本降级不属于本片已验。
