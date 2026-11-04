# 会话交接

## 2026-11-04 / M4-37 / F20,B26 四处分隔桌面工作区

本轮按ADR-072实现≥1280dp三栏工作区，左操作/记录、中棋盘、右侧可见侧栏上下分区。四个分隔条支持48dp拖动区、方向键及Slider读屏增减动作，重置22/70/55/55。范围为P：左栏19–34%，棋盘占剩余宽度60–80%，左右分区25–72/25–75%，并受可用尺寸保护。站点完整范围/算法U。比例只保留当前工作区，不持久化。

代码：`lib/app.dart`、`lib/features/workspace/resizable_workspace.dart`；专项测试`test/widgets/resizable_workspace_test.dart`验证装配、拖动改变实际pane尺寸、重置、Slider语义。专项`flutter test test/widgets/resizable_workspace_test.dart --reporter expanded`2/2；根`flutter test --reporter compact`512通过/5跳过（需要官方Pikafish/NNUE环境）；`flutter analyze --no-pub`无问题。复用唯一runner PID86855热重载成功（Reloaded 3 of 1736 libraries，2231ms），App PID87104仍唯一实例；CUA现场拖动/键盘未验。

用户关心的测试实例：`flutter test`只运行`flutter_tester`，不会启动`chessNext.app`；重复实例来源是重复`flutter run -d macos`。后续继续复用runner并核实PID数。

下一步仍继续全站目标（登录后功能除外），不把M4-37当成完成目标。B26的源站几何范围、触屏及重启持久化、F19原生窗口语义保留U；随后继续B25/F27设置审计与项目实现、B24自建在线目录/部署和功能矩阵剩余缺口。


## 2026-11-04 / 用户要求继续全站对齐：M4-32至M4-35 / B25

用户明确续跑持续开发；排除登录部分，其它在线能力保留范围，后续采用自建可替换后端与部署方案。无代理授权；许可决策暂缓不阻挡离线开发。不要在单功能后停止，不要宣称全站已对齐。启动本轮前重新读了项目要求文档和相应skills；以磁盘/命令输出为准。

已独立提交：`d476409`（M4-32 棋谱定时播放/步时，ADR-067）、`cce3558`（M4-33 棋谱栏/播放按钮显隐，ADR-068）、`f3a6517`（M4-34 面板切换栏，ADR-069）、`df8376d`（M4-35 棋盘长按/右键菜单配置，ADR-070）。每片根测试、analyze、macOS运行通过后提交。M4-35专项10/10；根`flutter test --reporter compact`509通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync与VM连接成功（PID87104/VM `127.0.0.1:60069`），但`open returned 1`未置前，未做人工视觉/右键验收。5跳过依赖官方Pikafish/NNUE。

**进程说明（回应用户）：**`flutter test`使用`flutter_tester`宿主，本轮根测试期间进程表没有`chessNext.app`；这些测试不会启动多份桌面App。`flutter run -d macos`才会启动真实App。之前每个功能重复`flutter run`导致多次实例可能留存；本轮清理到单例，并保留一个TTY交互runner。后续通过该runner热重载；如果runner失效，先查进程数量、停旧runner/App，再只启动一个。当前GUI App PID87104、Flutter runner会话27500。

E50操作设置本轮项目行为已补播放、棋谱栏/播放按钮显隐、侧栏切换、动作菜单；源站执行策略和面板映射仍U/P，未动源站偏好。E51入口观察由E52实操补全：悬浮模式为居中棋盘+底部状态/工具行，“⋯”菜单可返回多栏工作区；原生置顶/独立窗口U。E52/E53确认4个splitter；左栏22/棋盘70及两处分区55均在重置后复原。上下分区拖动观察值左侧25–72、右侧25–75（视口1280×720，完整范围/跨屏幕U）。临时审计标签已关闭，用户标签仍在`#/settings`。

下一步：E52提交`bed1456`，E53及矩阵/待办/交接提交`a308cb0`，SESSION_LOG校订提交`e57891b`。按现场行为实现本机布局/显示模式，然后根测试、analyze、复用唯一macOS runner；继续矩阵内其它功能、F27翻译、自建在线后端/部署方案及全站差距。相应技能：`feature-audit`审计、`flutter-feature`实现、`quality-gate`验收、`session-handoff`交接；按当前子任务读取，不需一次读完。

## 2026-11-04 / M4-36 / F19,B26 悬浮工作区

已提交`5048330 feat(workspace): 增加棋盘悬浮工作区`：AppBar显示模式菜单切换分析/悬浮窗。悬浮态以紧凑居中棋盘代替常规侧栏，底部状态/设置/悔棋/更多菜单；更多可新局、翻转、编辑、退出回常规布局。ADR-071，状态不持久化，不改变棋谱/分析。参考E52实际验证了应用内页面切换与退出，原生置顶/独立窗口仍U。

专项`flutter test test/widgets/floating_workspace_test.dart --reporter expanded`通过；根`flutter test --reporter compact`510通过/5跳过（官方Pikafish/NNUE需配置）；`flutter analyze --no-pub`No issues found。macOS沿PID86855现有runner热重载成功；App PID87104唯一。人工点击尝试CUA报`noWindowsAvailable`，仅截屏确认原模式入口；悬浮态macOS交互未验。热重载未新开实例。

下一步继续B26实装四分隔条及重置，保留测值U边界；每片根测试/analyze并复用唯一macOS runner，不停止全站推进。

## 2026-11-04 / B25 持续交付：M4-31侧栏面板显隐

用户授权持续推进至登录相关部分外全部可确认功能/设置，不在一项功能后停。在线能力仍保留范围，采用可替换自建后端并提供部署方案；离线优先仅为推进顺序。许可决策按要求暂缓，无代理授权。

本轮先读取AGENTS/README/CURRENT_STATE/HANDOFF/DECISIONS、恢复技能及F21/B23文档，确认入口HEAD `a74d53b`、工作树干净。参考站只读完成E49语言列表和E50操作设置范围；无源站设置变更。审计提交`e8b6017 docs(audit): 记录语言与操作设置证据`。随后分别交付：

- M4-30 `0053171 feat(settings): 支持侧栏面板顺序调整`（ADR-065）：四种本机侧栏拖动重排、持久化、坏值拒绝和读取竞态保护。
- M4-31 `4a02127 feat(settings): 支持侧栏面板显隐`（ADR-066）：四种侧栏独立开关，隐藏后不构造面板子树；全隐藏时仍能从AppBar进入设置恢复。

E50站点的AI/云库/局势图/着法与本机对弈/分析/复盘/候选并非已证实一一对应（项目映射P）；播放时长、播放按钮、棋谱栏/面板切换栏与长按/右键菜单仍缺；E49语言切换没有实际选择，翻译与持久性U。

验证：`flutter test test/application/preferences_controller_test.dart test/widgets/side_panel_order_test.dart --reporter expanded`7/7；根`flutter test --reporter compact`505通过/5跳过；`flutter analyze --no-pub`No issues found；`flutter run -d macos`Build/Sync成功，PID78894、VM `127.0.0.1:51984`，runner会话21286仍运行。5项跳过需本机官方Pikafish/NNUE环境。`flutter_tts`仍有SwiftPM未来兼容warning。CUA尝试读取macOS窗口超时，人工视觉验收未做。额外首轮执行记录：M4-30全量根测试505/5、analyze发现弃用`onReorder`后换成推荐`onReorderItem`再跑最终门槛；M4-31首轮widget点击目标因未滚动而miss，修正`ensureVisible`后专项通过。

