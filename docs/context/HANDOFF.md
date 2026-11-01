# 会话交接

2026-11-02 Asia/Shanghai。先读AGENTS/README/CURRENT_STATE/DECISIONS、git status/log及模块文档；旧交接history/2026-11-02-before-text-exchange-handoff.md，失败/跳过/中断见SESSION_LOG。以磁盘/输出/追踪为准。

## 授权与完成边界

持续业务实现直到可确认全站功能对齐；每功能全量flutter test+flutter analyze通过后独立中文Conventional Commit。macOS实际运行已授权。在线自建可替换后端+部署方案；许可决策暂缓，不挡开发。完整对齐远未达成，不最终停下给审查。初始研究限制已按授权扩展，AGENTS与Skills同步b429166。

## 最近完成与证据

最近52e696d棋谱资料/保存草稿，1558bbd纯PGN，f7d2bb9分支点导航，927c45a引导，ccb2762帮助；当前M4-01c PGN文字交换本次提交见git log。模块IMPLEMENTED_MODULES/ADR005–020。

RecordTextExchange静态Isolate.run仅String→纯领域DTO/错误字符串，ImportedRecord携tree/metadata/source；PGN或旧文字识别，Meta及评注完整原子提交。导入busy可取消，PopScope/代次/route在退场尚mounted时拦迟到结果；clipboard读取仍可编辑并防晚到；App在解析/确认/先保存后核epoch+内容/位置修订。导出开窗tree+metadata快照，五格式Dropdown、PGN评注checkbox/不可无损错误禁复制，派生标签重算、声明结果不裁决。无系统filepicker，拒绝WXF/多局/RAV/NAG，不冒称全PGN。方案PGN_EXCHANGE_SLICE/ADR-020。

当前最终根显式官方NNUE238/238、flutter analyze无问题；本片5应用+7组件新增，含旧文字3回归目标15/15。核心未改沿用65/65+dart analyze。原生旧文字单项1/1（00:05）+新PGN单项1/1（00:11）exit0已确认：真实worker、注入MemoryClipboard端口、实际5节点完整保存和新App恢复；不触系统剪贴板。原生文件现19用例，本片未全跑19；上个资料片完整18首17+1定位失败修后资料1过。没有待等待验证命令。日志/tmp/chessnext-pgn-exchange-{application,target,full-final,analyze,native-legacy,native}.log。

本片初analyze5项大括号限定dart fix、后1项自定义active含mounted但flow不识别补显式mounted，修后完整门槛；不是业务测试失败。资料片core测试空List推断警告、native同名定位/漏变量失败已记录，不隐去。

## 核心文档所有权

GameTree只棋树/注释/所选lineAnchor；BoardSession并列GameMetadata，资料只内容revision/dirty，不改positionRevision，不重启普通分析/AI；整谱/候选仍内容revision过期。SavedGame/FileGameRepository schema1可选metadata、旧无字段empty、坏资料走备份/原件保留。FileDraft转传、Draft key加metadata，纯资料与命名空草稿可恢复。清最后字段仍dirty，覆盖保护以dirty判断。PGNCodec profile与限额见PGN_CODEC_SLICE，标签和编码主来源PGN_RESEARCH/E20，都是自制夹具。

## 下一可执行：文字棋谱文件导入

先研究官方Flutter file_selector当前稳定/平台能力/API，原始来源登记版本/包hash，新增依赖不要凭记忆。建议拆read-only单文件UTF8 PGN/FEN/普通文字导入为下一功能：ports文件服务返回有界字节/文件名（取消正常），适配器用官方picker+有界流读取/UTF8严格解码，应用用已有worker；不把UI耦合XFile/路径IO。文件名只用于显示/建议标题，不执行或自动联网。

复用导入snapshot/dirty确认/先保存后重验，IO/编码/超限/旧epoch失败不覆盖对局；取消与晚到同规则。现App._import协调逻辑可抽共用用例后供文字与文件；必须先方案/接口失败模型。格式先pgn/txt/fen，文件夹/拖放/多局/GBK等后续各增量。外部文件**导出覆盖**的沙箱/原子替换要先技术验证，不跟读文件混一大批。

macOS Computer Use桌面权限未授，不能用OS脚本/替代截图绕过；官方文件对话框选择若无法操作保持未验，仍可验证插件注册/build、注入picker+实际文件流/上层UI，不称真实系统选择已跑。之后再做系统文件导出/图片GIF/错题训练/布局外观声音/自建后端/五平台与完整历史规则；不因某个平台未验停止其它独立工作。

## 环境与恢复注意

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。2026-11-02官方latest仍Pikafish2026-09-06/commit4c17cee，lock及NNUE SHA见engine/pikafish.lock.json。.local不入Git，原生源与签名后hash/NNUE运行前Isolate校验，单EngineGateway所有者/取消屏障。根门槛：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze。核心cwd packages/xiangqi_core运行dart test/dart analyze；原生flutter test integration_test/local_board_test.dart -d macos，必要按plain-name选相关项。

integration_test只在测试内保持framework-resumed，生产无覆盖；raw生命周期[]不当真实OS焦点/隐藏/最小化/人工视觉。其它四平台/移动FFI未验，不能说已支持。普通用户窗口PID38211/旧run22326曾在，不主动关；测试覆盖build入口，最终审查前需要普通main重建，别热重启丢用户未保存内容。Fake Widget真实异步用pump_until/runAsync，不能删生产await来迎合假时钟。

IAB browser2 tab4本轮自制普通方向炮八平五/马２进３/炮二进二选中支线末端，E19导航/E20 PGN导出已V并markHandoff；压缩先cua.rewriteDocumentation再fresh AX。E20原下载/样本hash在manifest；截图只研究，不作App资源。参考准确率/妙手公式/题库版本与其它未知仍在FEATURE_GAPS/BACKLOG，原生WDL/损失报告不冒充网站同算法。

## 最新完成 M4-01d

只读UTF8单文件导入已经实现并独立提交（见git log）。端口RecordFilePicker/typed失败；适配器FileSelectorRecordPicker独占XFile/IO，256000字节/64000字符、严格UTF8、读取预算5秒与订阅取消/名称清理；ImportFileDialog预览/确认/取消退场代次，App._import(fromFile:true)共享快照/dirty/先保存保护。main已注入官方file_selector1.1.0，锁定传递版本与LICENSE/archive摘要见legal登记。macOS Debug/Release user-selected.read-only+sandbox，Pod嵌入生成变更真实保留。

目标18/18，根256/256显式官方NNUE和analyze均exit0；native文件目标1/1真实IO+worker+保存及源不变通过，实际Debug签名含只读/sandbox。系统chooser注入，不当NSOpenPanel实际选择验证；Release实际构建/其它平台未验。核心未变65沿用。初测试接口误用和WXF夹具首标签失败、analyze冗余import已记SESSION_LOG/TRACEABILITY。无待等待会话；日志/tmp/chessnext-file-import-*.log。普通旧用户窗口不要关。下一外部文字文件导出先验证sandbox/替换失败模型，写服务独立于只读端口；此段覆盖前文“下一导入”的旧建议。
