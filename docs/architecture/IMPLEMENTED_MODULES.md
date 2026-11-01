# 当前模块与依赖（2026-11-02）

本文件描述磁盘上的实现；ARCHITECTURE.md保留原始设计与后续目标。

| 边界 | 当前路径 | 所有权 |
|---|---|---|
| 纯Dart领域 | packages/xiangqi_core | 棋盘规则、FEN、编辑草稿、不可变棋树与文字格式；不依赖Flutter/IO |
| 会话 | lib/application/board_session.dart | 当前文档、游标、选中、dirty/revision/epoch/positionRevision、输入锁 |
| 棋谱用例 | lib/application/library_controller.dart | 保存/打开/导入新文档；读取竞态与保存失败状态 |
| 引擎调度 | lib/application/engine_session_controller.dart + engine_play.dart | 单引擎所有权、分析/AI互斥、取消/迟到结果、资源预算 |
| 端口 | lib/ports | EngineGateway、GameRepository、TextClipboard；UI不实例化进程/文件IO |
| 适配器 | lib/adapters | UCI进程、沙箱资源定位、文件快照仓库、Flutter剪贴板 |
| 表现 | lib/features | board/editor/library/analysis/play/transfer；编辑草稿与导入结果确认前不覆盖会话 |
| 装配 | lib/main.dart + app.dart | 生产仓库/引擎注入、路由与生命周期；测试用内存仓库与显式Fake |

GameTree是文档唯一棋谱真值；Position缓存不可变。文字导入先得到整棵合法新树再一次替换；剪贴板通过端口，失败可手动粘贴/复制。导出FEN不承诺保存分支/注释。在线服务和移动C ABI尚未落地，不能把接口设计算运行验证。

后续扩展：ReviewCoordinator作为可抢占后台任务复用EngineGateway；Auth/Sync/Book/Recognition均提供独立DTO与失败模型，可替换自建后端，部署方案纳入B10；UI不跨端口请求网络。设置/自动草稿应独立于显式棋谱仓库，避免把用户保存文档当临时缓存覆盖。

中文记谱由领域ChineseNotation负责，基于执方/源局面生成，不受UI棋盘旋转影响。中文解析通过合法候选的格式唯一匹配，拒绝歧义；界面显示可变，稳定UCI字段及GameTree schema保持不变。

自动草稿由DraftController/DraftRepository负责，FileDraftRepository只写chessnext-drafts；显式库仍只写chessnext-records。恢复创建未保存副本。正常退出/后台在composition root协调flush，失败选择在Material对话框呈现。设计边界和未验证持久性见ADR-006。