最新功能提交后工作树干净；文档状态更新待单独提交。下一步沿B25继续操作设置垂直增量（可先评估每步播放间隔/当前线路自动播放），同时审计剩余设置；F27须有完整翻译资源再开放语言选择。B24还需可替换自建在线皮肤目录和部署方案；全站其它在线/格式/训练差距仍按矩阵推进。不能称F20/F27/F21或全站已对齐。

## 2026-11-04 / B23 持续交付：M4-29主棋盘棋子移动动画

M4-29已单独提交`177abff feat(board): 增加棋步移动动画`。ADR-064：主棋盘每次显示的走棋身份更新时，棋子从from格移动到to格；复用`AnimationSpeed`的项目映射（关0/快300/标准600/慢1200ms），系统Reduce Motion优先静止。过渡中将落点格的视觉棋子换成IgnorePointer overlay；棋谱/规则同步提交不等待动效。只有`XiangqiBoard`主棋盘开启动画，`BoardSurface`默认静态，因此编辑器、PV预览、PNG/GIF快照不动。新身份会重启/替代前一动效，落点无棋子或速度关时立即静态。

专项`flutter test test/widgets/board_piece_move_animation_test.dart --reporter compact`5/5通过，覆盖慢/快档、快速连续新着替代、关档及运行中切换Reduce Motion；最终根`flutter test --reporter compact`503通过/5跳过；`flutter analyze --no-pub`无问题；最新`flutter run -d macos` Build/Sync PID74615、VM `127.0.0.1:64108`。CUA `getApp("chessNext")`连续两次超时，故窗口/动效视觉验收not run。`flutter_tts` SwiftPM未来兼容warning。源站动效对象/速度映射U，项目行为P。M4-29已提交；补充回归已提交`759970b test(board): 覆盖移动动画速度边界`。随后继续B23/F28剩余音频/朗读与F27语言，在线目录留在离线工作后推进。PID74615仍运行，flutter run session 86168仍在。

## 2026-11-04 / B24 持续交付：M4-28项目皮肤包文件夹导入

## 2026-11-04 / B24 持续交付：M4-28项目皮肤包文件夹导入

M4-28已提交`a807155 feat(skins): 支持导入本机皮肤文件夹`。ADR-063仅接受解压的项目schema1布局，根`skin.json`+`images/<PieceImageSlot>.<png|jpg>`，拒绝链接/未知内容/多余层级；尺寸边界复用M4-27 ZIP解码器（单图512KiB、14图/7MiB、manifest64KiB、临时ZIP8MiB）。项目P，站点文件夹格式/成功仍U。取消/失败不写数据，应用层走M4-27完整预检、用户确认、新ID和无覆盖导入。目录读取限制根最多2项、图片目录最多14项；系统面板尚未人工验收。

专项`flutter test test/adapters/file_selector_piece_skin_folder_picker_test.dart --reporter compact`2/2通过；`flutter analyze --no-pub`无问题。调试修复const factory、PieceImageSlot导入、baseSkin类型及无效PNG IDAT checksum。根`flutter test --reporter compact`首次出现1失败/5跳过，错误输出未留存；expanded复跑498通过/5跳过。`flutter run -d macos`Build/Sync成功PID71234/VM `127.0.0.1:59893`，flutter_tts SwiftPM未来兼容warning。代码已提交。无其它后台运行任务。

F21仍未完成：在线目录/点赞作者排序、任意站点导入兼容、系统面板人工验收及全站其它差距仍待推进。下一项先审计其它离线设置（B23/F28音效/动画及F27语言），再推进自建可替换在线服务和部署方案。登录相关除外。

## 2026-11-04 / B24 持续交付：M4-27项目格式皮肤ZIP导入

M4-27代码及门槛完成，待独立中文提交。ADR-062仅接受M4-26项目schema1单皮肤ZIP，不宣称支持站点任意格式。系统选择流读≤8 MiB；解码前后检查≤15中心项、固定白名单路径、无重复项/软链接/目录/路径穿越、清单≤64 KiB、图片总展开≤7 MiB/单图≤512 KiB、槽位唯一/全部引用、SHA-256和真实PNG/JPEG解码。全包确认前不落盘；用户确认后新ID、不覆盖重名/超过64拒绝；先存图片后持久化目录，目录失败时清理图片，清理失败有可能残留不可见孤儿文件夹。成功选用该皮肤。选文件器目前仅主入口macOS注入。

专项codec/picker/library/exporter`flutter test test/application/piece_skin_package_codec_test.dart test/adapters/macos_piece_skin_package_exporter_test.dart test/adapters/file_selector_piece_skin_package_picker_test.dart test/application/piece_skin_library_test.dart --reporter compact`13/13；根`flutter test --reporter compact`496通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync PID69107/VM `127.0.0.1:56731`。未实际操作系统面板/人工视觉。调试期间初次target遗漏尚未创建的picker测试文件、后续发现测试输入类型错误及误把XFile.name当可靠扩展名；已加入测试、修正字节类型并移除名称强制检查，由类型过滤+ZIP结构校验防护。日志`/tmp/chessnext-m427-final-test.log`。

先提交M4-27中文独立提交。之后继续站点ZIP/多套包与文件夹导入审计（E42/E48成功仍U），并推进其它设置和在线皮肤自建可替换服务部署。F21/全站开放。

## 2026-11-04 / B24 持续交付：M4-26本机用户皮肤ZIP导出

M4-26实现和门槛完成，待独立中文提交。ADR-061定义`skin.json` schema1及`images/<slot>.<ext>`固定路径、SHA-256清单。图片复用PNG/JPEG真实解码限制，最多14张/7 MiB原图累计/8 MiB最终ZIP；macOS系统保存位置，原生`writeZipAtomic`校验ZIP签名/大小后原子写。导出不含其它皮肤/账户/棋谱。`archive` 4.6.0从传递依赖改直接依赖，MIT许可已有归档和LICENSE SHA记录。

目标专项编码/适配器4项通过；全量`flutter test --reporter compact`492通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync PID67175/VM `127.0.0.1:54273`。5跳过依赖官方引擎/NNUE配置，flutter_tts SwiftPM未来warning；未实际操作系统保存面板/人工视觉检查。日志`/tmp/chessnext-m426-final-test.log`。

检查diff并提交M4-26。下一项B24安全ZIP/文件夹导入：处理路径穿越、symlink、解压总字节/文件数/压缩比、重复槽/皮肤和失败原子性；E42/E48成功边界U，项目约束需标P。之后在线目录和自建后端部署设计。F21/全站开放。

## 2026-11-04 / B24 持续交付：M4-25用户皮肤独立阴影

M4-25已提交`1589a60 feat(skins): 支持用户皮肤独立阴影`。ADR-060将平台无关PieceSkinShadow值对象放ports，用户皮肤定义可选保存阴影JSON；旧目录缺字段时仍回退到内置基础皮肤阴影，新建复制当前活动皮肤或内置预设参数。设置对用户项写目录，对内置项继续写AppPreferences；BoardDisplayScope、棋盘/编辑和PNG/GIF快照均带用户阴影值。范围沿用ADR-056项目P，E43端点/算法仍U。

