# macOS 运行与本地棋盘验收

2026-11-01 / M2-04 / F01、F04、F05 → B05。

仓库根目录执行：

```sh
flutter pub get
flutter run -d macos
```

需要本机 macOS、Xcode 与 CocoaPods（`pod`）；本轮在 macOS14.4 arm64 / Xcode15.0 / Flutter3.44.6 成功运行。macos/Podfile 使用本机SDK官方模板，Podfile.lock固定依赖。首次运行将编译窗口应用。主应用当前为本地双人棋盘，不需要引擎文件、网络或账号；Pikafish分析界面尚未接入。

## 本轮功能

Material3明暗主题、带河界和九宫的棋盘、读屏棋子/坐标/选中/落点语义；点击选子与合法落点、非法落子提示、走子轮换、单步悔棋、棋盘翻转、UCI着法列表、新局确认、将死/困毙提示。方向键移动棋盘光标、Enter/Space选子落子、Escape取消；点击棋盘恢复键盘焦点。窄窗口和大字可滚动，棋盘触点最小48dp。

BoardSession负责内存会话、历史与状态通知，View不直接调用引擎/文件/数据库；规则仍在纯Dart包。当前历史是线性内存快照，不冒充B16棋树分支或持久化。界面明确关闭后不保留，非空新局需要确认。未实现AI对弈、保存恢复、完整历史裁决、文件导入或局面编辑界面。

## 验证

- `flutter test`：11/11（含2个会话与2个Widget测试）。
- `flutter analyze`：无问题。
- `bash tools/check.sh`：上两项及规则26/26、引擎2/2，各处分析均通过。
- `flutter test integration_test/local_board_test.dart -d macos`：1/1，原生App验证中炮、翻转、悔棋、新局取消/确认、主题切换。
- 可用 `CHECK_MACOS_INTEGRATION=1 bash tools/check.sh` 一次执行含桌面窗口的检查。
- 普通 `flutter run -d macos` 已成功启动；后续再次从测试入口重建到普通入口验证Debug签名稳定性。

本轮桌面Computer Use权限未授予，因此没有声称人工截图/原生点击检查通过。原生操作证据来自Flutter integration_test；系统报告无法自动置前窗口，但测试在App进程内成功完成。

## Debug构建修复

初次没有原生插件时可以构建，但加入integration_test后工具要求CocoaPods：补入SDK官方Podfile及Flutter-Debug/Release对Pods配置的引用，修复PODS_ROOT未定义导致的Podfile.lock同步错误。

本机默认adhoc签名的designated requirement为二进制cdhash，后续重建后沙箱初始化等待；进程采样停于_libsecinit_appsandbox。将应用设置为独立dev.chessnext.app，并仅在Debug配置使用稳定的同identifier签名要求，重建后可继续使用本应用开发容器。App Sandbox始终开启，没有清理用户容器或修改系统隐私设置。Release保留单独签名配置；此配置不代表已完成正式签名、公证或发行。

暂存诊断日志在/tmp，不提交调试服务地址。后续设备或正式开发证书环境应复核签名配置。

## M3-02更新

主应用已接本地库和分析面板。执行python3 tools/setup_pikafish.py准备官方制品，再flutter run -d macos，会自动将本机校验后的引擎/网络打入构建产物并签名helper；不再需要手工签名。若制品缺失，棋盘仍可用，分析报告不可用。当前构建签名用于本地开发，不声称正式公证通过。
最新原生集成3/3通过，包含真实Documents保存恢复以及包内引擎NNUE搜索、多PV切换与停止。Engine资源只存在.local和build，不提交Git。

文字文件交换：生产main已注入单UTF8文件导入及五格式文件导出；当前Debug/Release user-selected.read-write（导入切片历史曾只读），sandbox始终开启。保存经Foundation atomic私有通道，原生集成以注入chooser+真实沙箱容器文件验证；实际系统Open/Save面板/外部授权/Release实际签名待平台人工验收。此未验状态不代表无功能入口，也不能称已通过外部位置验证。
