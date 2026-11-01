# M4-01a / F08,F12 / B19：单局PGN codec（P）

2026-11-02，源PGN_RESEARCH/E20。首片只交纯Dart API与真实自制样本契约；不标App已经支持PGN，后续资料模型/文字界面/文件入口各自验收。

契约：PgnRecord不可变tree+标签，派生Game/FEN/Format/Result规范化；非派生标签保留，结果是文件声明，不自行裁决。PgnCodec.parse支持单局ICCS（大小写/有无连字符）或Chinese（省略Format默认Chinese）、BOM、2/6字段FEN、PGN红r规范化w、花括号根/逐着/结果后评注。合法性统一Position/ChineseNotation，不另写规则。回合编号若出现核对FEN回合与先手，缺编号可读；结果终止必须存在并与Result标签一致。

限额：64000字符、规范化后最多64标签、标签名64/值4096、1999着、单节点合并评注10000；超限/非法根和着法/重复标签/多局/括号变着/WXF/NAG明确错误，先构造完才返回，不改任何会话。结果后只能评注。不支持不等于丢掉后继续。

导出PgnCodec.path只根到游标，ICCS/Chinese可选，保留所选节点和根评注/其它标签、明确不含支线和未来。Game首标签、规范化FEN、Format和结果自洽；黑先用...且按FEN回合编号。评注含花括号无法无损导出则报错，调用者可显式includeComments:false，不偷偷替换字符。字节等同性不保证，要求标签语义/初始局面/合法着法/评注往返。

验收：E20 151字节原文件解析3步、中文/黑先/自定义根/标签转义/Unicode/注释和结果、保留非派生元数据、编号/超限/语法/非法着法/不支持特性明确拒绝、源树不变与导出范围。纯包dart test+dart analyze，根显式NNUE flutter test+flutter analyze后独立中文feat(notation)提交。没有UI/原生改动不空跑macOS；下一M4-01b资料/交换界面按实际数据损失设计，不把codec当完整功能对齐。
