## M4-83 / F15,F20 / ADR-113 大师谱整局只读预览（验证通过，待提交）

自建大师谱索引可选包含经运营者授权的PGN；查询仍只返回metadata与`hasRecord`，用户显式点开后按ID懒加载详情。服务和客户端限制大小并核对ID、数据集来源、license/署名、精确FEN/完整历史和PGN主线；局面/文档/筛选变化会丢弃旧响应。独立只读主线对话框不写入主棋谱。服务包`dart test`6/6、`dart analyze`无问题；定向Flutter16/16；根`flutter test --concurrency=1 --reporter expanded`629通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-83-final.log`；`flutter analyze --no-pub`、格式/diff检查通过；`flutter build macos --no-pub`成功（111.9MB，已有flutter_tts SwiftPM警告）。未能附着现有PID50598/runner50125，未打开新App；实际macOS运行/热重启/视觉验收未验证。测试使用单串行tester且无GUI，结束后tester退出，原桌面实例仍唯一。真实PGN授权与部署语料仍U；F15/全站不关闭。代码与文档待独立中文提交。

## M4-82 / F15,F20 / ADR-112 来源选择跨路由持久化（已提交 943cc14）

`bookLookupSource`偏好默认cloud且兼容旧schema；设置页和主面板共享云库/大师谱选择，按偏好Controller异步编辑合并规则持久化。来源切换不触发查询。定向8/8；根`flutter test --concurrency=1 --reporter expanded`623通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-82.log`；`flutter analyze --no-pub`与diff-check通过；`flutter build macos --no-pub`成功（既有flutter_tts SwiftPM warning）。实际App attach/runtime未验，仍仅PID50598一个GUI。本机跨重启保持是P，E55只验证同标签页路由保留。F15/全站仍未对齐。

## M4-81 / F15,F20 / ADR-111 大师谱筛选客户端（已提交 2e44365；macOS实际运行未验证）

主工作区云库卡片可切换云库/大师谱。大师谱提供范围、棋手/赛事、年份和胜和负过滤，显式查询后才向配置的自建索引服务提交当前FEN+完整线路；请求和响应有界、来源字段校验、失败分类、前后分页、位置/过滤变化过期保护。无地址不联网；只展示metadata/许可署名，不读取整局、不落子。筛选匹配/排序/pagination语义为项目P。

专项7/7；根`flutter test --concurrency=1 --reporter expanded`623通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-81-final.log`；`flutter analyze --no-pub`及diff-check通过。`flutter build macos --no-pub`最终版本构建成功，输出仅含已存在的flutter_tts SwiftPM及插件Swift未来兼容警告。根测试用一个串行`flutter_tester`，没有启动GUI。当前只有原chessNext PID50598/runner50125。携已知VM URL及自动发现均附着超时，未开新App；macOS app运行/热重启/人工视觉未验证。取得现有VM连接后再做实机验证；不要无提示关闭可能含用户数据的现存App或重复`flutter run`。

## M4-80 / F15,F20 / ADR-110 自建大师谱索引查询（已提交 457c904）

新增可选`POST /v1/master-games/query`服务端契约与operator-supplied索引，不携带站点棋谱；可按精确FEN+history、分类、玩家/赛事子串、年份闭区间、结果和有界分页查询，响应提供索引元数据及license/attribution。默认无环境变量时不装载。具体匹配逻辑为项目P；Flutter客户端过滤器/整局读取和授权运营未完成。E87年份min/max仅是页面DOM声明O。

专项3/3；`dart test`6/6、服务包`dart analyze`通过；根`flutter test --concurrency=1 --reporter expanded`616通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-80.log`；root `flutter analyze --no-pub`及diff-check通过。macOS复用PID50598/runner50125，同步1,640ms、热重启2,180ms；退出后原App存活，无tester/attach副本或新GUI。未做界面视觉验收。单独提交后继续M4-81 Flutter大师谱筛选客户端/失效模型，随后完善整局读取、F27及其余登录外范围；F15和全站仍未完成。

## M4-79 / F15 / ADR-109 云库候选中文记谱（验证通过，待提交）

云库查询候选现在以查询局面的中文记谱为主，UCI、scoreCp、weight为辅助信息；记谱来自本地捕获位置与已通过合法性过滤的候选，不新增网络字段或自动走棋。专项6/6；根`flutter test --concurrency=1 --reporter expanded`613通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-79.log`；`flutter analyze --no-pub`、`git diff --check`通过。5项跳过需官方Pikafish/NNUE。macOS仅attach既有PID50598/runner50125，同步1,611ms、热重启2,148ms；脱离后PID50598存活，进程检查无tester/attach残留及第二个GUI。测试仅一个串行tester。未做人工视觉验收。代码和追踪文档待单独中文feature commit；随后继续大师谱数据契约/授权部署审计、B24/F27及其它登录外差距，全站仍未对齐。

## 最新审计 E86 / F15,F20 大师谱筛选边界

参考站显示大师谱筛选范围“全部/对局/棋书”、棋手或赛事搜索、起始/截止年和红胜/和/黑胜。未填字段/点击仍然查询。随后在设置明确恢复“云库”，回主界面云库项确认生效；候选列表显现但来源可能是已有缓存或自动请求，保持U。年份范围、筛选执行、数据授权/协议均U。详REFERENCE_EVIDENCE E86。

## 最新审计 E85 / F21,B24 棋盘边距单步联动

空白未保存棋盘草稿中左33按加号一次到33.5，右465到465.02；上33、下519和格点50/50不变。反向减一次恢复四边默认。确认丢弃草稿后设置页仍默认棋盘/棋子、100%、坐标开、对面倒置关。该值只为默认附近单步V，不给整体几何算法赋值，边界/全局映射继续U。证据见REFERENCE_EVIDENCE.md E85。

# 当前状态

## M4-78 / F15 / ADR-109（门槛通过，待提交）

主工作区增加只读云库面板：显式选择开局/残局，按下查询才向偏好中配置的自建服务发送当前FEN与完整线路；无地址不联网。返回着法经当前合法着复核，仅显示及保留数据集许可/署名，不自动落子。导航/新局和切换库类型均使旧响应失效。

定向`book_lookup_controller_test.dart`6/6；根`flutter test --concurrency=1 --reporter expanded`613通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-78-final.log`；`flutter analyze --no-pub`和diff-check通过。macOS复用PID50598/runner50125，最终TTY attach同步1,266ms、热重启787ms，脱离后原进程仍存；最终进程检查无tester/attach副本。锁屏，人工视觉验收未做。代码/ADR/追踪文档待单独中文feature commit。继续推进登录外全部范围；站点大师谱筛选/查询语义、在线部署/授权及F27完整语言资源未解决，全站仍未对齐。

## 上一进展 M4-77 / F21,B24 / ADR-108

单槽图片写入中断回收已于`5fb9eb4`提交；详情见其后历史交接条目。


## 最新进展 M4-77 / F21,B24 / ADR-108（验证完成，待提交）

图片仓储读取时清理项目已知命名格式下未引用的单槽图片文件/中断staging目录；仅对槽清单不存在或清单/图片有效的槽执行；保留当前引用、未知文件、坏manifest和损坏图片。定向5/5；根`flutter test --concurrency=1 --reporter expanded`607通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-77.log`；`flutter analyze --no-pub`和diff-check通过。

macOS复用PID50598/runner50125，attach同步1,067ms、热重启1,112ms，脱离后原App仍活；根测试串行单tester、结束无残留、无新App。锁屏视觉not run。测试/ADR/研究文档待单独中文提交。B24图层映射继续，之后推进F27完整本地化及其它登录外差距；全站仍未完成。

## 前序已提交

M4-76 `0d9079b`回收未登记皮肤图像目录；M4-75 `d20b8f8`真实文件仓储重开测试；M4-74 `c34f246`几何草稿编辑；M4-73 `fc60883`保存与应用分离。

# 当前状态

## 最新实现 M4-76 / F21,B24 / ADR-107（验证完成，待提交）

成功加载皮肤定义后，以有效custom ID清理未登记的用户图片目录；保留内置/已登记皮肤，包括空孤儿目录。清单加载失败时不清理；清理失败报告错误，不破坏定义/选择/图片。定向14/14；根`flutter test --concurrency=1 --reporter expanded`606通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-76.log`；`flutter analyze --no-pub`、diff-check通过。

macOS复用PID50598/runner50125，attach同步1,083ms、热重启1,194ms，脱离后原App存活；串行单tester且无残留，没有新App。锁屏视觉not run。代码、ADR-107及矩阵/交接待单独中文feature commit。继续B24图片/定义跨仓储失败矩阵及F27和其它登录外差距，全站仍未对齐。

## 前序已提交

M4-75 `d20b8f8` file-backed皮肤/图片重开测试；M4-74 `c34f246`独立几何草稿编辑；M4-73 `fc60883`保存与应用分离；M4-72 `3c82245`删除失败一致性。

# 当前状态

## 最新进展 M4-75 / F21,B24 file-backed生命周期回归（验证完成，待提交）

新增使用真实文件Preferences、棋盘皮肤清单和图片仓储的controller重建测试。保存非活动皮肤几何/落点PNG后重建controller，值/图像恢复且原内置皮肤仍选中；单独使用该用户皮肤后再次重建，当前ID/几何恢复。定向9/9，根`flutter test --concurrency=1 --reporter expanded`604通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-75.log`；`flutter analyze --no-pub`、diff-check通过。

macOS复用PID50598/runner50125，attach同步984ms、热重启1,278ms，脱离后原App仍活；单tester无残留，没有新开App。锁屏视觉not run。测试/追踪/交接待单独中文test commit。继续分析图片/定义跨仓储崩溃原子性、F27语言覆盖和其它登录外差异；源站reload语义仍U。

## 前序已提交

M4-74 `c34f246`已存皮肤几何草稿编辑；M4-73 `fc60883`保存/应用分离；M4-72 `3c82245`删除失败一致性；M4-71 `45dcb69`拖动预览；M4-70 `283d01f`几何串行写入。

# 当前状态

## 最新实现 M4-74 / F21,B24 / ADR-106（已提交 c32e2c3）

已保存棋盘皮肤新增独立几何草稿编辑（9×10拖点、四边、专属棋子缩放、落点标记旋转、恢复默认）。取消不写入，保存只更新profile不应用，列表“使用”独立切换。定向3/3；根`flutter test --concurrency=1 --reporter expanded`603通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-74.log`；`flutter analyze --no-pub`、diff-check通过。

macOS复用PID50598/runner50125，attach同步978ms、热重启1,171ms，脱离后原App仍活；测试串行单tester，结束无残留，不曾新开App。锁屏视觉not run。功能、ADR、矩阵及交接已于`c32e2c3 feat(settings): 增加棋盘皮肤草稿编辑`单独提交；继续B24跨进程file-backed图层生命周期、F27语言资源与其它登录外缺口。全站未对齐。

## 前序已提交

