# 当前交接（2026-11-05，Asia/Shanghai）

## M4-82 / F15,F20 / ADR-112 云库来源选择持久化（代码中，专项通过）

偏好字段`bookLookupSource`默认cloud并兼容旧数据；设置页/主面板都写同一字段，异步加载合并及持久化测试通过，来源切换不查询。定向8/8、根623通过/5跳过/0失败、analyze和macOS build通过；实际GUI runtime/视觉未验，原PID50598唯一运行。待单独提交。

## M4-81 / F15,F20 / ADR-111 大师谱筛选客户端（已提交 2e44365，macOS运行未验）

新增`MasterGamesService`及HTTP适配器、`MasterGamesLookupController`和主界面大师谱筛选UI；无endpoint离线，字段编辑不触发请求，查询需显式按键，过滤/位置变化旧响应失效；分页metadata带许可/署名，不读取整局。M4-81专项7/7、根623通过/5跳过/0失败，analyze/diff-check通过，`flutter build macos --no-pub`构建通过（既有插件兼容警告）；测试期间只有串行flutter_tester，现有GUI仍仅PID50598。macOS attach用历史/当前runner URL及自动发现均未连上；未运行`flutter run`，未产生新App。还需补既有PID50598的macOS app运行/热重启/视觉验证，不能宣称macOS运行已验。

下一步：先跑M4-82根测试/analyze/macOS build，复核M4-81 GUI运行态安全附着的可行性；再拆分整局受授权读取/只读复盘，审计B24余下格点/边距设置与保存边界、F27全部语言资源，再按功能矩阵其它登录外未完成项持续推进。总目标仍未完成。

## M4-80 / F15,F20 / ADR-110 自建大师谱索引查询服务端（已提交 457c904）

服务端新增可选`CHESSNEXT_MASTER_GAMES_ROOT`与`POST /v1/master-games/query`，schema1索引文件仅由运营者供给，不附带站点/第三方棋谱。精确FEN+完整history定位，过滤字段与值域有界；响应只给索引metadata和数据集许可署名。Nginx样例关闭该端点access log并限速。Flutter筛选页面和整局读取未实现；匹配/排序/分页均是项目P，不能声称复刻参考站。E87只观察年份DOM min=1/max=9999，真实键盘/stepper和查询行为U；筛选窗已关且操作来源恢复云库。

定向`flutter test --concurrency=1 test/server/master_games_server_test.dart --reporter expanded`3/3；服务包`dart test`6/6、`dart analyze`无问题；根`flutter test --concurrency=1 --reporter expanded`616通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-80.log`；`flutter analyze --no-pub`及diff-check通过。macOS只attach既有PID50598/runner50125，1,640ms同步、2,180ms热重启；Ctrl-C后原PID50598存活，无tester/attach残留或第二个App。未做UI视觉验收。

提交M4-80后直接推进M4-81：Flutter大师谱过滤模型/客户端，使用独立`MasterGamesService`端口，按明确配置endpoint且用户显式操作才发送当前局面；保留离线行为和许可署名。继续处理完整棋局内容/详情、F27本地化及矩阵其它登录外差异，不停止、不宣称全站对齐。

---

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-79 / F15 云库候选中文记谱（门槛通过，待提交）

`BookLookupController`为每个合法候选从查询时位置生成中文记谱；UI以该记谱为主标题，并附UCI、scoreCp和weight。保留M4-78的显式查询、自建可替换BookService、许可署名、无效响应隔离与不自动走棋边界。

专项`flutter test --concurrency=1 test/application/book_lookup_controller_test.dart --reporter expanded`6/6；根`flutter test --concurrency=1 --reporter expanded`613通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-79.log`；`flutter analyze --no-pub`、`git diff --check`通过。macOS复用既有PID50598/runner50125，TTY attach同步1,611ms、热重启2,148ms，Ctrl-C脱离后PID50598仍活。测试期间只有一个串行`flutter_tester`，结束后无tester/attach残留、无新GUI。视觉检查未做。

单独提交后继续推进F15大师谱筛选实际查询/授权数据集与部署方案，以及B24几何未知、F27完整Locale资源和矩阵中其它登录外功能；不可把本片或阶段性覆盖称为全站对齐。

---

# 当前交接（2026-11-05，Asia/Shanghai）

## E86 / F15,F20 大师谱筛选审计

可见字段：全部/对局/棋书范围、棋手/赛事搜索、起始/截止年、红胜/和/黑胜。没有提交。设置已恢复“云库”；返回后候选列表出现但不确定为缓存还是自动查询。边界与数据集授权/部署保持U。参考证据与矩阵已更新。

接下来按长期目标继续登录外缺口；B25后端先确定可授权大师谱数据方案与字段契约；F27完整Locale资源仍未启动。不要声称全站对齐。

---

# 当前交接（2026-11-05，Asia/Shanghai）

## E85 / B24 棋盘左边距stepper局部复核

空白未保存草稿里左边距33 +1 step=33.5、右465→465.02，上33/下519和格点不变；反向减1精确恢复默认。随后确认放弃，设置页默认值完整。该单样本保持局部V，完整四边公式、其它轴/端点与格点映射仍U。证据E85已入参考证据/矩阵/缺口。

继续B24以可控值审计为主，不把未知数值引入P模型；用户要求登录外全站持续推进。

---

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-78 / F15 / ADR-109 主界面手动云库查询（门槛通过，待提交）

新增主工作区“云库”只读卡片，显式选择开局/残局并主动查询。只向明确配置的自建服务发送当前FEN及根到游标完整线路；默认不联网、不自动走棋。合法着复核、服务数据集许可/署名展示、导航/切库废弃旧结果。定向6/6，根613通过/5跳过/0失败，analyze无问题；最终TTY attach同步1,266ms、热重启787ms，脱离后复核仅原PID50598。现仅待提交。

