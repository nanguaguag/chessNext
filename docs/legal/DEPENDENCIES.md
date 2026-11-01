# 开发依赖来源记录

运行时新增 [path_provider 2.1.6](https://pub.dev/packages/path_provider)（flutter.dev，BSD-3-Clause），使用getApplicationDocumentsDirectory将用户棋谱置于平台Documents路径。官方平台说明涵盖Android/iOS/macOS/Windows/Linux；本项目仅验证macOS。本次连同平台实现与native hooks的确切版本、归档SHA256由pubspec.lock记录；没有将官方平台支持声明冒充本项目验收。

Flutter提供的integration_test/flutter_test仅为开发依赖。其SDK版本和工程锁文件保持可追溯；发布前的完整SBOM/第三方NOTICE仍另行处理，不阻挡用户要求的本地开发。引擎与NNUE没有纳入Git或当前App包。
