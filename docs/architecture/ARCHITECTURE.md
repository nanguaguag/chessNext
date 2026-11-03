# 架构设计基线（P，未实现）

采用功能模块 + MVVM 表现层 + 纯 Dart 领域 + 端口适配器。参考 [Flutter 架构指南](https://docs.flutter.dev/app-architecture/guide)，复杂象棋规则独立领域层。依赖指向领域/接口，composition root 唯一装配具体实现。

```mermaid
flowchart TD
 UI[Material 3 Views] --> VM[ViewModels]
 VM --> APP[应用用例 / 会话协调]
 APP --> DOMAIN[纯 Dart 领域]
 APP --> PORTS[端口接口]
 ADAPTERS[本地存储 / 原生引擎 / 在线服务] --> PORTS
 ROOT[Composition root] --> ADAPTERS
 ROOT --> APP
```

## 模块与所有权

| 模块（未来路径） | 拥有的数据和职责 | 禁止依赖 |
|---|---|---|
| lib/domain/xiangqi | Piece、Square、Position、Move、FEN、合法走法、RuleProfile、终局裁决 | Flutter、网络、存储、引擎 |
| lib/domain/game_tree | GameDocument、GameNode、分支、注释、标签、游标 | 视图坐标、native |
| lib/application/session | 模式、脏状态、命令、撤销、positionRevision | Widget、具体适配器 |
| lib/application/analysis | 搜索调度、分数归一化、MultiPV、复盘任务 | FFI 细节 |
| lib/ports | EngineGateway、GameRepository、MoveSpeechPort、AudioFeedbackPort、BookService、RecognitionService、SyncService、PlatformFiles | 插件实现 |
| lib/adapters/engine | Process/FFI、UCI 编解码、崩溃恢复 | UI |
| lib/adapters/storage | SQLite候选、schema迁移、事务、草稿 | Widget |
| lib/adapters/online | 认证、超时、缓存、重试、服务 DTO | UI |
| lib/features/*/presentation | board/editor/library/review/training/settings 的 View/ViewModel | native、HTTP、SQL |
| lib/design_system | 色彩、排版、适配、可访问组件 | 业务仓储 |
| lib/app | 路由、依赖装配、生命周期 | 不放领域规则 |
| native/pikafish | 固定上游、最小 C ABI、构建补丁与许可 | Dart UI |

状态管理先用可替换 ViewModel 接口，Riverpod 为候选而非已锁定依赖。路由、SQLite、文件选择插件在 M1 核对当前版本/许可证后 ADR 锁定，避免纸面依赖承诺。

## 核心契约

EngineGateway: capabilities、initialize(config)、start(position + history, limits, token)、stop(reason)、events、dispose。事件携带 engineEpoch/searchToken/positionRevision。EngineCapabilities 由握手选项产生；unsupported 功能在 UI 禁用并解释。EngineConfig 与 PlayStrength 分开，禁止假设 Skill Level 存在。

GameRepository: 草稿事务、显式保存、按 id 读取、分页检索、删除恢复、schemaVersion；导入文档先验证后提交。GameNode 使用稳定 ID、parentId、有序 children、move、comment；局面由根 FEN + 路径得到，可缓存但不重复作为主数据。

BookService.query(PositionKey) 返回 moves/source/fetchedAt/status，不直接落子；应用层决定来源优先级和合法性。RecognitionService 只返回候选局面和置信度，不覆盖会话。SyncService 用 revision/baseRevision 检测冲突，保留双方副本而非最后写入覆盖。

## 一致性

UI 是状态投影，唯一会话协调器提交命令。一次导入或新局只更新一次文档 revision；存储失败维持 dirty。持久化包括文档 schema、规则 profile、引擎/网络版本、分析配置和评分视角，使复盘可解释。账号 token 存平台安全存储，日志不含棋谱正文/凭据，遥测默认关闭（项目提案）。

## 平台边界

桌面用 Process 隔离故障；移动尝试嵌入原生库，经工作线程/Isolate 通信。生命周期、分享、文件、相机、窗口菜单为平台适配器。iOS 静态链接与构建 hooks 的适用性必须真机 spike；不把桌面进程方案套用到手机。

## 2026-11-01 离线落地细化

范围权威为 planning/OFFLINE_SCOPE。暂不实例化Auth/Sync/CloudBook/RemoteRecognition；使用明确 unavailable 能力而不是假数据。保留端口可替换，不在UI调用网络。

生产工程建议保持单Flutter应用 + 独立纯Dart领域package + 引擎端口package + native桥接package；先按目录边界组织，只有跨运行时和独立测试价值才拆包。当前 research/spikes/flutter_engine_probe 是可丢弃验证，不直接搬成生产框架。

数据流：View发Intent→SessionController验证领域命令→提交GameDocument revision→Repository事务保存→AnalysisCoordinator串行取消旧搜索/排新搜索→EngineGateway事件→校验epoch+revision→AnalysisState→View。游标与棋盘朝向属于会话/展示，不变更棋谱根局面；编辑草稿与正式文档隔离。

调度优先级：用户对弈搜索 > 当前局面分析 > 整谱后台复盘。共用单引擎实例，抢占先stop/drain，不重入go；只在当前请求有效时落子。退出/后台先停搜索，保存草稿；恢复不自动落子。高频info合并到约10Hz UI刷新，bestmove/error不节流丢弃。

分析缓存key = 规范化根局面+完整相关走子历史+规则profile+引擎SHA+网络SHA+搜索配置（history对重复裁决重要，不能只FEN）。保存score原始cp/mate/bound与sideToMove，展示时独立归一化；复盘算法版本单独存储，阈值未校准不标“准确率”。

技术候选：内置ChangeNotifier/ViewModel可支撑第一垂直切片；引入Riverpod需独立ADR说明收益。SQLite/Drift作为存储候选，文件/分享/权限插件在选用时核实版本、五平台能力和许可证。当前spike只有SDK/Flutter测试依赖，未锁生产生态。

引擎难度端口接收预算策略而非虚构SkillLevel；RuleService独立裁决，向不具规则切换能力的引擎发送合法且有历史的局面。UI呈现unsupported能力，禁止让任意setoption文本直通native。

## M2-01实际落地路径

纯Dart领域已在 packages/xiangqi_core 独立包实施，对应上文规划lib/domain/xiangqi的规则职责；生产Flutter应用后续通过path依赖使用，不复制规则代码。接口采用不可变Position/Move/Square，play负责合法性，FEN解析与编辑语义校验分层。当前legalMoves为无历史的棋盘合法性，不能作为完整规则profile裁决替代。

M4-05 增加的 AnimationSpeed 是本机展示偏好，不进入规则/棋谱/引擎端口；Composition root 将不可变值注入 BoardDisplayScope，最后一步标记按新局面变化使用时长。四档时长属于项目映射且仅覆盖光圈，见 ADR-042。

M4-06的BoardFeedbackController是BoardSession与AudioFeedbackPort间的应用层事件翻译；偏好开关驱动，不向规则、GameTree或UCI发送音频依赖。生产root仅注入AudioplayersFeedback，组件/领域测试用静音或fake端口。播放器异常是可选副作用并隔离，不改变已提交着法。见ADR-043。

M4-08由BoardFeedbackController按已提交节点的父局面计算ChineseNotation，并通过独立MoveSpeechPort请求系统朗读，不复用AudioFeedbackPort或走棋音效开关。FlutterTtsMoveSpeech只在官方插件已声明的平台并发现已安装中文voice时播报；Android跳过标记联网语音，Linux/Web保持静音。可用性/异常不影响棋局。见ADR-044。
