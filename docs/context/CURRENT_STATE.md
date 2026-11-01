# 当前状态

日期2026-11-02（Asia/Shanghai）。M3-02：本地棋谱分支/保存已实现，正式Pikafish分析已接主App；全站对标尚未完成。

用户要求持续推进至全站对齐，每功能先flutter test/flutter analyze再单独中文Conventional Commit，不提前停下来审查。用户已选在线部分自建可替换后端并提供部署方案；旧的在线/账号“延期”仅表示先后顺序，不再永久排除。许可按要求暂不处理，不阻挡本地开发。

## 当前实现

- d3ba721 macOS棋盘；fd295fa棋谱分支/注释/游标、主线提升/变着删除；9e408b2本地保存/命名搜索/打开/备份恢复。
- 53e4f4f正式EngineGateway/UciEngine/Process运输；本轮AnalysisController与主界面分析面板、cp/mate/bound视角归一化、MultiPV、深度/时间/NPS、推荐/回复箭头、线程/Hash/变化数设置。内容revision、positionRevision和引擎generation分别隔离保存与搜索竞态。
- macOS构建脚本从.local核对hash后复制官方引擎/NNUE/许可到Resources并签名helper；Sandbox开启。不在Git提交二进制。缺少.local时仍能构建棋盘，分析明确不可用。
- 离线规则为纯Dart包；IO与引擎都经端口注入，组件测试使用显式内存/假引擎。

## 最近验证

带PIKAFISH_EXECUTABLE/PIKAFISH_NETWORK环境的根flutter test33/33、flutter analyze无问题；核心32测试及分析通过。macOS原生3/3：双人棋盘、Documents临时目录真实保存/新实例恢复、应用包内官方NNUE搜索/切换MultiPV=2/停止。未授Computer Use权限，不能声称截图/人工视觉验收通过。2026-11-02重查官方latest仍指向2026-09-06。

## 接续

下一项F03本地AI对弈（分析互斥、执方、催招/变招/悔棋）→局面编辑、FEN/棋谱导入导出、自动草稿→整谱复盘/错题→设置/体验→在线后端与五平台。B16仓库当前单窗口快照实现，见ADR-005，不声称SQLite、断电fsync或跨进程写事务通过。历史长将长捉/重复/自然限着、移动FFI、Windows/Linux、正式签名公证仍未完成。

现有用户运行窗口不要自动关闭；测试创建的App与helper已收尾。以git status/git log为准；无需依赖聊天记忆。环境Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。
