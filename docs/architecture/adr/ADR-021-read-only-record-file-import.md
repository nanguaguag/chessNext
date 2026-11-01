# ADR-021：只读文件端口与有界文字导入

日期2026-11-02，状态：当前macOS切片接受；其它平台和真实系统面板操作未验。

系统文件选择经RecordFilePicker端口，仅向UI返回显示名和有界文字；file_selector、XFile、路径、文件流均留在FileSelectorRecordPicker。单文件只读，stat/实际流256000字节、严格UTF8/64000字符、每读取阶段5秒绝对预算、取消流订阅；用户选择不限时。插件失效/读取/编码/大小/超时分类错误，不泄露绝对路径。名称清理控制符并截取160码点。

选择与解析不等于导入。Material3预览需明确确认；取消选择保留已有预览，新文件失败则清除旧预览。解析复用后台工作Isolate。对话框退场代次丢弃迟到工作，App复用文字导入的epoch/内容/位置校验、dirty确认、先保存及再校验，资料与棋树一次替换。外部文件永不写入。

macOS生产main注入插件，Debug/Release只申请user-selected.read-only并保持sandbox。iOS过滤用public.data，其它用扩展，过滤不是格式校验；官方声称平台支持不当实测。引入依赖及SHA登记legal/FILE_SELECTOR_DEPENDENCIES。

取舍：本片不将外部文件绑定为可自动覆盖的编辑目标，不持久保留路径/安全书签，不为GBK猜码。另做写文件/分享适配器及各平台签名验证，避免读取功能提前扩大写权限。系统面板人工操作未验，不以注入chooser代替该证据。