实现范围不含源站“大师谱”搜索过滤、数据部署/内容许可验收及F27完整本地化；全站尚未对齐。提交M4-78后继续登录外的其它矩阵差距，不要停在单功能完成。

---

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-77 / F21,B24 / ADR-108 单槽图片替换中断回收（验证完成，待提交）

`FileBoardSkinImageRepository.save`将新图片移入皮肤目录后再原子替换槽manifest。进程中断时可能留下未引用的项目命名图片或`.slot-pending-*`目录。现在`load`只在manifest不存在，或有效manifest引用的图片解码校验通过时，才回收对应槽中可识别的未引用image file/pending directory；按固定槽名、图片后缀、数字时间戳并以`followLinks:false`确认普通文件/目录。未知文件保留。manifest存在但无效/是链接、引用缺失或图片损坏时，不做该槽回收，保留恢复线索。不是跨文件原子写入。

定向`flutter test --concurrency=1 test/application/board_skin_image_library_test.dart --reporter expanded`5/5；根`flutter test --concurrency=1 --reporter expanded`607通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-77.log`；`flutter analyze --no-pub`和`git diff --check`通过。macOS复用PID50598/runner50125，VM Service `61579/4bLZ1MhsyEk=`同步1,067ms、热重启1,112ms，Ctrl-C后App仍存活。串行单tester，测试和attach结束无残留，无新App。

工作树包含文件适配器/测试与ADR-108、研究/context更新；请单独中文feature commit。之后继续审计图层映射批量导入/保存的失败事务，并持续推进F27完整语言资源与其余登录外网站差异，不宣称全站完成。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-76 / F21,B24 / ADR-107 启动回收孤儿图片目录（验证完成，待提交）

创建/删除流程分别写棋盘图片仓储与用户定义清单，进程可能在两次写操作之间终止。新增图片端口`pruneCustomSkins`：仅在`BoardSkinLibraryController.initialize`成功加载profile清单后调用，以有效用户ID作为保留集，文件适配器删除无定义的`custom-*`图片目录（含空文件夹）；内置皮肤和清单登记项目保留。若profile文件损坏/IO失败则跳过回收并保留所有图片；清理IO失败给出可重试错误，不改定义/选择。该机制不保证多文件原子提交，也不是源站支持证据。新增ADR-107。

专项`flutter test --concurrency=1 test/application/board_skin_image_library_test.dart test/application/board_skin_library_test.dart --reporter expanded`14/14；根`flutter test --concurrency=1 --reporter expanded`606通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-76.log`；5项需官方Pikafish/NNUE。`flutter analyze --no-pub`及`git diff --check`通过。macOS复用PID50598/runner50125，VM Service `61579/4bLZ1MhsyEk=`同步1,083ms、热重启1,194ms；Ctrl-C后App存活，无测试/attach残留或新App。

代码、测试及ADR/决策/矩阵/计划/交接待单独中文feature commit。下一步继续审计图片层保存/清理的跨文件失败与进程中断安全，再推进F27完整语言覆盖和其它登录外缺口，不声称全站已对齐。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-75 / F21,B24 真实文件仓储保存/重开回归（待单独提交）

新增跨controller生命周期测试，使用真实`FilePreferencesRepository`、`FileBoardSkinLibraryRepository`、`FileBoardSkinImageRepository`。先持久化当前内置jade，创建一套`apply:false`用户皮肤，写入四边/跨度/棋子比例/落点旋转几何和落点PNG；重建全部controller后几何与PNG仍在、jade仍选中。随后单独使用用户皮肤，再重建controller后用户ID与几何仍恢复。该测试验证本机项目适配器，不说明源站reload或重启行为。多文件崩溃原子性仍待研究。

定向`flutter test --concurrency=1 test/application/board_skin_library_test.dart --reporter expanded`9/9；根`flutter test --concurrency=1 --reporter expanded`604通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-75.log`；五项需官方Pikafish/NNUE，`flutter analyze --no-pub`与`git diff --check`通过。macOS复用PID50598/runner50125，VM service `61579/4bLZ1MhsyEk=`同步984ms、热重启1,278ms；Ctrl-C后原App仍活。根测试单tester，结束后无残留；attach脱离后无残留；未运行`flutter run`/新增GUI。锁屏，视觉not run。

工作树仅有测试、traceability/backlog/session log；应单独中文test commit。之后继续F21多文件图片/profile崩溃原子性和F27完整语言覆盖及其余非登录网站差距，不能在这一片后停。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-74 / F21,B24 / ADR-106 已存棋盘几何草稿编辑（已提交 c32e2c3）

按E67已确认的保存不自动应用，为用户棋盘目录增加“编辑”入口。弹层中格点拖动、四边、皮肤棋子比例、落点旋转与恢复默认都只修改本地草稿；取消不写仓储，保存才一次更新profile几何，仍保持当前内置/用户皮肤不变。保存错误保留草稿；应用通过列表现有“使用”单独操作。未涵盖图片槽草稿/替换事务。新增ADR-106、决策/矩阵/缺口/交互/计划/追踪已更新。参考站重载/重启仍U。

定向`flutter test --concurrency=1 test/widgets/board_skin_library_dialog_test.dart --reporter expanded`3/3。根`flutter test --concurrency=1 --reporter expanded`603通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-74.log`，5项依赖未配置的官方Pikafish/NNUE；`flutter analyze --no-pub`及`git diff --check`通过。macOS复用PID50598/runner50125，VM service `61579/4bLZ1MhsyEk=`同步978ms、热重启1,171ms；Ctrl-C后原App仍存活。全程串行单tester，测试/attach均无残留；没有新App，未用`flutter run`。屏幕锁定，人工视觉验收not run。

