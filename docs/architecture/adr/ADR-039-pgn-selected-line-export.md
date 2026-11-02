# ADR-039：PGN默认完整所选线路，可显式导出当前路径

2026-11-02，E33修正原E20末端样本范围推断。源站在三着阅读点导出PGN包含五着所选线路（两未来）；镜像前后相同。项目此前只有根到当前路径，现对PGN默认includeFuture=true，保留显式false兼容根到当前；其它FEN/普通文字范围不改，不称全树RAV。

RecordTextExchange只把不可变源tree.currentLine最后节点的goTo视图传给原PgnCodec.path，不修改core编码器/源游标/anchor/文档；当前线选了非主线后仍导出它的未来，不借用另一主线兄弟。GameMetadata保持原结果及未知标签，FEN/Format仍按该根与目标格式派生，ICCS和中文同一范围逻辑。

ExportTextDialog保留打开时tree/metadata快照，增加默认开的“包含所选线路的后续着法”，忙态禁用/切换清旧状态。复制与文件读取同rendering，不因背后会话导航/改谱导出别的棋谱。可显式省略评注；默认包含未来若遇不可表示评注则可见失败且禁用copy/save，由用户选择范围或省略，不静默删除内容。

E33自制PGN作为语义fixture；应用覆盖根/中间/非主线anchor/末端、范围/评注/资料/不改源，组件覆盖200%/复制文件一致/打开快照/错误恢复，native用实际Foundation原子文件写入并解析两个范围。系统保存面板仍chooser注入、Clipboard仍测试端口，不据此宣称人工面板或OS剪贴板验证通过。