M4-73 `fc60883`保存/应用分离；M4-72 `3c82245`删除失败一致性；M4-71 `45dcb69`拖动预览；M4-70 `283d01f`几何串行持久化。

# 当前状态

## 前序实现 M4-73 / F21,B24 / ADR-105（已提交 fc60883）

依据E67已验证的“保存不应用，后续使用单独切换”，本机棋盘皮肤库新增“仅保存”，保留原“新建并使用”并能从列表独立“使用”。两者都复制当前几何与图层；仅保存时当前选择不变。定向11/11。首轮根测试里既有`engine_candidates_test.dart`并发抢占用例触发30秒间歇超时；单测重跑1/1通过，根全量复跑`flutter test --concurrency=1 --reporter expanded`603通过/5跳过/0失败（日志`/tmp/chessnext-root-test-m4-73-final.log`）。`flutter analyze --no-pub`、diff-check通过。

macOS复用PID50598/runner50125，attach同步984ms、热重启2,045ms，脱离后原App仍在；无额外App/tester/attach残留，未使用`flutter run`。锁屏视觉验收not run。代码、ADR-105与矩阵/追踪/上下文已于`fc60883`单独提交；继续B24跨进程file-backed皮肤事务、F27完整语言资源及其它登录外缺口，全站仍不完整。

## 前序增量已提交

M4-72 `3c82245`删除失败原子性；M4-71 `45dcb69`保留格点拖动预览；M4-70 `283d01f`串行持久化高频几何。


## 最新实现 M4-72 / F21,B24 / ADR-104（已提交 6bee7ed）

删除当前用户棋盘皮肤原来先将偏好切到内置基底再写定义清单，清单写入失败时造成“删除失败但已切换”。现在清单保存成功后才更新运行列表、回退当前选择和清理皮肤图片；失败保留当前ID/定义/图像。故障注入专项8/8；根`flutter test --concurrency=1 --reporter expanded`602通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-72.log`，5跳过需官方Pikafish/NNUE；`flutter analyze --no-pub`、diff-check通过。

macOS复用PID50598/runner50125，attach同步1,188ms、热重启1,060ms，脱离后原App仍活。根测试单并发单tester，结束无残留；未使用`flutter run`或新开App。视觉验收锁屏not run。代码、ADR-104及研究/上下文记录已随`6bee7ed fix(settings): 保持棋盘删除失败状态一致`单独提交；继续B24皮肤存取事务和登录外全站差异，不能标全站完成。

## 前序棋盘几何修复（已提交）

M4-71 `45dcb69`保留格点拖动乐观预览（根601/5跳过）；M4-70 `283d01f`串行持久化高频拖动最终值（根600/5跳过）。细节见各自TRACEABILITY和HANDOFF。


## 前序实现 M4-71 / F21,B24 / ADR-103（已提交 45dcb69）

棋盘格点编辑器此前在父级用旧的持久化几何重建时会覆盖拖动预览；现在拖动中保留本地乐观几何，仅在无拖动且父值实际改变时同步。回归测试模拟每次拖动回调后父组件都用旧值重建，并校验把手不回跳。专项5/5；根`flutter test --concurrency=1 --reporter expanded`601通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-71.log`，5跳过需官方Pikafish/NNUE；`flutter analyze --no-pub`、diff-check通过。

macOS复用PID50598/runner50125，VM Service attach同步1,053.6ms、热重启1,158ms；Ctrl-C后原App存活。根测试单并发、单tester、结束无残留；attach无残留，没有新开App。未用`flutter run`。屏幕锁定，人工视觉验收not run。代码、ADR-103和追踪文档已于`45dcb69`单独中文提交。之后继续B24棋盘皮肤保存/应用/删除/reload事务与参考几何审计，以及F27语言资源和其他登录外差距；全站仍未对齐。

## 前一实现 M4-70 / F21,B24 / ADR-102（已提交 283d01f）

自定义皮肤几何高频变化按皮肤ID串行合并写入，持久化拖动最终值。定向13/13，根600通过/5跳过，analyze通过，attach复用原实例。详情见TRACEABILITY。


## 最新实现 M4-70 / F21,B24 / ADR-102（待提交）

自定义棋盘皮肤格点/边距调整现按皮肤ID串行合并高频几何写入。目录忙碌时保留最新拖动值，等待当前保存结束后再写，避免`loading`期间更新被静默拒绝；内置皮肤仍用偏好仓储。定向13/13；根`flutter test --concurrency=1 --reporter expanded`600通过/5跳过/0失败（日志`/tmp/chessnext-root-test-m4-70.log`，跳过需官方Pikafish/NNUE）；`flutter analyze --no-pub`和diff-check通过。

macOS复用PID50598/runner50125，attach同步1,186ms、热重启1,027ms；脱离后原App仍运行。根测试单并发、单flutter_tester，无残留；本轮未用`flutter run`、未启动GUI副本。锁屏，视觉验收not run。代码、ADR-102及矩阵/缺口/追踪/待办现待单独中文feature commit。下一步持续B24几何映射与保存/应用/reload审计，并继续F27和矩阵其它登录外缺口；源站映射仍U、全站未完成。


## 最新实现 M4-69 / F31 / ADR-101（待本片提交）

普通反馈（M4-68）及版权投诉（M4-69）均支持用户主动选择最多3张PNG/JPEG（每张≤256KiB、总计≤512KiB），显示缩略图/名称/大小且可移除；提交前完整预览目的地、字段和附件，确认后才发送。服务端严格校验base64、文件名、MIME/签名、大小；反馈与包含投诉人身份/权属信息的投诉继续分别私有保存，无附件读取接口。两个Nginx路由均限制1MiB，协议请求上限768KiB。生产服务、运营者访问/保留/清理、真实投递和外部交流仍待办，F31开放。

定向Flutter9/9、服务端Dart6/6，服务端analyze/编译通过；根`flutter test --concurrency=1 --reporter expanded`599通过/5跳过/0失败，根analyze/diff-check通过。macOS复用原App PID50598/runner50125，attach同步1,174ms、热重启1,248ms；测试前后只有一个GUI实例，根测试单一tester且无残留，未使用`flutter run`。屏幕锁定，人工视觉not run。追踪详见TRACEABILITY与ADR-101。

当前用户要求继续推进至登录外全站功能/设置覆盖，不要在单个功能提交后停下；每个实现增量仍独立执行根测试/analyze/macOS复用验证并中文提交。提交M4-69后继续B24棋盘格点/边距映射与编辑草稿保存应用/reload事务审计，并继续矩阵其它登录外缺口；全站仍未对齐。

## 前一实现 M4-67 / F31 / ADR-099（已提交，历史上下文）

关于页已加版权投诉文字表单与显式预览确认；独立`CopyrightComplaintService`复用安全HTTP传输。自建服务通过`CHESSNEXT_COPYRIGHT_ROOT`启用隔离私有收件路由；16KiB请求/1,000条，拒绝未知字段，无公开读取，文档含Linux/Nginx隔离配置。附件、实际投诉处理/运营、公开外链与生产部署验收未做，F31仍开放。

定向Flutter 7/7、服务端Dart 4/4；服务端`dart analyze lib bin test`和exe编译通过。根`flutter test --concurrency=1 --reporter expanded`595通过/5跳过/0失败；5跳过缺官方Pikafish/NNUE。根`flutter analyze --no-pub`通过；首次分析的两条花括号info已修正后复跑通过。`git diff --check`通过。首轮定向有编译/滚动/断言问题，均记录并修正后通过。

macOS没有新开App；复用PID50598/runner50125，attach同步953ms、热重启1,085ms，脱离后App仍活。根测试单并发，仅一个tester，结束无残留。attach退出后曾短暂遗留attach CLI PID95102及frontend_server PID95152，已TERM清理并复核退出；当前不应存在测试/attach后台任务。锁屏，人工视觉not run。禁止以`flutter run`验证以免增加App实例。

完成M4-67单独中文feature commit后继续用户授权的登录外全站差距，不在此停止。下一阶段优先回到B24：审计棋盘几何/边距、拖点与保存应用/reload事务；另继续F27全语言资源及FEATURE_GAPS其它缺口。全站仍未对齐。

# 最新审计 E81 / F27,F31 English反馈与版权投诉表单

E81从About打开反馈及版权投诉页面进行访客只读抽样。主要字段/文案英文，但两个附件入口“选择文件”仍中文；Feedback默认勾选设备/版本、未勾当前棋谱。未展开设备明细、未填表/上传/提交。随后回显示设置切回简中，复核系统主题/晴蓝/夜间棋盘开，状态恢复。E81追踪待文档commit；English全覆盖仍未达成。

## 最新已提交 M4-66 / F21,B24 / ADR-098 棋盘边距精确输入（9c1470d）

棋盘显示设置四边百分比滑杆旁新增可键入一位小数的字段。提交时按当前边界和至少55%横/纵跨度钳制，经现有偏好/用户棋盘皮肤控制器保存；滑杆、拖点校准仍可用。该项目百分比输入为P，与站点E76/E77显示0–500/0–550但完整单位/联动仍U的字段分离。

专项`flutter test --concurrency=1 test/widgets/board_skin_library_dialog_test.dart test/widgets/piece_skin_images_test.dart --reporter expanded`8/8；根`flutter test --concurrency=1 --reporter expanded`593通过/5跳过/0失败（日志`/tmp/chessnext-root-test-m4-66-final.log`）；`flutter analyze --no-pub`无问题、`git diff --check`通过。根首次compact运行591通过/5跳过/2失败；定位为新字段增加垂直高度后，`piece_skin_images_test`两处旧测试点击滚动区外按钮。加入`ensureVisible`后相关套件8/8及完整根测试复跑通过。仅一个串行`flutter_tester`，结束无残留。

macOS复用既有PID50598/runner50125，通过`flutter attach --debug-url=http://127.0.0.1:61579/4bLZ1MhsyEk=/ --no-dds`同步1012ms、热重启8613ms；脱离后PID50598仍存活。全程未执行`flutter run`，没有新开chessNext。屏幕锁定，窗口人工视觉验收not run。M4-66已于`9c1470d feat(settings): 增加棋盘边距精确输入`单独提交。继续B24保存应用事务/几何差距、F27完整多语言和其他登录外缺口，不能声称F21或全站完成。

## 最新审计 E80 / F27 英语多页面覆盖（2026-11-05）

访客English实看设置目录、显示、棋盘/棋子及棋盘选择器、分析、标记、声音/音效选择器、操作快捷动作、关于、主页面与主菜单；所见静态文案均英语，主界面着法示例变拉丁ICCS。动态皮肤名/作者、品牌和法定备案链接仍中文/专名。切回简中，主题/色调/夜间开关恢复E79基线。只是抽样，不覆盖所有弹窗/错误/练习/导入导出，不称English完整。F27完整语言资源仍缺；当前项目未实现Locale选择器。E80追踪待文档提交。

## 最新实现 M4-64 / F27 / ADR-096

