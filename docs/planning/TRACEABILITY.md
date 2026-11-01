# 需求追踪

需求→证据与模块见 FEATURE_MATRIX；需求→待办见 BACKLOG；待办→阶段见 MILESTONES。本文件定义验证分组，不代表已通过。

| 测试组 | 需求 | 证据 | 验收方式 |
|---|---|---|---|
| T01 规则/棋盘/编辑 | F01,F04–F06,F23 | E01,E03,E08 | 纯领域用例+组件/触控实测 |
| T02 搜索/对弈/资源 | F02,F03,F22,F24,F25 | E01,E02,E08 | 真实UCI+fake竞态+五平台 |
| T03 文档/格式/仓库 | F07,F08,F10–F13,F16,F18 | E04–E06 | 自制样本往返+事务/迁移 |
| T04 复盘/训练 | F14,F17,F32 | E01,E07,E09 | 评分基准+取消恢复+练习流程 |
| T05 云端/识别/认证 | F09,F15,F30 | E01,E04 | 可替换服务contract+离线/隐私 |
| T06 体验/支持 | F19–F21,F26–F29,F31 | E01,E08 | 明暗/字号/键盘/读屏/平台菜单 |

每次实现新增记录：F-ID、证据版本、ADR、变更提交、测试名称/命令、平台、结果、未解问题。无提交/命令不得填通过。本轮所有 T 组未执行。

## 离线修订

纳入/延期映射见 OFFLINE_SCOPE（覆盖F01–F32）；增量见B13–B20。T02真实引擎通讯子集现已通过Flutter test，日志 docs/engine/evidence/flutter-test-uci.log；它不覆盖对弈业务、领域合法性、FFI或其他平台，其余T组仍未执行。

## M2-01验证记录

F01/F06/F07 → B15首切片 → packages/xiangqi_core → T01规则/FEN子集：dart analyze通过，dart test 11/11通过；python3 tools/verify_xiangqi_perft.py四组逐分支一致，见 engine/evidence/xiangqi-perft.json。平台为macOS上的Dart3.12.2 VM，未声称五平台运行。领域规则不依赖Flutter。终局/历史/编辑语义校验未覆盖，整个F项仍未完成。仓库无提交ID，变更均未提交。

## M2-02 / F06 → B15 编辑局面校验

基线b3b423a已提交。新增validateForPlay结构化错误、坐标定位和不可变结果；检查数量、将士象落点、兵卒初始路径与未过河同路重复、将帅照面、非行棋方被将军。新增9个纯Dart测试及3个Flutter契约测试。bash tools/check.sh：根Flutter5/5与analyze通过，纯Dart20/20与analyze通过，引擎2/2与analyze通过。规则包新增独立analysis_options，避免继承Flutter lint依赖。完整历史可达性/长将长捉未实现；不把B15整项标完成。
