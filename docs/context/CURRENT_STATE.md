# 当前状态

2026-11-02 Asia/Shanghai。完整对标仍在开发，不能宣称全部对齐。历史切片状态已归档history/2026-11-02-before-piece-size-state.md，验证详planning/TRACEABILITY和SESSION_LOG。

## 授权与门槛

用户已明确扩展最初调查授权，持续业务实现、实际macOS运行；每功能flutter test+flutter analyze通过后中文Conventional Commit，所有可确认功能对齐后再交审查。在线选自建可替换后端并提供部署方案，离线优先仅为顺序。许可决定暂缓不挡开发，继续登记来源，不复制参考资源/棋谱库。没有分代理授权。

## 当前交付

- 纯Dart规则/FEN/合法着法与自将照面/将死困毙/独立编辑语义，历史长将长捉/重复完整裁决仍缺。
- macOS Material3棋盘/键盘语义/翻转/dirty保护；不可变棋树稳定ID/评注/分支切换置顶删除、完整选定线路及前后分支点/虚拟列表。
- 本地命名库/搜索/备份、独立300ms草稿/dirty副本恢复/退出失败保护；资料GameMetadata并列文档真值，未知字段保留；独立50条最近阅读按根+完整UCI路径恢复。
- 独立局面编辑/棋子盒/拖放右键/红黑先/清空初始互换旋转镜像/非法不提交。
- FEN/UCI/ICCS/中文/有限单局PGN文字剪贴板交换，PGN后台worker携资料和评注；单UTF8文件导入有界流/严格编码/预览；macOS五格式UTF8文件导出原生Foundation atomic，取消边界清楚/不清dirty。RAV/WXF/多局/GBK/XQF等仍缺。
- 单UCI引擎调度/取消屏障/超时EOF/迟到保护，MultiPV/评分箭头/WDL；AI执红黑双AI/催招变招悔棋。macOS沙箱内签名helper+NNUE，运行前Isolate验证身份，资源TT复用。
- 当前线路/整树可取消最佳或多候选有限队列，单步父局面候选试走分支，首评分曲线/详情/跳转/跳过已有；完整历史/身份/预算键的有界内存及独立文件缓存，损坏降级重算；WDL预期损失报告为项目模型，不冒充源站准确率算法。
- 原创可搜索离线帮助、四步只读引导/首次版本记忆；主题、资源/AI用时独立偏好；全局字号系统/100/115/130实时记忆且保留系统非线性；棋盘显示坐标红黑路数与翻转镜像/编辑器共用；棋子尺寸10–200/步5/重置，仅面容与拖动反馈缩放，点击交点不变；推荐箭头组合显隐/尖标准宽头部/即时偏好，不重启搜索或丢最新PV。

实际边界见architecture/IMPLEMENTED_MODULES及ADR-005至026。

## 最新验证

M3-22最终显式官方NNUE根flutter test310/310，flutter analyze无问题，均exit0；核心未改沿用65/65+dart analyze。macOS上片完整23/23通过，尺寸片相关坐标+尺寸2/2、当前箭头片真实NNUE单项1/1通过，当前25项未全跑25，不夸大最后命令。无待等待验证进程。失败/修复/未跑全部留SESSION_LOG，截图/AX为研究证据。

生产main有文件导入/仅macOS文件导出；当前Debug/Release user-selected.read-write+sandbox，实际Debug签名已核，Release实际构建签名未验。系统Open/Save面板/外部授权/精确scope释放、真实OS焦点/最小化/人工视觉未验，Computer Use桌面权限未授不绕过；native fixture只保持framework-resumed，raw[]不是OS验证。Android/iOS/Windows/Linux运行与移动FFI仍未验/未实现。

## 下一步与环境

下一F26变着箭头准确对象/局部开关联动补审计后单功能；仍有F21素材/落子与选择样式、F28声音动画、布局/工作区/语言、错题/题库、其它文件/图片GIF/OCR、完整历史规则、五平台引擎、在线自建后端+部署待做，详FEATURE_GAPS/BACKLOG。站点未知不能凭入口推断成功。

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。2026-11-02官方latest复核仍Pikafish2026-09-06 commit4c17cee，lock/NNUE校验见engine/pikafish.lock.json，.local忽略不提交。普通用户旧窗口不关闭/热重启；native测试覆盖build入口，最终审查前需重建普通main。