应用设置新增晴蓝/青玉/枫木/檀木/墨五色调选择，随确认写入schema1偏好并作用于Material 3 light/dark主题seed。色值是项目映射P；棋盘/棋子皮肤、夜间棋盘、标记颜色不改变；源站真实色值/全页面作用范围未知。F27不关闭，夜间棋盘及完整语言资源仍缺。

专项`flutter test --concurrency=1 test/application/preferences_controller_test.dart test/widgets/preferences_test.dart --reporter expanded`10/10。首轮因测试断言空值安全编译失败，修正测试断言后专项通过。根`flutter test --concurrency=1 --reporter compact`591通过/5跳过/0失败；`flutter analyze --no-pub`无问题，`git diff --check`通过。复用PID50598/runner50125，`flutter attach --debug-url=http://127.0.0.1:61589/dTmglI9Y_pk=/ --no-dds`同步1,035ms、热重启1,082ms，Ctrl-C后App仍存活；测试单串行flutter_tester，无多开App。屏幕锁定，人工视觉验收not run。

## 最新进展 M4-65 / F27 / ADR-097（未提交）

E79已实际验证：深色模式同一默认parchment棋盘，夜间开关关时浅米木色，开启后深棕；返回跟随系统、晴蓝、开关开、简中。M4-65新增本机默认开关；只对 dark + selected skin ID parchment + BoardSkin.parchment调色，色值P；浅色/关闭/jade/自定义皮肤不变。PNG/GIF快照记忆该偏好/皮肤ID，偏好旧schema缺字段兼容为开。F27依然开放：语言切换/完整多语言资源、参考站五色值/应用范围、非默认皮肤夜间条件未完成。

专项首轮19通过/1失败，后修正测试Theme状态复用后夜间专项2/2；设置/偏好/图像/GIF专项其它项通过。根`flutter test --concurrency=1 --reporter compact`593通过/5跳过/0失败，`flutter analyze --no-pub`无问题，`git diff --check`待最终检查。复用PID50598/runner50125：attach sync1,022ms、hot restart1,039ms；Ctrl-C脱离后应复核原App仍存活。锁屏本机窗口视觉not run；参考站实际状态已恢复E79前值。用户关心的测试残留：根测试串行单flutter_tester，测试后无残留；未运行flutter run/新App。

## 最新审计 E78 / F27（2026-11-05）

参考站显示与语言页观察五种色调、默认开启的“深色模式用夜间棋盘（只有默认棋盘有效）”及四种语言候选；色调青玉选择并复原晴蓝、语言菜单取消均有操作验证。色调影响范围/值、夜间显示行为和持久性仍U，未操作主题/夜间开关。审计追踪已更新，待文档提交。本机F27仍缺五色调、夜间棋盘设置和完整语言切换资源。

当前进程复核：ChessNext仅PID50598/runner50125；无`flutter_tester`残留。上一全量根测试最终591通过/5跳过/0失败，5跳过是Pikafish/NNUE官方环境缺失。后续根测试固定`--concurrency=1`；它运行一个flutter_tester而非启动chessNext。macOS验证复用既有实例attach，避免新App窗口。

## 最新实现 M4-63 / F31（已提交 e51388c）

问题/建议表单复用可选自建服务根地址；用户填写类别、描述、可选联系方式后必须审阅目标地址和完整数据并明确确认。只发显式字段，不含设备/浏览器/OS/棋谱/诊断信息；连接本身会向服务/托管层暴露来源IP。Dart自建服务以`CHESSNEXT_FEEDBACK_ROOT`显式启用私有收件路由，请求≤16KiB、最多5,000条、无公网读取/服务内IP存储；样例Nginx关闭access log并设每IP每分钟6次、突发5次。附件、版权投诉、外部交流和生产运营仍未交付，F31开放（ADR-095）。

定向7/7；服务端2/2、analyze/编译通过；根`flutter test --concurrency=1 --reporter compact`591通过/5跳过；根`flutter analyze --no-pub`及`git diff --check`通过。macOS复用PID50598/runner50125，attach同步1,054ms、热重启1,114ms，脱离后PID50598存活。仅一个串行根flutter_tester，无新chessNext。5跳过为缺少官方Pikafish/NNUE；屏幕锁定，视觉人工验收not run，生产自建服务未部署/未投递。

## 最新实现 M4-61（已提交 e880d69）

F31关于页接入可选自建发布根地址（默认空/完全离线），仅手动点击后GET版本清单，展示当前/历史更新说明与版本比较；HTTPS公网、loopback HTTP，5秒/2MiB，校验schema/UTC/排序/身份，区分不可达、无效和HTTP拒绝。无设备/用户/棋谱字段，不下载或安装程序包（ADR-093）。

专项13/13；根`flutter test --concurrency=1 --reporter compact`584通过/5跳过；`flutter analyze --no-pub`与`git diff --check`通过。macOS `flutter attach --debug-uri=http://127.0.0.1:61579/4bLZ1MhsyEk=/`复用PID50598/runner50125，sync1066ms、热重启1052ms，Ctrl-C脱离后PID50598仍存活。全量测试串行只启动一个chessNext仓库`flutter_tester`；另有PID70890/70651属于独立`tuner_flutter`，不是本项目测试或App。5个跳过因未配置官方Pikafish/NNUE环境。锁屏，视觉人工验收not run。

## 最新审计 E76 / F21,B24（2026-11-05）

棋盘编辑器四个边距字段DOM声明min0、左右max500、上下max550（O）。极值输入局部验证：左500时右跟到500，左0后右保持500；右输入0移焦显示8；上输入550带动下550，但下输入0后上保持550（V）。在未保存新建草稿恢复33/33/465/519后确认放弃；复核设置仍默认棋盘/棋子、100%、坐标开、倒置关。字段配对结果不对称，实际内部单位、统一约束/几何公式仍U；本机双点百分比预览是项目P，未映射站点值。

E77实操补齐右最大500、上最小0、下最大550；下输入550显示549.96，再按加号到550且禁用。恢复33/33/465/519后放弃草稿，设置检查无变化。范围/精度完整行为及几何公式仍U，详REFERENCE_EVIDENCE。

## 最新增量 M4-59（已提交 512915c）

F31交付本机离线“关于与开源许可”入口，显示chessNext、pubspec版本0.1.0+1、离线及无更新/反馈服务状态，依Flutter LicenseRegistry查看依赖许可。浏览不网络访问/改偏好。远端更新检查/日志、反馈/投诉及交流入口未实现，F31继续开放（ADR-091）。

专项`flutter test --concurrency=1 test/widgets/about_support_test.dart --reporter expanded`1/1；根`flutter test --concurrency=1 --reporter compact`575通过/5跳过；`flutter analyze --no-pub`无问题。复用唯一PID50598/runner50125，attach sync1201ms、热重启1061ms；锁屏未视觉验收。未产生新chessNext。

## 最新增量 M4-58（已提交 b3f9f36）

F21/B24本机棋盘设置新增“拖动格点校准”对话框，预览9列×10行网格，左右上/右下拖点分别按画布宽/高百分比编辑相应边；遵守现有1–99%和最小跨度55%约束。四个原滑杆仍保留。映射为项目P，不等同站点33/465读数或其未知耦合算法（ADR-090）；F21/B24及全站登录外目标均未关闭。

专项`flutter test --concurrency=1 test/widgets/piece_skin_images_test.dart test/widgets/board_geometry_editor_test.dart --reporter expanded`8/8；根`flutter test --concurrency=1 --reporter compact`574通过/5跳过；`flutter analyze --no-pub`无问题，`git diff --check`通过。首轮根测试570通过/5跳过/2失败，定位为预览直接嵌入后把旧偏移控件挤出视口；改为独立对话框后专项和根测试复通过。复用App PID50598/runner50125，VM attach同步1060ms、热重启1020ms；脱离后两进程仍存活且唯一。锁屏未做人工视觉验收。测试始终串行单`flutter_tester`，没有重复打开chessNext。

## 最新增量 M4-57（已提交 7b582ae）

AI单步新增开局/残局策略和自建BookService接线：默认best/残局开/离库10全回合；开局关/最佳/100cp内按权重随机、残局以非将棋子≤8判定、离库最多255均为P，源站规则U（ADR-089）。地址默认空，完全离线；设置注明单步会发送局面与完整历史。候选经本地合法着法复核，miss/异常/无效候选回退本机引擎；普通对弈和持续分析不走云库。

定向32/32；根`flutter test --concurrency=1 --reporter compact`572通过/5跳过；`flutter analyze --no-pub`、`git diff --check`通过。复用App PID50598/runner50125，attach同步1047ms、热重启993ms。macOS锁屏，窗口视觉未验；未启动额外app/并行测试进程。实现及研究追踪待独立feature commit。

## 最新增量 M4-56（已提交 7bf3b2d）

新增BookService领域端口及HTTP客户端适配器（ADR-088），精确请求开局/残局kind、FEN与完整历史；HTTPS公网/loopback开发地址约束，5秒超时、32KiB边界、协议/署名校验和类型化失败。显式传入endpoint才会请求；尚未接composition root、偏好设置、策略、缓存、合法着法校验或AI回退，不能称端到端云库。

HTTP专项4/4；根串行`flutter test --concurrency=1 --reporter compact`568通过/5跳过；`flutter analyze --no-pub`、BookService Dart analyze及`git diff --check`通过。纯端口/适配器改动，未启动或重启macOS app；串行测试仅1个flutter_tester、没有新增chessNext。

## 最新实现 M4-55（已提交 4f515e9）

按E71/F22,F23建立自建只读开局/残局云库查询服务端切片（ADR-087）：运营者可提供带许可/归属元数据的book.json；按类型、完整FEN和着法历史精确查询，返回候选着法、分值及权重。默认不附带任何棋库、不记录查询；包含限流式请求大小、清单结构及候选校验、示例配置、systemd/nginx部署参数。M4-56已有纯传输客户端但未注入App，且无实际数据集，因此不宣称云库端到端或全站对齐。

专项服务器测试12/12；根串行`flutter test --concurrency=1 --reporter compact`564通过/5跳过；`flutter analyze --no-pub`与服务端`dart analyze server/skin_catalog/lib server/skin_catalog/bin`无问题；`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server`成功；`git diff --check`通过。M4-55仅服务端，不需重启macOS；复用既有PID50598/runner50125，未启动新App。M4-56已补纯传输客户端，但尚未注入App。

## 最新实现 M4-54（已提交 1804040）

F22分析界面AI走棋现在有独立的0–20本机难度偏好、1/3/10秒预设、0不限时、0.5–600秒项目自定义时长及最大深度设置；难度按固定节点预算映射（ADR-086，P），不宣称等同参考站等级。M4-53提供单步操作并做文档/局面/树身份校验。参考站离库步数、开局/残局云库执行及真实等级算法未实现或未知，F22/F23仍开放。

M4-54专项24/24；根目录`flutter test --concurrency=1 --reporter compact`558通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。macOS复用唯一App PID50598/runner PID50125，attach同步1,090ms、热重启1,042ms；系统锁屏，人工视觉验收未做。根测试只运行一个`flutter_tester`，未启动新chessNext。