M4-74代码/测试、ADR-106、决策及矩阵/追踪/context已于`c32e2c3 feat(settings): 增加棋盘皮肤草稿编辑`单独提交。之后继续B24本机file-backed图像与定义保存/重开/删除的失败矩阵、源站其它格点/图片边界；继续F27语言切换和所有其它登录外未完成项，不能宣称F21或全站完整。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-73 / F21,B24 / ADR-105 棋盘皮肤保存与应用分离（验证完成，待提交）

E67验证源站新建页“保存”后仍留在编辑器，当前设置仍是默认棋盘；列表出现“我的棋盘”，之后单独点“使用这套”才切换。已存皮肤重新编辑并保存也不自动应用。项目原来只有“新建并使用”，现controller create显式接收apply；棋盘库有“仅保存”和“新建并使用”，未选定义可从列表独立“使用”。复制格网/几何与图片、偏好选择/失败边界保留原逻辑。跨reload/重启持久性仍U。

定向`flutter test --concurrency=1 test/application/board_skin_library_test.dart test/widgets/board_skin_library_dialog_test.dart --reporter expanded`11/11。首轮根全量有一项既有`engine_candidates_test.dart`测试超时；该用例单测重跑1/1，随后完整根`flutter test --concurrency=1 --reporter expanded`603通过/5跳过/0失败，最终日志`/tmp/chessnext-root-test-m4-73-final.log`；五项因缺官方Pikafish/NNUE跳过。`flutter analyze --no-pub`及`git diff --check`通过。macOS复用PID50598/runner50125，VM service `61579/4bLZ1MhsyEk=`同步984ms、热重启2,045ms，Ctrl-C脱离后原App仍活。全量测试与attach退出无残留、无新GUI App。

此轮首次新增Widget test因默认偏好未落盘时`MemoryPreferencesRepository.value`为空而断言抛空安全异常；已改断言按应用默认值核验后定向11/11。无业务失败残留。代码、测试、ADR-105及研究/上下文现待独立中文feature commit。提交后继续B24真实文件仓储重载/图片与定义一致性，以及F27所有语言资源和矩阵其它登录外缺口，不停止于单个增量。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-72 / F21,B24 / ADR-104 当前棋盘皮肤删除失败一致性（已提交 6bee7ed）

修正`BoardSkinLibraryController.delete`的顺序：之前先切换当前选择到皮肤基底，再尝试写删除后的定义清单；若清单保存失败，调用返回失败但选择已经改变。现先持久化列表移除，成功后才更新运行态列表/回退选择/删除图像。测试用故障仓储使保存失败，验证当前profile ID、定义和图片全部保留。新增ADR-104并更新DECISIONS/矩阵/缺口/待办/TRACEABILITY。项目错误处理P，不推断站点语义；失败后的源站状态及reload仍U。

定向`flutter test --concurrency=1 test/application/board_skin_library_test.dart --reporter expanded`8/8；根`flutter test --concurrency=1 --reporter expanded`602通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-72.log`（五项依赖本机未配置官方Pikafish/NNUE）；`flutter analyze --no-pub`、`git diff --check`通过。macOS复用PID50598/runner50125，VM Service `61579/4bLZ1MhsyEk=` attach同步1,188ms、热重启1,060ms；Ctrl-C脱离后原App仍运行。根测试只一个串行tester，测试和attach结束无残留；无第二个App。

M4-72代码/测试、ADR-104及上下文文档已于`6bee7ed fix(settings): 保持棋盘删除失败状态一致`单独提交。下一步继续B24棋盘皮肤保存—使用—删除—重载的完整本机故障矩阵和设置差距，不在此提交后停止；之后继续F27完整语言覆盖及FEATURE_MATRIX中其它登录外项目。总目标仍未完成。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-71 / F21,B24 / ADR-103 棋盘格点拖动预览修复（验证完成，待提交）

`BoardGeometryEditor.didUpdateWidget`原先每次父级重建都覆盖本地预览。自定义几何保存启动会先触发loading通知，而profiles仍是旧持久化值，于是拖动把手视觉回跳。现在仅当父级几何实际更新且当前没有拖动时同步；拖动期间保留本地乐观状态。测试由`StatefulBuilder`在每次`onChanged`后以旧几何重建，最终断言几何和把手位置仍前进。新增ADR-103，DECISIONS/矩阵/缺口/待办/TRACEABILITY已同步。映射仍为项目P，源站完整几何/保存应用reload语义仍U。

定向`flutter test --concurrency=1 test/widgets/board_geometry_editor_test.dart --reporter expanded`5/5。根`flutter test --concurrency=1 --reporter expanded`601通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-71.log`（五项需官方Pikafish/NNUE）；`flutter analyze --no-pub`与`git diff --check`通过。macOS复用PID50598/runner50125，VM service `61579/4bLZ1MhsyEk=` attach同步1,053.6ms、热重启1,158ms，Ctrl-C脱离后原App仍活。根测试期间一个串行tester，完成后无残留；全程未运行`flutter run`或新开App。锁屏，视觉验收not run。

关于多开：确认根`flutter test`只创建`flutter_tester`，没有GUI App；`flutter run -d macos`才可能重复启动App。以后统一复用既有VM attach并检查前后PID。当前独立chessNext仍只有PID50598，runner 50125；无根tester/attach残留；PID50168 frontend_server属于原runner，PID95554属于无关`tuner_flutter`，均非新增实例。

当前工作树含M4-71代码/测试、ADR-103和context之外相关矩阵/追踪文档，需diff复核并单独中文feature commit。提交后继续B24棋盘皮肤保存—使用—删除—重载事务以及源站几何未知值审计，继而继续F27全语言资源与功能矩阵其它非登录差距，不停于单个commit。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-70 / F21,B24 / ADR-102 棋盘几何串行持久化（验证完成，待提交）

