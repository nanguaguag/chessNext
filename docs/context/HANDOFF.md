# 当前交接（2026-11-05，Asia/Shanghai）

## 授权与目标

持续实现和实际macOS运行已获授权；目标是对齐 xiangqiai.com 登录后功能以外的所有可确认功能与设置，不依赖旧聊天记忆。离线优先推进，在线能力仍在总范围，采用自建可替换后端并提供部署方案。许可决策按用户要求暂缓。每个功能单独中文Conventional Commit，并执行根`flutter test`、`flutter analyze`；macOS变更复用同一App/runner。无代理授权。

## 当前产物

- `1804040 feat(settings): 增加AI走棋预算设置`（M4-54/ADR-086）：独立AI走棋难度、时长与不限时最大深度偏好，固定节点映射属于P；参考站精确棋力算法、自定义上界和云库行为不宣称对齐。
- `c7b7af6 feat(analysis): 增加分析界面AI单步走棋`（M4-53/ADR-085）：分析界面单步、过期结果保护、运行分析恢复。
- M4-54专项24/24；根串行测试558通过/5跳过；`flutter analyze --no-pub`和`git diff --check`通过。
- 复用macOS PID50598与runner PID50125；attach同步1,090ms、热重启1,042ms。系统锁屏，未做人工视觉验收。测试期间单一`flutter_tester`，无新增chessNext实例。

## 未完成和下一步

F22/F23仍未完成：自建可替换BookService、离开云库步数、云开局/残局选项的真实搜索行为、自定义时长边界与难度映射的参考站算法仍U或未实现。E71观察到开局库选项“关闭/最佳着法/分差内随机”，具体随机分差U。下一步实现只读服务契约与自建数据部署；运营者提供拥有或获准分发的数据，不能附带或伪装第三方棋库结果。之后继续功能矩阵所有剩余非登录差距（如F21格点/边距完整几何、F27全页面语言覆盖、F31关于/支持）。不宣称全站对齐。

## 工作树与运行状态

HEAD为`b3025a7`，工作树干净。当前唯一macOS Debug App为PID50598，runner PID50125；无`flutter_tester`或attach CLI。继续macOS验证时连接既有VM Service `http://127.0.0.1:61589/dTmglI9Y_pk=/`，不要重复执行`flutter run`。参考站IAB临时tab2停在恢复后的AI走棋设置页，tab1用户原页面未触碰；没有修改参考站设置。

## 本轮实际命令

- `flutter test --concurrency=1 test/application/engine_play_test.dart test/application/preferences_controller_test.dart test/widgets/preferences_test.dart --reporter expanded`：24/24通过。
- `flutter test --concurrency=1 --reporter compact`：558通过/5跳过。
- `flutter analyze --no-pub`：无问题。
- `git diff --check`：通过。
- `flutter attach --debug-url http://127.0.0.1:61589/dTmglI9Y_pk=/ --no-dds`：同步1,090ms、热重启1,042ms，随后Ctrl-C脱离，App与runner仍在。