## 工作树与持续目标

HEAD `e880d69`功能提交，当前上下文/E76追踪有待单独docs commit。持续目标：对齐登录外所有可确认功能与设置；保留自建可替换在线后端和部署方案，不宣称全站完成。下一步继续F21格点/边距保存生命周期和其它设置审计/实现，再推进F31用户审阅数据后显式提交的自建反馈/版权流程、F27多页面语言等缺口。许可决策暂缓，不阻挡本地开发。

## 2026-11-05 / E72 F21棋盘几何审计

参考站既有“我的棋盘”编辑页复核左边距单步联动：33.0→33.5时右边距465.00→465.02；减回后退出并确认丢弃草稿，回设置页确认原显示状态。记录见`docs/research/REFERENCE_EVIDENCE.md` E72；只证明该字段单次联动，不证明全局几何公式。当前代码以四个独立归一化边距滑杆提供编辑，源站双蓝点拖动与坐标映射仍U，后续作为项目交互P设计，不把源站原始数值映射成项目百分比。

用户反馈测试曾重复打开多个chessNext。Flutter全量测试使用`--concurrency=1`；Mac功能验证复用既有App，通过VM Service `flutter attach`热重启，不执行新的`flutter run`。进程检查见唯一App PID50598；runner PID50125需在下一次macOS验证时重新核对。无后台flutter_tester。

## 2026-11-05 / E73 F21右下格点映射审计

E73在既有棋盘草稿对右下点向右下拖约10视口像素：右465→475、下519→530.52；近似反拖后右464.04/下519.54，不能精确复原。手动设回右465/下519并确认丢弃，复核设置回默认棋盘/棋子、100%/坐标开/倒置关。全局公式/增益/往返误差原因继续U。证据待中文docs提交；无业务代码改动。

## 最新审计 E70（2026-11-05）

F31参考站关于页只读观察到当前版本构建号929/47a59ac6及检查更新、更新日志、问题反馈、版权与投诉、讨论群入口。更新日志AX点击后截图/AX未见变化，结果仍U；未触发更新检查或外发反馈。证据已更新REFERENCE_EVIDENCE/矩阵/缺口/交互/追溯/待办；纯文档审计待diff check/commit。

## 当前交付 M4-52（已提交 73d2291）

本机应用设置可按线程×64 MB自动分配Hash，切换到手动可保留自选值；分析面板参数表单通过统一偏好控制器应用设置并关闭自动模式。真实EngineCapabilities/设备上限钳制，旧偏好缺字段按原手动Hash读取。专项10/10；根`flutter test --concurrency=1 --reporter compact`551通过/5跳过；`flutter analyze --no-pub`无问题；复用PID50598/runner50125 attach同步1086ms、热重启1055ms。Mac锁屏未人工视觉验收。测试全量时只有一个flutter_tester，未启动额外chessNext。

## 持续目标

继续F31与B25/F27及登录外全站缺口，不宣称全站对齐。在线能力仍为自建可替换后端并提供部署方案。
## 当前实现 M4-52（待门槛和提交）

按E69/F24增加本机线程×64MB自动Hash模式与手动切换；基于EngineCapabilities/设备约束钳制，显式分析参数变更回手动。新`autoHash`可选偏好字段；旧schema1配置缺省时保留手动Hash。设置/控制器专项`flutter test test/application/preferences_controller_test.dart test/widgets/preferences_test.dart --reporter expanded`10/10；根`flutter test --concurrency=1 --reporter compact`551通过/5跳过，`flutter analyze --no-pub`无问题，`git diff --check`通过。复用唯一App PID50598/runner50125，attach同步1086ms、热重启1055ms；锁屏未做人工视觉验收。门槛通过，代码/文档待本片单独中文提交。

## 最新审计 E69（2026-11-05）

访客高级分析页默认5线程/320MB；“解限”开关切换页面推荐上限10/512与1024/1984MB，线程5→6时自动内存320→384MB。仅UI操作，真实引擎能力U。纯文档审计已提交`417965e`。

## 持续目标与进程

继续B25/F27和登录外全站缺口，不宣称全站对齐。唯一macOS App PID50598/runner PID50125复用。根测试使用`--concurrency=1`只保留一个`flutter_tester`，不会启动chessNext GUI。
## 最新审计 E69（2026-11-05）

访客高级分析设置默认5线程/320MB；“解限”开关使页面推荐最大值从10线程/512MB变为1024/1984MB，5→6线程时自动内存320→384MB。复原开关及默认线程/内存。只验证页面联动，不代表真实引擎/设备资源上限；内存步进、手动边界及刷新/重启持久性U。证据已追加RE/矩阵/缺口/交互/追溯/待办，纯文档变更待diff check与中文提交。继续核对本机F24等价实现及全站剩余设置，不停在审计片。

## 当前交付 M4-51（已提交 3b688f4）

按E68将本机播放自定义范围对齐0.1–60秒，0.1特殊首档后每档0.5秒；根549通过/5跳过、analyze通过、macOS复用既有PID50598/runner50125热重启成功。锁屏未人工视觉验收。

## 进程纪律

当前复用唯一macOS chessNext PID50598及Flutter runner PID50125。`flutter test`仅启动flutter_tester，不创建桌面App；不要重复启动`flutter run`。
## 当前审计 E66–E68（2026-11-05）

E66操作验证左字段可减到0、左/上输入999后移焦分别夹限500/550，配对右/下值联动；其余独立边界和几何公式仍U。E67验证棋盘皮肤“保存”本次访客会话可回读修改值但不自动选中，“使用这套”才应用。E68验证源站播放自定义步时0.1–60秒、常规步进0.5秒及端点禁用，设置恢复预设2秒。E66/E67文档审计已提交b81e0ea；E68证据文档已提交4d31673。M4-51已实现本机0.1秒特殊首值、后续每步0.5秒至60秒，兼容历史≤30秒的100ms偏好。专项11/11，根549通过/5跳过，analyze无问题；macOS复用PID50598/runner50125热重启1,026ms，无新App；锁屏未人工视觉验收。M4-51代码及追踪待diff复核和中文feature commit。棋盘设置已恢复默认；临时测试皮肤因站点删除确认明确不可恢复，现等待用户对仅本轮创建样本的删除作答。继续B24和其它非登录功能/设置，不称全站完成。

## 当前审计 E64（2026-11-05）

访客临时棋盘皮肤编辑草稿验证边距stepper单击步距+0.5、左边距递增时右边距小幅联动，并采集一次左上格点拖动样本。AX边界只是语义声明，实际值域/完整几何公式仍U。已更新参考证据、矩阵、缺口、交互规格、追溯和待办；纯文档变更待单独提交。草稿已丢弃并恢复默认设置，用户原IAB tab1未触碰。

## 当前交付 M4-48（已提交）

`c8e4f43 feat(skins): 对齐棋盘缩放范围`已完成：根据E63把本机棋盘皮肤棋子缩放范围设为60–140%、整数步进。E64仅为审计，无代码改动，无需运行Flutter测试/分析。当前仍复用唯一macOS App PID50598和runner PID50125；不要另启实例。F21/全站设置继续未完成，继续按矩阵审计并推进，不在单片后停止。

## 当前交付 M4-49（已提交 4c795a8）

自建只读服务可选加载独立棋盘皮肤目录根（board-catalog.json + board-packages），新增/v1/board-catalog列表/详情/项目ZIP端点，现有棋子路径兼容。服务定向6/6；根flutter test 545通过/5跳过；服务端`dart analyze`及根`flutter analyze --no-pub`无问题。服务端增量未启动macOS客户端，唯一PID50598/runner PID50125不变。

## 当前交付 M4-50（已提交 31740d3）

棋盘皮肤库接入在线棋盘目录，含共享自建端点、搜索/排序/分页、24页结果缓存/离线标记、SHA与schema1 ZIP验证、许可确认和署名本机持久化。专项14/14；根548通过/5跳过；`flutter analyze --no-pub`无问题。复用PID50598/runner PID50125，attach同步后热重启953ms，无第二实例；Mac锁屏，未人工视觉验收。中文功能提交`31740d3`。测试使用flutter_tester，不会启动chessNext GUI。

## 当前审计 E63（2026-11-05）

访客临时棋盘皮肤编辑器通过鼠标拖动确认棋子缩放实际最低60%、最高140%，60%右拖一个小样本到61%；棋子面容变化，网格及边距不变（V/O）。139%只在贴近滑轨右端出现，继续越过轨道边缘到140%，中间指针映射仍U。未保存，确认丢弃后默认状态恢复；用户原标签1未触碰。已追加REFERENCE_EVIDENCE。

## 当前实现 M4-48（验证完毕待提交）

按E63/ADR-082把棋盘皮肤几何中的棋子专属缩放值域从80–120%改为60–140%、整数1%步进；旧数据不迁移、范围均仍有效。测试覆盖60/140通过，59/141拒绝。专项12/12；根`flutter test --reporter compact`544通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。复用唯一macOS PID50598以attach热重载38/1745 libraries，1390ms，无新App；人工窗口验收未做。单独中文commit待做。格点拖柄/边距范围和耦合仍U；F21/全站未对齐，继续后续清单。

## 最新审计 E62（2026-11-05）

临时访客棋盘皮肤编辑页的棋子缩放滑杆AX声明min60/max140、当前100（O），键盘End/ArrowRight未改变当前值，所以真实可达端点/步长仍U；两个格点拖柄无AX范围属性，边距完整范围及联动仍U。未更改数值/保存，确认丢弃后默认棋盘/棋子、100%、坐标开、对面倒置关恢复（V）。证据已追加REFERENCE_EVIDENCE/矩阵/缺口/追溯/待办。用户原IAB tab1未操作；临时tab2已回棋盘设置页。

## 最新交付 M4-47（2026-11-05）

已提交`15cb8d6 feat(skins): 支持棋盘皮肤包导入导出`，采用项目自有schema1 ZIP、四图层白名单和SHA/实图验证，导入确认后新ID并应用，不表示兼容站点包。专项20/20、根544通过/5跳过、analyze无问题。复用唯一App PID50598通过attach热重启907ms；未开启第二个App，`open returned 1`造成窗口视觉not run。之后继续F21/B24和全站未关闭缺口；棋盘草稿/站点导入导出语义仍U。

## 当前推进 M4-47 已实现待提交（2026-11-05）

刚提交M4-46 `4a64a19 feat(skins): 增加本机棋盘皮肤库`。继续M4-47：用户棋盘皮肤项目schema1 ZIP导入/导出，四层图片白名单、SHA/实图校验、8MiB压缩包/7MiB总图/512KiB单图边界、导入确认/新ID/失败回滚。专项20/20，根测试544通过/5跳过，analyze无问题，diff check通过。macOS复用唯一App PID50598/VM61589，attach后热重载+热重启907ms；未启动第二个App，窗口视觉未验。此片文档待diff复核和单独中文commit。站点未知ZIP/文件夹、保存与编辑脏态及E59–E61几何语义仍U；F21/全站未对齐。commit后继续B24和全站剩余缺口，不停在本片。

