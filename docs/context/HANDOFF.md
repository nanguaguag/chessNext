# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS、git status/log与所涉模块文档；旧详情history/2026-11-02-before-numbered-arrows-handoff.md等，包含当时WIP，不以旧pending覆盖本交接。

## 授权与边界

持续实现直到可确认全站功能对齐，每功能完整flutter test+flutter analyze通过后中文Conventional Commit；实际macOS运行授权。在线自建可替换后端+部署方案，离线优先只是顺序。许可决定暂缓不挡开发但保留来源。无分代理授权。完整对标仍有很多缺项，不因又完成一片就停下要求审查。

## 最新检查点

M3-24局势条已完成，独立commit见git log。显式官方NNUE根flutter test331/331（99436）与analyze无问题（55541）exit0；完整macOS27/27（96958，04:53）exit0，核心未改沿用65/65+dart analyze。无待等待验证会话；日志/tmp/chessnext-evaluation-bar-*.log，失败/修复见SESSION_LOG/TRACEABILITY。

纯BoardEvaluation区分首PV原生WDL期望/缺失/bound/mate/真实终局，红方0–2000整数单位；记录Result不裁决局面。EvaluationBoard灰态/Tooltip/只读语义、翻转颜色、showEvaluationBar可选默认开/逐字段合并/即时偏好，不拥有引擎或存储。停止保留同局面，导航依现有位置修订清info。主棋盘最小总宽492开/464关，条20+8，保持坐标交点约48dp；编辑器无旧条。模型5+组件5+实际像素1通过，完整原生包含真实NNUE令牌不变/空间+28/停止及翻转/偏好新App/文档不变。ADR-028/EVALUATION_BAR_SLICE。

## 现有关键边界

纯core/不可变树+GameMetadata并列/dirty与epoch、Library/Draft/Recent/Preferences独立所有者，源模块图见IMPLEMENTED_MODULES。文字PGN静态Isolate只捕获String/typed DTO，文档替换多阶段快照校验；文件导入256000字节/64000字符严格UTF8/有界流/预览；macOS导出Foundation atomic、取消前后边界，不清dirty。production main已注入，file_selector1.1.0锁定，当前user-selected.read-write+sandbox，实际Debug签名已核。系统Open/Save面板人工选择/外部授权/scope精确释放/Release实际签名未验，chooser测试注入。

AppTextScaling系统保留原TextScaler非线性，手动100/115/130覆盖；BoardDisplayScope坐标/尺寸10–200步5/推荐组合及尖标准宽头部/全局变着。尺寸只变face/反馈，交点不变。推荐两支本步+预计应着一起显示隐藏，来源PV更新不停止，UI不直接IO。偏好schema1可选字段严格类型，旧无字段安全默认，错误重试与晚到逐字段合并。

单Gateway UCI取消屏障/NNUE签名前后身份/运行前Isolate校验/资源TT复用；队列/多候选/持久缓存/原生WDL与预期损失等读专门模块。网站准确率/妙手公式未知，不冒充同算法。B15仍领域规则，之前显示切片已校正B08/B20，不改旧ID。

## 下一可执行

F21落子标记/选择样式下一片，先参考实际操作。F26着法标记当前样本开关后无可确认可见区别，不推断对象；B22历史/预览、资源、声音动画、布局/工作区、错题题库、格式/图片GIF/OCR、自建后端与部署、完整历史规则、五平台ABI仍待持续推进。

IAB browser2/tab4 https://xiangqiai.com/#/，E19自制树正常方向、选中炮八平五/马２进３/炮二进二支线叶子，另一马八进七/马８进７主线仍在。E24分析已停止checkbox0但保留历史卡；E25恢复全局变着开/局部关/推荐开/标准/棋子100/系统字号。E25证据已commit，源站两层AND、父局面同级/单项/根/设置返回局部重置已V，编号1中央单次不导航，其它命中仍U。压缩后先cua.rewriteDocumentation再fresh AX；别重新载入。getAX在历史PV行会很长，可emit:false后截取操作段/过滤含“text 红分”的历史行，但文件注明截取/过滤。截图变更后保存并commentary嵌图；研究素材不进产品资源。

## 环境/命令

Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0；同日official latest Pikafish2026-09-06 commit4c17cee，lock及NNUE SHA见engine/pikafish.lock.json，.local不提交。根：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze。core cwd packages/xiangqi_core dart test/analyze。native flutter test integration_test/local_board_test.dart -d macos，可name筛选相关项。

native fixture仅framework-resumed，raw[]不是OS焦点/隐藏/最小化/人工视觉证明。Computer Use桌面权限未授，不OS脚本/替代自动化绕过。普通用户旧窗口PID38211/旧run22326曾在，不主动关或热重启；native测试覆盖build入口，最终审查前普通main重建。Fake真实异步用pump_until/runAsync，不删生产await。其它四平台/移动FFI仍未验证/实现。
