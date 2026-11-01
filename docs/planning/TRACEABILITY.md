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

## M2-03 / F01 → B15 将死与困毙

编辑局面校验已提交9b515d2。本切片新增boardOutcome：进行中/将死/困毙和胜方，拒绝无效编辑局面；困毙同样判负。新增6个纯Dart与2个Flutter契约测试，验证红黑困毙、将死、被将但可逃、无效局面和正常开局。bash tools/check.sh通过：根flutter test7/7与flutter analyze无问题；规则dart test26/26与dart analyze无问题；引擎flutter test2/2与flutter analyze无问题。历史裁决未实现，B15整体仍未完成。下一切片B16棋树/会话。每个功能单独中文规范提交，不在未测试平台标记通过。

## 2026-11-01 / M2-04 / F01,F04,F05 → B05 macOS棋盘

用户要求实际flutter run -d macos，优先落地Material3主App与线性内存会话：选子/合法落点/非法提示、轮换、单步悔棋、翻转、新局确认、UCI记录、终局、主题、键盘/语义和窄屏大字。非B16完整棋树，不含持久化或AI界面。

验证：flutter test11/11、flutter analyze无问题；规则26/26及分析、引擎2/2及分析通过；macOS原生集成测试1/1通过；普通flutter run -d macos首次及从测试重建回普通入口后均成功。Computer Use无权限，截图/人工检查未做；自动置前失败，但Flutter连接及App进程工作正常。尝试detach后终端关闭导致App退出，随后重新flutter run并保留开发会话。

修复过程：首轮测试暴露测试API误用与非法落点fixture误选己方棋子，修正后通过；集成测试要求Podfile，补SDK模板与Pods配置引用；后续重建在_libsecinit_appsandbox等待，确认为本地adhoc cdhash签名变化，Debug使用独立稳定identifier dev.chessnext.app后测试/普通启动均通过。Sandbox始终开启，未更改系统隐私权限或删除用户容器。详细运行指南planning/MACOS_RUN.md。

## M2-05 / F13 → B16 棋谱分支与注释

不可变GameTree、稳定ID、路径/游标、重走复用、主线提升、删除子树；session和UI实现分支选择/注释/前后首尾导航。导航不增加内容revision；新局保护独立于游标。根flutter test13/13、flutter analyze无问题；核心dart test30/30、dart analyze无问题。独立提交后继续磁盘保存。未宣称格式、存储或全站对标已完成。
