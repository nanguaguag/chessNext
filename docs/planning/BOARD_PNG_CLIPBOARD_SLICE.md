# M4-03 / F11 → B11,B19：棋盘PNG复制

复用M4-02的不可变BoardImageSnapshot与PngImage缓存；新增ImageClipboard端口，不复用文字TextClipboard，不从已保存文件回读，也不让UI直调MethodChannel或NSPasteboard。复制与保存共享同一开窗快照和首次PNG编码结果。

ImageCopyCancellation只取消尚未开始的平台写入；NSPasteboard写入一旦开始不能回滚。关闭/route退场后，迟到PNG不得启动剪贴板写入；平台成功后route已退场不再提示。失败类型化为unavailable/write，可在同窗重试，不改棋谱、dirty、引擎或文件。

macOS适配器经独立`dev.chessnext/image-clipboard.copyPng`发送不可变PNG字节；原生主线程用ImageIO实际解码尺寸，再声明`.png`并写NSPasteboard，读回相同字节才报告成功。生产使用general pasteboard；集成测试使用独立命名pasteboard，避免覆盖用户剪贴板。其它平台能力为空并明确禁用复制；GIF仍后片。

验收：端口取消/迟到/开始后边界与错误映射，保存后复制只编码一次，渲染失败可重试，200%按钮状态/关闭取消；macOS真实渲染900×1000、命名NSPasteboard写入读回、镜像变化。根官方NNUE全test/analyze、native目标通过后中文独立commit。
