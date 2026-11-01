---
name: session-handoff
description: 结束、压缩或切换 chessNext 会话前写入可靠交接。
---

# session-handoff

更新 docs/context/CURRENT_STATE.md、HANDOFF.md、SESSION_LOG.md；新增或变更决策时同步 DECISIONS 与 ADR。

交接必须包括日期/时区、授权范围、已改文件与F/B-ID、实际命令结果、没做的验证、未提交工作和下一条可执行操作。记录后台进程/临时制品与阻碍，勿记录凭据。无后台任务也明确说明。

用 git status 和实际文件核对交接，不把尝试写成完成，不让接手者依赖临时浏览器tab或聊天记忆。