修复`BoardSkinLibraryController.updateGeometry`在目录控制器`loading`时将拖动更新传入`_save`并立即返回false、可能丢失最后位置的问题。每个用户皮肤现只启动一个写入冲刷器，合并中间拖动值并在忙碌操作完成后写入最新值。测试使用延迟仓储阻塞首写，连续发送三次几何，验证三次Future成功、最终仓储与controller均为第三次值。新增ADR-102，矩阵/缺口/交互规格/待办已记录。此为本机可靠性修复；参考站跨轴微变、边界及完整公式仍U。

定向`flutter test --concurrency=1 test/application/board_skin_library_test.dart test/widgets/board_geometry_editor_test.dart test/widgets/board_skin_library_dialog_test.dart --reporter expanded`13/13。根`flutter test --concurrency=1 --reporter expanded`600通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-70.log`；5跳过需官方Pikafish/NNUE。根`flutter analyze --no-pub`、`git diff --check`通过。macOS复用PID50598/runner50125，VM service `61579/4bLZ1MhsyEk=` attach同步1,186ms、热重启1,027ms，Ctrl-C后原PID仍活。根测试一个串行tester且无残留，未运行`flutter run`，未新开App。锁屏，人工视觉验收not run。

本轮关于重复窗口：`flutter test --concurrency=1`只启动无GUI的`flutter_tester`；曾造成额外ChessNext窗口的风险来自以`flutter run -d macos`验证。此后macOS验证改为attach复用原实例，前后核对进程。当前实查PID50598仍是唯一chessNext，runner PID50125仍在；无tester/attach残留。

工作树的代码、测试、ADR-102、DECISIONS、FEATURE_MATRIX/GAPS、INTERACTION_SPEC、BACKLOG、TRACEABILITY和context待以独立中文feature commit提交。提交后不中断总体目标：继续B24格点/边距映射与草稿保存、使用、reload事务核验；并推进F27完整语言资源与功能矩阵其它登录外未完成项。不得宣称全站已对齐。

# 当前交接（2026-11-05，Asia/Shanghai）

## M4-67 / F31 / ADR-099 版权投诉表单与自建隔离收件（功能验证完成，提交待做）

用户明确要求继续登录外全站功能/设置对齐，不以一个功能结束。此次处理问题/建议之后的版权投诉文字首片：About入口复用已配置的自建发布根地址；独立投诉端口/表单，必填投诉人与邮箱、作品/权属、涉及内容链接，可选说明，须勾选真实性声明；先完整预览目标和字段，再二次确认发送。未实现附件，不能视为F31完成。

服务端新增独立`CHESSNEXT_COPYRIGHT_ROOT`收件目录与`POST /v1/copyright/complaints`，最多16KiB/1,000条、严格字段/长度/邮箱校验、不公开读取；Nginx关access log并单独限制2r/m。部署文档要求目录、访问与删除/保留策略。未部署服务、未投递真实投诉；无个人真实数据。

定向Flutter7/7、server Dart4/4/analyze/compile pass；根全量595 passed/5 skipped/0 failed，根analyze及diff check pass。5 skipped为本机无官方Pikafish/NNUE环境；首轮定向编译/测试和首次analyze info均已修复，最终门槛通过。macOS复用PID50598/runner50125：attach同步953ms、热重启1085ms，之后原App仍存活。测试使用`--concurrency=1`，无tester残留；退出attach后发现PID95102/95152残余attach/编译server并已TERM清理。无flutter run/新App。锁屏，视觉验收not run。

本片代码、ADR-099、服务部署文档、矩阵/缺口/追踪/交接已更新，`git diff --check`通过；尚未commit。下一步复核工作树并单独提交中文Conventional Commit，然后直接继续B24几何/保存应用事务及F27完整本地化/其他登录外缺口。不要因M4-67结束总目标。根测试不是新开App的原因；以后仍串行单tester，macOS只复用实例attach并清理attach进程。

# 2026-11-05 E81 / F27,F31 英文表单抽样与最新交接

E81审计英语About、反馈、版权说明与投诉表。字段和主要说明英文，两个表单的附件按钮仍中文“选择文件”；反馈页默认勾选设备/版本、未勾当前棋谱。本次未展开设备明细、未填表/上传/提交。切回简中，复核系统主题、晴蓝、夜间棋盘开。E81 evidence/matrix/gaps/spec/traceability待文档commit。

M4-66已提交`9c1470d feat(settings): 增加棋盘边距精确输入`：四边项目百分比新增一位小数直接输入、动态区间钳制及原controller保存。专项目标8/8、根593通过/5跳过/analyze通过；首轮根测试2条失败因表单变高使旧测试点击滚动外按钮，增加ensureVisible后定向及全量重跑通过。macOS复用PID50598/runner50125 attach同步1012ms/热重启8613ms，脱离后原App存活；根测试只有一个串行flutter_tester、结束无残留。用户强调不得重复启动App，继续仅attach，不用flutter run。

持续目标为登录部分除外全站对齐，不因一个功能或一次审计停。下一步提交E81纯文档，再继续F27完整本地化与B24几何/保存事务及矩阵其余差距。English全覆盖仍U，F21/全站未完成。

## M4-66 / F21,B24 / ADR-098 棋盘精确边距输入交接

用户持续授权继续对齐登录外全站功能与设置，不能每完成一项就停止；测试需避免造成多个chessNext。M4-66代码/测试/ADR/追踪已单独提交`9c1470d`。新增四边百分比数字输入（一位小数），按BoardSkinGeometry当前合法范围和最小跨度钳制，复用已有保存控制器；项目百分比P，不映射站点未知单位/算法。

定向`board_skin_library_dialog_test.dart`及`piece_skin_images_test.dart`合并8/8。根首轮591通过/5跳过/2失败，失败是设置表单变高后两条既有piece skin测试未将控件滚入视口；加`ensureVisible`后定向8/8。最终根`flutter test --concurrency=1 --reporter expanded`593通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-66-final.log`；5跳过为缺官方Pikafish/NNUE。本地`flutter analyze --no-pub`、`git diff --check`通过。

