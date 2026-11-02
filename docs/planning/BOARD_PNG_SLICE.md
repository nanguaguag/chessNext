# M4-02 / F11 → B11,B19：原创棋盘PNG快照与文件导出

E34确认源静态保存/复制是当前显示棋盘（含末步/评级/坐标、无侧栏/局势条），镜像跟随；本片先PNG生成/预览/保存，复制独立下一片。不使用研究图片或源站图形作为产品素材。

BoardImageSnapshot纯值捕获打开时Position/末步/可靠评级/有效推荐与本步变着/方向/棋盘外观；不保留Controller/IO，主谱后来变化不追随。只读预览排除棋盘交互与90格焦点，单组语义；冻结Scope和系统字体比例，静止末步标记。选子/目标/键盘焦点作为输入态不导出（P，源未验）。

项目固定450×500逻辑棋盘、2倍PNG=900×1000（P，不推源分辨率策略），有界尺寸/字节，UI异步toImage/PNG编码并释放Image。保存时busy/可关闭取消，关闭/route退场后不能开启迟到chooser或写入；已开始的原子写完成不可回滚，同现文字约定。错误可重试，固定快照PNG可缓存，不清dirty或暂停分析。

新增PngImage有界不可变PNG值、PngFileExporter及类型化失败；复用文件取消协议但独立PNG限制。macOS新writePngAtomic方法独立于文字256k/UTF8约束，工作队列验证实际PNG图像和维度后Foundation atomic/同regular目标约束，chooser由file_selector。其它平台仍可预览生成，文件能力未实现则说明并禁保存；正式main注入macOS端口。UI不直IO。

验收：DTO冻结/外观开关/源不变、真实PNG签名/尺寸/方向/像素/有界数据、adapter选择取消/迟到/写失败/重试/持有不可变数据、200%窄窗只读/关闭取消渲染与迟到选择/不改谱或引擎。根官方NNUE全test/analyze，native实际900×1000PNG解码/文件原子替换及坏PNG不覆盖/固定源与方向，中文commit。OS人工保存面板/其它平台未验，复制/GIF后片。
