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

## E10 / 2026-11-02 编辑器续审（访客桌面）

实际操作：编辑→清空→把黑将从d9移到e9→完成。观察到将帅照面提示，点击完成仍停留编辑器并出现“无效的局面”。[AX](editor-invalid-submit-2026-11-02-ax.txt)、[截图](screenshots/editor-facing-2026-11-02.png)。

清空只留黑将d9/红帅e0且保留当前先手；先切黑先再清空，黑先保持：[AX](editor-clear-black-2026-11-02-ax.txt)、[清空截图](screenshots/editor-clear-2026-11-02.png)。初始局面按钮将先手重置红先：[AX](editor-initial-black-2026-11-02-ax.txt)。

清空后红黑互换：黑将e9、红帅d0，先手切黑，即纵向映射后换色；[AX](editor-swap-2026-11-02-ax.txt)、[截图](screenshots/editor-swap-2026-11-02.png)。旋转/左右翻转控件入口可见；左右翻转后导出FEN显示复制成功，但浏览器Clipboard读取为空，未验证真实导出内容，也未以此证明是否改动底层FEN。

仅研究与测试证据，不作产品素材。没有登录、注册或调用私有API。

E10续：清空后点击灰色红帅棋子盒再点e1，没有新增第二帅；选择红兵后连续点a3/c3，两兵均出现且盒仍选中。[截图](screenshots/editor-palette-2026-11-02.png)。2026-11-02访客、左右镜像视图；棋子数量限制与连续放子为V，截图仅研究证据。

## E11 / 2026-11-02 文字导入（V）

https://xiangqiai.com/#/，访客桌面。导入对话框粘贴自制标准初始FEN + `moves h2e2 b9c7`，导入显示“FEN局面·2步”，此前测试局面未保存，选择不保存后出现“导入成功”，棋谱列有炮二平五/马２进３。[AX](text-import-2026-11-02-ax.txt)、[截图](screenshots/text-import-2026-11-02.png)。该次不验证URL、中文、复杂分支格式或非法输入处理；没有上传用户棋谱、登录或调用私有API。

## E12 / 2026-11-02 整谱复盘续审

URL https://xiangqiai.com/#/，IAB访客桌面，E11自制两步谱h2e2/b9c7，当前游标为开始。资源加载遮罩消失后操作，不注册、不写入账号。截图仅研究，不进产品资源。

- O：棋谱分析先选快速（最佳着法）或彻底（所有可接受着法）。本次首次打开配置显示每局面2.0秒、深度16、节点0万、线程1、当前着法列表、跳过已分析开启、3个局面；未清空站点存储，不把采样值当永久默认。见[配置AX](review-options-2026-11-02-ax.txt)、[截图](screenshots/review-options-2026-11-02.png)、[模式](review-modes-2026-11-02-ax.txt)。
- V：快速开始出现1/3进度、当前着法马２进３（先处理叶局面的观察）、候选/深度和取消按钮；随后完成为分析结果，红100.0%/黑88.8%和平均损失等，仅单次输出、不是算法复刻依据。[运行](review-running-2026-11-02-ax.txt)、[结果](review-result-2026-11-02-ax.txt)、[截图](screenshots/review-result-2026-11-02.png)。
- O：标记说明包含妙手、绝佳、最佳、优秀、好着、不精确、错误、败着、错失良机、更快杀法；界面声明胜率损失2/5/10/20%分界。未验证算法或分类正确性。[说明](review-legend-2026-11-02-ax.txt)、[截图](screenshots/review-legend-2026-11-02.png)。
- V：重新分析时跳过开关初值变为关；开启后待处理数量由3变0。0局面仍可点开始，提示没有需要分析的局面，随后关闭配置返回棋盘。[跳过](review-skip-2026-11-02-ax.txt)、[空队列](review-empty-2026-11-02-ax.txt)。AX过渡曾滞后，后续full状态确认配置已关闭，旧索引因此不可复用。
- V：再开重算，将时间改5秒、深度通过只读步进按钮降为0（截图已看见0），跳过关闭。运行1/3时点取消，先显示正在取消/禁用按钮及已取消提示；随后运行面板消失，分析结果入口仍保留。[取消](review-cancelled-2026-11-02-ax.txt)、[停止](review-stopped-2026-11-02-ax.txt)、[取消参数](screenshots/review-cancel-options-2026-11-02.png)。不能由此推断旧结果覆盖/丢弃的全部规则。

