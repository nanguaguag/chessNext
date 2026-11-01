# ADR-022：文字文件导出与macOS原子写入

2026-11-02；状态：当前macOS接受，真实系统保存面板及外部沙箱授权未验。

导出与内部棋谱保存分离，RecordFileExporter无路径接口，只接固定文字快照、白名单扩展和取消令牌。MacOsRecordFileExporter拥有file_selector保存面板及私有MethodChannel；UI和领域不接触XFile/路径/IO。平台尚无相应安全writer时不注入文件保存，保留已有文字复制。字符/UTF8字节预算与导入相同，拒绝无损UTF8编码失败。

macOS RecordFileWriter在utility串行队列使用Foundation Data.write(.atomic)，不直接截断现有目标。通道再次校验绝对本机路径、预算、UTF8，拒绝目录/非普通文件包括符号链接，不传NSError路径详情。Dart File.rename官方约定允许先删除目标，因此不将它当跨平台安全覆盖契约。本地探针和原生真实通道验证不等于断电、外部/网络/云盘原子性证明。

开窗时固定tree+metadata，格式及评注范围沿现有显示；按钮开始时固定text/extension，等待中冻结格式/复制/保存，允许关闭。关闭取消令牌使迟到的系统选择不开始写入；已经进入原子写入的任务完成，不能在Dart超时后虚称撤回。晚到UI结果不关闭别的路由或修改文档。写入成功仅提示文件保存，不清dirty或绑定LibraryController。

本片明确增加写入用途，Debug/Release user-selected改为read-write，sandbox保持；系统保存对话框负责选位置/覆盖确认。路径不留偏好/书签，不支持重启自动覆写。实际外部面板选择和安全作用域撤销须平台验收；现插件只返回path，未宣称已证明资源作用域精确释放，后续核对插件或原生URL所有权。M4-01d历史只读签名证据不覆盖此后版本。
