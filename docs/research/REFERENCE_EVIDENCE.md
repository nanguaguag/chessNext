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