macOS未新启动App：复用原App PID50598、runner PID50125，Flutter attach文件同步1012ms、热重启8613ms；Ctrl-C后PID50598仍存活。测试期间一个串行flutter_tester，结束无残留。当前确认无`flutter_tester`/attach客户端；`tuner_flutter` PID70651是其他项目。屏幕锁定，视觉人工验收not run。

下一步先提交E81纯文档，再持续推进B24编辑保存/应用/reload生命周期、F27多语言资源与语言选择、以及功能矩阵中其它登录外差距。源站完整几何仍U；不能将F21/全站标完成。后续根测试加`--concurrency=1`；macOS复用同一App attach，禁止为验证重复运行`flutter run`。

## 最新审计 E80 / F27

English多页面抽样覆盖显示/设置目录、棋盘与选择器、分析、标记、声音与音效选择、操作及长按菜单、关于、主页面与菜单；样本静态文案已翻译且主界面记谱使用ICCS拉丁表示。用户数据化的棋盘皮肤名/作者和备案链接仍中文/专名。未覆盖所有弹窗、错误、导入/编辑、题库/训练，不宣称全站English完整。切回简中，复读系统主题/晴蓝/夜间开关开，状态恢复。证据、矩阵、缺口、追踪、交互、待办和context正在做纯文档commit；工作树需要复核。

后续F27应先基于静态文案与动态内容分类盘点语言资源，完整覆盖主应用/设置/错误/弹窗前不开放语言选择器；当前chessNext尚未有Locale偏好/资源。M4-65已完成/提交`abeace7`，M4-64 `642c3f6`，E78 docs `4658adc`。当前应检查 `git status`，提交E80文档后持续推进，勿在审计/一项功能后停止总体目标。

## 最新状态 M4-65 / F27 / ADR-097

E79复核：深色主题下默认棋盘夜间开/关视觉从浅米切换深棕（V），访客页主题/色调/夜间开关/语言均恢复到系统/晴蓝/开/简中。M4-65接入持久化开关，默认开，仅Material暗色+内置parchment皮肤且选择ID为`parchment`时用原创深棕/格线/标签色；浅色、关闭、jade和用户自建皮肤不改变。偏好和默认皮肤身份冻结在PNG/GIF快照。具体颜色是项目P，源站色值、非默认皮肤/OS暗色跟随持久性仍U。F27语言选择与全页面翻译资源尚未实现，整项未关闭。

验证：专项偏好/设置/快照首轮19通过/1测试失败（测试MaterialApp切换主题时状态复用），调整唯一key后`night_board_test`2/2通过；其余同轮专项通过。全根`flutter test --concurrency=1 --reporter compact`593通过/5跳过/0失败；5跳过缺官方Pikafish/NNUE资源。`flutter analyze --no-pub`通过；`git diff --check`待最终。macOS复用PID50598/runner50125：attach sync1,022ms/hot restart1,039ms，Ctrl-C后需最终进程复核；无新flutter run。屏幕锁定，本机视觉验收not run。

本轮连续提交：`4658adc docs(audit): 记录显示语言色调选项`、`642c3f6 feat(settings): 增加界面色调选择`。M4-65代码及ADR-097/E79追踪仍在工作树待diff检查/独立中文feature commit。用户关心测试是否多开App：测试前/后App唯一PID50598/runner50125；根测试单flutter_tester，运行结束无残留；全程未运行flutter run。下一步提交M4-65后继续F27全页面语言资源盘点和全站剩余登录外功能，不停在一项功能上。

## 最新 M4-64 / F27 / E78

已在App设置接入晴蓝/青玉/枫木/檀木/墨五种色调，作为Material 3明/暗主题seed持久化；偏好缺字段默认晴蓝。具体seed是本机P映射，不控制棋盘皮肤、其它图片图层、棋子/标记，且不实现未经审计的夜间棋盘行为。ADR-096明确历史数据升级默认变化。参考站五色作用范围/值、夜间模式实际变化仍U，F27仍开放。

M4-64专项10/10（专项首轮因测试断言缺少nullable theme的`!`编译失败，修复测试后通过）；根串行`flutter test --concurrency=1 --reporter compact`591通过/5条件跳过/0失败；`flutter analyze --no-pub`及`git diff --check`通过。5项Pikafish/NNUE用例因无官方本机资源跳过。macOS attach现有VM `61589/dTmglI9Y_pk=/`同步1,035ms、热重启1,082ms，Ctrl-C后PID50598仍存活。全程仅单一根flutter_tester，未启动新App。

E78、ADR-096、F27追踪和本上下文均随独立提交待确认。当前工作树含M4-64代码及追踪文件变更。进程复核仅App PID50598和runner PID50125，无flutter_tester、attach任务；不得运行`flutter run`。下一步继续用访客设置页对夜间棋盘/主题切换做可恢复的只读审计；之后按证据设计项目实现，并盘点全页面语言资源。需继续其它登录外功能，不因M4-64停止或宣称全站对齐。

## 最新工作续接 / E78 与后台 App 检查

