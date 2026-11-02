# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS、git status/log与所涉模块文档；旧详情history/2026-11-02-before-numbered-arrows-handoff.md等，包含当时WIP，不以旧pending覆盖本交接。

## 授权与边界

持续实现直到可确认全站功能对齐，每功能完整flutter test+flutter analyze通过后中文Conventional Commit；实际macOS运行授权。在线自建可替换后端+部署方案，离线优先只是顺序。许可决定暂缓不挡开发但保留来源。无分代理授权。完整对标仍有很多缺项，不因又完成一片就停下要求审查。

## 最新检查点

业务基线51dcba0推荐箭头、a0a9024 E25审计；当前M3-23本步编号箭头独立commit见git log。最终显式官方NNUE根320/320（43252）与analyze0（6777）exit0；macOS旧推荐+新编号2/2（71609，00:26）exit0，之后只改超限提示文案。当前26原生未全26；上个完整23/23（34715）过。核心未改沿用65/65+dart analyze。所有命令收尾，无未等待验证会话；失败/修复见SESSION_LOG和TRACEABILITY，日志/tmp/chessnext-variation-arrows-*.log。

M3-23：纯CurrentMoveArrows按当前节点parent.children投影稳定ID/原编号/父Position记谱，树对象缓存；最多64，当前在首64外时取首63+当前。完整列表不截断，超限说明。BoardSession.showCurrentVariationArrows默认false、非文档/无内容或位置修订，普通读谱保留，根/replaceTree/newGame/打开App设置清除。局部callback绑定epoch。AppPreferences.showVariationArrows可选默认true，Controller逐字段合并/serial/retry，Scope只读全局门控。两个开关都开才显示，局部不写全局，global关local可开但不画并有说明。

VariationPanel局部Switch/current编号subtitle，主棋盘提供投影，编辑器不传旧树。VariationArrowsPainter绿色箭头/数字徽号在棋子下、IgnorePointer/只读语义，共用boardSquarePoint/BoardArrowsPainter头部。后者新增recommendationColor并纳入shouldRepaint；旧实际像素3项仍过。根/单项/置顶删除/新谱/过期callback/>64合法局面/双层画面Fake请求不变/命中/200%语义/绿色实际像素已验，ADR-027/VARIATION_ARROWS_SLICE。

本片首App.showDialog patch多逗号造成编译失败已修；后1大括号info和1unused测试import已清，最终门槛无问题。没有修改引擎生命周期来迎合测试。

## 现有关键边界

纯core/不可变树+GameMetadata并列/dirty与epoch、Library/Draft/Recent/Preferences独立所有者，源模块图见IMPLEMENTED_MODULES。文字PGN静态Isolate只捕获String/typed DTO，文档替换多阶段快照校验；文件导入256000字节/64000字符严格UTF8/有界流/预览；macOS导出Foundation atomic、取消前后边界，不清dirty。production main已注入，file_selector1.1.0锁定，当前user-selected.read-write+sandbox，实际Debug签名已核。系统Open/Save面板人工选择/外部授权/scope精确释放/Release实际签名未验，chooser测试注入。

AppTextScaling系统保留原TextScaler非线性，手动100/115/130覆盖；BoardDisplayScope坐标/尺寸10–200步5/推荐组合及尖标准宽头部/全局变着。尺寸只变face/反馈，交点不变。推荐两支本步+预计应着一起显示隐藏，来源PV更新不停止，UI不直接IO。偏好schema1可选字段严格类型，旧无字段安全默认，错误重试与晚到逐字段合并。

单Gateway UCI取消屏障/NNUE签名前后身份/运行前Isolate校验/资源TT复用；队列/多候选/持久缓存/原生WDL与预期损失等读专门模块。网站准确率/妙手公式未知，不冒充同算法。B15仍领域规则，之前显示切片已校正B08/B20，不改旧ID。

## 下一可执行

F26局势条：先实测源站开关/当前有效或缺失数据/翻转视角/停止状态，随后设计本地原生WDL预期得分呈现，不凭cp猜实战胜率。缺WDL/bound/mate必须分别定义，不伪造50%。其它F26着法标记、F21落子/选择/素材，F28声音/动画、布局/工作区、B22 PV历史/小棋盘、错题题库、格式/图片GIF/OCR、自建后端与部署、完整历史长将长捉、五平台ABI与发行仍待实现，持续推进。

IAB browser2/tab4 https://xiangqiai.com/#/，E19自制树正常方向、选中炮八平五/马２进３/炮二进二支线叶子，另一马八进七/马８进７主线仍在。E24分析已停止checkbox0但保留历史卡；E25恢复全局变着开/局部关/推荐开/标准/棋子100/系统字号。E25证据已commit，源站两层AND、父局面同级/单项/根/设置返回局部重置已V，编号1中央单次不导航，其它命中仍U。压缩后先cua.rewriteDocumentation再fresh AX；别重新载入。getAX在历史PV行会很长，可emit:false后截取操作段/过滤含“text 红分”的历史行，但文件注明截取/过滤。截图变更后保存并commentary嵌图；研究素材不进产品资源。

## 环境/命令

Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0；同日official latest Pikafish2026-09-06 commit4c17cee，lock及NNUE SHA见engine/pikafish.lock.json，.local不提交。根：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze。core cwd packages/xiangqi_core dart test/analyze。native flutter test integration_test/local_board_test.dart -d macos，可name筛选相关项。

native fixture仅framework-resumed，raw[]不是OS焦点/隐藏/最小化/人工视觉证明。Computer Use桌面权限未授，不OS脚本/替代自动化绕过。普通用户旧窗口PID38211/旧run22326曾在，不主动关或热重启；native测试覆盖build入口，最终审查前普通main重建。Fake真实异步用pump_until/runAsync，不删生产await。其它四平台/移动FFI仍未验证/实现。
