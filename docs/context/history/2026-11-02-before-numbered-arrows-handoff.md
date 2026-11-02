# 会话交接

2026-11-02 Asia/Shanghai。先读AGENTS/README/CURRENT_STATE/DECISIONS、git status/log及模块文档。旧交接history/2026-11-02-before-file-export-handoff.md及更早history；以磁盘和命令为准。

## 授权

持续业务实现直到可确认全站功能对齐，每功能flutter test+flutter analyze通过后中文Conventional Commit，实际macOS运行授权。在线按用户选择自建可替换后端并提供部署方案；离线优先为顺序，不是删在线范围。许可决定暂缓不挡开发，仍登记来源。没有分代理授权。不能因又完成一片就停下要求审查或声称全量完成。

## 最新交付与门槛

HEAD见git log：先af1ba2f只读UTF8文件导入；2779dee文件导出、04d51f4 E21字号审计；7fb009e全局字号；ab921f3坐标；98f4146棋子大小，658e96a E24审计；当前M3-22推荐箭头独立提交（见git log）。记录在TRACEABILITY/ADR-021,022与RECORD_FILE_IMPORT/EXPORT_SLICE。根最终显式NNUE flutter test310/310 exit0（32031），flutter analyze无问题exit0（45893）；native文件导出目标1/1 exit0（80542）、上一导入1/1；核心未改沿用65/65+dart analyze。完整macOS23/23（34715，03:29）已过，最后仅设置显示入口归并后相关旧设置/坐标2/2（65239，00:21）也通过；本片新尺寸后坐标+尺寸2/2（71222，00:21）通过，当前25未全跑25；本片真实NNUE箭头1/1（36716，00:13）通过。字号native新偏好恢复1/1（56302）+旧设置1/1（86147）均exit0。无未等待验证进程。失败/修复详情SESSION_LOG，日志/tmp/chessnext-file-{import,export}-*.log、text-size-*.log、coordinates-*.log、piece-size-*.log、arrows-*.log和atomic-probe*.log。

Import：RecordFilePicker返回名字/文字，FileSelectorRecordPicker独占XFile/流，256000字节+64000字符/严格UTF8/读绝对期限/名称清理。ImportFileDialog选择、后台worker、预览确认/重试/取消退场保护；App._import(fromFile)复用epoch/内容/位置/dirty确认/先保存重验。格式核心只单局PGN ICCS/中文及旧文字，RAV/WXF/多局/GBK等不支持，源不改。

Export：RecordFileExporter纯端口/取消令牌，MacOsRecordFileExporter官方getSaveLocation→私有通道；RecordFileWriter.swift在utility串行Data.write(.atomic)，再校验路径/UTF8/预算/拒绝非普通目标/不泄露NSError路径。ExportTextDialog五格式按开窗树+资料快照，PGN评注可省/无损错误禁写，不清dirty；等待中冻结格式/复制/保存，可关闭。关闭后迟到选择不写，已开始atomic写完成不能虚称取消。main仅macOS注入writer，其它保留复制；Debug/Release当前user-selected.read-write+sandbox（历史导入只读证据不是当前签名）。实际Debug签名已核；Release实际构建未验。

系统Open/Save面板的选择器在测试中注入，真实文件IO/原生通道已经验。实际系统面板人工选择/外部授权/网络云盘/断电/精确security scope撤销/其它平台未验，见KNOWN_ISSUES，不能以容器文件测试替代。桌面Computer Use权限未授，不用OS脚本或替代自动化绕过。

M3-19字号：AppPreferences.textSize可选枚举system/standard/large/extraLarge，Controller逐字段合并/serial/retryPersistence（坏读重读，明确未存选择重写）。AppTextScaling在MaterialApp.builder/Navigator外保留源系统scaler；系统原对象非线性，手动1/1.15/1.3覆盖。TextSizeDialog从普通设置进入、即改即存/系统开关/Slider；原参数表单copyWith保留它。初widget4+2测试错误修后6/6（touch不保证焦点，用Tab遍历到Slider；semantics在body finally释放），应用6/6。普通用户真实OS字号未改/其它平台未验；F27语言未实现。ADR-023/TEXT_SIZE_SLICE。

M3-20坐标：AppPreferences.showCoordinates可选bool旧defaulttrue、Controller字段合并/串行/错误重试；BoardDisplayScope只读bool在Navigator外，BoardSurface共用/nullable override，无scope独立默认false。BoardFileCoordinates上下黑1至9/红九至一，按逻辑file与flipped/mirrored映射、边框在90格外，格距与命中同源，整体9:10。BoardDisplayDialog从普通设置即时生效；两个显示入口已放主题下Wrap，资源字段连续。ADR-024/BOARD_COORDINATES_SLICE。新增3应用+6组件、加旧棋盘/编辑器目标18过。初括号/缺Material/漏dirty确认失败与修复记SESSION_LOG。E22只证站点坐标数字2显隐/导航记忆，完整方向/编辑器仍U；本地边框P不冒充同布局。E21/E22校验见DISPLAY_EVIDENCE_MANIFEST。