## 当前推进 M4-46（2026-11-05）

工作树正在实现F21/B24本机用户棋盘皮肤库（验证完毕待提交）：创建复制当前皮肤格网和图片并即时应用，支持选择/改名/删除，用户格网独立保存且进入主盘、编辑器、PNG/GIF。根`flutter test --reporter compact`541通过/5跳过；`flutter analyze --no-pub`无问题。首轮唯一失败为已有piece皮肤Widget测试使用不唯一的String下拉框查找器，按ValueKey修复后定向6/6并全量通过。测试期间未启动chessNext App。唯一`flutter run -d macos --no-pub` Build/Sync成功，App PID50598、VM `127.0.0.1:61589`；`open returned 1`，窗口视觉验收未完成，保留runner复用。E59–E61源站几何持久化、包导出、草稿语义和旋转实际效果仍U；F21/全站未完成。ADR-080与追踪文档已更新，本片commit后继续B24，不因M4-46停工。

## 最新审计 E61（2026-11-05）

F21/B24在访客临时标签新建棋盘皮肤页不改参数直接“保存”，页面生成本地ID并显示“已保存”；另一同浏览器标签打开“我的皮肤”仍见“我的棋盘”（E61，V）。随后删除仅此审计生成的皮肤，复核默认棋盘/棋子、100%、坐标开、对面倒置关仍保持。该证据只证明同浏览器标签间列表可见，不证明reload/重启持久性；编辑脏态、实际几何数据保存、导出仍U。用户原标签1未触碰；临时标签2留在恢复后的`#/settings/board`，本轮结束会自动清理。当前无运行的chessNext/Flutter runner进程；需要macOS验收时再单独启动一个并复用，不重叠实例。证据更新于REFERENCE_EVIDENCE E61。

## 最新审计 E60（2026-11-04）

F21/B24在访客临时标签新建棋盘皮肤草稿后点击“使用”，实际生成本地`local-ecad26d8-8bd9-4013-97a2-a427fb3084e5`并立即应用，编辑页显示“已换上”/“使用中”，列表出现“我的棋盘”（V）。审计后先应用默认棋盘，再删除仅由本次操作产生的皮肤；复读设置确认默认棋盘/棋子、100%、坐标开、倒置关。重载/重启持久化仍U；用户原tab1未动，临时tab10留在恢复后的棋盘设置页（CUA无关闭接口）。证据E60。仅文档改动，未跑测试/analyze，未启动macOS。

## 最新交付 M4-45（2026-11-04）

F21/B24按ADR-079支持本机用户皮肤集合ZIP：项目自有外层包2–16项/≤8MiB，嵌套单皮肤schema1包；全包路径、SHA、图片格式先校验，用户可勾选多套导出、导入选择子集；重名/容量不足项禁选，许可署名展示并保留，批次图片暂存失败全回滚，成功使用新ID并选中第一项。定向14/14；根`flutter test --reporter compact`535通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。复用PID6602 runner热重载7/1740 libraries（2498ms），PID6847仍唯一App；根测试未打开App。人工macOS窗口视觉未验。源站多套ZIP格式仍U，不声称兼容；F21/全站不完整。

## 最新交付 M4-44（2026-11-04）

F21/B24按ADR-078为自建目录实现离线查询缓存：仅缓存通过schema校验的成功页，SHA-256查询键、每页≤2MiB、最多24页、临时文件替换；请求先联网，超时/传输不可达才按精确查询键回退，页面标“离线缓存”和抓取时间。HTTP拒绝/无效响应不使用旧页；包导入许可流程不变。定向9/9；根`flutter test --reporter compact`529通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。复用runner PID6602热重载Reloaded 8/1739 libraries（2161ms），App PID6847仍唯一实例；根测试未启动App。服务真实托管和UI人工现场点选未验证，F21/全站不完整。

## 最新审计 E59（2026-11-04）

F21/B24新建棋盘皮肤编辑页显示格点50/50、边距33/33/465/519、棋子缩放100%，并有重命名/导出/使用/保存入口；均只记录可见状态，没有操作按钮。即便未改控件，返回仍提示“放弃修改”；确认后回`#/settings/board`，默认状态保持。保存/使用/导出结果及空草稿dirty原因仍U。证据见`REFERENCE_EVIDENCE.md` E59。用户原IAB tab1未动，独立审计tab10留在已恢复棋盘设置页。

## 已提交 M4-43（2026-11-04）

F21/B24新增自建目录服务→HTTP客户端→分页搜索→有界下载/SHA→项目包codec→皮肤库许可元数据持久化的loopback集成验证。样包由测试自行生成，不含参考站资源。专项1/1；根`flutter test --reporter compact`526通过/5跳过；`flutter analyze --no-pub`通过。`flutter_tester`运行期间未启动新App；复核唯一runner PID6602/App PID6847。服务部署到真实托管环境及UI人工点选验收仍未做，F21/全站不完整。M4-43提交`c6bc08e`。

## 已提交 M4-42（2026-11-04）

F21/B24完成在线皮肤包有界下载/摘要与schema1图片包二次校验、许可署名二次确认、本机安全导入；用户皮肤定义持久保存许可证和署名并随导出/复制保留。定向12/12，根测试525通过/5跳过，analyze通过。复用runner PID6602/App PID6847，热重载确认Reloaded 39/1738 libraries，未启动新App。人工macOS视觉验收受`open returned 1`影响未做。M4-43补充了自制样包loopback集成测试；缓存策略、真实部署和UI人工验收仍待推进。

## 已提交 M4-41（2026-11-04）

F21/B24目录浏览UI与自建URL偏好已实现：访客可保存HTTPS自建目录地址（loopback允许HTTP）、搜索/五类排序/分页刷新，查看作者、点赞、许可和署名；空目录、连接失败/HTTP/响应错误分别提示，点击详情不会自动下载/导入。专项8/8、根524通过/5跳过、analyze通过。macOS唯一runner PID6602/App PID6847、VM `127.0.0.1:53684` Build/Sync成功，`open returned 1`，未完成人工视觉检查。M4-41提交`38886a5`；下载/哈希校验/安全导入见M4-42。

## 已提交 M4-40（2026-11-04）

F21/B24按ADR-075完成只读在线皮肤目录客户端传输端口：公开DTO、分页/搜索与五类排序、许可/署名/哈希解析、8秒超时、2MiB响应上限、仅HTTPS远端/loopback HTTP，以及断网/拒绝/无效响应分类。定向3/3，根测试522通过/5跳过，analyze无问题。最初runner PID2226/App PID2479未能热重载确认，后替换旧实例并运行`flutter run -d macos --no-pub`，Build/Sync成功，App PID5725、VM `127.0.0.1:52805`；`open returned 1`，未做窗口视觉验收。当前只保留这一组实例。UI、服务器URL设置、缓存、下载/导入尚未接入，F21继续开放。

## 已提交 M4-39（2026-11-04）

F21/B24按E42、ADR-074实现自建公开只读棋子皮肤目录服务和部署说明。服务支持固定包ID、许可/署名元数据、显式搜索/分页与默认/点赞/名称/作者/最新排序，ZIP SHA-256校验；不引入登录、上传、用户点赞写入或网站资源。默认目录为空。Flutter客户端/服务器地址/缓存/离线交互尚未接入，F21及全站仍开放。

定向5/5；根`flutter test --reporter compact`519通过/5跳过；`flutter analyze --no-pub`无问题。已离线解析依赖、编译独立Dart可执行文件，并在macOS本机启动后以curl验证health和空目录结果。没有运行`flutter run`、没有新增/停止chessNext实例；原runner PID2226和App PID2479仍运行。首轮测试页码夹具、if大括号及服务包分析配置问题均记录并修复后复跑通过。M4-39提交`ae9858e`。下一片接入皮肤库UI与用户可配置服务URL，显示许可/署名和明确离线状态，再完成安全下载导入。

## 最新审计 E58（2026-11-04）

F21/B24临时棋盘编辑草稿观察格点、边距和缩放：默认格点50/50、四边33/33/465/519、棋子缩放100%；拖左上蓝点约一格后左/上/右/下显示85.50/87/465.18/519.09；缩放轨道视觉两端当次显示60%/139%，右端再按右方向键无变化。拖点公式、单位、确切范围/缩放对象仍U；退出确认丢弃后默认设置已恢复，临时标签已关闭。

E58及对应gap/交互规格/ADR-054证据边界已提交`f46aea8`。按B24继续剩余用户皮肤与在线可替换后端/部署工作；F27全站翻译资源尚未覆盖，全站仍未对齐。

## 最新交付 M4-38（2026-11-04）

F27/B25按E57、ADR-073增加“棋盘居中/棋盘靠左”本机布局预设。旧偏好缺字段默认居中；设置应用后持久化。宽屏靠左模式重排棋盘、记录/操作与侧栏三列，并提供棋盘宽度拖动、键盘、Slider语义和重置。项目布局值域为P；源站完整断点/宽度算法仍U。F27其他语言/翻译资源未完成，登录后能力仍按授权排除，全站尚未对齐。

定向测试10/10；根`flutter test --reporter compact`514通过/5跳过；`flutter analyze --no-pub`无问题。macOS `flutter run -d macos --no-pub` build/sync成功、VM `127.0.0.1:49754`，但系统锁屏导致`open returned 1`、无法置前，未做人工视觉验收。已提交`1aceb59`。仅当前runner会话运行，未因测试打开App。继续审计F27全站语言资源和全站未完成设置，不停在此功能。

## 最新审计 E54（2026-11-04）

F27访客显示语言实操：English选择会立即翻译当前设置页，返回设置首页再进入仍保持英文；切回简体中文恢复。证据E54已追加到参考证据、功能矩阵/缺口、交互规格、待办和追溯。仅确认本次标签页内即时效果及页间保持；刷新/重启、繁体/越南语覆盖和全站完整翻译仍U，因此尚未开放不完整语言或宣称F27完成。用户原IAB标签1未操作；临时审计标签4留在设置首页且已恢复简体中文。

E54审计已提交`149a153`。继续B25/F27及剩余全站缺口，不因一次审计停下。

追加E55：`#/settings/operations`默认云库，并单独列出“大师谱”来源选项；此前E50将其写入四面板描述需校正。点选后主面板切为大师对局筛选，当前局面提示无谱；过滤弹层有范围/搜索/步数/胜负筛选，未执行查询。已切回默认云库。请求/查询结果、刷新/重启保持和离线边界U。临时标签4仍在操作设置页，默认值保留。

追加E56：English切换后显示设置页reload仍为英文；繁體该页有简繁混用，越南语该页有译文并将示例记法改为拉丁字母。只覆盖该设置页，不说明其他路由完整。两临时标签均恢复简体中文并关闭；原始标签1未动。F27完整本地化仍未实现。

