# ADR-020：后台文字解析与文档快照交换

2026-11-02，F07/F12/B19，当前实现；验收见TRACEABILITY。前置有限PGN codec与文档资料已通过。

RecordTextExchange是无Flutter/IO/引擎的应用格式协调器，ImportedRecord同时带tree/metadata/source。默认静态Isolate.run仅捕获输入String，返回纯领域DTO或错误字符串；主线程恢复FormatException，避免假定异步错误跨线程类型。真实VM传输已经验证，未承诺毫秒性能或其它平台已跑。中间Unicode BOM资料保留，只有起始BOM处理。

ImportTextDialog通过TextImporter函数可替换解析服务；解析中冻结输入和重复提交，可取消；clipboard读取期间仍可编辑并防晚到覆盖。PopScope/代次/route当前性在路由尚未dispose的退场动画中也拦迟到结果，不能仅靠mounted。已取消worker允许完成但丢弃，不声称强制杀线程。App在解析/替换确认/先保存后分别核验文档及内容/位置修订，原子提交资料与树；未确认不改旧文档。

导出明确捕获开窗时tree+metadata。五种格式，非PGN不含资料/评注，PGN可含所选路径评注但不导出其它分支和未来；完整文档用本地保存。格式选择和评注控制在复制中冻结，复制值固定，花括号评注等无法无损表达的错误显示且禁复制，由用户明确省略评注。PGN派生Game/FEN/Format依据实际根/格式生成，Result仍是记录声明，不裁决。

本片只文字/剪贴板交换，不冒称系统文件选择/拖放/批量/所有PGN方言支持。原生新用例用注入剪贴板端口，真实worker/文件保存/新实例恢复；不把它当系统剪贴板人工验收。文件服务属于下一独立接口和平台验证。
