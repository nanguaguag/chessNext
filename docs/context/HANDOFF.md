# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS、git status/log与所涉模块文档；旧详情history/2026-11-02-before-numbered-arrows-handoff.md等，包含当时WIP，不以旧pending覆盖本交接。

## 授权与边界

持续实现直到可确认全站功能对齐，每功能完整flutter test+flutter analyze通过后中文Conventional Commit；实际macOS运行授权。在线自建可替换后端+部署方案，离线优先只是顺序。许可决定暂缓不挡开发但保留来源。无分代理授权。完整对标仍有很多缺项，不因又完成一片就停下要求审查。

## 最新检查点

M3-29所选PV前缀已完成，独立中文commit见git log。显式官方NNUE根373/373（90009，00:39）与analyze0问题（33296）exit0；**完整macOS32/32（36917，06:49）exit0**，核心未改65沿用。全部验证session结束；日志/tmp/chessnext-pv-apply-*.log。新增真实NNUE+worker原子两步/保留旧后续、资料和评注、实际文件保存与新App完整恢复、原entry同源重开复用不dirty，旧31项全回归通过。raw lifecycle[]只fixture不代表OS焦点/人工视觉。证据64项stat/SHA/实际sips尺寸与本地链接16项核验过。

ADR-033/PV_APPLY_SLICE：纯PvPrefixAction/取消/枚举失败，Controller.createPvPrefixAction打开时捕获source tree/epoch/content+position revision，源entry epoch/node/FEN须匹配。旧entry同源重开可取当前新快照（保留新评注后续），打开后变更过期。先disable/stop屏障→gen/stopfailed/源/cancel→纯PvPrefixPlan Worker全树追加最多128步/2000节点→复查→Session.commitContinuation单次发布；新节点revision+1，已有复用只位置revision/不dirty，epoch/metadata/库绑定不变。planner可注入测试worker等待取消/源变。UI监听sourceChanges即时stale禁用/0和busy禁用/停播放/Close取消未提交，typedPvPreviewExit成功关原preview及history current/mounted route，迟到不关新route。帮助已补。K09普通手工/旧入口容量未统一是代码审计差距，PV已提前原子拒绝，不能称全App解决。

初UI脚本format断言失败使Preview未写/History先引用缺API，analyze4编译错+8info；补完API后9 braces限定fix，最后测试underscore1info修。目标12→16→17及最终全量/native全部运行无失败。新增8应用+4组件，旧预览5回归，目标17（59687）。不要把旧analyze失败覆盖为通过，详情SESSION_LOG。

M3-28 fd6b2fb预览：PvPreview真实worker至多128步整体合法重放/中文/不可变序列；Dialog loader代次/route取消迟到，自适应+虚拟步表/只读BoardSurface/语义，1/0/首尾/键盘/点着/800ms主动播放暂停/失活退场停Timer。来源score/方向固定，未选择应用时不改谱或搜索；原始361/原生单1过，现在完整32回归已覆盖。

M3-27 43ce8f7历史列表：AnalysisHistory/PvHistoryEntry64×128/100ms普通分析采样/深拷贝rawPV，source Position/epoch/nodeId/revisions，忽略仅time/nps变化；位置变清空、停止/同位置重启保留，清空不改搜索，打开前snapshot+方色，Dialog虚拟化/评分/WDL/bound。**E31已发现原站跨位置仍留历史，这一清空设计成为已知待补差距，不能关闭B22。** 原站精确上限仍U。

M3-26 c5e7c04选子样式：SelectionStyle lift旧默认/frame，独立偏好/Controller合并/Scope/Dropdown；面容抬8%格距/阴影，transformHitTests=false且在pieceSize外；框固定交点，空位/拖动反馈无选择态。主盘编辑器共用，根345/native单1已过，ADR-030。

M3-25 d3abe10落子标记根338/native单1；ADR-029/LAST_MOVE_MARKER_SLICE，current.move及(epoch,cursorId)展示身份，600ms光圈单周/系统减少动画/首次插入animateOnMount，方向评注不重启，源环/终点框，初始恢复静止，根与编辑器无旧标记。

M3-24局势条9721f20：BoardEvaluation首PV原生WDL红方0–2000预期得分/缺失boundmate灰态/真实领域终局独立，记录Result不裁决；EvaluationBoard只读语义/随flip/隐藏回收28，默认showEvaluationBar；主棋盘min492开/464关保交点约48。停止保留同位置/换位置清info，不拥有引擎IO。完整27过，ADR-028。