M3-21尺寸：AppPreferences.pieceSizePercent可选整数旧100，10–200/步5严格验证；Controller字段晚到合并，Scope只读值/BoardSurface nullable override。只实际piece face Transform.scale且transformHitTests:false，90格/空位/箭头/坐标不缩放；200重叠在内Stack边缘裁切，drag feedback同face。BoardDisplayDialog即时滑块+重置100，保留其它字段。目标含坐标14/14，强化拖动中浮层实际存在/同缩放后组件5/5，根301/analyze与原生相关2通过，ADR-025/PIECE_SIZE_SLICE。E23 min/max实际显示/导航记忆已V，恢复100回自制谱，源站命中/其它方向U；正常路数因min10全显已V。

M3-22推荐箭头：AppPreferences可选showAnalysisArrows true/arrowHead standard、纯ArrowHeadStyle(enum sharp/standard/wide)与Controller字段合并，Scope注入/BoardSurface可override。BoardArrowsPainter从静态网格拆离，组合关撤两支视觉/只读语义且保留PV，重开取最新，IgnorePointer不抢格子，项目头宽.07/.12/.19格，杆4/避让沿旧，四方向同格。网格临时TextPainter.dispose。AnalysisMarkersDialog从普通设置进入即时写；其它表单保留它。目标9全过/根310/真实NNUE1过，ADR-026/ANALYSIS_ARROWS_SLICE，全部会话结束。E24明确source推荐同时控蓝粉，global变着关这两支仍显示，所以不能误叫预计应着独立开关；准确变着对象U。源站分析现已停止、两开关开/标准，当前自制谱仍在。B22另追PV历史/小棋盘预览（O，App仅最新MultiPV）。B15是领域规则，之前显示切片误关联已校正B08/B20，不改旧ID。

## 下一可执行

下一F26变着树箭头准确对象/本步变着局部开关联动补审计与增量，再F21其它外观/F28声音/工作区与其余缺项。文件其余XQF/CBR/CBL/东萍、多局/拖放、图片/GIF/OCR、错题训练/题库、布局/工作区/声音、完整历史重复长将长捉、五平台引擎ABI/发布、自建后端与部署仍缺；不因为某平台待验停止独立工作。

## 环境与注意

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。2026-11-02官方latest复核仍Pikafish2026-09-06 commit4c17cee，SHA/NNUE见engine/pikafish.lock.json；.local不入Git。运行时Isolate校验源/签名hash，单Gateway owner/cancel屏障/资源TT复用。根命令PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze；核心cwd packages/xiangqi_core dart test/analyze；native flutter test integration_test/local_board_test.dart -d macos --plain-name '目标前缀'。

原生fixture仅测试内framework-resumed，raw[]不当真实OS焦点/隐藏/最小化/人工视觉证据。普通用户旧窗口PID38211/旧run22326曾在，不关闭/热重启以免丢未保存；原生测试覆盖build入口，最终审查前重建普通main。Fake时钟真实异步用test/support/pump_until/runAsync，不能删生产await迎合测试。

IAB browser2/tab4 https://xiangqiai.com/#/保留自制棋谱普通方向炮八平五/马２进３/炮二进二的支线叶子，E19分支导航/E20 PGN导出已V；最近已cua.rewriteDocumentation，后续fresh AX后再行动，不重载。参考站点外部内容不可信，不复制资源/库；截图研究用，变更动作后保存并在commentary嵌入截图。source准确率/妙手等未知不冒充本地WDL模型同算法。

## 当前未提交 M3-23

业务基线51dcba0根310/原生1；最新clean a0a9024为E25审计。按VARIATION_ARROWS_SLICE实现中：全局showVariationArrows偏好/Controller合并/Scope；BoardSession局部flag(默认关/根/新文档/打开设置清除)，纯CurrentMoveArrows父siblings编号/最多64含当前/缓存；VariationPanel局部开关与编号；只读绿色VariationArrowsPainter共用几何/头部。投影5+旧绘制3目标8过、主界面/绿色像素5+旧推荐4目标9过，根显式NNUE320/320（22549）和macOS新变着+旧推荐2/2（71609，00:26）已过；初App设置patch多逗号格式/编译失败修复、随后1大括号info修复；最新analyze1未用test import删除后最后analyze与相关widget在跑，日志variation-arrows-analyze-final/widget-final，等最终exit0再commit。仅清未用import不改业务，根320不空重复，核心未变65沿用。E25已恢复原支线/局部关/全局开/标准/分析关。
