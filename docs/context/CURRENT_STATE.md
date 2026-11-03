# 当前状态

## 最新交付 M4-12（2026-11-03）

F21/B24本机原创棋盘配色选择已完成：宣纸木色/松石青，即时应用并持久化，BoardDisplayScope贯通主棋盘、局面编辑、PNG/GIF冻结快照。全量根测试453通过/5跳过，analyze0；macOS `flutter run -d macos`构建/同步成功，VM `127.0.0.1:58201`、PID27652。M4-12提交待本次代码提交完成后登记。F21皮肤清单、图片导入、编辑器及在线自建后端仍未完成。E42补充排序/搜索/导入入口实测。

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

实际边界见architecture/IMPLEMENTED_MODULES及ADR-005至042。

## 最新验证

M4-08：根 `flutter test --reporter compact` 441通过/5跳过（仅未配置官方Pikafish环境）；`flutter analyze` 无问题。专项应用/组件14/14；macOS integration_test/audio_feedback_test.dart 1/1，五条声音asset及TTS通道请求成功。普通 `flutter run -d macos` 构建启动PID19009，VM Service `127.0.0.1:50874`。flutter_tts暂不支持Swift Package Manager（Flutter未来可能升级为错误）并有AVSpeechSynth枚举warning。未能人工确认语音听感/主窗口视觉，Linux/Web与其他系统未验。历史引擎实机测试见SESSION_LOG。

生产main有文件导入/仅macOS文件导出；当前Debug/Release user-selected.read-write+sandbox，实际Debug签名已核，Release实际构建签名未验。系统Open/Save面板/外部授权/精确scope释放、真实OS焦点/最小化/人工视觉未验，Computer Use桌面权限未授不绕过；native fixture只保持framework-resumed，raw[]不是OS验证。Android/iOS/Windows/Linux运行与移动FFI仍未验/未实现。

## 下一步与环境

E35证据已复核110项；E38/E39补审F28更换弹层和独立音效开关。M4-04 / F11 GIF预览和macOS保存已交付，提交见git log。M4-05/M4-06/M4-07/M4-08分别交付项目光圈速度、选子/走棋及吃子/将军/将死本机合成提示音、中文系统TTS独立开关。F28仍缺音色选择/试听/自定义文件导入、Linux语音适配与实际语音音色核验、真实棋子移动动画范围审计；全站仍有F21素材、布局/工作区/语言、错题/题库、其它文件格式/GIF系统分享/OCR、完整历史规则、五平台引擎、在线自建后端+部署待做，详FEATURE_GAPS/BACKLOG。站点未知不能凭入口推断成功。

M4-07验证：根 `flutter test --reporter compact` 440 passed/5 skipped，5项需未配置的官方 Pikafish 环境；`flutter analyze` 无问题；专项13/13；macOS integration音频1/1；普通 `flutter run -d macos` 已启动 PID16653，VM Service `127.0.0.1:49641`。Xcode构建可能有既有audioplayers Swift并发warning；主窗口人工视觉/听感和其它平台未验。详 `TRACEABILITY.md` 与本轮 `SESSION_LOG.md`。

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。2026-11-02官方latest复核仍Pikafish2026-09-06 commit4c17cee，lock/NNUE校验见engine/pikafish.lock.json，.local忽略不提交。普通用户旧窗口不关闭/热重启；native测试覆盖build入口，最终审查前需重建普通main。
