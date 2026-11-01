# 中国象棋PGN调查

2026-11-02，F08/F12/B19。不能把国际象棋SAN或FEN50步规则套用为中国象棋规则。

## 主来源与边界

D：[象棋百科全书原始中国象棋PGN规范（2006修订）](https://www.xqbase.com/protocol/cchess_pgn.htm)：标签在着法之前，Game声明Chinese Chess；Format可Chinese/ICCS/WXF，省略默认为Chinese；支持花括号评注、结尾结果和多棋局。该规范不是本站实现证明，不复制其中例谱或第三方解析代码。头部结果可能来自认输等对局结论，不要求棋盘已将死。其FEN例含红方r别名，项目PGN可兼容规范化为w，通用FEN旧契约仍独立。

V：E20下载自制151字节UTF8无BOM样本，[PGN](samples/E20-self-created-iccs.pgn)/[来源SHA清单](samples/E20-manifest.json)。四标签Game/Result/FEN/Format，ICCS大写连字符，FEN两字段，三步至当前选中支线。另一已存主线未包含；本轮未添加评注，不能推断网站PGN评注支持。截图[导出后状态](screenshots/E20-pgn-export.png)。不含站点库棋谱或代码。

## 增量建议（P）

先独立纯Dart单局PGN codec：保留不可变标签Map与根/着法/评注，支持ICCS和已有中文记谱解析；严限长度/标签/着数，原子构造，不支持的WXF/括号变着/多局/数字注解必须明确拒绝，不静默丢弃。导出限定根到当前路径，调用者明确其它分支/未来不导出；结果按文件声明保留，不伪造裁决。评注包含花括号时不能无损写标准评注，报错或由用户明确选择不导评注。

随后App文字交换与文件端口分片接入；目前GameTree/本地SavedGame无赛事/棋手元数据持久化，不能解析后悄悄丢掉标签却宣称完整资料导入。应先加资料模型/存储可选字段或明确预览与用户确认损失；UI必须可审查。之后逐项WXF/变着/多局/GBK等，待对应主规范与自制fixture，不一次宣称所有PGN均兼容。

M4-01b续：GameMetadata/BoardSession/SavedGame的可选资料字段、本地保存和草稿已验收；GameTree仍专管棋树，资料并列保持。PGN交换界面/文件入口仍未接，下一按独立增量，不将资料模型当PGN导入可用。