专项`flutter test test/application/piece_skin_library_test.dart test/application/piece_skin_shadow_test.dart test/application/board_image_snapshot_test.dart test/application/board_gif_test.dart test/widgets/piece_skin_images_test.dart --reporter compact`22/22；根`flutter test --reporter compact`488通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync成功PID65664、VM `127.0.0.1:51711`。跳过为本机缺官方引擎/NNUE配置；flutter_tts SwiftPM未来warning；未人工视觉验收。日志`/tmp/chessnext-m425-final-test.log`。

下一步继续B24用户皮肤包导出、ZIP/文件夹安全导入，再设计在线皮肤目录自建可替换后端和部署方案。F21/全站仍开放。

## 2026-11-04 / B24 持续交付：M4-24皮肤库搜索/排序/选择

M4-24已提交`f59a884 feat(skins): 增加本机皮肤库搜索排序`。皮肤库支持回车提交名称搜索、默认/名称/最近创建排序、点击条目持久化选择并关闭。E42确认源站回车行为和五种排序入口；点赞/作者排序因本机皮肤无对应数据，仍缺，不伪造。首次专项编译错误（selectPieceSkin需传皮肤和ID）已修复；最终目标专项11/11、根`flutter test --reporter compact`488通过/5跳过、`flutter analyze --no-pub`无问题、`flutter run -d macos`Build/Sync启动PID64446/VM `127.0.0.1:49993`。flutter_tts提示SwiftPM未来兼容；未做窗口视觉验收。日志`/tmp/chessnext-m424-final-test.log`。

M4-24下一切片M4-25阴影已独立完成，详本交接顶部。F21/全站未完成。

## 2026-11-04 / B24 持续交付：M4-23用户皮肤大小/位置

用户要求继续推进至登录部分外所有可确认功能/设置，不因单项停下。持续实现和macOS运行、每功能根`flutter test`+`flutter analyze`通过后单独中文commit已授权；在线功能保留，按自建可替换后端并提供部署方案；离线优先只是顺序，无分代理，许可暂缓。

E43观察新建皮肤编辑页的大小滑杆、位置方向键/自动对正；一次数值为大小初50、最右70、左侧约20.5、右移显示1。完整范围和保存/使用/导出未操作，仍U。ADR-059按项目方案P：本机用户皮肤大小80–120%、横纵偏移±8%格宽，步1%。创建复制当前参数，设置改动按用户皮肤独立持久化，主盘/编辑器/PNG/GIF一致。

M4-23已提交`c3b9dd2 feat(skins): 支持用户棋子大小位置独立调整`。定向19/19，最终根`flutter test --reporter compact`488通过/5跳过；`flutter analyze --no-pub`无问题；`flutter run -d macos`Build/Sync成功PID63084、VM `127.0.0.1:64399`。跳过要求官方Pikafish/NNUE配置，flutter_tts有SwiftPM未来warning；未做人工窗口视觉检查。

M4-22已提交`b83193e feat(skins): 支持本机多套棋子皮肤`，建立皮肤目录/独立图片ID/创建选择重命名删除。M4-23补上大小/位置独立参数。剩余B24含逐用户阴影、搜索/排序/导出、ZIP/文件夹导入、在线目录+自建后端部署。工作树当前含M4-23源码/测试/文档，请提交前核对。F21/全站未完成。

## 2026-11-04 / B24 持续交付：M4-22本机用户棋子皮肤目录

用户最新要求持续推进，不完成一项就停止，目标为登录部分以外所有可确认功能与设置。持续业务实现/macOS运行、每功能根`flutter test`+`flutter analyze`通过后中文Conventional Commit已授权；在线能力不移出总范围，使用自建可替换后端并提供部署方案；离线优先只是顺序。无分代理。许可决策暂缓，不阻挡开发。

本轮起点磁盘状态：HEAD `5430f52 docs(context): 更新批量导入交接`；此前工作树留有M4-22接口/偏好/文件图片仓库部分改动。已读取AGENTS/README/CURRENT_STATE/HANDOFF/DECISIONS与project-onboarding/flutter-feature/quality-gate及棋盘设计/证据材料。

M4-22已提交`b83193e feat(skins): 支持本机多套棋子皮肤`：ADR-058本机皮肤目录，最多64套用户皮肤；自定义ID引用内置基底风格；复制当前图片覆盖并隔离用户图片文件夹；选择、创建、改名、删除、偏好持久化；主盘/编辑/PNG/GIF读取选中ID图片。M4-23另已独立大小/位置；阴影仍共享基础预设。搜索/排序/导出、ZIP/文件夹导入、在线目录未做。E42/E48源站导入成功/覆盖边界仍U。

M4-22验证：根`flutter test`484通过/5跳过，analyze通过，macOS Debug PID59671/VM `127.0.0.1:59146`；代码已提交。M4-23与当前工作树/下一项见本文件顶部，不宣称F21或全站完成。

## 2026-11-04 / B24 持续交付：M4-21多选棋子图片与 E48 ZIP 说明续审

持续授权仍有效：继续推进登录部分除外的已确认全站功能和设置，不在单功能后停；在线能力保留为自建可替换后端与部署方案；离线优先；无分代理。许可暂缓。M4-24/M4-25分别见本交接顶部；验证后M4-25待提交。

改动：`PieceImageBatchPicker`、`NamedPieceImage`、最多14张/7 MiB读取、控制器整批预检/逐槽保存与失败重试、映射预览弹窗、设置入口及应用/Widget测试。ADR-057、DECISIONS、FEATURE_MATRIX/GAPS、INTERACTION_SPEC、BACKLOG、TRACEABILITY已更新。E42/E48确认访客入口有ZIP/图片多选/文件夹；页面称ZIP可含多套并在下一步选择、只本机保存。但文件选择没有可见结果，未选用户文件；格式/成功/覆盖仍U。本机数量/累计限制和映射交互为P。未支持ZIP、文件夹或完整皮肤清单。

实际验证：定向`flutter test test/application/piece_image_library_test.dart test/widgets/piece_skin_images_test.dart --reporter compact` 10/10；根`flutter test --reporter compact` 481通过/5跳过（官方Pikafish/NNUE测试环境未配置，exit0）；`flutter analyze`无问题；`flutter run -d macos` Build/Sync成功，PID56134、VM `127.0.0.1:53841`，run进程会话仍保持。插件`flutter_tts`有既有SwiftPM兼容警告；CUA窗口人工视觉验收未做。`git diff --check`通过。未加依赖/外部素材。

E48记录位于`docs/research/REFERENCE_EVIDENCE.md`。本轮浏览器以访客默认设置进入皮肤选择器，观察“支持主流皮肤格式；一个压缩包里有多套，下一步可以选导哪些”和只本机保存声明；ZIP按钮没出现可确认文件选择/导入结果，后续关闭说明弹层并回列表，无文件选择。浏览器当前在棋子选择器（所有设置仍默认，未选文件、未应用）；IAB临时页不应作为后续依赖。下一片先实现本机用户棋子皮肤目录/选择/持久化，解决“多个ZIP皮肤集合”可落地模型；随后安全ZIP/文件夹导入和目录搜索/排序/重命名/删除/导出。网站在线皮肤需可替换自建后端及部署方案。不要宣称F21/全站已完成。

## 2026-11-04 / B24 持续交付：M4-20棋子阴影

