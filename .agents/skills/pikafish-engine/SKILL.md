---
name: pikafish-engine
description: 调查、验证或集成 chessNext 的原生 Pikafish 与 NNUE、UCI 生命周期。
---

# pikafish-engine

先读 docs/engine/PIKAFISH_RESEARCH.md、ADR-002、docs/legal/LICENSING.md。固定官方发行tag、完整SHA、网络SHA256和构建环境；更新前重新核查latest，不能沿用聊天中的最新版结论。

以实际 uci option 握手确定能力，勿假定 Skill Level/UCCI/规则切换存在。桌面Process与移动C ABI分别验证；FFI不得阻塞UI或跨边界抛异常，明确缓冲所有权。停止等待旧bestmove后再启动下一搜索，阻止旧epoch更新新局。

保存真实握手、NNUE加载、短搜索、stop/quit日志与测量；未执行写明。初始阶段仅允许spike；当前授权与实现范围以CURRENT_STATE及最新用户指令为准。已授权的业务引擎增量遵守flutter-feature与逐功能测试/提交门槛，不将旧spike措辞当新的审批要求。修改上游保留最小补丁和对应源码许可记录。
