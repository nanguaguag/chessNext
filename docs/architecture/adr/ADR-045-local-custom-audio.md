# ADR-045：按事件保存本机自定义提示音

- 状态：已采纳（M4-09）
- 日期：2026-11-03
- 需求：F28 / B23

## 决定

每类 `AudioFeedbackKind` 可单独试听、导入 WAV/MP3 或恢复默认。`AudioFilePicker`、`AudioOverrideRepository` 和 `AudioFeedbackPort` 是独立端口；Material 设置只调用 `AudioLibraryController`。导入限 512 KiB 与 5 秒，拒绝不支持的编码/损坏容器。文件和 schema 1 清单保存在应用支持目录的 `chessnext-audio` 子目录。清单文件名严格匹配事件名、数字时间戳及扩展名；自定义文件缺失/损坏时播放器回退应用内原创音效。

自定义音效不上传。替换采用临时目录写入，再先移动新文件、后原子替换清单，最后删除旧文件；重置只删除本事件清单及其受控文件。

## 验证和边界

WAV PCM/IEEE float 与 MPEG Layer III 逐帧验证结构及长度；超大、畸形和超时文件分别报错，取消选择不修改现值。macOS integration 使用 `DeviceFileSource` 成功加载本机用户路径。全量 Flutter 测试 446 通过、5 跳过（官方引擎环境未配置），`flutter analyze` 无问题，`flutter run -d macos` 已启动。

不实现参考站“音效1/2/随棋子皮肤”预设；参考站成功导入/试听尚未观察到，素材和组合优先级继续标为未知。其它平台文件选择器与音频解码未实际验收。