U：彻底模式实际执行、所有分支范围、参数极值/全0、缓存键与跨重启、准确率和胜率换算公式、妙手/唯一着判断仍须补证。运行进度与最终图形/等级应分开验证，不能从图标推断逻辑。

## 2026-11-02 原生批量搜索前核查（D）

固定tag2026-09-06官方[uci.cpp](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/uci.cpp)解析可同时接收depth/movetime/nodes，searchmoves必须放最后；ucinewgame清空搜索状态。[ucioption.cpp](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/ucioption.cpp)即使同值仍执行变更回调，[engine.cpp](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/engine.cpp)线程/Hash回调会调整资源，[tt.cpp](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/tt.cpp)重分配Hash并清空。当前适配器每次搜索都发送三项setoption和ucinewgame，批量分析前应分别补组合限额、会话/资源复用；实际性能改进幅度需测量，不凭源码宣称提速百分比。

## E13 / 2026-11-02 变着与彻底复盘（访客桌面）

URL https://xiangqiai.com/#/，IAB；沿用E11自制两步谱及E12浏览器存储，非清洁默认状态。增加b2e2（炮八平五）构成四局面棋树；无账号、私有API或用户棋谱。

- V：从炮八平五回到开始，着法列表仍显示该线路；下一着直接回到炮八平五。点击同级炮二平五切换，显示其后马２进３。见[回退AX](branch-back-2026-11-02-ax.txt)、[截图](screenshots/branch-back-2026-11-02.png)、[切换](branch-select-2026-11-02-ax.txt)。
- V：本步变着列出当前节点同级着法。置顶炮八平五后列表顺序和禁用按钮改变，当前炮二平五线路保持；随后置顶炮二平五还原。删除入口仅O，未执行。见[提升AX](branch-promote-2026-11-02-ax.txt)、[截图](screenshots/branch-promote-2026-11-02.png)。
- V：当前线路范围计3局面（含游标之后）；所有变着计4。该次改变用时后开启跳过仍4，不能推断缓存键。见[线路](review-line-scope-2026-11-02-ax.txt)、[整树](review-tree-scope-2026-11-02-ax.txt)、[跳过](review-tree-skip-2026-11-02-ax.txt)。
- O/V：彻底配置多出最多着法数5，声明含最佳、收够即停；本次5秒/深度0/节点0/线程1、整树范围运行，从叶局面1/4和第1候选到完成。结果红98.3%/黑94.3%仅单次观测。见[配置](review-deep-options-2026-11-02-ax.txt)、[运行](review-deep-running-2026-11-02-ax.txt)、[终态](review-deep-progress-2026-11-02-ax.txt)、[结果截图](screenshots/review-deep-result-2026-11-02.png)。
- O/V：完成后本步变着已有两炮，另列引擎建议兵七进一/兵三进一/马八进七，未自动入谱。当前炮二平五时点击红方建议兵七进一的试走，列表变为开始→兵七进一，已保存变化由1增2、本步变着新增兵七进一；即在父局面新增并切换同级分支，并非黑方当前局面追加。见[分析后详情](review-deep-moves-2026-11-02-ax.txt)、[试走AX](branch-engine-trial-2026-11-02-ax.txt)、[截图](screenshots/branch-engine-trial-2026-11-02.png)。

U：候选预算按局面还是每候选、可接受着法筛选、评分/准确率公式、缓存跨重启及取消结果覆盖策略、删除交互。E12取消后再看摘要数值曾变化，不能声称取消保证结果回滚。截图仅用于研究。

## E14 / 2026-11-02 彻底候选与单步入口

