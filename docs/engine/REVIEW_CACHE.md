# 本地复盘缓存（2026-11-02）

F32/B18，ADR-012。默认跳过已分析，关闭开关强制重新计算；仅精确条件匹配的完整评分可命中，不把无评分或bound冒充完整结果。

键由SHA256编码已验证引擎/NNUE/ABI、规范根FEN和完整历史、规则/算法版本、时间/深度/节点、Threads/Hash/单路PV和其他UCI默认配置。epoch/token、节点ID、游标/线路锚点/注释不参与。未知身份仍能计算但不缓存。详情见ENGINE_IDENTITY.md；不能因末局面相同或引擎名称相同就命中。

端口ReviewCacheRepository支持MemoryReviewCacheRepository（测试/预览默认2048条LRU）及FileReviewCacheRepository。正式main将文件适配器注入App/引擎协调器。目录为ApplicationSupport/chessnext-analysis-cache，与棋谱、草稿、偏好独立；缓存可重新生成，不清除或更改用户棋谱。

文件schema1，单条最多64KiB、最多2048条/32MiB（暂存写入时可额外占一条）；原始侧分cp/mate、深度、PV及采样统计通过严格类型/范围校验。wrapper包含payload SHA256，文件读取验证文件名key/schema，应用层复用前验证完整PV合法性；不跟随单条符号链接。PV上限256，评分/计数有策略上限，未来版本先升级schema。有效文件在新仓库实例/进程中可读取。

写入串行、同目录暂存flush+rename，失败不覆盖棋谱数据；不为可再生缓存生成棋谱式备份。损坏/未知schema缓存条目删除并上报，当前任务停用缓存后实际计算；下次可重新生成。启动清理本缓存目录内.pending-暂存目录。容量淘汰按本实例LRU；重开从文件写入时间恢复近似顺序，不承诺跨进程精确访问顺序。默认单窗口，不处理多个进程同时写同目录的全局事务；Windows/Linux原子替换语义尚未实测。

缓存单次IO有2秒应用层超时，失败后同一任务不继续反复访问坏缓存；底层IO可能稍后完成，但epoch/job屏障阻止迟到结果进入新会话。引擎计算结果仍可查看，dirty/显式保存不受缓存成败影响。强制重算产生不完整结果时保留此前完整缓存，取消只保留已完成节点。强杀/断电可能丢弃缓存末条，不承诺零丢失；残留暂存可清理并重算。

验证方法：

- `flutter test`包含文件重开、校验损坏/UTF8/超限/未来schema/错误key/partial字段/数字/PV、LRU/总量、序列写入失败、暂存清理和路径/符号链接测试。
- `dart run tools/probe_review_cache.dart write TEMP_DIRECTORY`再用独立进程执行`read`：仅协议fixture，不是引擎评分证据；采样见validation/cache-process-2026-11-02.jsonl，两进程PID不同。
- macOS集成用真实ApplicationSupport临时子目录、包内NNUE及全新App/Controller/Repository/Engine实例验证落盘命中，再破坏一条验证降级重算。此为新应用对象与新引擎进程，宿主Flutter测试进程不退出；不把它称作人工OS关闭重启或断电验收。

实际通过数量与命令、失败修复记录以TRACEABILITY/SESSION_LOG为准。缓存能力不代表彻底候选、胜率、准确率/分类和错题已实现。
