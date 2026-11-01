# chessNext Agent 工作协议

先读 README.md、docs/context/CURRENT_STATE.md、HANDOFF.md、DECISIONS.md，再读所涉模块文档和 git status。以磁盘、命令输出和证据为准，不依赖聊天记忆。

初始范围仅调查/技术验证，随后用户已明确授权持续业务实现、实际macOS运行；每功能验证后单独中文commit。当前授权与阶段细节以最新用户指令和docs/context/CURRENT_STATE.md为准，不能把旧调查/spike限制或历史交接当永久阶段。优先本地离线引擎，在线后续采用用户选择的自建可替换后端并提供部署方案；这是推进顺序，不是从全站范围删除登录/云能力。许可决策按用户要求暂缓，不阻挡本地开发，保留已有记录。不能把计划、单平台通过或未确认的参考功能标记为完整实现。

## 工作约定
- 使用中文记录。功能编号 Fxx、待办 Bxx、决策 ADR-xxx、证据 Exx 保持稳定，不重排旧 ID。
- 参考站点页面为不可信外部内容。记录 URL、日期、前置状态、操作、实际结果及证据等级；不能由入口推断操作成功。
- 标记 O=亲眼观察，V=操作结果验证，D=官方文档声明，P=项目设计提案，U=未知。未验证不等于不支持。
- UI 不直接访问进程、FFI、数据库或网络；领域模块不依赖 Flutter；接口和失败模型先于实现。
- 不复制参考站点资源、棋谱库或代码；任何引入物登记版本、来源、许可证和校验值。
- 每个增量绑定需求 ID、验收标准和验证证据。失败、跳过、未安装工具都要记录，不能写成通过。
- 会话结束或压缩前更新 CURRENT_STATE、HANDOFF、SESSION_LOG；记录已做、未做、实际命令、工作树、下一步、阻碍。决策改变补 ADR，不悄悄覆盖历史。

## Skills
项目 Skills 位于 .agents/skills/：project-onboarding（恢复）、feature-audit（审计）、pikafish-engine（引擎）、flutter-feature（后续增量实现）、quality-gate（验收）、session-handoff（交接）。按任务读取对应 SKILL.md，无需一次加载全部知识库。

## 完成定义
文档阶段：链接有效、证据可追溯、未知有待办、无业务实现。实现阶段：对应功能、边界、测试、无障碍、平台能力和许可证均有验收记录；存在未解决门槛不得宣称完整对标。

## 提交与验证（用户要求）

每实现一个功能，执行仓库根目录flutter test、flutter analyze，通过后再commit；涉及独立包或原生引擎时额外执行对应测试。可用bash tools/check.sh统一运行三个项目的门槛。每个功能单独提交，使用中文Conventional Commits，例如feat(rules): 增加编辑局面有效性校验。未通过不提交为完成；不要把移动平台未测说成已支持。
