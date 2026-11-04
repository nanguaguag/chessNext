# 开发依赖来源记录

运行时新增 [path_provider 2.1.6](https://pub.dev/packages/path_provider)（flutter.dev，BSD-3-Clause），使用getApplicationDocumentsDirectory将用户棋谱置于平台Documents路径。官方平台说明涵盖Android/iOS/macOS/Windows/Linux；本项目仅验证macOS。本次连同平台实现与native hooks的确切版本、归档SHA256由pubspec.lock记录；没有将官方平台支持声明冒充本项目验收。

Flutter提供的integration_test/flutter_test仅为开发依赖。其SDK版本和工程锁文件保持可追溯；发布前的完整SBOM/第三方NOTICE仍另行处理，不阻挡用户要求的本地开发。引擎与NNUE没有纳入Git或当前App包。


服务端皮肤目录使用直接依赖 [crypto 3.0.8](https://pub.dev/packages/crypto)，来源 pub.dev，BSD-3-Clause，归属 Dart project authors；归档SHA-256：`e3626ae6270383c9e3a549f34e9c4cd26c09ae6a9adaab2bf4737a00340efdc4`（与 `server/skin_catalog/pubspec.lock` 一致）。
