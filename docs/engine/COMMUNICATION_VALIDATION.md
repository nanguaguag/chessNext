# Flutter ↔ Pikafish 通信验证 / 2026-11-01

## 已验证事实

官方 latest HTML 指向 Pikafish-2026-09-06，git ls-remote 固定提交 4c17cee11f888ae1d48a9494f2e2239f019f0a1f。GitHub API 因共享出口rate limit返回403，改用公开发行页与tag核查，不依赖缓存的最新版结论。

完整制品清单见 [pikafish.lock.json](pikafish.lock.json)；hash来自本次官方包下载实测，未验证上游签名。macOS二进制为arm64/x86_64通用包，NNUE文件50,706,378字节。制品只存.local，不提交二进制或权重。

环境：Flutter stable 3.44.6、Dart 3.12.2、macOS14.4 arm64、Xcode15.0。本轮未升级Flutter，不宣称它是最新stable。

| 验证 | 结果 | 原始证据 |
|---|---|---|
| flutter analyze | 通过，无问题 | 本次命令输出 |
| Flutter真实引擎测试 | 通过：握手、选项、NNUE、MultiPV=2、depth6、走h2e2后200ms搜索、100轮go infinite/stop/bestmove、quit exit0 | [日志](evidence/flutter-test-uci.log) |
| 缺失引擎负向测试 | 通过：ProcessException，未冒充成功 | Flutter测试2/2通过 |
| flutter build macos --debug | 通过 | 生成最小诊断App，不是完整象棋App |
| 沙箱App内helper | 通过：NNUE、MultiPV、限时搜索、3轮stop/quit，进程exit0 | [App日志](evidence/macos-app-uci.log) |
| App直接运行外部引擎 | 失败：Operation not permitted | macOS Sandbox阻止仓库外部helper；需应用内打包与签名 |

“NNUE加载成功”判据是引擎输出 NNUE evaluation using 指定路径；“bestmove”只校验坐标语法，未实现领域合法性判断。100轮压力测试为串行收尾验证，不等于完整生产竞态、RSS或热性能测试。

## 可重复命令

在仓库根目录执行 `python3 tools/setup_pikafish.py`（需要curl和7z，先读权重许可）。然后按 research/spikes/flutter_engine_probe/README.md 执行flutter analyze/test。脚本固定URL与hash，版本更新须人工审查许可和hash。

`python3 tools/run_macos_probe.py` 构建诊断App，将helper和权重放入Resources，helper使用sandbox+inherit entitlement，App保留生成的debug sandbox entitlement，adhoc签名后运行。它仅操作可重建构建产物，不关闭系统Sandbox。PROBE_AUTO_EXIT仅验证真实Flutter App进程通信，不声称已验证交互、绘制或性能。发布时需要正式build phase/Developer ID/公证与对应源码分发，不能照搬adhoc签名。

## 未验证

Android/iOS C ABI、Windows/Linux、发行签名、非法局面、故障重启、stop超时、长行/半包fixture、内存泄漏、性能/热管理均未完成。桌面通信成功不等于全平台支持。源码未做修改或本地编译；运行的是官方发行二进制。

## 许可发现

发行包独立NNUE许可禁止未经允许商用，见 legal/LICENSING；发行前必须解决。文档先前将权重许可列未知，本轮取得原文后收紧结论，不把权重声称为GPL。

沙箱内引擎报告共享内存不可用，回退到Local memory后正常工作；性能和RSS仍需单独测量。helper签名在构建副本进行，原始.local制品hash保持不变。