授权持续到登录后功能除外的全站可确认功能与设置全部推进；离线优先，其它在线服务继续保留并采用自建可替换后端及部署方案；不使用分代理。许可决定暂缓，不阻挡本机开发。

M4-19已提交`1e5f192 feat(skins): 增加落点图片旋转`，475通过/5跳过、analyze无问题、macOS PID51661/VM `127.0.0.1:63351`启动成功；CUA应用窗读取超时、人工视觉验收未完成。M4-20完成本机棋子预设阴影模式及方向/距离/模糊/浓淡偏好，主盘/编辑器/PNG/GIF共享呈现。E43一次示例可观察、范围和映射仍U；项目值域P详ADR-056。定向通过，最终根478通过/5跳过、analyze无问题；最终`flutter run -d macos` Build/Sync成功PID54316，VM `127.0.0.1:51653`，插件`flutter_tts`提示未来SwiftPM兼容警告。CUA视觉验收未做。当前代码/文档待单独中文提交，然后继续B24下一片：先复核皮肤清单/导入证据，再定M4-21。保留macOS实例，不误杀。F21/全站不完整。

## 2026-11-04 / M4-17 棋盘图片图层

实现每种BoardSkin独立的棋盘背景/起点/落点/选中框本机PNG/JPEG覆盖，支持逐槽预览/替换/恢复、受限manifest文件仓库和安全加载；主盘/局面编辑共用，PNG/GIF捕获冻结值。E44源站四种图层观察已核，替换/保存/使用结果仍U；格点/四边/旋转未实现。

定向3/3，全量469通过/5跳过（缺官方Pikafish/NNUE测试环境），analyze0。macOS构建/同步成功、VM `127.0.0.1:50487` PID44785；`open returned 1`所以前台视觉未核。首次全量失败是现存Tab traversal预算不足，扩容后专项及全量通过。ADR-053和研究/计划文档已写，功能已提交`c7e3151 feat(skins): 支持本机棋盘图片图层`；本次交接文档另行提交。

E45补证：落点标记旋转switch可0→1，但没有自定义图片，动画效果和时序仍U；E46重复左边距stepper三次33→34.5，右侧联动约465→465.06；其他边界未知。两次草稿均丢弃且设置恢复。下一步仍在B24：根据E44模型设计并实现棋盘格点定位/坐标/缩放，再单独处理落点标记旋转；几何/旋转精确源站行为未知时保留P/U。之后皮肤清单、ZIP/多文件/文件夹导入和在线自建替换后端部署。不要宣称F21/全站完成。

## 2026-11-03 / M4-16 交接

基于E43观察完成预设专属位置微调：横/纵各自值域-8…8，方向键1%步进，自动对正写0；每个PieceSkin独立持久化。Render层按棋格宽比例只平移面容、关闭hit tests；不改落点、棋谱或引擎。Material3显示当前X/Y及边界disable；PNG/GIF冻结参数。专项测试偏好范围/往返/late-load、方向操作/自动对正、命中测试和快照均通过。

根`flutter test --reporter compact` 466通过/5跳过；`flutter analyze`零问题；`flutter run -d macos` PID33743，VM Service `127.0.0.1:64032`。修正过一次dart assert语法错误后，dart format及专项通过。已更新ADR-052/FEATURE_MATRIX/GAPS/INTERACTION_SPEC/BACKLOG/TRACEABILITY；`git diff --check`通过，提交`ff9feb1 feat(skins): 支持本机棋子位置微调`。

E44已继续审计棋盘新建编辑页：格子/图片两个tab、两个格点slider、左上/右下marker及棋子缩放；左stepper点加号后33→33.5、右边点同步465→约465.02；图片层有棋盘/起点/落点/选中框替换和落点图旋转开关。保存/使用/导出没点，全部结果U；草稿按提示放弃后完整确认设置默认不变。

下一步按E44先设计并实现本机BoardSkin棋盘背景/标记图层覆盖，确保主盘和PNG/GIF共用；再逐项实现格点几何/棋子缩放、阴影、ZIP导入与本机皮肤库管理。源站保存/使用/导出操作未测，仍为U。继续不要关闭F21或宣称全站齐全。

## 2026-11-03 / M4-15 交接

网页E43已核对新建棋子编辑器：大小初值50、最右观察70、左侧附近20.5；位置四方向步进/自动对正/归零；阴影无/柔和/明显和四个参数字段。仅操作了位置右移后自动对正、选择柔和，然后按返回确认放弃草稿。页面恢复到设置页默认棋盘/棋子/100%/坐标开/倒置关，无用户棋谱更改。保存/使用/导出按钮未点，结果为U。E43已记录。

M4-15实现两个 PieceSkin 独立大小偏好80–120%、1%步进、默认100%，与现有全局棋子大小相乘。迁入AppPreferences schema1可选字段，Controller支持异步读取时并发修改保留；BoardDisplayScope传当前皮肤比例；PNG/GIF快照冻结比例。专项通过；根464通过/5跳过，analyze0；macOS run PID32670 / VM `127.0.0.1:63024`。首次目标测试因测试文件漏导入PieceSkin失败、随后analyze报unused import；补导入后通过，记录SESSION_LOG。

`git diff --check`通过；功能提交`9a4001b feat(skins): 支持本机预设棋子缩放`。M4-15范围是项目P，源站精确最小值未知。后续B24优先设计/实现本机每皮肤位置偏移，归零/自动对正保持边界明确；阴影参数与原图/布局作用模型、棋盘图片、ZIP导入另片。全站对标未完成。

## 2026-11-03 / M4-14 交接

M4-14完成F21单棋子图片替换。实现`PieceImagePicker`、`PieceImageRepository`、`PieceImageLibraryController`及PNG/JPEG校验，本机支持目录存储；每种PieceSkin分别保存红黑14个棋子槽位。Material3弹窗可预览当前图、逐项替换/恢复。512 KiB、1024×1024、1MP。图像进入主盘、编辑器及PNG/GIF快照；导入取消不改变原值，读取损坏覆盖时回退默认图。格式/尺寸/Controller/file repository 4项、棋盘映射Widget1项定向通过。

根`flutter test --reporter compact` 461通过/5跳过；`flutter analyze`零问题；`flutter run -d macos`构建并运行PID31311，VM Service `127.0.0.1:61522`。已登记ADR-050、B24/traceability/feature matrix/gaps/design；`git diff --check`通过，功能提交`a755228 feat(skins): 支持本机替换棋子图片`。新需求仍是逐增量门槛。

下一步先继续E41后续的参考站皮肤编辑器边界审计（尺寸/位置/阴影以及保存/应用/取消，恢复页面初始状态），并实现不依赖在线服务的本机单项；批量ZIP导入先定义归档路径/解压上限/失败原子性。源站只记录观察和已操作结果，绝不复制皮肤资源。F21/全站仍未完成。

## 2026-11-03 / M4-10 交接

E40补证：源站走棋音效有音效1/2/随棋子皮肤方案和独立试听；音效2选择退出弹层后仍保留，之后恢复音效1；吃子选择器只有默认音效和试听。最终回到声音设置主页，五音效开关全开、着法朗读关、动画标准、无弹层，棋谱无修改。

项目实现走棋方案本地持久化，`AudioSoundPreviewPort`独立试听三个方案。生成原创 `assets/audio/move2.wav`；随皮肤占位映射当前默认sound1并明确写在UI，因为F21尚无皮肤选择。自定义走棋文件仍优先，方案选择禁用直至恢复默认。其他事件的默认音效未改。ADR-046。