追加E57：1280×720下显示设置“棋盘靠左/棋盘居中”实际改变主界面列结构；靠左时棋盘/着法在左、AX棋盘宽39；居中恢复左着法/中央棋盘/右侧引擎云库和22/70/55/55。已恢复居中并关闭临时标签。断点及持久化未知；本机当前固定三栏尚无此预设。

E56审计提交`a5df531`；E57审计与矩阵提交`d3176c6`。`git diff --check`通过，待最终状态核对。当前macOS锁屏，CUA无法读取原生窗口；只改了审计文档，没有运行测试/analyze或启动App。下一步继续拆解E57“棋盘靠左”的真实列模型并对照`ResizableWorkspace`，再实施本机偏好；保留宽度断点、窄窗/大字号验收，不把项目尺寸映射冒充源站。

E54/E55审计文档提交依次为`149a153`、`2ee7dc9`、`649d8fa`、`a446786`；E56已提交`a5df531`。审计未改代码，因此未运行测试/analyze，也未启动macOS。`pgrep`再次确认唯一现存runner PID86855及App PID87104；CUA报本机锁屏，未做前台检查。`flutter test`不负责启动App，本轮也没有调用测试命令。临时源站标签均关闭，用户标签1仍在设置页。

## 最新交付 M4-37（2026-11-04）

按E52/E53、ADR-072将B26/F20从两栏扩为≥1280dp三栏：左操作/记录、棋盘、右侧栏上下区域。四个48dp分隔抓手可拖动，键盘方向键与Slider无障碍增减动作可调；“重置布局”恢复22/70/55/55。项目P范围：左栏19–34、棋盘占余宽60–80、上下分区左25–72/右25–75；空间约束保留至少492dp棋盘及220dp右栏。比例为当前工作区内存态。参考站完整边界/算法、跨尺寸/触屏/重启行为仍U。

代码`lib/features/workspace/resizable_workspace.dart`；专项`test/widgets/resizable_workspace_test.dart`覆盖三栏装配、四隔条拖动、真实pane尺寸变化、重置和读屏增量。最终专项`flutter test test/widgets/resizable_workspace_test.dart --reporter expanded`2/2；根`flutter test --reporter compact`512通过/5跳过（缺官方Pikafish/NNUE环境），`flutter analyze --no-pub`无问题。复用唯一macOS runner PID86855热重载成功（Reloaded 3 of 1736 libraries，2231ms），App PID87104；测试没有启动App，也未新增实例。CUA人工拖动/键盘验收未做。

B26剩余：源站完整尺寸/纵横触控/持久化行为未知，原生置顶/独立窗口语义U。全站仍未对齐，后续继续审计F20语言/其它设置和其余功能缺口。


## 上一交付 M4-36（2026-11-04 14:03 CST）

M4-36 `5048330 feat(workspace): 增加棋盘悬浮工作区`按ADR-071、F19/B26实现本机悬浮工作区（临时进程状态）：AppBar“显示模式”在分析/悬浮窗之间切换；悬浮态隐藏常规侧栏，居中显示棋盘，底部有引擎状态/设置/悔棋/更多；更多菜单有新局、翻转、编辑、退出。未模拟OS置顶或独立窗口，站点这部分仍U。专项`flutter test test/widgets/floating_workspace_test.dart --reporter expanded`通过；根`flutter test --reporter compact`510通过/5跳过；`flutter analyze --no-pub`无问题。现有macOS runner PID86855热重载成功（Reloaded 2 of 1735 libraries）；PID87104仍唯一App。CUA能截取当前标准工作区并看到显示模式入口，但点击报`noWindowsAvailable`，悬浮态macOS现场交互未验；以widget测试作为行为证据。没有新启动App。

M4-36代码与功能文档已提交`5048330`；本段状态记录随后更新。之后B26继续实装4个参考分隔条与重置（E52/E53）；左栏宽/棋盘宽/左侧上下分区/引擎云库上下分区要单独映射，不能把现有2栏直接称三栏完成。F19原生置顶/跨窗口仍U。全站未对齐。

本轮持续推进用户授权的登录部分外全站范围；单功能提交，不把项目映射冒充站点对齐：

- M4-32 `d476409 feat(settings): 增加棋谱定时播放与步时设置`（ADR-067）：从当前游标沿选定线路定时播放至末尾停止；步时0.5/1/2/3秒及0.5–30秒自定义/100ms步进，本机持久化。E50源站起点/循环/自定义范围仍U。
- M4-33 `cce3558 feat(settings): 支持棋谱栏与播放按钮显隐`（ADR-068）：两个独立偏好；隐藏播放入口会停止播放。
- M4-34 `f3a6517 feat(settings): 增加侧栏面板切换栏`（ADR-069）：开启后在本机对弈/分析/复盘/候选四面板中切换一个，关闭恢复堆叠布局。项目分组P。
- M4-35 `df8376d feat(settings): 配置棋盘长按与右键菜单`（ADR-070）：本机动作白名单支持复制FEN、复制当前线路中文着法、文字/剪贴板导入、文字导出、本地保存。未实现东萍UBB、局面链接/搜索。

M4-35定向偏好/菜单测试10项通过；根`flutter test --reporter compact`509通过/5跳过（依赖官方Pikafish/NNUE）；`flutter analyze --no-pub`无问题。macOS Debug Build/Sync成功，PID87104、VM `127.0.0.1:60069`；日志报告`open returned 1`未能置前，但Flutter设备同步及VM连接成功。只保留一个runner及其App。Widget `flutter test`运行Flutter测试宿主，没有启动`chessNext.app`；多实例来自反复执行`flutter run -d macos`，后续保留交互式runner复用。`flutter_tts`仍有SwiftPM未来兼容warning。未做人工窗口/右键视觉验收。

E52/E53继续B26：实际切换/退出悬浮窗；观察到4个分隔条。两处上下分区55→58可拖动，观察值边界左侧25/72、右侧25/75；“重置布局”使两者回55。左栏拖动联动棋盘宽，边缘值19.132652282714844，重置恢复22/70。完整源代码范围/跨屏幕几何仍U。临时标签已关闭，用户原`#/settings`标签未改。F19原生窗口置顶/独立窗口语义仍U。B25还缺E50源站策略核验；F27完整本地化、F21在线自建可替换目录/部署以及全站其它未完成项仍开放。全站未对齐。

E52已提交`bed1456`，E53/矩阵/待办/交接提交`a308cb0`，校准提交`1405f32`。M4-36已提交`5048330`。之后继续实现F20分隔条及全站差距。

## 最新交付 M4-31（2026-11-04 03:06 CST）

按用户“继续推进登录部分外全站功能/设置”授权推进F20/B25：E49记录参考站语言候选简体中文/繁體中文/Tiếng Việt/English；E50记录操作设置播放时长、棋谱栏、四面板排序显隐、长按/右键快捷菜单入口和开关。只观察候选/入口，没有改源站偏好；真实语言切换、设置持久化与菜单动作保持U。审计文档提交`e8b6017 docs(audit): 记录语言与操作设置证据`。

M4-30按ADR-065实现四类项目侧栏卡片（对弈/分析/复盘/候选）拖动重排，偏好schema1严格完整排列，迟到读取合并；`0053171 feat(settings): 支持侧栏面板顺序调整`。M4-31按ADR-066再实现四卡片独立显隐，全部隐藏仍可从AppBar设置恢复，空可见集合合法、旧字段默认全开、异步读取合并；`4a02127 feat(settings): 支持侧栏面板显隐`。项目面板映射是P，不宣称等同E50站点分组。

专项偏好/真实主界面测试7/7；最新根`flutter test --reporter compact`505通过/5跳过，5项依赖官方Pikafish/NNUE环境；`flutter analyze --no-pub`无问题；最新`flutter run -d macos`Build/Sync PID78894、VM `127.0.0.1:51984`，runner会话21286仍在。flutter_tts SwiftPM未来兼容warning。CUA读窗口超时，人工视觉验收未做。其余E50播放时长/播放按钮/棋谱栏/面板切换栏/长按右键菜单、F27完整本地化、B24自建在线皮肤目录和部署，以及其它全站可确认缺口仍待持续推进。

## 最新交付 M4-29（2026-11-04）

B23/F28 棋步移动动画（ADR-064）：主棋盘在走棋身份变化时从起点到落点移动棋子；动画速度复用关/快/标准/慢项目时长，Reduce Motion和关档静态。动画中隐藏落点棋子视觉但保留棋盘语义/命中；不延迟棋谱/规则提交。编辑器/分析预览/PNG/GIF静态。定向5/5；根`flutter test --reporter compact`503通过/5跳过；`flutter analyze --no-pub`无问题；最终`flutter run -d macos`Build/Sync成功PID74615/VM `127.0.0.1:64108`。CUA窗口读取超时两次，人工视觉验收未做。已提交`177abff feat(board): 增加棋步移动动画`，补充边界已提交`759970b test(board): 覆盖移动动画速度边界`。源站动画对象和速度映射仍U；F28未完成。

## M4-28（2026-11-04）

B24/F21项目schema1皮肤包文件夹导入（ADR-063）：macOS选择已解压目录，仅接受根`skin.json`及`images/<槽位>.png|jpg`，拒绝未知条目、链接和额外层级；单文件≤512 KiB、最多14图/累计7 MiB、清单≤64 KiB/临时ZIP≤8 MiB，复用M4-27完整验证/确认/新增流程。格式为项目P，站点文件夹格式仍U。专项2/2；最终根`flutter test --reporter expanded`498通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync启动PID71234/VM `127.0.0.1:59893`。首次紧凑根测试出现1次失败，未能复现，expanded复跑全通过。已提交`a807155 feat(skins): 支持导入本机皮肤文件夹`。

M4-27已提交`07eb534 feat(skins): 安全导入本机皮肤包`。最终根测试496通过/5跳过、analyze无问题；macOS Build/Sync PID69107/VM `127.0.0.1:56731`。文件选择面板未人工验收。

## M4-27（2026-11-04）

B24/F21项目皮肤包ZIP安全导入（ADR-062）。仅接受本机schema1单皮肤包。详见`07eb534`；根496通过/5跳过，analyze无问题，macOS Build/Sync PID69107/VM `127.0.0.1:56731`。站点ZIP行为仍U。

## M4-26（2026-11-04）

B24/F21用户皮肤ZIP导出（ADR-061）：本机定义与14槽PNG/JPEG图片、固定路径、SHA-256清单一同压缩；复用图像校验，最多14图/7 MiB源图/8 MiB ZIP；macOS系统保存面板、原子二进制写入，取消不写。archive 4.6.0 MIT已登记直接依赖。专项编码/保存4项通过；根`flutter test --reporter compact`492通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync启动PID67175/VM `127.0.0.1:54273`。E43导出仅O，源站包格式/操作结果仍U；未人工操作系统保存面板。代码文档待独立提交。下一安全ZIP/文件夹导入，再在线目录与部署；F21/全站不完整。

