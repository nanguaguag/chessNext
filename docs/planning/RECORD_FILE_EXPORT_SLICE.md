# M4-01e / F12 / B11,B19：UTF8文字文件导出（P）

2026-11-02。既有五种文字格式导出同一开窗快照，新增“保存文件”。导出不改变当前棋谱dirty/本地库绑定，保留格式损失提示；PGN评注无法无损表示时仍禁写，可显式省略评注。

先技术验证macOS Foundation Data.write(.atomic)：先写辅助文件，完成后替换目标；不使用Dart File.rename承诺跨平台安全覆盖（其官方文档允许先移除目标），也不直接truncate旧文件。探针覆盖新建/替换/目录失败/缺父目录保留旧内容；只证明本机文件系统，不等于外部NSSavePanel授权或断电持久化。原始来源：[Apple atomic](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic)、[sandbox选择文件](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)、[Dart rename](https://api.dart.dev/dart-io/File/rename.html)。Apple页面web正文缺失，经官方.md端点取得内容，未复制上游代码。

RecordFileExporter端口只接内容/格式扩展/建议文件名与取消令牌。macOS适配器独占官方file_selector保存对话框及本项目原生atomic写入通道。系统选择取消正常；写入前验证字符/字节/扩展，平台不支持/选择/写失败分类。仅macOS已有安全writer，Android/iOS/Windows/Linux暂不注入，不用不安全降级冒称支持。

Debug/Release从只读升级为user-selected.read-write，继续sandbox；只有显式保存文件才写外部目标。文件路径不进UI/日志/持久偏好；无安全书签，重启不能自动覆盖。系统负责文件名/覆盖选择确认；关闭Flutter导出窗口后迟到选择不得开始写入，已经开始的atomic写入完成独立于棋谱文档，回调不碰其它路由。写入不附超时后假装已取消，因为原生写入不能撤回；UI可关闭但已确认目标的工作继续。

验收：技术探针、端口/大小/取消/不支持/异常映射、开窗快照与格式名/评注/禁写/重试/取消退场、真实macOS通道新建/替换/失败与源文档不变、全量flutter test/flutter analyze后单独中文commit。实际系统保存面板人工交互、外部沙箱授权/网络盘/云盘/断电/Release实际签名/其它平台保持未验，不以注入选择器替代。
