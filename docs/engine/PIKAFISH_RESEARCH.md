# Pikafish 调查

核查日期 2026-11-01。[官方 latest](https://github.com/official-pikafish/Pikafish/releases/latest) 当次跳转 [2026-09-06](https://github.com/official-pikafish/Pikafish/releases/tag/Pikafish-2026-09-06)，短 SHA 4c17cee。发行说明介绍通用二进制的 CPU 自动选择及 NNUE 升级。不能把 master 当稳定版，也不能把说明中的通用二进制推断为覆盖全部移动 ABI。

[官方 README](https://github.com/official-pikafish/Pikafish/blob/master/README.md) 明确为 UCI 中国象棋引擎，无 GUI；采用原生源码构建保留 NNUE，勿误用 UCCI 协议。[固定 tag engine.cpp](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/engine.cpp) 暴露 Threads、Hash、Clear Hash、Ponder、MultiPV、Move Overhead、nodestime、UCI_ShowWDL、EvalFile 等选项；未看到 Skill Level 或规则切换选项，因此网页难度和亚洲规则不能直接一一映射到该引擎。

[固定 tag evaluate.h](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/evaluate.h) 的默认网络名为 pikafish.nnue。不能仅靠文件名判兼容：需记录来源、完整 SHA256、大小、匹配引擎提交和许可；加载失败显示修复路径，不静默换网络。

## 通信方案

| 方案 | 优点 | 限制 | 决策 |
|---|---|---|---|
| 桌面 Process + stdin/stdout | 原生速度、可重启、保留标准 UCI | 签名/执行权限、stderr背压、路径 | 首选候选 |
| 移动 C ABI + dart:ffi | 原生 NNUE、避免子进程假设 | 需最小包装、线程和内存所有权、进程内崩溃 | 必做 spike |
| MethodChannel | 生命周期/平台能力便利 | 不适合高频分析消息 | 控制面可选 |
| WASM | 网页分发便利 | 不作为本项目原生性能承诺 | 不优先 |

[Flutter FFI 官方指南](https://docs.flutter.dev/platform-integration/bind-native-code) 当前推荐 package_ffi/build hooks（自 3.38）。这是绑定方式依据，不能证明未经改造的 C++ 引擎自动兼容五平台。C ABI 提案为 create/send/poll/stop/destroy，字符缓冲由分配方释放，不跨边界抛 C++ 异常；搜索/等待在 native 工作线程，UI 不阻塞；不要通过重定向全进程 stdin/stdout 包装 main。

## UCI 生命周期设计与验证脚本规格

以 [固定 tag uci.cpp](https://github.com/official-pikafish/Pikafish/blob/Pikafish-2026-09-06/src/uci.cpp) 为协议依据。以下为未来交互序列，**本轮未执行**：

1. 启动并发送 uci，等待 uciok，保存全部 option；超时退出并标记 failed。
2. 按握手能力 setoption（先低资源 Threads=1、Hash=16、MultiPV=1），isready 等 readyok。
3. ucinewgame；position startpos；go depth 4；接收 info 与 bestmove，校验着法合法。
4. position startpos moves h2e2；go movetime 1000；确认先手及分数视角。
5. go infinite；stop；等待 bestmove 才允许下一次 go；重复100轮并测试退出、EOF、崩溃、长行与半包。
6. quit 并验证退出和线程/内存释放；FFI 执行相同语义，不强迫其重用阻塞控制台循环。

默认拟定握手10秒、stop2秒；这些是可配置初值而非已测性能。stop超时桌面终止进程重启；FFI 无法安全强杀任意线程，需 cooperative stop/join，经实测失败时禁用该会话，不能假称已释放。

## 构建与性能门槛（待执行）

先获取完整 tag SHA 和制品清单，不执行未知二进制。依上游 make help 确认目标；产物记录编译器、flags、SDK/NDK、OS、ABI、CPU指令、网络校验及补丁。桌面优先 macOS arm64/x64、Windows x64、Linux x64；移动 Android arm64-v8a 与 iOS arm64，其他架构待需求确认。

对比同源码/网络/线程/Hash 的原生 CLI 和适配器：固定10个合法开中残局、冷暖启动、固定节点与固定时间、各5次中位数；记录NPS、时间、RSS峰值、停止延迟、10分钟热降频。目标适配器计算耗时增量≤5%，持续UI帧不被阻塞；不跨不同硬件比较NPS。

实际验证状态：仅静态源码与网页引擎结果核查，原生编译、C ABI、NNUE加载、性能、最低平台版本均未验证。B02/B03 是实施前的阻断门槛。

## 2026-11-01 后续实测更新

此前“仅静态核查”是首轮状态；本轮已取得官方制品并在Flutter test和真实macOS App沙箱内验证通信成功，详见 [通信报告](COMMUNICATION_VALIDATION.md)。没有本地编译上游源码，移动FFI/其他桌面仍未测；NNUE独立非商用限制已确认，见legal/LICENSING。
