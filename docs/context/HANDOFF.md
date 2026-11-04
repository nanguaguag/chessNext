# 当前交接（2026-11-05，Asia/Shanghai）

## M4-57 当前进展（已提交7b582ae）

把BookService配置接入持久化偏好和分析AI单步；开局/残局模式、地址、离库步数；地址空不联网，并明示查询会发当前FEN及完整历史。当前局面、规则合法性、epoch/positionRevision/tree门控仍有效；服务miss/网络/协议异常或候选非法回退本机引擎。站点随机分差/残局识别/上界未知，项目暂定100cp、非将棋子≤8、已完成全回合计数、最多255（P），见ADR-089。

定向32/32；根串行`flutter test --concurrency=1 --reporter compact`572通过/5跳过；`flutter analyze --no-pub`和diff check通过。复用App PID50598/runner50125 attach同步1047ms、热重启993ms；锁屏无法人工视觉验收，无新App。feature已提交`7b582ae feat(book): 接入AI走棋云库策略`；本交接另做中文docs commit。

下一步继续E71其余控制边界与实际搜索外行为（避免凭未知规则冒充源站），随后按剩余功能矩阵推进F21格点/边距边界、F27/F31支持等登录外功能；后端数据授权与部署联调仍待用户配置实际数据/环境。不要因连续几个F22切片而宣称全站对齐。

## M4-56 当前进展（已提交7bf3b2d）

在已提交M4-55服务端`4f515e9`上增加`BookService`端口和`HttpBookService`适配器（ADR-088）。只在调用方显式传入endpoint时请求；公网HTTPS、loopback HTTP，5秒超时、request/response 32KiB、history 512、候选32；核对请求键回显、候选格式/唯一性和数据集署名。HTTP failure按Unavailable/Rejected/InvalidResponse区分，不落子/不缓存/不重试。专项4/4；根测试568通过/5跳过；Flutter/Dart analyze与diff check通过。未接app composition root/设置/AI走棋，无macOS运行需要；未新增chessNext。

M4-56及追踪材料已单独提交；本轮上下文更新另做中文docs commit。下一片把endpoint与开局策略、残局开关、离库步数设置落实到持久化偏好，并用AI单步进行合法候选复核/未命中或失败时本机引擎回退；E71随机分差和残局判定未知值须在项目决策中标P。随后继续F21格点/边距几何、F27/F31及其它登录外差距。全站目标仍未完成。

## 最新进展 M4-55 / 服务端云库查询切片

M4-55已由`4f515e9 feat(server): 增加自建云库查询接口`提交，M4-56随后增加独立BookService传输端口（`7bf3b2d`）。服务端可选operator book.json，kind+完整FEN+history精确查询；响应候选着法/分值/权重及数据许可/归属，不附数据、不记录查询。请求32KiB、最多512步历史/32候选；systemd/nginx有部署配置。仍非端到端云库：客户端未注入App、无AI合法棋步核验/策略和真实授权数据。

验证：专项`flutter test --concurrency=1 test/server/book_catalog_server_test.dart test/server/skin_catalog_server_test.dart --reporter expanded`12/12；根`flutter test --concurrency=1 --reporter compact`564通过/5跳过；`flutter analyze --no-pub`、`dart analyze server/skin_catalog/lib server/skin_catalog/bin`、`git diff --check`均通过；服务端`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server`成功。仅服务端变更，未重启App；唯一既有PID50598/runner50125保留，测试单一flutter_tester，没有新chessNext。

M4-55功能已单独提交；完成本交接文档的中文docs提交后，继续F22/F23 Flutter BookService接入、开局最佳/分差随机/残局云库与离库步数（随机分差等源站未知值须标U并选择项目P）；随后继续B24/F21几何审计与其余设置、F27/F31等登录外缺口。持续目标未完成，不得宣称全站对齐。

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
# 2026-11-05 当前交接

用户持续授权实现登录以外全部功能/设置并实际运行macOS，禁止使用子代理。当前 HEAD `3e9e60e`；M4-55/56/57已提交（自建云库服务端、HTTP客户端、AI单步云库策略），尚不等于端到端部署数据或全站对齐。在线能力保留在范围，采用用户自建可替换后端；许可决定暂缓。

本轮完成E72参考站左边距单步复核，更新`REFERENCE_EVIDENCE.md`、`FEATURE_MATRIX.md`、`FEATURE_GAPS.md`、`INTERACTION_SPEC.md`、`TRACEABILITY.md`、`BACKLOG.md`及CURRENT_STATE。数据：左33→33.5、右465→465.02，再恢复；退出确认丢弃草稿。`git diff --check`通过。证据仅支持一个左到右联动样本。

用户反馈曾因测试重复打开多个chessNext。本轮检查只发现既有App PID50598，没有运行`flutter run`或根测试；后续测试必须串行`flutter test --concurrency=1`。macOS改动只能复用既有App及VM Service attach，操作前核对PID；不得再次启动app实例。最后明确的既有runner PID50125需重新核对。

工作树：E72文档审计改动待提交；无业务代码改动。未跑测试/analyze/macOS（纯审计）。下一步单独提交E72文档后，继续F21/B24双格点/边距交互设计与实现，逐项保持源站未知值为U；每个功能根目录串行`flutter test`、`flutter analyze`、复用Mac app并单独中文feature commit，随后更新上下文。