用户要求继续对齐登录以外全站功能/设置，不得每项后停工。已重新读取AGENTS/README/CURRENT_STATE/HANDOFF/DECISIONS及相关Skills，并检查git状态/提交。当前唯一chessNext App PID50598，runner PID50125；没有`flutter_tester`残留。上一完整根测试最终591通过/5跳过/0失败，5跳过因本地未配置官方Pikafish/NNUE。串行根`flutter test --concurrency=1`运行一个测试宿主，不启动App；重复App只会来自`flutter run`/手动开程序。本轮继续禁止新`flutter run`，macOS变更需复用App attach。

新增E78显示语言页证据，目前文档改动待提交：`REFERENCE_EVIDENCE.md`、`FEATURE_MATRIX.md`、`FEATURE_GAPS.md`、`BACKLOG.md`、`TRACEABILITY.md`、`CURRENT_STATE.md`、`HANDOFF.md`。显示页五色调与夜间棋盘开关是观察证据O，青玉选中再恢复晴蓝及语言弹窗取消是V；真实色值/应用范围、夜间效果、其它页面完整译文为U。下一项继续F27的本机色调功能设计/实现，并将未知影响明确标为项目P，不宣称源站完整等同；语言完整资源和夜间棋盘另列待办。

当前工作树含E78文档改动，尚未做diff check/提交。完成文档审计提交后继续独立功能增量，每片串行根测试、analyze，通过后中文Conventional Commit；涉及macOS只attach既有PID50598。会话最终更新SESSION_LOG。全站持续目标未完成；无子代理、无后台flutter测试任务。

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

## 追加 E73 审计（2026-11-05）

在相同既有棋盘草稿复测右下点：约10个视口像素右下拖动使右465→475、下519→530.52；同距离反拖后AX读数右464.04/下519.54。将右/下数值输入恢复为465/519后，退出并确认丢弃。设置页复读默认棋盘/棋子、100%、坐标开、倒置关。更新REFERENCE_EVIDENCE、矩阵、缺口、交互规格、追溯待提交；证据只支持一次局部拖动及一次往返失败，不推导公式或原因。随后继续F21/B24和其它登录外功能，不在单片后停工。
# 2026-11-05 最新交接 / M4-58

用户持续授权实现登录以外所有功能/设置及实际macOS运行；不得用代理。用户特别指出测试不应启动多个chessNext：根Flutter测试用`--concurrency=1`，macOS代码验证复用既有runner/app的`flutter attach`，不要新跑`flutter run`。当前HEAD `b3f9f36`，M4-58 feature commit已完成，下面本交接文档更新待独立中文docs commit。

M4-58/F21/B24实现本机9列×10行棋盘格预览及双拖柄；左上仅改left/top，右下仅改right/bottom，以预览画布比例换算并钳制现有1–99%、最小跨度55%。四边0.5%滑杆继续保留。全部几何写入通过原Preferences/BoardSkin controller，即时保存。值映射为项目P，绝不宣称是站点算法。ADR-090、矩阵/缺口/交互规格/追溯/待办已提交；源站完整边界、公式、保存与重载仍U。

验证：`flutter test --concurrency=1 test/widgets/piece_skin_images_test.dart test/widgets/board_geometry_editor_test.dart --reporter expanded`8/8；根`flutter test --concurrency=1 --reporter compact`574通过/5跳过；`flutter analyze --no-pub`无问题；`git diff --check`通过。首轮根测试570通过/5跳过/2失败，两失败来自新增预览把既有棋子偏移设置控件推到视口外；改为单独校准Dialog后同专项及完整根测试通过。复用既有PID50598与runner50125，VM Service 61579，attach同步1060ms、热重启1020ms，脱离后App/runner仍在。测试过程中只见一个flutter_tester；没有新开GUI实例。Mac锁屏，人工视觉验收not run。

参考站E72审计已单独提交于`78c4040`，左33→33.5/右465→465.02仅为一个步进样本。现在没有未提交功能代码；下一步继续F21剩余几何/棋盘和棋子编辑功能，及F27/F31等登录外全站缺口，不能在单个增量后停下或宣称全站完成。在线能力仍为自建可替换后端并有部署方案，许可决策暂缓。

## 追加 E74 / F31（2026-11-05）

从关于页进入访客反馈`#/feedback`并展开“查看内容”，确认描述≤2000字符、可选≤3图、联系方式、默认附带设备/版本，展示platform/version/build/bundle/channel/os/model/UA/locale/screen dims；未输入或提交。版权`#/copyright`说明公开邮箱及投诉材料/处理流程；投诉表`#/feedback?type=copyright`要求投诉人、邮箱、作品、权属、涉及内容、真实性确认及可选最多3图。检查更新、更新日志无可见AX结果，是否网络请求U。逐级返回`#/settings`，未改棋谱/账号/设置。E74五份研究追踪及CURRENT_STATE已更新，待中文docs commit。下一步继续F31本机About/支持实现设计与其余登录外缺口，仍不把单片当全站完成。

E75清理：收到用户明确“确认删除（仅本次创建）”后，只删除审计用访客皮肤“我的棋盘”。删除后AX列表已无该项，棋盘设置仍默认棋盘/默认棋子、100%、坐标开、倒置关；无其它数据改变。REFERENCE_EVIDENCE/SESSION_LOG/CURRENT_STATE已记录，待diff check/docs commit。
# 2026-11-05 最新交接 / M4-59

当前HEAD `512915c`。用户持续授权实现登录外全部功能/设置及macOS实际运行，要求持续推进，不在单片后停。严禁子代理。用户特别要求测试不能导致多个App：根测试仅`flutter test --concurrency=1`；macOS验证复用唯一PID50598/runner50125，通过VM Service `http://127.0.0.1:61579/4bLZ1MhsyEk=/`的交互`flutter attach`。本会话两次全量根测试各只出现一个flutter_tester；未启动chessNext新实例。

