# 当前状态

2026-11-02（Asia/Shanghai）。完整对标仍在开发，不能交付完整对齐声明。

## 授权与工作方式

用户已明确授权业务实现、实际macOS运行，要求持续推进所有可确认功能；每个功能先flutter test/flutter analyze，再单独中文Conventional Commit。在线部分选择自建可替换后端并提供部署方案。原始调查限制已被后续实现授权扩展；历史保存在SESSION_LOG和history/，不以聊天记忆替代磁盘。许可按要求暂缓，不阻挡开发。

## 已实现

- 纯Dart规则：合法走法/自将/照面、编辑语义校验、将死和困毙判负；完整历史裁决尚缺。
- macOS Material3棋盘：键盘/语义、翻转、合法落子、前后首尾、新局保护、明暗与滚动大字布局。
- 不可变GameTree：分支、注释、主线提升/删除、稳定ID；本地命名保存/搜索/打开/备份恢复。
- 正式UCI/原生进程：取消屏障、超时/EOF、迟到结果、MultiPV分析/评分视角/箭头/预算；应用内NNUE helper签名打包，Sandbox开启。
- 单引擎本地AI：执红黑/双AI、用时、催招/排除候选变招、双步悔棋、输入锁与分析互斥。
- 独立局面编辑：棋子盒限额/连续放子、拖动/拖出/右键、红黑先、清空/初始/互换/旋转/镜像、错误定位、有效提交/取消保护。
- FEN/UCI/ICCS/中文文字导入导出：合法性及错误步数、未保存保护、Clipboard端口、导出损失提示；中文支持前中后/多列叠兵/士象例外/繁体和数字宽度。棋树/引擎仍存UCI。

- 独立自动草稿：300ms去抖、串行快照、主文件/备份恢复、dirty副本恢复、初始化/失败/脏数据保护、后台flush与正常退出失败提示。损坏原件归档保留，见ADR-006；不承诺强杀/断电零丢失。

- 本机偏好：主题、线程/Hash/MultiPV、AI用时，schema1独立存储/备份/坏文件保护/读写失败，初始化逐字段合并和硬件/握手能力钳制；不存AI角色。主题变更不重启引擎。桌面失焦但可见继续，隐藏停止；移动inactive停止。

## 验证和平台

本功能根flutter test72/72（含官方NNUE live测试）、flutter analyze无问题；核心dart test46/46、dart analyze无问题；macOS原生9/9：棋盘、真实沙箱存储重开、NNUE多PV、AI/变招/悔棋、编辑、中文导入导出、实际Documents自动草稿重开恢复、ApplicationSupport主题/参数重开恢复、包内引擎组合预算。4组perft与官方引擎一致。尚未验证Android/iOS/Windows/Linux，不能把macOS通过外推。

本轮原生交互测试明确保持framework-resumed前提（只在integration_test内，普通main无覆盖），真实OS焦点/最小化/隐藏仍待平台QA；生产生命周期由独立组件测试。原生曾停滞一轮被INT中断、首次自建Binding冲突均未记通过，见SESSION_LOG。

原生测试失焦后的enterText必须重新tap并pumpAndSettle后验证实际值；已修测试辅助函数。AI原生整套曾出现状态“分析已停止”无协议错误的偶发中止，单项及最终整套通过；增加生命周期trace与失焦取消组件回归，不静默删除失败记录。Computer Use桌面权限未授，窗口自动置前失败，Flutter原生交互测试通过，人工截图/视觉验收未做。

组合depth/时间/节点预算已在EngineRequest/UciEngine和真实NNUE验证；原生9/9本轮原始事件确有hidden/inactive，fixture使交互前提明确。UI复盘尚未实现。同会话资源/Hash复用已通过命令/真实引擎/微基准验证，见RESOURCE_REUSE.md。下一项完整当前线路的可点击/虚拟化着法列表，作为复盘分析范围与曲线跳转基础，再整谱队列与曲线。

## 继续推进

接下来整谱复盘/评分曲线/错题→文件格式/图片与GIF→工作区/外观/音效/帮助→自建后端→五平台与完整规则。各项应再拆成独立验收增量；B01深层审计持续进行。没有自造账号/云库/识图成功结果。

环境Flutter3.44.6/Dart3.12.2、macOS14.4 arm64/Xcode15.0。Pikafish官方latest于2026-11-02复核为2026-09-06，SHA/制品校验见engine/pikafish.lock.json。本机.local不提交制品。
