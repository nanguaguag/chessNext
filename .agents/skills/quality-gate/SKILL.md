---
name: quality-gate
description: 检查 chessNext 阶段交付和验证证据，防止把计划或单平台通过当成完成。
---

# quality-gate

按 docs/planning/MILESTONES.md、TRACEABILITY.md、TEST_STRATEGY.md 选择门槛。文档阶段检查链接、编号、状态一致、来源和未知项；Skills运行可用校验器。

实现阶段核对需求→变更→测试→平台证据；检查引擎stop竞态、持久化失败恢复、离线无账号、无障碍与许可的相关项。只运行对本次变更有意义的检查，不编造通过结果。

报告 pass/fail/not-run/blocked 和理由；未完成必要项时不声明完整对标。将残余问题写入 KNOWN_ISSUES 和 BACKLOG。