已完成M4-58 `b3f9f36 feat(settings): 增加棋盘拖点校准` 与E73审计`0fb198d`。M4-59 `512915c feat(settings): 增加离线关于与许可页`：显示chessNext、版本0.1.0+1、离线状态及Flutter本地依赖许可页；不联网/改设置。定向1/1；根575通过/5跳过；analyze通过；attach sync1201ms、热重启1061ms；锁屏未人工视觉验收。M4-59完整追踪已在feature commit中，当前context文档更新待独立docs commit。

F31保持开放。E74发现反馈表会默认附带设备/版本/浏览器数据，版权投诉会要求个人联系方式及权属证明；没有输入或提交。E75按用户“确认删除（仅本次创建）”删除唯一审计样本棋盘“我的棋盘”，列表确认消失；默认棋盘/棋子、100%、坐标开、倒置关保持。E73右下拖点反拖不可精确复原，算法未知。有关审计均有证据并已记录。

下一步：M4-60为自建更新元数据服务/手动检查功能定义固定schema与部署方案（先只读版本/日志、不下载/安装），空URL离线；然后反馈/投诉明确数据预览、用户显式提交、自建部署和本机草稿；继续F21几何/编辑事务、F27全页面语言及其它缺口。保留全站矩阵差异，不宣称完成。License决策依用户要求暂缓；如真实后端需用户自备授权资源。
## 追加 M4-61 / E76（2026-11-05）

`e880d69 feat(settings): 接入自建版本检查`已提交。F31关于页配置可选自建版本服务；默认空且无后台请求，用户点击才取只读版本清单/历史；专项13/13、根584通过/5条件跳过、analyze干净。macOS复用PID50598/runner50125 attach热重启1052ms成功，脱离后App唯一存活。根测试串行；PID70890/runner70651是`tuner_flutter`，不属于本仓库，测试未启动ChessNext新窗口。

E76参考站读到边距输入aria min0，水平max500/垂直max550；左500→右500、左0时右仍500、右输0实显示8；上550→下550，下输0后上仍550。按默认33/33/465/519恢复未保存草稿并丢弃，设置检查默认棋盘/棋子、100%、坐标开、倒置关。证据写REFERENCE_EVIDENCE/矩阵/缺口/追溯；完整几何关系继续U。本轮审计无持久改动。

下一步继续F21/B24几何编辑和全站登录外设置审计，实现每一可确认的缺口后分别根串行flutter test、analyze、涉及macOS时attach既有实例，并单独中文提交；当前进程仍为PID50598/runner50125，无后台根测试。尚需提交本次上下文/E76 docs更新。全站未对齐完成；登录范围除外，后端自建可替换方案保留。

## 追加 E77（2026-11-05）

空白草稿验证余下三个边距端点：右max500、上min0、下max550；下输入550先显示549.96，按stepper+后精确550并禁用。左/右/上/下恢复33/465/33/519后放弃草稿，设置回默认棋盘/棋子、100%、坐标开、倒置关。E77及证据索引待docs单独提交。继续实现/审计F21格点保存、图层与用户皮肤事务，再处理F31反馈/版权等登录外剩余项。

# 2026-11-05 最新交接 / M4-63

用户再次说明持续开发目标：对齐登录外所有可确认功能/设置；不要在每个增量后停工。用户询问全量测试是否正常、为何反复打开多个App。本轮确认：现存只有ChessNext PID50598与其原runner PID50125；`flutter test --concurrency=1`仅串行启动单个flutter_tester，不启动macOS应用。重复窗口风险来自另行执行`flutter run`。本轮未执行`flutter run`，只用既有VM Service `flutter attach --debug-uri=http://127.0.0.1:61589/dTmglI9Y_pk=/`同步/热重启，约1,054/1,114ms，Ctrl-C后原App仍存活。另有PID70651/70890为tuner_flutter，与chessNext无关。

M4-63/F31/ADR-095实现问题/建议自建投递：设置可选根地址留空默认离线；表单只含类别、描述和可选联系方式；先预览准确地址/字段再明确提交。HTTP适配仅HTTPS公网/loopback HTTP，严格响应校验，不自动重试。自建Dart服务通过`CHESSNEXT_FEEDBACK_ROOT`可选启用POST，字段有界、16KiB请求、5,000条上限、私有exclusive写入，无公开读取/服务内IP存储。UI告知服务/托管层会看到连接来源IP；Nginx样例关闭access log并每IP限6次/分钟、突发5次。运营者自行设定保留周期，界面明示。附件、版权投诉表、外部联系方式、真实服务部署/收件流程仍待；F31开放。

最终验证：定向反馈7/7；server `dart test`2/2、`dart analyze lib bin test`干净、`dart compile exe bin/skin_catalog_server.dart -o /tmp/chessnext-skin-catalog-server`通过；根全量591通过/5条件跳过/0失败；根`flutter analyze --no-pub`、`git diff --check`干净。两次定向测试早期断言和FileMode接口失败已修复。屏幕锁定未人工视觉验收；无实际外部发送、生产部署或生产收件验证。最终热重启同步1,054ms/1,114ms，测试器运行时和结束后均未多开chessNext。

M4-63已单独以`e51388c feat(settings): 支持自建反馈预览与提交`提交；相关追踪、矩阵与ADR-095已写入。下一步继续F31版权/交流入口取证，和F21棋盘几何保存生命周期/其它全站设置；保持O/V/D/P/U边界。五项Pikafish/NNUE用例需配置官方制品才能运行。当前Mac运行实例仍唯一；工作树应保持干净。

## M4-67 门槛及交接补记（2026-11-05）

