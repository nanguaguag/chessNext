# M3-35 / F12 → B11,B19：PGN所选线路与未来着

E33在阅读停三着时PGN实际包含所选线路五着，且镜像前后字节一致；原E20末端样本不能推广范围。项目PGN默认完整所选线路（含当前之后已存未来），非整树/RAV，不导出未选兄弟分支。普通FEN/文字依旧当前局面或根到当前，不混合未知格式范围。

RecordTextExchange.exportText增加includeFuture默认true，仅PGN采用不可变tree.currentLine末节点的goTo视图给PgnCodec.path；不改调用者游标、anchor、revision、metadata或dirty。显式false保留旧根到当前行为。ExportTextDialog增加“包含所选线路的后续着法”复选框，默认开/忙态禁用/清旧status，复制和保存都使用当前同一rendering文本；始终取打开时tree/metadata快照，不取底下后来导航或变更。

默认包含未来评注可能暴露不支持的PGN花括号评注，必须显示错误/禁用复制保存；用户可显式关闭未来或评注，不能静默丢失。其它metadata/结果/中文与ICCS/文件取消错误保护保留。

验收：根/中间/非主线anchor/末端/default与false、双格式评注资料、源不可变、E33样本语义；200%选项/错误恢复、复制=文件、开窗后源改不追随/dirty不清；native实际原子PGN文件完整线路与可选当前路径读回并解析。root真实NNUE全test/analyze，相关native后独立中文commit。core编码算法不改，不称RAV多局/其它二进制已支持。
