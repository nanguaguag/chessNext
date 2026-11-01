# 当前状态

日期：2026-11-01，Asia/Shanghai。M2-05：已实现棋谱分支/注释/导航，以及可用flutter run -d macos启动的Material3离线双人棋盘；整体产品和M2尚未完成。

用户要求离线优先，登录后/在线服务延期；许可暂不处理，不阻挡本地开发。每功能执行flutter test、flutter analyze通过后中文Conventional Commit。规则在纯Dart包，UI仅通过BoardSession访问会话，不直接接引擎或存储。

## 已实现

- 基线b3b423a；局面校验9b515d2；将死/困毙6e7fd77；本轮macOS棋盘功能独立提交，哈希见git log。
- 主应用lib/main.dart、lib/app.dart；BoardSession内存走子历史；棋盘绘制、语义、点击/键盘选子落子、提示、单步悔棋、翻转、新局确认、着法记录、主题和终局提示。
- macos平台工程，1120×850初始窗口/520×640最小窗口。Debug稳定签名identifier dev.chessnext.app，Sandbox开启。Podfile与Pods配置引用补齐，解决加入集成测试后的构建问题。
- Pikafish仍在research/spikes/flutter_engine_probe验证；主界面尚无AI分析/AI对弈。

## 本轮验证

根flutter test11/11、flutter analyze无问题；规则26/26及analyze通过；引擎2/2及analyze通过；macOS原生integration_test1/1通过。flutter run -d macos实际启动成功，且从测试入口重建回普通入口后再次启动成功。未授予Computer Use桌面权限，无法截图/人工点击验收；系统自动置前返回失败，但进程和Flutter连接成功，原生测试完成。证据与命令见planning/MACOS_RUN.md。

## 下一步/限制

B16棋谱磁盘保存恢复；随后B14生产引擎端口和主UI分析集成。为满足本次macOS运行请求，先交付线性内存会话和UI，不冒充完整B16。关闭App不保留当前棋局，界面已提示。历史长将长捉/重复/自然限着仍未实现；Android/iOS/其他桌面、性能热测、正式签名公证未验收。

曾尝试detach，但终端会话结束后App也退出；已重新启动flutter run，保留活跃开发会话供用户运行。用户可自行关闭。用git status确认提交后工作树；不要关闭用户后续自行开始的对局。环境Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0。

M2-05：纯Dart GameTree提供不可变分支、稳定节点ID、注释、主线提升和子树删除；BoardSession基于棋树导航，后退不再删除棋谱，前进可恢复已有着法，hasContent独立于游标保护新局。UI有分支选择、主线/删除菜单、注释与前后导航。根Flutter13/13及analyze通过；核心30/30及analyze通过。磁盘保存尚未实现。
最新用户要求持续对齐全站所有功能，每功能验证后提交；账号/在线服务纳入远期目标，不以旧延期记录当作永久排除，真实服务仍需依赖确认。