专项audio library 5/5；macOS integration 3/3，覆盖内置五声音/三个预览/本地自定义路径/持久化sound2实际asset调用；根 `flutter test --reporter compact` 446通过/5跳过（引擎环境变量缺失）；`flutter analyze`0问题；`flutter run -d macos`启动PID24870、VM Service `127.0.0.1:54576`，进程继续运行不关闭。构建提示flutter_tts未采用SwiftPM（warning未来可能升级error）；无阻断。

已更新E40、FEATURE_MATRIX/GAPS、BACKLOG、TRACEABILITY、ADR-046、架构、LICENSING（sound2 SHA）；`git diff --check`通过，单独中文提交见git log。下一步F21棋子皮肤与随皮肤映射/动画范围审计，再继续其他本机差距。不要将占位音效说成皮肤联动完成；F28和全站仍不完整。

## 2026-11-03 / M4-09 交接（待本片提交）

F28/B23新增本机自定义音效导入：`AudioFilePicker`/`AudioOverrideRepository`/`AudioFeedbackPort`隔离，`AudioLibraryController`协调，Material对话框只触发应用层；应用支持目录保存按事件独立的文件和schema1清单。512KiB/5秒，支持PCM/IEEE-float WAV和MP3 Layer III。取消不改配置；失败有类型文案；清单路径正则限制并防路径穿越；损坏/缺失的自定义资源退回本机原创默认声音。导入后可试听/恢复默认。

专项 `flutter test test/audio_library_test.dart --reporter expanded` 5/5；macOS `flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded` 2/2（含真实临时自定义WAV本地路径）；根 `flutter test --reporter compact` 446通过/5跳过（需设置官方引擎环境），`flutter analyze` 无问题。`flutter run -d macos` 成功，PID21638，VM Service `127.0.0.1:52467`，仍运行，不要终止。无新依赖；引用既有file_selector/audioplayers。

已更新TRACEABILITY/FEATURE_MATRIX/FEATURE_GAPS/BACKLOG/ADR-045；本片未新增依赖，沿用既有file_selector/audioplayers登记。提交前复核`git diff --check`通过；提交见git log。下一步恢复README/CURRENT_STATE/HANDOFF/DECISIONS，读相关Feature Audit技能，继续B23或转其它本机未完功能。不要宣称源站导入成功、预设音色、其它平台或F28全部完成。证据状态与下一调查见REFERENCE_EVIDENCE E37/E38及FEATURE_GAPS。

## 2026-11-03 / M4-08 交接

用户授权持续审计和实现至参考功能对齐；每功能根目录`flutter test`、`flutter analyze`通过后单独中文Conventional Commit。在线使用自建可替换后端并提供部署方案，当前仍优先离线。上一M4-07提交 `7444c64`；该提交后工作树干净再开始本片。

M4-08 / F28/B23完成独立系统TTS：偏好`AppPreferences.speakMoves`默认false，切换与走棋音效独立；节点位置变更时由BoardFeedbackController计算父局面ChineseNotation，经MoveSpeechPort发给flutter_tts 4.2.5 adapter。适配器只使用已安装中文voice，Android跳过network_required，串行等待播放；没有中文voice或接口异常静默，Web/Linux不调用（插件不声明Linux）。源站E39仅确认五类音效开关互相独立，并未触发棋步/验证朗读声学行为；源站到底对导航读谱是否朗读仍U。macOS integration发起查voice/说话请求1/1，但不把这写成所有设备都可发声。文件/架构/证据/未知见 `TRACEABILITY.md`、`ADR-044`、`FEATURE_GAPS.md`。

实际验证：专项应用/组件14/14；根`flutter test --reporter compact` 441通过/5跳过（官方Pikafish env未设）；`flutter analyze`无问题；`flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded` 1/1；`flutter run -d macos` PID19009，VM service `127.0.0.1:50874`。flutter_tts暂不支持Swift Package Manager并有AVSpeechSynth未来case warning；人工听感/视觉、Linux/Web和其它OS未验。会话仍有`flutter run`前台进程，勿停用户旧窗口。无其它后台任务。

提交前补查`git diff --check`、lock/归档license、`CURRENT_STATE`和本hand-off；单独commit中文消息 `feat(audio): 增加离线着法语音朗读`。之后继续B23：音效方案/试听/本地自定义文件导入，或继续审计F21。

## 2026-11-03 / M4-07 交接

当前用户授权持续审计并实现；每功能根 `flutter test` + `flutter analyze` 通过后单独中文Conventional Commit，用户要求功能全部对齐后再停。线上采用自建可替换后端并提供部署方案；本轮仅继续离线F28，不扩到云能力。先读AGENTS/README/CURRENT_STATE/DECISIONS；检查时工作树从干净提交 `964fcd7` 起。

M4-07为F28/B23新增吃子/将军/将死事件偏好、原创WAV、分类播放及设置开关；源站事件组合优先级未知，项目决策按将死>将军>吃子>普通落子，特殊开关关时普通走棋开关接管。E38补证将军/吃子/绝杀的更换弹层均显示默认试听和独立本机导入说明；没有成功展示文件选择状态，不能称导入成功。素材哈希/决策见LICENSING和ADR-043。新增3素材；修改端口、Controller、audioplayers adapter、preferences/settings、测试、功能矩阵/证据/差距/待办/追踪/许可/决策。

验证实际通过：专项Dart+组件13/13；macOS `flutter test integration_test/audio_feedback_test.dart -d macos --reporter expanded` 1/1加载五条本机WAV；根 `flutter test --reporter compact` 440通过/5跳过（PIKAFISH环境未设）；`flutter analyze` 无问题；普通 `flutter run -d macos` 构建运行PID16653，VM Service `127.0.0.1:49641`。全量首跑既有键盘焦点遍历因设置多三个Switch失败，piece-size测试Tab上限由10扩至16，单项及全量复验通过。需保留初失败记录。Xcode可能打印既有Swift6 warning；其它平台、人工听感/视觉未验。flutter run会话仍运行，不要关闭用户旧窗口。没有其它后台任务。

先检查 `git diff --check`、`git status`、生成器重跑后校验wav哈希，再单独提交：`feat(audio): 增加吃子将军与将死提示音`。随后按B23下一片审计/实现音效选择器或自定义本地导入；不要宣称F28完成。

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS、git status/log与所涉模块文档。用户授权持续实现、每功能完整flutter test+flutter analyze后中文Conventional Commit、实际macOS运行；在线自建可替换后端+部署方案。许可决定暂缓不阻挡，保留来源；没有分代理授权。不能以局部完成结束全站审查。

## 当前检查点

M4-04 / F11 GIF预览+macOS保存已实现，工作树待提交。冻结所选完整线路及方向/显示偏好，最多64帧，首末帧替代时长；原创450×540逐帧、image4.12.0 Isolate编码、12MiB门槛、macOS ImageIO逐帧校验与Foundation atomic。目标10/10、根NNUE435/435、analyze0，macOS实际双帧/2与3秒/原子文件/坏GIF不覆盖1/1。`flutter run -d macos`构建启动，open返回1后VM service出现。随后CUA getApp超时且被中断，人工入口/视觉未验；run session中断后需fresh检查应用状态。