根目录最终`flutter test --concurrency=1 --reporter expanded`：595 passed、5 skipped、0 failed；跳过项依赖未配置的官方Pikafish/NNUE。`flutter analyze --no-pub`、server `dart analyze lib bin test`、server `dart test --reporter expanded` 4/4、server exe compile及`git diff --check`通过。专项Flutter 7/7。根全量测试运行一个串行tester，没有GUI App；当前原chessNext PID50598/runner50125维持不变。复用既有VM Service attach sync953ms/hot restart1085ms成功。attach退出遗留PID95102/95152已清理，后续再复核状态；没有执行flutter run。

实现F31投诉文字表单及自建隔离收件并未完成投诉附件、邮箱/群外链、真实运营/保留/法务流程，因此只是M4-67首片，不能关闭F31。全站登录外对齐仍长期目标，继续按矩阵/缺口推进；下一个可执行项优先审计并补B24棋盘几何、格点/四边耦合未知和草稿保存—应用—reload事务，再推进F27完整语言资源，不应在本片后停工。

## E82 样本清理完成

已按用户确认删除唯一“我的棋盘”审计样本；删除后列表不再出现该项，回到棋盘设置确认默认棋子/棋盘、100%、坐标开/倒置关与原值一致。参考站截图在UI操作结果展示，文本证据E82已记录。未改变线上皮肤或局面。若新审计需要另建样本，应优先用未保存草稿并取消，避免再次产生不可恢复数据。

## E83 B24 几何小样本

空白未保存棋盘草稿操作上边距减/加一步：上33→32.5→33，下519→519.04→519；左33/右465/格点50/50/缩放100%未变。已确认丢弃草稿并回棋盘设置默认态。证据只限单步，不把它外推为公式。下一步继续边距/格点跨轴操作和保存—应用—reload差异审计，所有临时样本优先不保存。

## 2026-11-05 最新交接 / M4-68 / ADR-100

用户要求持续推进登录外全站功能/设置，不要每项结束就停。用户指出每次测试似乎多开ChessNext；核实根`flutter test --concurrency=1`只运行一个`flutter_tester`，不会启动macOS GUI。危险操作是`flutter run`；本轮未使用。唯一既有ChessNext PID50598 / runner50125持续运行。复用VM Service `http://127.0.0.1:61579/4bLZ1MhsyEk=/`执行attach同步1,191ms、热重启1,494ms，Ctrl-C脱离后PID50598仍存活；结束时无根`flutter_tester`/`flutter attach`/`flutter run`残留。`tuner_flutter`的后台frontend_server与本项目无关。

本轮完成M4-68 / F31 / ADR-100普通反馈附件首片：显式文件选择PNG/JPEG，最多3张/每张256KiB/总512KiB；展示/移除/预览确认；自建服务严格校验并只写私有记录。投诉表单附件、真实部署运营的访问/删除/留存、外部交流方式仍待完成，F31开放。真实发送/部署未进行，屏幕锁定未人工视觉验收。

实际验证：定向Flutter9/9；server `dart test --reporter expanded`6/6、`dart analyze lib bin test`干净、exe编译通过；根`flutter test --concurrency=1 --reporter expanded`598通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-68.log`，5项需官方Pikafish/NNUE；根`flutter analyze --no-pub`和`git diff --check`通过。完整结果已加TRACEABILITY。代码、ADR及矩阵/缺口/计划/上下文记录当前待单独中文commit。

下一步提交M4-68后继续B24：沿参考设置页审计格点拖动、宽高比例、四边联动和预览保存/使用/reload事务，严格记录O/V/P/U，不外推公式；随后实现已证实缺口并逐项继续F27完整多语言及功能矩阵未完成项。别在本增量commit后停止，也不要宣称全站已对齐。

## E84 追加 / B24 格点水平拖动局部样本

在访客参考页空白未保存草稿中两个把手各水平拖约20截图像素，AX读数记录在`REFERENCE_EVIDENCE.md` E84。存在跨轴/对边小变化，但屏幕坐标未标定、可能是采样/画布映射/精度，整体算法仍U。返回确认丢弃并核对设置默认，没保存/使用/导出。当前工作树为M4-68后清洁基线，E84文档更新是独立待提交的audit docs片；随后不要停在审计提交，继续检查本机BoardGeometryEditor响应式几何、拖拽与输入映射，修复可证明的问题，再按门槛提交，之后推进其它登录外缺口。

## 2026-11-05 最新交接 / M4-69 / ADR-101

M4-68问题反馈图片附件于`b3977a7`提交，随后E84格点水平拖动审计于`4624bd8`提交。本轮继续M4-69/F31：版权投诉表复用文件选择端口，用户可显式添加最多3张PNG/JPEG（每张256KiB/总512KiB）、预览/移除并在完整目的地/字段/附件预览后确认；附件写入隔离的投诉私有目录，不与一般反馈合并。服务端/部署限值统一768KiB请求/1MiB Nginx，投诉目录1,000条、无公读。ADR-101已起草。

门槛：定向Flutter9/9；server6/6、`dart analyze lib bin test`干净、exe编译成功；根`flutter test --concurrency=1 --reporter expanded`599通过/5跳过/0失败，日志`/tmp/chessnext-root-test-m4-69.log`；根analyze/diff-check通过。macOS复用PID50598/runner50125，attach sync1,174ms、hot restart1,248ms；脱离后仍唯一App。串行测试只有单个tester，测试后无残留，未用`flutter run`。屏幕锁定，人工视觉及真实部署/外发not run。代码、ADR、矩阵/计划/交接文件待独立中文commit。

用户要求继续登录外全站对齐，不要每功能提交后停。本次commit后下一项仍B24：检查本机BoardGeometryEditor响应式单轴、格点输入与棋盘皮肤保存/应用/恢复/重载，找到可证实差距后实现并继续完整门槛；后续继续F27全部语言资源及功能矩阵其它缺口。当前没有全站完成声明。
