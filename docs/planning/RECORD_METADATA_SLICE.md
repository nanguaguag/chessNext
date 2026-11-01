# M4-01b / F10,F12 / B16,B19：棋谱资料与本地保留（P）

2026-11-02，PGN格式层已验收。此片提供赛事/棋手/结果等离线资料及存储基础，不冒充已确认的参考登录后表单；用于避免后续PGN导入静默丢标签。

纯Dart GameMetadata有界不可变标签：最多64、ASCII标签名1–64、值4096、无控制字符；Result可选四种声明、Game若有应为Chinese Chess。未知标签保留，FEN/Format属于格式层解释，此层只作有界数据承载，不把文件解析器塞到BoardSession。相等按内容而非Map顺序，empty可作旧文档默认。

BoardSession原子持有tree+metadata；replaceTree可传资料，新局/新局面默认清空；updateMetadata有变化才内容revision+dirty，不改positionRevision/不重启分析。metadata-only也是hasContent，不因无着法跳过未保存保护。Library.save快照带资料，延迟写不把晚编辑标clean；open/import/restore原子带资料。

SavedGame新增可选metadata默认empty，schema1可选字段，旧文件无字段可读；FileGameRepository坏metadata转换FormatException走既有备份/坏主原件保护。FileDraftRepository必须转传，DraftController key加metadata，资料单独编辑也能自动保存，恢复为dirty副本保持未知标签。最近阅读仍只是位置，不复制资料或棋谱。

Material3棋谱资料入口编辑赛事/地点/日期/轮次/红方/黑方和记录结果；默认不填也不造资料，按实际改动更新并保留未知/派生字段。结果是记录而非裁决，不强行结束棋局。表单绑定epoch+revision，开着期间文档/内容改变拒绝旧表单覆盖；导航变化可保留；取消/noop不dirty。未知标签提供只读查看与保留说明，不无声删减。

验收：内容相等/限额/旧文件/坏资料与备份、资料only dirty/草稿恢复/延迟保存、编辑取消/noop/过期保护/200%字号/未知保留、资料编辑不重启分析/AI，macOS真实保存与新实例/独立草稿。核心dart test/analyze、根真NNUEflutter test/analyze、相关原生项，通过后独立中文feat(records)提交。下一PGN文字交换再文件端口；本片仍不宣称App能读PGN文件。

边界补充：清空最后一项资料仍是dirty修改，新局/导入/库打开/退出/草稿恢复等覆盖保护以dirty判断，不能因当前内容为空漏提示。空但具已命名标题的草稿仍可恢复；默认无名初始空盘不制造恢复噪声。
