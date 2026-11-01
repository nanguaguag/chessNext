# 证据索引

采集：2026-11-01（Asia/Shanghai），https://xiangqiai.com/#/，未登录，CUA + 支持的 Playwright locator。页面未提供构建版本；随时间变化，日期是证据边界。没有使用网站内部隐藏状态/API 推断功能。

| ID | 路径与操作 | 结果与证据 |
|---|---|---|
| E01 | 首页 → 菜单，查看主布局 | 工具栏、棋谱库/错题/最近阅读、引导、显示模式等已观察；初始“下一着”禁用。完整原始树未保存，属于当次浏览记录 |
| E02 | 首页 → 开始分析 → 分析模式关 | 输出红分、D、秒、K 和变化；开关恢复0，结果仍保留；[AX](analysis-ax.txt)、[截图](screenshots/analysis.png) |
| E03 | 首页 → 编辑 → 取消 | 编辑面板、红黑先、棋子盒说明和各操作；取消返回；[AX](edit-ax.txt)、[截图](screenshots/edit.png) |
| E04 | 首页 → 导入 → 关闭 | 拍照/识别图片/文件/文件夹/剪贴板和文字；空输入按钮禁用；没有真正导入，原始树未落盘 |
| E05 | 保存/分享 → 分享/导出 | 完整导出选项；没有执行远端分享；[AX](export-ax.txt)、[截图](screenshots/export.png) |
| E06 | 菜单 → 棋谱库 → 官方精选 | 我的棋谱要求登录；精选显示赛事/棋手/开局/古谱/排局；[AX](records-ax.txt) |
| E07 | 菜单 → 错题本 | 转到 #/study，要求登录才能练习；[AX](mistakes-ax.txt) |
| E08 | 菜单 → 设置 → play/analysis/display/sound | 四组字段和当前值见矩阵；未改动设置，未测持久化；原始树未保存，需要补证 |
| E09 | [官方指南](https://xiangqiai.com/guide/) | 指南目录声明整谱分析；不是运行成功证据 |

截图仅用于研究，不授权作为 App 资源。分析截图数值只是单次采样，不能当性能基准。原始 AX 可能带动态 UI id，不应用于长期稳定定位。

## 官方技术资料

- S01 [固定最新发行](https://github.com/official-pikafish/Pikafish/releases/tag/Pikafish-2026-09-06)：latest 跳转确认，短提交 4c17cee；完整 SHA 与制品校验仍待取证。
- S02 [README](https://github.com/official-pikafish/Pikafish/blob/master/README.md)：引擎定位、构建和许可；master 是动态资料，打包必须重核 tag 文件。
- S03 [固定 tag 引擎选项](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/engine.cpp)、[UCI](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/uci.cpp)、[NNUE 默认名](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/evaluate.h)。
- S04 [Flutter FFI](https://docs.flutter.dev/platform-integration/bind-native-code)、[架构指南](https://docs.flutter.dev/app-architecture/guide)、[SDK archive](https://docs.flutter.dev/install/archive)。
- S05 [Material 3 API](https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html)。
- S06 [Apple App Review](https://developer.apple.com/app-store/review/guidelines/)；GNU 站点条款抓取超时，不作为已完成许可审查。