E35 / F11动态图审计已完成，提交见git log及后续补证工作树。自制5着所选线路在当前读到第3着时生成根+5着共6帧，明确包含两步未来、不含另一保存变化；实际GIF89a 500×600。区别时长0.3/0.2…/0.4确认首尾替代对应帧步时，空标题可生成。确认先到预览，下载按钮才触发文件；系统Web Share只验证打开与Escape取消。步时0.2–10秒、首尾0.2–30秒实际钳制。110项manifest已核，参考GIF/截图只在docs研究，不能进产品。最终表单恢复空标题/2.0/2.0/3.0，主谱/分析状态未改、无弹层。

M4-03 / F11 PNG图片复制已完成，本次功能提交见git log。ImageClipboard与TextClipboard/文件端口分离；Dialog保存复制共享首次PngImage、busy互斥、平台失败复用缓存重试、关闭取消迟到生成。MacOsImageClipboard独立MethodChannel；ImageClipboardBridge ImageIO实际解码后声明PNG NSPasteboard并读回核对。生产general，集成使用命名pasteboard避免覆盖用户剪贴板。ADR-041/BOARD_PNG_CLIPBOARD_SLICE。

相关11/11、native真实渲染+命名pasteboard+镜像+坏PNG1/1（00:04）通过；官方NNUE根425/425（session85147，00:55）+analyze0（2.0秒）exit0。现40未全40，完整32基线，core67沿用。general跨应用人工粘贴/其它平台/GIF未验。

M4-02 / F11原创棋盘PNG与macOS文件保存已完成，本次功能提交见git log。BoardImageSnapshot只复制打开时Position/末步/可靠评级/当时有效箭头/双方向及显示偏好；BoardImageDialog固定450×500只读预览、2倍900×1000 PNG、主题字号动画冻结、缓存/重试/退场取消。PngImage独立8MB/4096/400万像素门槛，MacOsPngFileExporter经独立writePngAtomic、ImageIO实际解码、regular目标与Foundation atomic；原文字UTF8/256KB不变。main仅macOS注入，图片复制/GIF/其它平台未做。ADR-040/BOARD_PNG_SLICE。

目标15/15通过；官方NNUE根419/419（session7987，00:55）+analyze0（2.1秒）exit0。macOS生产真实PNG/冻结同局面字节一致/镜像变化/坏PNG目录符号链接不覆盖1/1（00:06）过。现39未全39，完整32基线，core67沿用。`flutter_tester`真实栅格测试两次卡住后SIGINT，未冒充通过；实际生产macOS渲染与原生解码已覆盖。系统chooser人工/外部scope/人工视觉与其它平台未验。

M3-35 / F12 PGN完整所选线路完成，提交见git log。RecordTextExchange.exportText.includeFuture默认true仅PGN，source.currentLine末端goTo只读视图交原PgnCodec.path（core没改），非主线anchor取正确选定未来；false仅根到当前，普通文字/FEN不变。ExportTextDialog复选框默认开、includeComments独立、busy禁改与清状态，copy/file同rendering、固定打开tree/metadata；未来非法评注明确错误/禁导出，显式范围/省评注可恢复，不默丢。帮助/引导/README范围已修，ADR-039/PGN_SELECTED_LINE_SLICE。

目标14/14（80555），根显式NNUE404/404（98447，00:50）+analyze0（78476）exit0，native新实际Foundation文件/两范围两记谱格式/源后来修改不追随/MemoryClipboard一致1/1（5512，00:09）exit0。现38未全38，完整32基线，core67沿用。无测试失败，新增test unused import warning移除；全部session消费完，/tmp/chessnext-pgn-line-*.log。真实系统Chooser/Clipboard仍未验，不扩大含义。

M3-34 / F05,F02左右镜像完成，提交见git log。session.mirrored独立flip会话方向，主盘Material按钮+Tooltip/toggled语义；XiangqiBoard共用BoardSurface镜像，所有交点/坐标/箭层/末步/徽标方向。newGame/replaceTree与flip一样保留会话，退出默认P；Editor独立不继承。AnalysisPanel打开前capture mirror，与side取session.flipped一起经History→Preview→BoardSurface固定来源方向，Main后改不追随。ADR-038/BOARD_MIRROR_SLICE。

目标8/8（37532），根官方NNUE400/400（25411，00:49）+analyze0（84413）exit0；native真实NNUE不重搜/identity与token保留、真实worker组合小盘1/1（56475，00:10）exit0。现37未全37，完整32基线，core67沿用。初目标workerloading用pumpAndSettle超时→用pumpUntil真实异步；Piece实例等号→90格side/type值比；取消tooltip/关闭预览实际标签修，最终8过。测试新增unused import warning移除，最终analyze0。全部session已消费，/tmp/chessnext-mirror-*.log。

M3-33 / K09节点容量已修，提交见git log。GameTree.maxNodes/typed GameTreeCapacityException是纯core统一真值，play先已有复用/合法新增才拒绝，fromJson/PGN文字/仓库/最近阅读/PV同源；Session捕获MoveRejection.capacity不改树/元资料/epoch/两revision/dirty/选子只通知一次，删除腾空间ID递增。AI暂停执方/代次/排程/解锁，error空且保留同Gateway可直接分析；CandidateApplyResult四态和旧tryCandidate bool包装，UI明确容量失败，PV worker映射原子capacity。ADR-037/DOCUMENT_CAPACITY_SLICE。独立4MiB长评注存储限制K10尚无入口预预算，已代码审计记录，未跑超限UI。

最终根395/395（88333，00:46）与analyze0（2394），core67/67（90140）+dart analyze0（74714），目标16/16（78961），native实际2000浅树/AI容量后同NNUE继续分析/FileGameRepository保存新App恢复元资料评注1/1（57594，00:11）均exit0。现36未全36，最近完整32基线。初fixture假定n1留空/首候选searchMoves非空失败，改root留一合法未录入+allowed回退合法集合，并修漏替换后全过；初analyze2curly info修。日志/tmp/chessnext-capacity-*.log，所有session已消费，无后台验证。最后补其它数量常量引用后已再次全量/core/native过。E33已完成参考站镜像/旋转组合/预览方向与PGN文件前后对比，91项manifest全部SHA/bytes/sips尺寸核对；正常方向与原阅读点已恢复、markHandoff。

M3-32 / F32,B08,B09复盘配置已交付，提交见git log。AppPreferences.reviewMode可选枚举/严格类型/逐字段晚读合并与保存失败重试；ReviewOptionsDialog打开读mode，切换立即保存/取消保留（不启停任务）。ReviewPanel注入initialSkipExisting：无结果true，任何已有结果false；skip是单次任务意图，不更改应用API默认和cache完整身份策略。loading配置入口禁用、原epoch/revision保护仍在；其它预算/范围默认未记忆。ADR-036/REVIEW_CONFIGURATION_SLICE。

新增2应用+3组件、连旧目标10/10（93046）；最终官方NNUE根390/390（49975，00:42）+analyze0（15635）exit0；native新配置/真实NNUE/文件新App恢复1/1（85476，00:11）过。现35未全35，完整32基线，core65沿用。初目标未验证Fake试缓存失败是安全策略正确，换VerifiedFake后过；初analyze1info括号修。日志/tmp/chessnext-review-config-*.log，所有session结束。此前根390首过后补帮助文本，已再全量390过。无新依赖资源。