## M4-25（2026-11-04）

B24/F21用户皮肤独立阴影（ADR-060）：用户定义持久化完整阴影值，新建复制活动皮肤或内置预设值；设置仅更新当前用户项，不污染基础预设/其它用户皮肤。主棋盘/编辑器/PNG/GIF快照都用所选用户项值；值域沿用ADR-056项目P，E43精确边界/算法仍U。专项22/22，根`flutter test --reporter compact`488通过/5跳过，`flutter analyze --no-pub`无问题，`flutter run -d macos`构建/同步启动PID65664、VM `127.0.0.1:51711`。无人工视觉验收。已提交`1589a60 feat(skins): 支持用户皮肤独立阴影`；下一处理用户皮肤导出与安全导入包，随后在线目录及部署设计。F21/全站仍不完整。

## M4-24（2026-11-04）

B24/F21本机皮肤库搜索/排序/选择：回车提交名称搜索，默认/名称/最近创建排序，选择即保存所选ID并关闭；赞数/作者排序未假造，等待在线元数据。根488通过/5跳过、analyze无问题、macOS PID64446/VM `127.0.0.1:49993`。已提交`f59a884 feat(skins): 增加本机皮肤库搜索排序`；窗口视觉验收未做。继续F21/全站未对齐。

## M4-23（2026-11-04）

B24/F21用户棋子皮肤独立大小/位置（ADR-059，项目P）：用户皮肤分别记忆80–120%比例、X/Y±8%格宽，每1%步进/默认100%、0偏移；创建时复制当前项参数。设置滑杆/方向键按当前自定义ID写回目录，内置两预设仍使用原偏好字段。主盘/编辑器共享，PNG/GIF捕获冻结独立参数；交点命中保持原逻辑。E43对应控件和单步有观察，但完整边界、保存/使用/导出结果仍U。另修启动时先恢复偏好、后校验本机皮肤目录的顺序；失效自定义ID回退基础预设。

定向参数/快照/棋盘皮肤测试19/19；最终根`flutter test --reporter compact`488通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync成功PID63084、VM `127.0.0.1:64399`。5项跳过依赖本机官方Pikafish/NNUE；flutter_tts有SwiftPM未来兼容warning。未做窗口人工视觉验收。已提交`c3b9dd2 feat(skins): 支持用户棋子大小位置独立调整`；继续F21其余设置与全站差距，不宣称全站已对齐。

## M4-22（2026-11-04）

B24/F21本机用户棋子皮肤目录：新增本机持久化皮肤ID/名称/基础样式定义，可从当前选择复制图片覆盖，新建/选择/重命名/删除；用户图片按ID隔离并克隆源文件保持格式，删除当前用户皮肤回到基础内置样式。目录上限64套、清单64 KiB、名称32 Unicode码点为项目P（ADR-058）。用户皮肤目前共享基础样式的大小/位置/阴影设置；搜索/排序/导出、ZIP/文件夹导入、在线目录仍待办。E42/E48只观察入口/说明，实际导入与覆盖仍U。

专项目录测试3/3；既有图片与棋盘设置专项10/10、9/9；根测试484通过/5跳过；analyze无问题；macOS Debug PID59671/VM `127.0.0.1:59146`。已提交`b83193e feat(skins): 支持本机多套棋子皮肤`。E42/E48仅观察入口/说明，ZIP/文件夹实际导入U。

## M4-21（2026-11-04）

B24/F21本机批量棋子图片导入：多选PNG/JPEG、14张/7 MiB批次限额（P）、预览唯一槽位映射、整批预检与逐槽可重试保存。E42只观察入口，源站导入成功/覆盖策略仍U；ZIP、文件夹在M4-22后仍未实现。专项10/10、根481通过/5跳过、analyze无问题、macOS PID56134/VM `127.0.0.1:53841`，窗口人工验收未做。已提交`107e372 feat(skins): 支持批量导入棋子图片`；E48说明证据提交`ffbf362`。

## M4-20（2026-11-04）

B24/F21本机棋子皮肤阴影编辑：按圆章/方章预设独立保存无/柔和/明显、方向、距离、模糊、浓淡，并投影至主盘/编辑器及PNG/GIF静态快照。E43可见字段与一次柔和参数示例，但范围、算法和保存/使用语义仍U；项目选定角度0°–359°、偏移和模糊0%–20%格宽、浓淡0%–100%并标P（ADR-056）。定向、快照与设置测试通过；根478通过/5跳过，analyze无问题，macOS构建启动PID54316/VM `127.0.0.1:51653`。CUA窗口视觉检查not run。已提交`549d807 feat(skins): 编辑本机棋子阴影`；继续F21及全站仍未对齐。

## 最新交付 M4-19（2026-11-04）

自定义落点标记图片旋转：开关按BoardSkin持久化；仅自定义落点图在末步身份变化时旋转一周后静止，同身份重建不重播；速度遵循AnimationSpeed，Reduce Motion立即静止。首次挂载保持静止，起点图/默认标记不受影响，PNG/GIF仍是静态快照。E45只证实参考站开关0→1，源站实际效果和时序仍U；项目行为见ADR-055。专项与偏好UI共15项通过，根475通过/5跳过、analyze无问题；macOS构建启动PID51661/VM `127.0.0.1:63351`。CUA确认进程运行但读取应用窗口超时，人工视觉验收not run。已提交`1e5f192 feat(skins): 增加落点图片旋转`。F21及全站仍未对齐。

## 已交付前序 M4-18（2026-11-04）

棋盘几何：每种本机棋盘预设独立归一化格网四边偏好；四个0.5%步进滑杆、每边1%–99%、横纵跨度至少55%、恢复默认。棋盘预设另有80%–120%/步1%棋子面容比例，与全局及PieceSkin比例相乘。统一变换覆盖棋盘图层/格线/棋子/标记/分析层；点击按变换命中原逻辑交点；坐标路数标签按相同左右端点排布；PNG/GIF快照冻结几何。项目值域/算法P，不代表源站规格。根473通过/5跳过，analyze通过，macOS构建启动PID50585/VM `127.0.0.1:61180`；CUA窗口读取超时，人工视觉验收not run。详ADR-054/TRACEABILITY/SESSION_LOG。
## 最新交付 M4-17（2026-11-04）

F21/B24本机棋盘图片图层：按每种BoardSkin支持棋盘背景、起点、落点、选中框四种PNG/JPEG图层逐项替换/恢复；本机有界校验与文件仓库；设置入口Material 3；主盘/编辑器同源渲染，PNG/GIF快照冻结图像。定向3/3；根`flutter test --reporter compact`469通过/5跳过；`flutter analyze`无问题；macOS app成功构建/同步，VM `127.0.0.1:50487` PID44785，但`open returned 1`前台失败，未人工视觉验证。已提交`c7e3151 feat(skins): 支持本机棋盘图片图层`。详ADR-053/TRACEABILITY/SESSION_LOG。E44网页保存/替换成功仍U。E45核落点旋转switch 0→1但无图时动画仍U；E46重复左stepper三次，33→34.5、右边距联动约0.06，其余范围未知。两次均丢弃草稿并复核设置默认恢复。棋盘几何审计/设计已记录ADR-054；下一步按该项目提案实现独立几何切片，旋转时序另定，之后继续皮肤列表/导入；F21及全站未完成。截止2026-11-04 Asia/Shanghai：HEAD为本次文档提交，工作树干净，较`origin/main` ahead 6；macOS Debug app PID44785仍运行，`flutter run -d macos` runner PID44412仍在前台会话；IAB审计草稿均已丢弃，不依赖临时浏览器状态。

## 最新交付 M4-16（2026-11-03）

本机棋子预设位置微调：每个预设各自记录X/Y，视觉方向键按棋格宽1%步进、±8%有界；自动对正回0。仅画面平移，不改变逻辑交点/命中区域；PNG/GIF捕获。根466通过/5跳过，analyze0；macOS run PID33743/VM `127.0.0.1:64032`。已提交`ff9feb1 feat(skins): 支持本机棋子位置微调`。

## M4-15（2026-11-03）

E43审计棋子皮肤大小/位置/阴影/图片页和取消草稿：见REFERENCE_EVIDENCE。M4-15为圆章/方章分别持久化80–120%比例，叠加全局棋子缩放，使用M3快照。根464通过/5跳过，analyze0；macOS run PID32670/VM `127.0.0.1:63024`。已提交`9a4001b feat(skins): 支持本机预设棋子缩放`。位置/阴影编辑和保存/使用/导出边界未闭合。

## M4-14（2026-11-03）

F21/B24按14类棋子本机替换PNG/JPEG，含Material3预览/逐槽替换/恢复、512 KiB/1024边长/1MP限制、校验及本机应用支持目录保存，并传递至PNG/GIF快照。专项控制器/仓库4项与棋盘映射Widget1项通过；根测试461通过/5跳过，analyze0；`flutter run -d macos`构建并启动，VM `127.0.0.1:61522`，PID31311。已提交`a755228 feat(skins): 支持本机替换棋子图片`。F21仍缺ZIP/多选/文件夹导入、棋子编辑几何、棋盘图片、皮肤管理及在线目录；详B24/ADR-050。

## M4-13（2026-11-03）

F21/B24增加本机棋子样式“传统圆章/方章墨韵”；主盘/编辑/PNG/GIF共用并持久化。“随棋子皮肤”走棋音效按当前样式解析音效1/2，试听和摘要同步，自定义音效仍优先。根测试456通过/5跳过、analyze0；macOS音频integration 3/3；最新`flutter run -d macos`构建/同步成功，VM `127.0.0.1:60040`、PID29670。M4-13已提交`4c94f6b feat(board): 支持本机棋子皮肤预设`。F21皮肤清单、图片导入和编辑器仍缺。E41/E42记录了源站观察/交互。

M4-12 已提交`de9de01 feat(board): 增加离线棋盘配色`：宣纸木色/松石青贯通主盘/编辑/PNG/GIF；全量453通过/5跳过，analyze0；macOS PID27652。

M4-11 已提交`eb44677 feat(board): 支持对面棋子翻转显示`：偏好默认关闭、按视觉上方阵营旋转180°字形，覆盖主盘/编辑/PNG/GIF；根450通过/5跳过、analyze0。该轮macOS open曾报前台异常，后同步/VM成功。

## M4-09 与 M4-10（2026-11-03）

F28/B23新增按事件本机导入自定义音效：受限WAV PCM/IEEE-float或MP3 Layer III，512KiB/5秒，独立替换、试听、恢复默认；目录和清单路径受控，用户取消不改现值。专项5/5，macOS集成2/2，根 `flutter test --reporter compact` 446通过/5跳过（缺官方Pikafish环境变量），`flutter analyze` 无问题。`flutter run -d macos` 已启动PID21638，VM `127.0.0.1:52467`。交付提交见git log。浏览器证据E37/E38，参考站导入成功仍未知。下一按B23推进音效方案或棋子动画范围审计；F28仍未完成，全站未完成。

