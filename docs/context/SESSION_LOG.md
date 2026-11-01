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