M3-31 / F26,B08,B18当前着本机评级徽标完成，提交见git log。ReviewReport.assess抽取原规则并供报告复用，版本native-wdl-loss-v1/阈值不改；Controller先核epoch/revision/stale，用run身份+node缓存。根/缺失/未评级/bound/mate无徽标，旧谱同ID无借用。BoardSurface顶层IgnorePointer/ExcludeSemantics，语义附真实交点；共享boardSquarePoint翻转镜像/固定格距角徽，不随棋子大小，编辑器不传。六类Material原创图标+可滚动图例，不冒充站点高级算法。showMoveGrades schema1可选默认开/严格类型/晚读合并/串行写/重试，复盘与设置共享，关仍留数值/光圈/其它标记，不重启引擎。BACKLOG勘误：v1原已<2%，先前E32声称有等号差异错误，不改模型。

目标14/14（81530）过；显式官方NNUE根最终385/385（30612，00:42）与analyze0（93098）exit0；macOS新增真实NNUE三局面复盘/徽标/翻转/双入口/文件偏好新App恢复1/1（6123，00:10）exit0。现34未全34，最近完整native32/32（M3-29，06:49）。核心未改65/65+dart analyze沿用。首次根384过1失败：旧字号测试全页SwitchListTile非唯一，scope TextSizeDialog后全量通过。初版其它编译/fixture失败见SESSION_LOG，未隐去。验证进程全结束；日志/tmp/chessnext-grade-*.log。

## 下一可执行

下一提交M4-04本地改动（测试/分析/原生已过），再继续全站功能审计与增量实现；近期候选F28声音/动画设置实测。系统分享与其它平台GIF另片。

M4-03实际使用独立通道而非RecordFileWriter通道；native命名pasteboard由原生写后立即读回相同PNG字节，避免污染general。生产general分支代码相同但未做人工跨应用粘贴，因此不能扩大为系统剪贴板全验收。

E34/E35自制位置图片仍含参考外观资源，只docs研究，不拿作产品/单测渲染素材；样本清单samples/E34-manifest.json与E35-manifest.json。E35动态图是根+所选5着，不是6个棋步；每帧20厘秒来自三项均0.2样本，不代表默认2/2/3时长的成品。截图PNG后缀实际JPEG照旧。clipboard read只处理E34本次image/png，原FEN空读失败不被此改称成功。

E33曾发现F12/B19差距，现M3-35已补：阅读停三着源PGN包含所选线路五着（两未来），项目PGN默认完整所选线路并可关闭未来，不称全树RAV。E33首次FENclipboard空未取值，0字节文件已删除；导出复制后弹层自动退，旧104关闭索引无layout失败已记录；未读其它系统剪贴板。原站镜像/旋转/preview都恢复，正常红下/未镜像/源三着reading+两future/另一branch保留，AI分析0，评级数据保留，无弹层。原始PGN下载在Downloads自有两文件，研究样本sources/SHA已登记。

尚缺B22 hover/站点跨文档与容量、K09统一2000节点门槛、F21素材、F28声音动画、布局/工作区/语言、错题/训练/题库、XQF/CBR/CBL/DhtmlXQ/WXF/RAV/多局/GBK/文件夹拖放、图像GIF/OCR、自建后端认证同步/云库/识图部署、完整重复/长将长捉规则、五平台引擎构建运行发行。离线优先是顺序，不是删除在线范围。

## 关键边界与恢复

纯core+不可变树稳定ID/metadata并列；BoardSession epoch/content revision/positionRevision/dirty分开；Library/Draft/Recent/Preferences独立所有者。UI不IO，主装配注入。一个Gateway共享UCI取消屏障/迟到保护/NNUE身份和TT资源复用；实际macOS签名sandbox helper，仅Debug验过。其它平台/移动FFI/Release签名和系统Open/Save人工选择/外部scope精确释放未验。

M3-30历史64×128/100ms同谱跨位置保留，独立historyEpoch换谱清；latest infos/pending/推荐/局势条仍换位置清，源步数/中文标签仅位置变时算。只读worker预览/800ms显式播放/退场停、源评分冻结；窄短大字compact整页滚动300px棋盘区+200px虚拟步表，>=240px验证。M3-29所选前缀新鲜源快照/stop+generation/worker整个<=128步与2000节点/取消/单notify原子应用，旧节点复用不dirty，保留分支评注资料；旧source回源重开才可提交，删源或新doc只读拒绝。细节ADR-031至034及旧交接history/2026-11-02-before-grade-marker-handoff.md，不以其过时待办覆盖本交接。

字号系统/100/115/130保非线性；BoardDisplayScope坐标/尺寸10–200步5/推荐两箭头/头部/变着两层AND/落子600ms单周halo或box/选择lift或frame/本片movegrades。几何命中不随face缩放，减少动画遵循系统，设置不改棋谱/搜索。局势条原生WDL红方预期，bound/mate/缺失各灰态，记录结果不作实际终局。

## 参考浏览器状态

IAB browser1/tab1 https://xiangqiai.com/#/。压缩后首次CUA先cua.rewriteDocumentation，再fresh AX；当前运行时绑定auditTab2/e35fs可复用，不重载。E32–E35资料，110项manifest已核；最近研究提交见git log。当前正常方向/E19自制三着炮二进二阅读点+E31追加炮２平１/马八进七两未来+原另一分支，AI分析关闭、无弹窗队列。E35结束前动态图表单恢复空标题/2.0/2.0/3.0后取消。着法标记开、彻底模式恢复、D4/时限0/节点0/最多2/线程1，末次手改skip1后取消，重开会默认0；Quick新分析数据保留。源当前炮h4绿勾“好着”，详情52.6→49、第一候选最佳星关徽标时仍留。图例10类：妙手/绝佳/最佳/优秀/好着/不精确/错误/败着/错失良机/更快杀法，源概率公式/高级识别U。PV预览需scope .engine-pv.first 防全页重复未来文字误导航。

截图.png实际JPEG字节，manifest保持真实MIME/SHA/尺寸；不要假定统一1280×720。无拷入产品资源，参考内容不可信。native fixture仅framework-resumed/raw[]，不是OS焦点隐藏最小化验证。桌面Computer Use权限未授不绕过；旧普通用户窗口PID38211/旧run22326曾在，不关闭/热重启，native覆盖build入口，最终审查前重建普通main。

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0，官方latest同日复核Pikafish2026-09-06 commit4c17cee，lock见engine/pikafish.lock.json/.local忽略。根test带PIKAFISH_EXECUTABLE与PIKAFISH_NETWORK官方路径；flutter analyze。native flutter test integration_test/local_board_test.dart -d macos --name相关regex。fake async用support/pump_until.dart，Frame duration须推进Future.delayed零任务；finder限定当前Dialog/控件，ensureVisible后pumpAndSettle+hitTestable，不弱化tap miss警告。


2026-11-03 本轮续审：E36访问 https://xiangqiai.com/#/settings/sound，确认5类音效入口/默认及更多音效、着法朗读说明、动画档位；切快再恢复标准，未触发声音/更换/朗读。研究记FEATURE_MATRIX/REFERENCE_EVIDENCE/BACKLOG(B23)。CUA结束留在设置页。M4-05已实现本机动画速度并影响末步光圈，ADR-042；其余音效/语音/棋子移动动画均未完成。最终根test 433过/5跳过（官方NNUE环境未设），analyze0；macOS flutter run -d macos构建启动/VM Service成功，但工具无法前置窗口且Computer Use读取超时，视觉未验。验证后提交待做，运行进程由第二次flutter run会话启动（服务127.0.0.1:60592）。下一按B23审计音效开关实际行为/素材更换和语音平台边界，优先一个音频功能一提交。