URL https://xiangqiai.com/#/，IAB访客，E11/E13沿用存储及自制棋树。视图保留早期左右镜像，不能把屏幕坐标直接当逻辑棋盘坐标。无账号/私有API/用户棋谱。以下是采样，不代表永久默认或算法证明。

- V/O：彻底配置由5秒减至0（每次0.5秒），深度0加至4、最多着法5减至2（此时减按钮禁用）；节点0/线程1，当前线路/不跳过，待处理2局面。[配置AX](deep-candidates-options-2026-11-02-ax.txt)、[截图](screenshots/deep-candidates-options-2026-11-02.png)。候选上限最大值未测，不能由最小值推断。
- V：执行出现正在分析/当前候选兵三进一/深度4，曾短暂显示第0/0同时结果可见；后运行面板消失、结果摘要保留。[运行](deep-candidates-running-2026-11-02-ax.txt)、[终态](deep-candidates-result-2026-11-02-ax.txt)、[结果截图](screenshots/deep-candidates-result-2026-11-02.png)。这次太快未完整采样候选/局面先后次序，不能计时证明每候选或每局面预算。
- V/O：关闭结果后仍保留已有三条本步变着（炮二平五51%、炮八平五54%、兵七进一52%），另列兵三进一53%建议；旧的马八进七建议不再列出。最多2并未删除原始已存棋谱分支。[详情](deep-candidates-moves-2026-11-02-ax.txt)、[截图](screenshots/deep-candidates-moves-2026-11-02.png)。不能从总显示行数推断所有行都本次重算或可接受阈值。
- V：沿自制线路追加卒３进１、炮八平五后，后者详情出现彻底分析可行着法与设置；前一着详情因其父局面已有分析，展示已有建议。[首次节点](deep-single-entry-2026-11-02-ax.txt)、[新父局面入口](deep-single-fresh-2026-11-02-ax.txt)、[截图](screenshots/deep-single-fresh-2026-11-02.png)。只记录实际中文线路，不凭镜像坐标猜测FEN。
- O：单步设置显示同一组时限0、深度4、节点0、最多2，没有整谱范围/线程项；本次继承采样值，尚未双向修改证明持久存储关系。[单步配置](deep-single-options-2026-11-02-ax.txt)、[截图](screenshots/deep-single-options-2026-11-02.png)。
- V：完成设置并执行单步分析，红方炮八平五仍选中、未自动增加棋谱分支；出现红方建议兵七进一65%/炮二平五56%与试走按钮，用户原着仍保留且未显示评分。说明该入口针对当前着法的父局面候选，不能向黑方当前盘面直接追加红方建议。[操作](deep-single-running-2026-11-02-ax.txt)、[完整结果AX](deep-single-result-2026-11-02-ax.txt)、[截图](screenshots/deep-single-result-2026-11-02.png)。本次未再试走/删除；父局面试走入同级已由E13验证。

U：可接受阈值、逐次排除还是MultiPV、每候选/局面预算如何累计、全0/最大值、单步取消与AI抢占、同设置缓存深浅合并，以及胜率/准确率公式。不能以自有模型冒充同一算法。

## E15 / 2026-11-02 指南与访客界面差异

