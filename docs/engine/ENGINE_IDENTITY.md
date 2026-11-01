# 引擎身份与制品校验（2026-11-02）

关联F24/F25/F32、B14/B18。EngineIdentity是端口值对象，包含发行名、完整上游commit、上游原始可执行文件SHA256、签名后实际文件SHA256、NNUE SHA256、运行目标。schema1严格验证类型、hash格式、长度/控制字符；cacheIdentity固定字段顺序，字段顺序不同的JSON不会产生不同身份。

macOS构建：tools/bundle_pikafish.py先按pikafish.lock.json验证.local输入，复制/开发签名helper后计算实际可执行文件hash，写Resources/pikafish/identity.json。原始源二进制与签名后文件不能直接用同一个hash比较；签名变化可保守地使未来缓存失效。manifest不含可控执行路径，适配器只打开约定文件名。

openBundledEngine先verifyEngineBundle，校验实际可执行文件和NNUE，附加Dart运行ABI，再创建进程。文件摘要在工作Isolate内流式计算，避免在Flutter UI isolate读取/计算50MB权重；只在打开引擎时进行，不在每个go重复。manifest上限16KiB，单制品200MiB；超限/缺失/损坏明确失败，不猜测身份。此处证明制品与本地构建清单一致，不声称拥有上游数字签名认证或消除本地文件同时被修改的所有情况。

EngineGateway提供可空identity与name。UciEngine仅在握手starting阶段接受有界无控制字符的id name，晚到搜索行不能替换名称。任意外部CLI UciEngine默认没有已验证身份，仍可分析；未来持久复盘缓存必须要求identity，不以显示名推断引擎/NNUE版本。UI只显示真实握手名称，技术hash不进入主要下棋操作。

本切片未实现缓存。未来key仍必须包含规范根FEN、完整历史、规则profile、预算/线程/Hash/候选模式与算法版本；身份只是组成部分，不能只看末局面FEN、name或release复用结果。

SHA256使用[官方Dart crypto 3.0.8](https://pub.dev/packages/crypto)，2026-11-02查证。原为锁定传递依赖，此次升级为显式直接依赖，版本未变；包归档校验见pubspec.lock。许可原文及登记见legal/LICENSING.md。没有改Pikafish源码或NNUE。

后续M3-10已用此身份实现会话内存缓存，见ADR-012；身份切片自身不等同整谱缓存全量功能。
