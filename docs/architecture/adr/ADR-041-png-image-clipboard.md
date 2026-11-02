# ADR-041：PNG图片剪贴板与渲染缓存复用

- 状态：接受（macOS图片复制切片）
- 日期：2026-11-02
- 关联：F11、B11、B19、E34、ADR-040

## 背景

文字TextClipboard只处理字符串，不能承载PNG，也不能让UI直接调用NSPasteboard。图片保存已生成有界PngImage；同一对话框再次复制不应重新渲染或从用户选择的文件回读。系统剪贴板写入开始后无法安全回滚。

## 决策

新增ImageClipboard端口，输入拥有字节的PngImage和独立ImageCopyCancellation，返回copied/cancelled或类型化unavailable/write。取消只阻止尚未开始的平台写入；已开始操作独立完成。BoardImageDialog保存和复制互斥，共享首次成功生成的PNG缓存；渲染失败不缓存，平台失败重试复用缓存。route退场取消迟到渲染且不显示迟到结果。

macOS适配器通过独立`dev.chessnext/image-clipboard`通道发送PNG。ImageClipboardBridge用ImageIO实际解码并执行8MB、4096边长、400万像素门槛，再声明`.png`、写入NSPasteboard并读回相同字节才报告成功。生产使用general pasteboard；集成测试可选择固定命名pasteboard，避免覆盖用户数据，同时走相同验证和写入代码。

## 结果与边界

UI、应用快照和文字剪贴板均不依赖Cocoa。其它平台未注入能力时复制按钮禁用并解释。命名pasteboard的原生集成验证不等于人工从系统general pasteboard粘贴；拒绝/隐私提示、跨应用兼容、GIF和其它平台仍需各自验收。
