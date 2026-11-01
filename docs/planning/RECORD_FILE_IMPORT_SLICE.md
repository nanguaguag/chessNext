# M4-01d / F07,F12 / B19：只读文字棋谱文件导入（P）

2026-11-02。单个UTF8 PGN/FEN/txt文件，经用户选择后有界读取、后台解析、预览，再由既有导入保护原子替换。取消正常返回；大小、编码、读取、插件不可用、解析失败均不改棋谱。多局、GBK、二进制格式、目录、拖放与外部导出分别后续增量。

端口RecordFilePicker只返回displayName/text，不暴露路径或XFile。FileSelectorRecordPicker是唯一插件/流读取所有者：256000字节与64000字符双限额，严格UTF8，stat和实际流均校验，读取绝对5秒预算并关闭订阅；系统选择等待用户操作不限时。显示名限制160字符并清理控制符，不作为路径或自动联网依据。格式识别复用RecordTextExchange工作Isolate。UI只调用端口及格式用例。

生产main注入官方file_selector 1.1.0；macOS Debug/Release添加user-selected.read-only，继续启用沙箱，不申请写权限。平台按官方能力选择过滤：iOS public.data（任意类型，内容严格验证），其它pgn/fen/txt扩展；过滤不作为安全校验。官方能力表为D，不代表五平台已运行。

Material3对话框显示限制、选择/读取/解析状态、选中文件与格式/着数预览；忙时防重入，可取消，PopScope/代次/路由防迟到结果弹错或关闭另一窗口。App沿用导入开窗epoch/内容/位置快照、dirty确认及先保存后的再次验证。源文件永不修改；取消选择不清除已有成功预览，选了新文件后若失败不得沿用旧预览导入。

验收：真实文件流UTF8/BOM及PGN资料评注、取消/超限/谎报长度/编码/异常/超时清理、后台解析；UI预览/错误/重试/取消退场/200%字号，脏文档取消与先保存和旧文档保护；全量flutter test + flutter analyze后独立中文feat提交。macOS编译/插件注册/签名只读entitlement与注入chooser+实际文件IO验证；真实NSOpenPanel交互受桌面权限限制保持未验，不绕过。其它平台保持未验。

官方来源：[发布与平台表](https://pub.dev/packages/file_selector/versions/1.1.0)、本机pub缓存同版源码；解析的实际版本及archive SHA以pubspec.lock为准（包括由当前SDK约束选出的平台实现）。完整依赖清单见legal登记。
