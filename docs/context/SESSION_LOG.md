# 会话日志

## 2026-11-01 / M0-01

范围：调查、验证设计、文档与 Agent 体系。初始为空仓库，无 AGENTS。

操作：读取 skill-creator；使用 CUA 浏览器实际展开参考站点；官方 release latest 跳转 Pikafish-2026-09-06（短 SHA 4c17cee）；检查固定 tag 的 uci.cpp、engine.cpp、evaluate.h；核对 Flutter FFI/架构/Material 3 官方文档；读取本机 Flutter 缓存。

结果：分析输出已观察；访客棋谱/练习被登录阻挡；原生引擎未运行。GNU 条款页访问超时。生成文档与六个 Skills，保留后续审计与 spike 门槛。没有业务实现或外部提交。

验证：32个 Markdown 文件相对链接检查通过（0失效）；lib 下无业务文件。六个 Skills 的官方 quick_validate.py 均因本机 Python 缺 PyYAML 无法执行，不计通过；使用 Ruby 标准 YAML 解析替代检查，六个 frontmatter 的 name/description 与目录名均通过。未安装新依赖。

## 2026-11-01 / M1-01 离线通信

用户将登录后功能延期，本轮授权Flutter与最新版引擎跑通、架构与计划。读取项目状态与pikafish-engine Skill。GitHub API403限流后用公开latest HTML和git ls-remote确认2026-09-06及完整SHA；下载官方7z，校验macOS二进制/NNUE，保留GPL/AUTHORS/NNUE限制许可。发现权重禁止未经许可商用，制品保持.local不提交。

独立flutter create macOS诊断工程；真实引擎测试NNUE/MultiPV/200ms/100轮stop/quit通过，加缺失引擎负向测试，2/2通过，analyze通过；macOS构建成功。原生App执行仓库外helper被Sandbox拒绝，改为应用内helper继承sandbox并adhoc签名验证。最终状态见COMMUNICATION_VALIDATION与日志，不用构建成功冒充运行成功。

更新AGENTS授权范围、ADR-004、离线范围、架构、M1–M5和B13–B20。未实施业务，无git提交。

最终运行验证：应用内helper继承sandbox、adhoc签名后，真实Flutter macOS进程NNUE/双PV/限时搜索/3轮stop/quit通过，EXIT=0；未关闭Sandbox。日志已存macos-app-uci.log，调试VM服务URL已排除。

交付检查：37份项目Markdown相对链接0失效；两个工具脚本Python语法通过；下载校验脚本对已有制品复验通过；最终flutter analyze无问题；原生运行和100轮测试日志PASS。所有变更未提交，没有残留运行会话。

## 2026-11-01 / M2-01 B15规则核心

用户授权按计划开始实施，要求暂不处理授权问题。使用flutter-feature Skill，读取状态/架构/设计/交互规格后建立独立纯Dart包。实现坐标/FEN/七类棋子规则/将军及合法落子，不包含历史裁决或UI。

首轮测试10通过1失败：手工炮将军fixture缺少炮架，按规则补上e1红兵后11/11通过；并非通过修改规则迎合fixture。dart analyze无问题。4组局面对比本地固定版本Pikafish perft逐分支完全一致，日志及原始stdout存xiangqi-perft.json；初始3层79666，单步中炮2层1564，6步开局2层1100，炮吃马/车回吃3层46642。

本轮未重跑无改动的Flutter通信或移动测试；无引擎运行残留。包有pubspec.lock记录实际test依赖。AGENTS/CURRENT_STATE/HANDOFF和追踪更新范围，不删除既有许可事实。

## 2026-11-01 / 基座复验与首次提交

用户要求每功能flutter test、flutter analyze后中文规范提交。新增根Flutter测试入口（2个契约测试）与tools/check.sh，规则运行时仍纯Dart。复验全部通过：根Flutter2测试及analyze、纯Dart11测试及analyze、引擎spike2测试及analyze；4组perft逐分支一致；macOS沙箱App NNUE/3轮stop/quit成功。仅确认本机macOS技术路径，不宣称移动FFI或Windows/Linux通过。首次基线提交归档现有文档、通信与规则核心；随后新增功能独立提交。

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

## M2-06 / F10,F16本地部分 → B16 保存与恢复

新增版本化棋树JSON及损坏/重复/循环/非法着法校验；路径受限的文件仓库、同FS快照提交和旧版备份、可替换内存仓库、并发dirty/epoch/positionRevision保护。本地库可保存命名、搜索和重新打开分支/注释/游标。新增path_provider2.1.6及锁文件。
验证通过：根flutter test23/23与flutter analyze；核心dart test32/32与dart analyze；macOS原生集成2/2含真实Documents子目录保存与新App实例恢复。测试发现并修复弹窗initState通知父树造成build期setState，以及序列化节点顺序不稳定。ADR-005记录单窗口/文件大小/节点限制及未验证的持久性边界；不是网站账号同步，不宣称F16全量完成。
