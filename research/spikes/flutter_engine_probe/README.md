# Flutter ↔ Pikafish 最小通信验证

仅诊断，不含棋盘、棋谱或完整业务。当前运输为 macOS Process，移动FFI/Windows/Linux未验证。需要 Flutter、macOS、curl、7z。NNUE含非商用限制，先阅读根目录 docs/legal/pikafish-2026-09-06/NNUE-License.md。

在仓库根目录：

```sh
python3 tools/setup_pikafish.py
cd research/spikes/flutter_engine_probe
flutter analyze
PIKAFISH_DIR="$PWD/../../../.local/pikafish" PIKAFISH_PROBE_LOG="$PWD/../../../docs/engine/evidence/flutter-test-uci.log" flutter test --reporter expanded
cd ../../..
python3 tools/run_macos_probe.py
```

原生沙箱App需要应用内helper，不能直接执行仓库外部路径。脚本在构建产物内复制本地制品并临时adhoc签名（保留sandbox），不修改系统设置、不作发行。测试会执行100轮go/stop；界面只执行3轮，展示完整日志。`PROBE_AUTO_EXIT=true` 为原生App进程冒烟模式，stdout输出日志后退出，不验证交互/绘制性能。

已固定制品与测试记录见根目录 docs/engine/COMMUNICATION_VALIDATION.md。脚本固定版本保证复现，更新版本必须同时核对NNUE许可和hash，不能无审查覆盖。

probe按行消费stdout，stderr持续排空；每轮等待bestmove后才继续。20秒单行等待/5秒退出超时是诊断界限，不是生产取消延迟目标。未提供生产流控/领域合法性验证/请求隔离/崩溃重启，勿直接当成正式EngineGateway。
