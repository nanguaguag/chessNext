# 当前状态

日期：2026-11-01，Asia/Shanghai。当前M2-03：B15已实现规则核心、静态局面校验和将死/困毙判定；历史裁决和完整M2尚未完成。

用户授权按计划实施离线业务；账号和在线服务延期；许可事项暂不处理、不阻挡本地开发。每功能必须flutter test、flutter analyze通过后使用中文Conventional Commits独立提交。

## 产物与验证

- 技术基座：b3b423a。根Flutter包提供应用边界与契约测试；纯Dart规则位于packages/xiangqi_core。tools/check.sh统一验证根Flutter、规则包、引擎spike。M0文档/证据/Skills已归档。
- 通信：research/spikes/flutter_engine_probe，官方Pikafish2026-09-06及NNUE在.local（忽略目录），hash见engine/pikafish.lock.json。本轮重跑真实引擎2/2与macOS沙箱App成功（NNUE/3轮stop/quit）；4组perft逐分支一致。
- M2-02：9b515d2，validateForPlay返回静态局面错误类型、方色及坐标，20个纯Dart/5个根Flutter测试通过。
- M2-03：boardOutcome区分进行中、将死、困毙，后两者均由非行棋方获胜；无效编辑局面拒绝裁决。最新根flutter test7/7、纯Dart26/26、引擎2/2，三处analyze均通过。该功能独立提交，哈希以git log为准。

## 下一步与边界

下一切片B16棋树/分支/注释和会话游标，随后棋盘UI。需要历史的长将长捉、重复、自然限着尚未实现，boardOutcome不能替代完整GameResult。静态局面验证不证明历史可达性。没有业务棋盘UI/持久化；B14生产引擎适配器和移动FFI、Windows/Linux、性能/热测仍待做。本机macOS基座复验通过不等于全平台验证。

环境Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。无后台进程。所有本轮成果通过检查后提交，用git status确认工作树、git log确认提交。
