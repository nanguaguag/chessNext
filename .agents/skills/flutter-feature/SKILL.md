---
name: flutter-feature
description: 在获准实现后为 chessNext 交付单个 Flutter 功能增量；也适用于功能接口设计。
---

# flutter-feature

先确认 CURRENT_STATE 的授权范围；仅调查阶段只输出设计与测试规格，不生成完整业务。选择一个 F/B 项，读取 ARCHITECTURE、DESIGN_SYSTEM、INTERACTION_SPEC。

先定义可观察验收和失败模型，再改最小模块。UI仅调用ViewModel/用例，领域不依赖Flutter，IO经端口注入。使用Material3语义组件，平台文件/菜单/生命周期经适配器；覆盖断网、取消、字号、焦点。

执行与改动相称的验证，报告实际命令与平台。未跑平台保持未验证。更新追踪与交接，不以大批脚手架代替可验证增量。
