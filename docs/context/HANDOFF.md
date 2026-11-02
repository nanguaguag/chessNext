# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS、git status/log与所涉模块文档；旧详情history/2026-11-02-before-numbered-arrows-handoff.md等，包含当时WIP，不以旧pending覆盖本交接。

## 授权与边界

持续实现直到可确认全站功能对齐，每功能完整flutter test+flutter analyze通过后中文Conventional Commit；实际macOS运行授权。在线自建可替换后端+部署方案，离线优先只是顺序。许可决定暂缓不挡开发但保留来源。无分代理授权。完整对标仍有很多缺项，不因又完成一片就停下要求审查。

## 最新检查点

M3-28只读PV预览完成，独立中文commit见git log。显式官方NNUE根361/361（48185，00:37）与analyze0（62423）exit0，macOS新项1/1（53828，00:11）exit0；现native31未全31，上片完整27/27过，核心未改65沿用。所有验证进程结束。初4lint info/首目标RawTooltip类型断言问题已修，日志/tmp/chessnext-pv-preview-*.log。

ADR-032/PV_PREVIEW_SLICE：纯PvPreview工作Isolate整体合法重放至多128步/中文记谱/不可变Position序列，非法后缀整体拒绝，typed DTO+中文error；source history被截断时明确前128，并不宣称已校验尾。历史预览按钮→Dialog loader/generation/mounted/route防退场迟到/重试，源评分与方向固定、readonly BoardSurface/ExcludeFocus与合并语义；虚拟列表随cursor/200%与自适应分栏上下。初1/0原局面/首尾上一下一/左右键点着，800ms播放/暂停/尾停/末尾再播从0；手动/失活/退场/非当前route停Timer。帮助已补，无写谱按钮。新增8+历史3目标11、根361和真实macOSWorker/NNUE同token/不改谱通过。

M3-27 43ce8f7历史列表：AnalysisHistory/PvHistoryEntry64×128/100ms普通分析采样/深拷贝rawPV，source Position/epoch/nodeId/revisions，忽略仅time/nps变化；位置变清空、停止/同位置重启保留，清空不改搜索，打开前snapshot+方色，Dialog虚拟化/评分/WDL/bound。**E31已发现原站跨位置仍留历史，这一清空设计成为已知待补差距，不能关闭B22。** 原站精确上限仍U。

M3-26 c5e7c04选子样式：SelectionStyle lift旧默认/frame，独立偏好/Controller合并/Scope/Dropdown；面容抬8%格距/阴影，transformHitTests=false且在pieceSize外；框固定交点，空位/拖动反馈无选择态。主盘编辑器共用，根345/native单1已过，ADR-030。

M3-25 d3abe10落子标记根338/native单1；ADR-029/LAST_MOVE_MARKER_SLICE，current.move及(epoch,cursorId)展示身份，600ms光圈单周/系统减少动画/首次插入animateOnMount，方向评注不重启，源环/终点框，初始恢复静止，根与编辑器无旧标记。

M3-24局势条9721f20：BoardEvaluation首PV原生WDL红方0–2000预期得分/缺失boundmate灰态/真实领域终局独立，记录Result不裁决；EvaluationBoard只读语义/随flip/隐藏回收28，默认showEvaluationBar；主棋盘min492开/464关保交点约48。停止保留同位置/换位置清info，不拥有引擎IO。完整27过，ADR-028。

## 现有关键边界

纯core/不可变树+GameMetadata并列/dirty与epoch、Library/Draft/Recent/Preferences独立所有者，源模块图见IMPLEMENTED_MODULES。文字PGN静态Isolate只捕获String/typed DTO，文档替换多阶段快照校验；文件导入256000字节/64000字符严格UTF8/有界流/预览；macOS导出Foundation atomic、取消前后边界，不清dirty。production main已注入，file_selector1.1.0锁定，当前user-selected.read-write+sandbox，实际Debug签名已核。系统Open/Save面板人工选择/外部授权/scope精确释放/Release实际签名未验，chooser测试注入。

AppTextScaling系统保留原TextScaler非线性，手动100/115/130覆盖；BoardDisplayScope坐标/尺寸10–200步5/推荐组合及尖标准宽头部/全局变着。尺寸只变face/反馈，交点不变。推荐两支本步+预计应着一起显示隐藏，来源PV更新不停止，UI不直接IO。偏好schema1可选字段严格类型，旧无字段安全默认，错误重试与晚到逐字段合并。

单Gateway UCI取消屏障/NNUE签名前后身份/运行前Isolate校验/资源TT复用；队列/多候选/持久缓存/原生WDL与预期损失等读专门模块。网站准确率/妙手公式未知，不冒充同算法。B15仍领域规则，之前显示切片已校正B08/B20，不改旧ID。

## 下一可执行

B22下一：E31研究整理/commit（raw E31*已在research未追踪），随后所选前缀原子应用/停止屏障/epoch+源局面保护，再补跨位置历史与stale按钮。E31实测2/33“走到棋盘上”仅追加炮２平１/马八进七，原有另一条变化保留；返回原三着点再开相同PV/选2并应用，没有可见重复，仅回已有末端。按钮应用后短暂禁用“局面已变化”随后关闭；历史1368在新位置及返回仍留。主棋谱现在比E19多两步后续，已回原炮二进二阅读位置，AI/分析0，默认样式。曾全局getByText炮２平１.first误命中新出现的着法树后续而导航1步，freshAX发现后回退，再限定已观察DOM .engine-pv.first正确打开历史；不能把该误导航算预览成功。未删除任何数据，保留自制后续。

E30已6ca843e证据：预览步进/播放暂停/0边界/Escape，E31补应用与跨位置；原站跨文档/历史精确预算/来源绑定算法/正在分析和AI时的应用仍U。项目下一接口需要明确失败状态与不自动落子，不复制原站不安全行为。其它F21素材/F26评级标记、布局声音训练格式后端五平台和完整规则继续。

IAB browser2/tab4 https://xiangqiai.com/#/，E19自制树正常方向、选中炮八平五/马２进３/炮二进二支线叶子，另一马八进七/马８进７主线仍在。E24分析已停止checkbox0但保留历史卡；E25恢复全局变着开/局部关/推荐开/标准/棋子100/系统字号。E25证据已commit，源站两层AND、父局面同级/单项/根/设置返回局部重置已V，编号1中央单次不导航，其它命中仍U。压缩后先cua.rewriteDocumentation再fresh AX；别重新载入。getAX在历史PV行会很长，可emit:false后截取操作段/过滤含“text 红分”的历史行，但文件注明截取/过滤。截图变更后保存并commentary嵌图；研究素材不进产品资源。

## 环境/命令

Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0；同日official latest Pikafish2026-09-06 commit4c17cee，lock及NNUE SHA见engine/pikafish.lock.json，.local不提交。根：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze。core cwd packages/xiangqi_core dart test/analyze。native flutter test integration_test/local_board_test.dart -d macos，可name筛选相关项。

native fixture仅framework-resumed，raw[]不是OS焦点/隐藏/最小化/人工视觉证明。Computer Use桌面权限未授，不OS脚本/替代自动化绕过。普通用户旧窗口PID38211/旧run22326曾在，不主动关或热重启；native测试覆盖build入口，最终审查前普通main重建。Fake真实异步用pump_until/runAsync，不删生产await。其它四平台/移动FFI仍未验证/实现。