## 现有关键边界

纯core/不可变树+GameMetadata并列/dirty与epoch、Library/Draft/Recent/Preferences独立所有者，源模块图见IMPLEMENTED_MODULES。文字PGN静态Isolate只捕获String/typed DTO，文档替换多阶段快照校验；文件导入256000字节/64000字符严格UTF8/有界流/预览；macOS导出Foundation atomic、取消前后边界，不清dirty。production main已注入，file_selector1.1.0锁定，当前user-selected.read-write+sandbox，实际Debug签名已核。系统Open/Save面板人工选择/外部授权/scope精确释放/Release实际签名未验，chooser测试注入。

AppTextScaling系统保留原TextScaler非线性，手动100/115/130覆盖；BoardDisplayScope坐标/尺寸10–200步5/推荐组合及尖标准宽头部/全局变着。尺寸只变face/反馈，交点不变。推荐两支本步+预计应着一起显示隐藏，来源PV更新不停止，UI不直接IO。偏好schema1可选字段严格类型，旧无字段安全默认，错误重试与晚到逐字段合并。

单Gateway UCI取消屏障/NNUE签名前后身份/运行前Isolate校验/资源TT复用；队列/多候选/持久缓存/原生WDL与预期损失等读专门模块。网站准确率/妙手公式未知，不冒充同算法。B15仍领域规则，之前显示切片已校正B08/B20，不改旧ID。

## 下一可执行

M3-30下一：E31跨位置历史保留已V（37bfaac研究），现只在当前局面保留是已知差距。计划同一session文档epoch内保留64×128历史，latest infos/推荐/局势条仍随位置清空；换谱epoch清历史，sourcePly/来源着法标签，旧来源只读可预览但不同当前source不可应用，回源节点重新打开可以用M3-29已实现的新快照。保持未知跨文档源站策略为P，别耦合_lastSessionEpoch AI取消逻辑（可独立_historyEpoch）。测试需改旧“换位置history清”的预期，同时确认latest确实清旧/迟到token不进archive/新doc清、双执方源评分、deleted来源只读/不能误提交/200%/源返回应用。先计划和验收，功能通过根test/analyze后独立commit。

E31原站已37bfaac：源三着炮二进二添加两步炮２平１/马八进七后回原阅读点，保留新增后续和另一原分支，历史1368/AI分析0、样式默认。曾全页同名text误命中新后续只导航1步，fresh AX发现回退后限定.engine-pv成功预览，未计伪成功。source树现在有新增未来，不再把炮二进二称叶子。跨文档历史/来源绑定/活动AI原行为/hover仍U。其它F21素材/F26评级、布局声音训练格式后端五平台完整历史规则继续，不能停止称全部对齐。


IAB browser2/tab4 https://xiangqiai.com/#/，E19自制树正常方向、选中炮八平五/马２进３/炮二进二支线叶子，另一马八进七/马８进７主线仍在。E24分析已停止checkbox0但保留历史卡；E25恢复全局变着开/局部关/推荐开/标准/棋子100/系统字号。E25证据已commit，源站两层AND、父局面同级/单项/根/设置返回局部重置已V，编号1中央单次不导航，其它命中仍U。压缩后先cua.rewriteDocumentation再fresh AX；别重新载入。getAX在历史PV行会很长，可emit:false后截取操作段/过滤含“text 红分”的历史行，但文件注明截取/过滤。截图变更后保存并commentary嵌图；研究素材不进产品资源。

## 环境/命令

Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0；同日official latest Pikafish2026-09-06 commit4c17cee，lock及NNUE SHA见engine/pikafish.lock.json，.local不提交。根：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze。core cwd packages/xiangqi_core dart test/analyze。native flutter test integration_test/local_board_test.dart -d macos，可name筛选相关项。

native fixture仅framework-resumed，raw[]不是OS焦点/隐藏/最小化/人工视觉证明。Computer Use桌面权限未授，不OS脚本/替代自动化绕过。普通用户旧窗口PID38211/旧run22326曾在，不主动关或热重启；native测试覆盖build入口，最终审查前普通main重建。Fake真实异步用pump_until/runAsync，不删生产await。其它四平台/移动FFI仍未验证/实现。