D：[官方使用指南](https://xiangqiai.com/guide/)本次抓取声明标准模式及题库；未给页面构建号。

O/V：同日IAB访客菜单未观察到题库入口；打开棋谱分析方式选择器实际只列快速与彻底。[菜单AX](guide-menu-2026-11-02-ax.txt)、[截图](screenshots/guide-menu-2026-11-02.png)、[方式AX](guide-modes-2026-11-02-ax.txt)、[截图](screenshots/guide-modes-2026-11-02.png)。只验证控件可见，不代表文档中其他版本不存在该能力。未登录/注册/访问私有API，未开始新分析。

U：版本、设备或账号造成的差异，以及题库运行/标准配置。F33保留为D待核，不能凭指南宣称已运行或删去需求。指南胜率/准确率数学公式仍未取得。

## E16 / 2026-11-02 访客存题登录边界

URL https://xiangqiai.com/#/，E14同一自制棋谱访客，无账号。点击当前着法详情“存题”，V弹出“需要登录 / 该功能需要登录后才能使用，现在去登录吗？”取消后返回原谱，未登录/上传/新增题。[AX](E16-save-puzzle-login-ax.txt)、[截图](screenshots/E16-save-puzzle-login.png)。存题执行/训练流程仍U；本地错题功能是项目离线优先设计，不假称已确认网站登录后流程。

## E17 / 2026-11-02 访客最近阅读与公开入口

V：菜单→最近阅读，URL https://xiangqiai.com/#/records/recent ，访客无需登录即可进入；加载后“还没有阅读记录”。[AX](E17-recent-empty-ax.txt)、[截图](screenshots/E17-recent-empty.png)。此前自制棋谱编辑未出现阅读记录，不能据此断定所有草稿永不记录。

O/V：菜单→棋谱库→官方精选→古谱→事林广记→鸿雁惊寒副图2，公开只读标题及3/3章节导航出现（https://xiangqiai.com/#/c/034nmKTWYSb745Ug0GX29J/3），实际只显示开始、下一着禁用，没有观察到着法载入；不能把目录“6回合”当实际加载成功。[AX](E17-public-open-ax.txt)、[截图](screenshots/E17-public-open.png)。再菜单→最近阅读，仍显示空列表。[AX](E17-recent-after-open-ax.txt)、[截图](screenshots/E17-recent-after-open.png)。未获取私有API/复制棋谱数据/下载资源；自制棋谱原状态可能被公开页替换，但只是本轮研究自制材料。

U：站点阅读记录生成、去重/上限、持久化/游标恢复、跨设备同步、公开棋谱着法加载未成功原因。只将入口及空态标V。项目后续离线最近阅读的已保存棋谱ID/游标/排序为P，须独立验收。

## E18 / 2026-11-02 按钮说明与引导重放

前置E17公开只读页（https://xiangqiai.com/#/c/034nmKTWYSb745Ug0GX29J/3），访客，原着法未成功载入。菜单→按钮说明：V打开独立说明层，可见15组功能和进入引导入口；“知道了”关闭回原只读页，无需登录。[AX](E18-button-help-ax.txt)、[截图](screenshots/E18-button-help.png)。文本说明涉及导航、AI、导入、布局/变着；说明文字O不代表相应业务全部运行验证。

O：首尾图标的说明声称跳到前/后有变着的局面，无分支才到开头/末尾。本轮未操作带分支棋谱，不标V。现App绝对首尾不等同此分支跳转，缺口仍在F01/F13。

V：重新菜单→新手引导，出现1/4引导层及跳过按钮，第一步定位分析入口；点击跳过回原只读页，未开启引擎或修改棋谱。[AX](E18-tour-replay-ax.txt)、[截图](screenshots/E18-tour-replay.png)。此前E01四步首次引导已采样，本轮只验证重放首步/跳过；其余步骤/关闭后的持久标记仍U。本项目帮助需使用原创文字、实际控件和当前功能边界，不复制网页图标/图像/文案。

## E19 / 2026-11-02 分支点导航实际执行

URL https://xiangqiai.com/#/，访客，E18公开只读页点击新局后用鼠标创建自制棋树，无账号/资源下载/用户棋谱。新局截图棋盘正常方向，左红炮实际显示炮八平五，**不沿用E14旧镜像坐标**。

V：逐步自制炮八平五→马２进３→马八进七→马８进７，回到第二着，再落炮二进二，形成第二着局面有两个子节点（马八进七有后续马８进７；新炮二进二当前选中）。[创建AX](E19-branch-created-ax.txt)、[截图](screenshots/E19-branch-created.png)。只测试自制数据，未置顶/删除。

V：底部首端图标从炮二进二跳回马２进３分支点（没有直接到root），再按一次到开始。[到分支AX](E19-back-to-fork-ax.txt)、[到root AX](E19-back-to-root-ax.txt)。说明当前分支点本身被下一次后退跳过。

V：底部末端图标从开始跳到马２进３分支点，再按一次到所选炮二进二末端（没有强制回主线马八进七/马８进７）。[到分支AX](E19-forward-to-fork-ax.txt)、[截图](screenshots/E19-forward-to-fork.png)、[所选末端AX](E19-forward-to-selected-end-ax.txt)、[截图](screenshots/E19-forward-to-selected-end.png)。与E18说明一致：优先严格前/后分支点，没有其它点则到首尾。

U：多层嵌套分支/重复局面/当前根已有多个子节点等未在站点执行；用户更改线路后记忆范围仍需采样。项目增量应以稳定节点和所选线路实现严格前后最近分支，绝对首尾可保留为独立明确入口；读谱不改内容且应经引擎协调器暂停AI/保护旧结果。

## E20 / 2026-11-02 自制PGN文件实际导出

URL https://xiangqiai.com/#/，E19同一访客自制有分支棋树，当前炮二进二。保存/分享→分享/导出→PGN文件，先监听浏览器download再点击，V收到本机文件。源名xiangqiai_2026_11-02_05_38_47.pgn，151字节UTF8无BOM，SHA256 6f19538be1cb55cf50bc62f958f6ee842a9d39c0f0d4f9e3b5811d4f67b6e5f5，副本[样本](samples/E20-self-created-iccs.pgn)/[清单](samples/E20-manifest.json)/[导出后截图](screenshots/E20-pgn-export.png)。只含Agent自制棋步，不复制站点库或资源。

V：标签Game=Chinese Chess、Result=*、FEN双字段初始局面w、Format=ICCS；正文B2-E2/B9-C7/H2-H4至当前选中支线末端，另一主线马八进七/马８进７不在输出。可证本样本路径导出，不能推断所有导出格式/设置/评注/终局/黑方先手/编码均同。PGN导入尚未在站点执行。官方格式调查另见PGN_RESEARCH，D与本操作V分开。

## E21 / 2026-11-02 显示字号实际设置

URL https://xiangqiai.com/#/settings/display，访客桌面IAB，本机系统字号100%，初始follow开。仅自制E19棋树，所有AI关。菜单→设置→显示与语言。

V：关“跟随系统”后slider0；设2显示130%（特大），设1显示115%（大），预览及页面字号变化。开跟随显示100%且slider0；再关仍100%，未保留115%手动值。在follow开时直接设slider1，自动变follow关/115%。选115%按Escape回棋盘，再按菜单→设置→显示与语言，仍115%/follow关，证明本页导航间记忆，未重载/重启浏览器，不推断长期存储。自制谱着法/分支仍在，无落子/分析。最后恢复follow开/100%，Escape回原棋谱，已markHandoff。

[130%截图](screenshots/E21-display-extra-large.png)/[AX](E21-display-extra-large.ax.txt)、[115%截图](screenshots/E21-display-large.png)/[AX](E21-display-large.ax.txt)、[大字号棋盘](screenshots/E21-board-large.png)、[恢复截图](screenshots/E21-display-restored.png)。截图仅证据，非产品素材。系统非100%/不同平台非线性比例、页重载/跨进程记忆、语言选择与布局切换本轮未验（U/O）。

## E22 / 2026-11-02 棋盘坐标显隐

URL https://xiangqiai.com/#/settings与/#/，访客IAB，E19同一自制树/AI全关/系统字号恢复100%。设置棋盘与棋子内显示坐标初开，关闭后Escape回棋盘，原顶部空马位上方数字2消失；再入设置开关仍关（[AX](E22-coordinates-off.ax.txt)）。恢复开后回棋盘，顶部2重新可见，自制着法及另一分支仍在。[关闭截图](screenshots/E22-coordinates-off.png)/[恢复截图](screenshots/E22-coordinates-on.png)。V仅开关/页间记忆和可见数字显隐；其它数字大多被当前棋子遮挡，不能证明全部标注/翻转/镜像/编辑器/重载行为。项目独立坐标边框及红黑完整路数映射是P，后续测试不冒充站点V。

E21/E22截图与AX的尺寸/字节/SHA及来源用途统一见[显示证据清单](DISPLAY_EVIDENCE_MANIFEST.json)，不是产品可再分发素材许可声明。

## E23 / 2026-11-02 棋子大小范围与实际效果

URL https://xiangqiai.com/#/settings与/#/，访客IAB，E19自制树，所有AI关，系统字号100/坐标开。只读观察已显示的“棋子大小”slider DOM属性min=10/max=200/step=5/value=100（O）；通过AX setValue10与200，标签与滑块值分别更新（V）。Escape回棋盘，10%接近小点，200%发生相邻重叠和边缘裁切（V）；两次回访设置仍保留该值，仅证页间记忆。最后恢复100，回自制棋盘并markHandoff，无落子/谱替换。

[10%棋盘](screenshots/E23-piece-size-min.png)、[200%棋盘](screenshots/E23-piece-size-max.png)/[最大值AX](E23-piece-size-max.ax.txt)、[恢复100%](screenshots/E23-piece-size-restored.png)。10%下完整显示正常方向顶部Arabic1至9、底部中文九至一（V），补E22此前被棋子遮挡的正常方向未知；翻转/镜像/编辑/点击命中/重载仍未在站点操作，不从截图推算法。来源/摘要见DISPLAY_EVIDENCE_MANIFEST。

## E24 / 2026-11-02 实际推荐箭头组合与头部样式

URL https://xiangqiai.com/#/与/#/settings/analysis，访客IAB，E19自制三着支线末端，棋子100/字号系统100/坐标开，起始所有AI及分析关闭。启动分析实际出现D15等PV和蓝色本步/粉色预计应着两支箭头（V）；官方指南也如此解释颜色（D，https://xiangqiai.com/guide/）。[标准基线](screenshots/E24-arrows-standard.png)。

设置推荐箭头关、变着箭头仍开，返回棋盘分析PV有效但蓝/粉两支均不见（V）[关闭截图](screenshots/E24-arrows-recommendation-off.png)。重新推荐开、变着关、选宽，返回后蓝粉两支都在（V）[宽头](screenshots/E24-arrows-wide.png)。说明“变着箭头”开关不是预计应着的独立开关；其准确对象/本步变着局部开关联动未在本轮操作，保留U。选尖，返回可见更窄头部（V）[尖头](screenshots/E24-arrows-sharp.png)/[AX](E24-arrows-sharp.ax.txt)。本步和应着会随引擎PV变化，图片非固定走法比较，不声称量出原站像素算法。

最终停止分析（checkbox0，[截短AX](E24-analysis-stopped.ax.txt)，明确保留前2500字符状态证据），恢复推荐/变着均开、标准样式，回原自制树并markHandoff。[恢复设置](screenshots/E24-arrows-restored-settings.png)。未落子或开启AI自动走。PW checkbox locator找不到，改fresh AX15成功停止；没把失败点击当完成。

O：分析结果持续有多张不同深度的PV历史卡，标准基线截图还出现小棋盘预览；本地目前只显示最新MultiPV，历史/预览的触发与关闭流程待独立审计B22。全部截图/AX来源/摘要见DISPLAY_EVIDENCE_MANIFEST，不作产品素材。

## E25 / 2026-11-02 本步变着编号箭头、双开关与根边界

URL https://xiangqiai.com/#/、/#/settings/analysis，访客IAB，E19同一自制支线炮二进二，分析与AI均关。全局变着开/本步变着局部“棋盘箭头”关时无绿箭头；局部开后在当前已走完的棋盘上显示两条绿箭头：马八进七（编号1）和已选炮二进二（V）。起点属上一局面，并非当前局面的下一着。[开启](screenshots/E25-variation-arrows-on.png)/[编号](screenshots/E25-numbered-current-variations.png)。

全局变着关，返回主页面局部变回关（O，不由此推断是全局强制还是页面状态重建）；再次局部开为1但绿箭头仍无（V）[全局关AX](E25-global-off.ax.txt)/[局部开但全局关截图](screenshots/E25-local-on-with-global-off.png)。局部开后回设置全局仍关，说明局部不会改全局偏好。恢复全局开后返回局部又关，再开则有绿箭头。可确认两层都开才显示；精确页生命周期内部原因U。

在可见编号1中心（截图1280×720坐标463,544）点一次，当前仍炮二进二，未换支线（V，仅这个点）[结果](screenshots/E25-number-click-result.png)。上一着到马２进３，局部仍开，此时本步只有1项，仍画其黑马绿箭头（V）[单项](screenshots/E25-single-sibling.png)。再上一着两次到根，着法详情改为空态且无箭头/开关；下一着回第一步时局部关（V）[根](screenshots/E25-root-no-current-arrows.png)。

最后下一着回原炮二进二支线末端，局部关，全局开/标准/棋子100/字号系统，分析0，未新落子/置顶/删除。[恢复截图](screenshots/E25-restored.png)/[恢复AX](E25-restored.ax.txt，过滤超长引擎历史text行保留操作状态，非完整AX)。不同屏幕/翻转/编号其它点交互/超多兄弟/跨重载仍U。截图及AX摘要见DISPLAY_EVIDENCE_MANIFEST。

## E26 / 2026-11-02 局势条开关、旋转与停止状态

URL https://xiangqiai.com/#/、/#/settings/analysis，访客IAB，E19自制支线，E24分析已停止但保留PV历史/局势显示。设置局势条初开，关后返回红黑竖条消失，棋盘宽度分隔比例实际从70变68（V）；重开恢复70和竖条。[关闭](screenshots/E26-evaluation-bar-off.png)。

点翻转先只打开含旋转/左右翻转的菜单（O，[菜单](screenshots/E26-flip-menu.png)，未将这一步当已翻转），再点旋转棋盘，红棋到上/黑棋到下，竖条相应红上黑下（V）[旋转](screenshots/E26-evaluation-bar-flipped.png)。停止分析时这些显示仍存在（V），但历史PV卡仍写红分而曲线/云库标签已随视角改，不能推断所有历史卡视角一致。

最后再实际旋转恢复正常红下黑上，局势条开、分析0/AI关/本步局部箭头关，原自制支线仍选中。[恢复](screenshots/E26-evaluation-bar-restored.png)/[过滤历史行AX](E26-restored.ax.txt)。没有新落子/替换谱。来源/SHA见DISPLAY_EVIDENCE_MANIFEST。原站比例公式、完全无分析数据的空态/跨局面缓存/杀棋或边界值比例仍U。本地方案以原生WDL预期得分明确呈现，缺失不伪造50%，不冒充同公式。

## E27 / 2026-11-02 着法标记开关，效果仍未知

https://xiangqiai.com/#/settings/analysis 与/#/，访客IAB，E19自制三着支线，分析已关。着法标记初开，关闭后AX switch0，返回同一棋盘。两张[开](screenshots/E27-markers-on.png)/[关](screenshots/E27-markers-off.png)图未见可确认差异，不能把此开关说成最后落子光圈开关，也不能判定无效。AX [开](E27-markers-on-settings.txt)/[关](E27-markers-off-settings.txt)是设置状态V，具体标记对象仍U，下一用有已评估评级的自制谱再验。已恢复开，未改谱。

## E28 / 2026-11-02 落子标记两样式

https://xiangqiai.com/#/settings/board 与/#/，访客IAB，E19自制炮二进二末端，分析/AI关。初旋转光圈选中；选方框后返回棋盘，炮所在终点出现白色四角方框，原起点仍为小圆环（V，[方框](screenshots/E28-last-move-box.png)）。截图右下小棋盘为鼠标停PV上出现的预览，仅O，不把它归因于落子设置。回设置仍方框选中（V，[回访AX](E28-last-move-box-revisit.txt)）。再选旋转光圈恢复原终点光圈（V，[恢复](screenshots/E28-last-move-halo-restored.png)），完整棋树/选中着不变，所有分析/AI仍关。

旋转动画持续时长/系统减少动画/翻转/编辑器/重载记忆仍U；项目采用有限一次旋转并尊重减少动画为P，不能说同原站时序。图片为JPEG字节但保留原截图文件名.png，清单已按实际签名修正mime与尺寸（此前误按PNG字节偏移读JPEG导致错误尺寸，SHA不变）。