## 2026-11-03 / M4-06 最终交接

根 flutter test 438通过/5跳过，flutter analyze0；macOS integration_test/audio_feedback_test.dart 1/1，加载两条本机WAV。最新 flutter run -d macos 启动PID13873，VM Service 127.0.0.1:63861；Computer Use窗口/人工听感未验。依赖audioplayers 6.8.1；macOS插件有不阻断Swift并发warning。M4-06实现/验证完成，提交见git log。下一继续E37后剩余音效事件/自定义本地WAV/MP3导入/试听和着法朗读，按B23拆片；不要把目前两种短提示音说成F28完成。

## 2026-11-03 / M4-11 交接

E41补审F21：棋盘/棋子设置有上方一方180°开关；皮肤库有搜索/排序/我的/新建/导入/在线入口；编辑器可见棋子尺寸/位置/阴影/逐子图片及棋盘格点/位置/缩放/图像设置。棋子和棋盘空编辑草稿已各自安全丢弃，最终回设置页无修改。导入格式成功、各控件边界、保存/应用/导出、在线服务仍U。详情REFERENCE_EVIDENCE E41、B24。

M4-11已提交`eb44677 feat(board): 支持对面棋子翻转显示`。实现本机持久化`rotateOppositePieces`偏好，默认关闭；主盘/局面编辑/PNG/GIF快照共用。视觉上方阵营随棋盘旋转变化，只有棋子字形旋转。测试覆盖朝向正反、旧schema、坏数据、延迟读取合并。`flutter test --reporter compact` 450通过/5跳过；`flutter analyze`无问题；`flutter run -d macos`构建完成并连VM `127.0.0.1:56207`（PID26430），日志曾提示`Failed to foreground app; open returned 1`后仍成功sync/提供VM服务，记为已启动但前台提示异常。

下一步继续B24：先审计参考站棋子导入/皮肤编辑器保存应用边界，之后将独立的本机皮肤数据模型/选择与用户原创素材创建按增量实现。在线皮肤属于用户选定的自建可替换后端，需后续设计部署方案。F21/全站未完成。

## 2026-11-03 / M4-12 交接

E42补审皮肤选择：五种排序、搜索需回车后筛选、ZIP/图片多选/文件夹导入说明；没有选文件或导入。另新增M4-12原创棋盘配色：宣纸木色/松石青本机偏好，实时用于主盘/编辑/PNG/GIF快照，重开应用恢复。专项相关测试通过，根453/5 skip、analyze0，macOS run PID27652 VM `127.0.0.1:58201`。完整皮肤图片资源与编辑/导入尚未做。M4-12单独提交`de9de01 feat(board): 增加离线棋盘配色`，工作树提交状态以git查验；ADR-048/TRACEABILITY/E42/B24有记录。

## 2026-11-03 / M4-13 交接

M4-13实现“传统圆章/方章墨韵”本机PieceSkin，持久化并覆盖主棋盘/局面编辑/PNG/GIF；“随棋子皮肤”走棋音效与试听分别映射1/2。原自定义音效始终优先。专项目标测试通过；macOS plugin音频集成3/3；全量根456通过/5跳过、analyze0；最新macOS run PID29670/VM `127.0.0.1:60040`。F21皮肤目录、导入和编辑继续B24。代码提交后更新具体提交号。
## 2026-11-04 / E54 显示语言切换实证

访客临时IAB标签4在`https://xiangqiai.com/#/settings`，切English后显示设置页即时翻译，离开再进入显示页仍为英文，切回简体中文后恢复；用户原标签1未触碰。没有刷新/重启或验证繁体/越南语，因此F27全站完整本地化仍开放。操作结果、限制和引用见`REFERENCE_EVIDENCE.md` E54；功能矩阵、缺口、规格、待办和追溯均已同步。标签4仍打开且在设置首页，简体中文已恢复。此审计无需测试/analyze或重启App；下步直接以F27译文覆盖盘点为先，继续全站推进。

随后E55补审`#/settings/operations`：发现独立“云库/大师谱”来源分段，默认云库。点选大师谱后AX选中值切换，离开并重进设置页仍保留；主界面变成大师对局面板，当前临时局面提示无谱，打开筛选弹层见范围/搜索/步数/胜负控件但未提交查询。随后恢复云库默认。查询请求/结果、刷新/重启持久化及离线语义U。用户标签1未触碰；上一临时标签4已关闭。继续审计在线查询行为并盘点F27本地化覆盖。

本轮E56在新的临时标签5/6验证F27：English设置页reload保持；繁體在此页存在简繁混合，越南语此页有译文且示例着法为拉丁记法。临时标签均恢复简体中文并关闭，用户标签1未触碰。其他路由覆盖及重启行为仍U。本机已上锁导致CUA原生App状态探测提示无法解锁；浏览器审计继续成功，未触碰/启动桌面App。当前浏览器仅原始标签1仍开在设置页。

E56材料已提交`a5df531 docs(audit): 验证多语言翻译与重载记忆`；工作树干净。`pgrep`仍仅看到runner PID86855及一个App PID87104，未增加实例。没有测试/analyze/runner。当前 Mac 锁屏；若后续改码，根Flutter test/analyze仍可运行，但要实际macOS前台验收需解锁后复用PID86855，不要另起flutter run。下一步将F27扩展为完整本地化资源盘点；当前无ARB/l10n资源，仅依赖硬编码中文，显示设置对话框等也混合在一起。

随后E57在临时标签7、1280×720验证“棋盘靠左/居中”：靠左主界面棋盘和着法区靠左，AX splitter结构/棋盘宽改变；居中恢复三栏和默认分隔。已恢复居中并关闭标签。源站断点/记忆未知。本机M4-37还没有双预设；需按真实宽高/字号审查再实现。原始IAB标签1仍未操作，现只剩该标签。

E57已提交`d3176c6 docs(audit): 验证棋盘布局预设行为`，记录E57/E56的证据均在研究文档。此提交仅文档，无测试/analyze/macOS启动；本机锁屏令CUA原生应用无法读取。下一切片应检视并实现棋盘靠左布局，使主盘和着法区左置、其余侧栏右置，按宽屏验证，不只增加一个无效偏好控件。执行代码后根目录test/analyze并尽量解锁后复用现有PID86855；不要新开App。全站/语言仍未对齐。

E54/E55文档审计分别提交：`149a153 docs(audit): 验证显示语言切换行为`、`2ee7dc9 docs(audit): 补充谱库来源设置证据`、`649d8fa docs(audit): 验证谱库来源切换保持`、`a446786 docs(audit): 记录大师谱面板与筛选入口`。`git status --short`为空，`git diff --check`通过。此轮未运行测试/analyze/runner，故没有产生新棋盘进程。`pgrep -fal 'chessNext|flutter_tools.snapshot run'`确认既有`flutter run -d macos` PID86855及App PID87104仍在；没有新chessNext.app。下一步：在不提交谱库查询的前提下继续审计站点设置/在线查询的触发边界；然后继续盘点并实现完整F27本地化，持续推进到登录外矩阵差距收敛。
