# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS、git status/log与所涉模块文档。用户授权持续实现、每功能完整flutter test+flutter analyze后中文Conventional Commit、实际macOS运行；在线自建可替换后端+部署方案。许可决定暂缓不阻挡，保留来源；没有分代理授权。不能以局部完成结束全站审查。

## 当前检查点

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

下一M4-04 / F11,B11,B19：先写动态图切片设计/ADR，固定不可变根+所选线路快照、原创帧绘制、步时/首尾停留、帧数/像素/总时长/编码字节预算及失败模型；再实现预览和macOS GIF文件保存。系统外发分享、超长谱策略与其它平台另片，不能用E35参考GIF作产品fixture或视觉资源。

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