M4-10 / F28/B23：走棋事件音效1/2/随皮肤三选及各自试听，sound2为原创本机音；偏好持久化；吃子等其他事件仍使用默认音效。自定义文件存在时优先，内置方案禁用直至恢复默认；当前没有可切换棋子皮肤，“随皮肤”暂映射默认音效1并有明确提示，F21皮肤关联未完成。单测5/5、macOS集成3/3、根446/5 skip、analyze0、`flutter run -d macos`成功 PID24870/VM `127.0.0.1:54576`。参考站证据E40。交付提交见git log。后续B23处理皮肤声音联动/其它动画范围；仍未完整对齐F28及全站。

2026-11-03 Asia/Shanghai。完整对标仍在开发，不能宣称全部对齐。历史切片状态已归档history/2026-11-02-before-piece-size-state.md，验证详planning/TRACEABILITY和SESSION_LOG。

## 授权与门槛

用户已明确扩展最初调查授权，持续业务实现、实际macOS运行；每功能flutter test+flutter analyze通过后中文Conventional Commit，所有可确认功能对齐后再交审查。在线选自建可替换后端并提供部署方案，离线优先仅为顺序。许可决定暂缓不挡开发，继续登记来源，不复制参考资源/棋谱库。没有分代理授权。

## 当前交付

- 纯Dart棋树统一2000节点预算（含根），所有新增类型化容量拒绝；满谱已有复用/导航/评注/保存可用，删除后可新增。AI容量暂停解锁保留引擎，候选与PV原子拒绝，4MiB字节门槛独立K10。
- 纯Dart规则/FEN/合法着法与自将照面/将死困毙/独立编辑语义，历史长将长捉/重复完整裁决仍缺。
- macOS Material3棋盘/键盘语义/旋转与左右镜像组合（会话视图）/dirty保护；不可变棋树稳定ID/评注/分支切换置顶删除、完整选定线路及前后分支点/虚拟列表。
- 本地命名库/搜索/备份、独立300ms草稿/dirty副本恢复/退出失败保护；资料GameMetadata并列文档真值，未知字段保留；独立50条最近阅读按根+完整UCI路径恢复。
- 独立局面编辑/棋子盒/拖放右键/红黑先/清空初始互换旋转镜像/非法不提交。
- FEN/UCI/ICCS/中文/有限单局PGN文字剪贴板交换，PGN后台worker携资料和评注；PGN默认完整所选线路含未来、可显式仅当前路径/省评注，copy与file同开窗快照，普通文字范围不变；单UTF8文件导入有界流/严格编码/预览；macOS五格式UTF8文件导出原生Foundation atomic，取消边界清楚/不清dirty。RAV/WXF/多局/GBK/XQF等仍缺。
- 单UCI引擎调度/取消屏障/超时EOF/迟到保护，MultiPV/评分箭头/WDL；AI执红黑双AI/催招变招悔棋。macOS沙箱内签名helper+NNUE，运行前Isolate验证身份，资源TT复用。
- 本谱跨局面PV历史64×128/100ms采样、不可变源Position与步数/中文着法标签、固定快照虚拟列表；停止与换局面保留，换谱/新局清空。只读worker预览/播放/键盘及源评分，窄短窗大字号滚动保留可辨认棋盘；所选前缀经新鲜源快照/stop/worker全树准备/取消后原子应用，复用已有不dirty/保留分支评注资料。latest推荐/局势条数据仍换位置清空；旧来源或删除节点不能误提交。
- 复盘方式best/candidates即时本机记忆，取消不启动/不回滚；已有评分结果重开默认重算，显式开skip仍可复用安全缓存，skip仅本次意图。其它预算/范围仍每次默认。
- 当前着单节点WDL评级投影与独立只读角徽/交点语义，缺失或过期不画；复盘/设置共享着法标记偏好与滚动图例，隐藏保留损失数字，算法版本不变。
- 当前线路/整树可取消最佳或多候选有限队列，单步父局面候选试走分支，首评分曲线/详情/跳转/跳过已有；完整历史/身份/预算键的有界内存及独立文件缓存，损坏降级重算；WDL预期损失报告为项目模型，不冒充源站准确率算法。
- 当前棋盘可冻结打开时Position/末步/可靠评级/有效箭头/旋转镜像/显示偏好，以原创450×500只读预览生成900×1000 PNG；另可冻结根到所选线路完整未来，逐帧原创绘制并生成GIF预览。最多64帧、12MiB，超限明确拒绝不截断；macOS经独立GIF文件端口、ImageIO逐帧校验与Foundation atomic保存。PNG图片复制仍走独立NSPasteboard端口；GIF分享和其它平台图片适配尚未实现。
- 原创可搜索离线帮助、四步只读引导/首次版本记忆；主题、资源/AI用时独立偏好；全局字号系统/100/115/130实时记忆且保留系统非线性；棋盘显示坐标红黑路数与翻转镜像/编辑器共用；棋子尺寸10–200/步5/重置，仅面容与拖动反馈缩放，点击交点不变；推荐箭头组合显隐/尖标准宽头部/即时偏好，不重启搜索或丢最新PV；本步同级绿色编号箭头/双开关及会话局部重置，不改棋谱，最多64含当前原编号。局势条基于原生WDL红方预期得分、随视图旋转；缺失/bound/mate独立灰态，真实领域终局与记录结果分开；隐藏回收空间且不重启分析，停止保留同局面结果。最后一步提供源点环与终点光圈/四角框；动画速度偏好关/快/标准/慢按项目映射0/300/600/1200ms控制单周旋转，系统减少动画优先，本机记忆且不拦点击。选子抬起/固定交点四角框共用编辑器，10–200%棋子保持90交点命中/语义与合法落点，不改搜索或棋谱。

F21新增用户本机图片覆盖：14种棋子类型/阵营各一槽，PNG/JPEG受512 KiB、1024边长/1MP限制，预览替换/恢复入口，主盘/编辑与PNG/GIF快照采用当前所选图片；圆章/方章有独立本机尺寸比例80–120%与全局比例相乘、X/Y偏移±8%格宽。ZIP/多文件导入、皮肤阴影编辑、棋盘图层和列表尚缺。详ADR-050至052。

实际边界见architecture/IMPLEMENTED_MODULES及ADR-005至052。

## 最新验证

M4-08：根 `flutter test --reporter compact` 441通过/5跳过（仅未配置官方Pikafish环境）；`flutter analyze` 无问题。专项应用/组件14/14；macOS integration_test/audio_feedback_test.dart 1/1，五条声音asset及TTS通道请求成功。普通 `flutter run -d macos` 构建启动PID19009，VM Service `127.0.0.1:50874`。flutter_tts暂不支持Swift Package Manager（Flutter未来可能升级为错误）并有AVSpeechSynth枚举warning。未能人工确认语音听感/主窗口视觉，Linux/Web与其他系统未验。历史引擎实机测试见SESSION_LOG。

生产main有文件导入/仅macOS文件导出；当前Debug/Release user-selected.read-write+sandbox，实际Debug签名已核，Release实际构建签名未验。系统Open/Save面板/外部授权/精确scope释放、真实OS焦点/最小化/人工视觉未验，Computer Use桌面权限未授不绕过；native fixture只保持framework-resumed，raw[]不是OS验证。Android/iOS/Windows/Linux运行与移动FFI仍未验/未实现。

## 下一步与环境

E35证据已复核110项；E38/E39补审F28更换弹层和独立音效开关。M4-04 / F11 GIF预览和macOS保存已交付，提交见git log。M4-05/M4-06/M4-07/M4-08分别交付项目光圈速度、选子/走棋及吃子/将军/将死本机合成提示音、中文系统TTS独立开关。F28仍缺音色选择/试听/自定义文件导入、Linux语音适配与实际语音音色核验、真实棋子移动动画范围审计；全站仍有F21素材、布局/工作区/语言、错题/题库、其它文件格式/GIF系统分享/OCR、完整历史规则、五平台引擎、在线自建后端+部署待做，详FEATURE_GAPS/BACKLOG。站点未知不能凭入口推断成功。

M4-07验证：根 `flutter test --reporter compact` 440 passed/5 skipped，5项需未配置的官方 Pikafish 环境；`flutter analyze` 无问题；专项13/13；macOS integration音频1/1；普通 `flutter run -d macos` 已启动 PID16653，VM Service `127.0.0.1:49641`。Xcode构建可能有既有audioplayers Swift并发warning；主窗口人工视觉/听感和其它平台未验。详 `TRACEABILITY.md` 与本轮 `SESSION_LOG.md`。

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。2026-11-02官方latest复核仍Pikafish2026-09-06 commit4c17cee，lock/NNUE校验见engine/pikafish.lock.json，.local忽略不提交。普通用户旧窗口不关闭/热重启；native测试覆盖build入口，最终审查前需重建普通main。

## 2026-11-05 / E74 F31反馈与版权投诉边界

反馈表包含≤2000字、联系方式、≤3张截图，默认勾选附设备/版本；查看内容展示platform、version/build、bundle/channel、os/model、userAgent、locale及屏幕尺寸等数据。投诉表要求投诉人/邮箱、作品和权属说明、涉及链接及真实性声明。检查更新和更新日志无AX可见反馈但不能排除网络请求。未填表、传图或提交；已回到设置，棋盘偏好保持默认。下一步本机离线支持页及自建可替换反馈/更新接口须明确数据目的地和用户提交时机。

## E75 / 2026-11-05 审计样本已清理

用户明确授权“确认删除（仅本次创建）”。在棋盘皮肤列表仅删除审计样本“我的棋盘”，列表AX确认消失；关闭选择器后设置仍默认棋盘/默认棋子、100%、坐标开、倒置关。详见REFERENCE_EVIDENCE E75；未动其它皮肤/数据。E75纯文档追踪待提交。

## E82 / F21,B24 样本清理补记

用户确认只删除本次创建的审计样本。访客IAB皮肤列表核验唯一“我的棋盘”项后，按不可恢复确认删除；列表中该项消失，关闭选择器并复核默认棋盘/棋子、100%、坐标开、对面倒置关。证据E82已加；几何算法与reload语义仍U。没有其它站点/谱局更改。

## E83 / F21,B24 上边距单步观察

在空白未保存草稿中上边距33→32.5时下边距519→519.04；反向一步复回33/519，左/右、格点、缩放不变。按丢弃确认退出，默认设置恢复；没有保存皮肤。已追加E83；单步联动之外的一般模型仍U。

## 最新参考站审计 E84 / B24 格点单轴拖动

新建未保存棋盘草稿后，左右移动两个蓝点约20截图视口像素，AX记录边距变化；左上拖动同时有纵边/对边小变化，右下仅读到右/下明显改变与轻微下变化。视口坐标未标定，不能得出准确公式或声称实际跨轴耦合。草稿已确认丢弃，设置复核默认。证据详REFERENCE_EVIDENCE E84；下一步检查本机几何编辑器响应式单轴和事务路径，再审计/实现可确认差距。
