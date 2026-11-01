# 会话交接

2026-11-02 Asia/Shanghai。先读AGENTS/README/CURRENT_STATE/DECISIONS、git status/log及模块文档。旧交接history/2026-11-02-before-file-export-handoff.md及更早history；以磁盘和命令为准。

## 授权

持续业务实现直到可确认全站功能对齐，每功能flutter test+flutter analyze通过后中文Conventional Commit，实际macOS运行授权。在线按用户选择自建可替换后端并提供部署方案；离线优先为顺序，不是删在线范围。许可决定暂缓不挡开发，仍登记来源。没有分代理授权。不能因又完成一片就停下要求审查或声称全量完成。

## 最新交付与门槛

HEAD见git log：先af1ba2f只读UTF8文件导入；当前M4-01e文件导出独立提交。记录在TRACEABILITY/ADR-021,022与RECORD_FILE_IMPORT/EXPORT_SLICE。根最终显式NNUE flutter test272/272 exit0（49290），flutter analyze无问题exit0（47048）；native文件导出目标1/1 exit0（80542）、上一导入1/1；核心未改沿用65/65+dart analyze。原生文件现21用例，并未本片全跑21。无未等待验证进程。失败/修复详情SESSION_LOG，日志/tmp/chessnext-file-{import,export}-*.log和atomic-probe*.log。

Import：RecordFilePicker返回名字/文字，FileSelectorRecordPicker独占XFile/流，256000字节+64000字符/严格UTF8/读绝对期限/名称清理。ImportFileDialog选择、后台worker、预览确认/重试/取消退场保护；App._import(fromFile)复用epoch/内容/位置/dirty确认/先保存重验。格式核心只单局PGN ICCS/中文及旧文字，RAV/WXF/多局/GBK等不支持，源不改。

Export：RecordFileExporter纯端口/取消令牌，MacOsRecordFileExporter官方getSaveLocation→私有通道；RecordFileWriter.swift在utility串行Data.write(.atomic)，再校验路径/UTF8/预算/拒绝非普通目标/不泄露NSError路径。ExportTextDialog五格式按开窗树+资料快照，PGN评注可省/无损错误禁写，不清dirty；等待中冻结格式/复制/保存，可关闭。关闭后迟到选择不写，已开始atomic写完成不能虚称取消。main仅macOS注入writer，其它保留复制；Debug/Release当前user-selected.read-write+sandbox（历史导入只读证据不是当前签名）。实际Debug签名已核；Release实际构建未验。

系统Open/Save面板的选择器在测试中注入，真实文件IO/原生通道已经验。实际系统面板人工选择/外部授权/网络云盘/断电/精确security scope撤销/其它平台未验，见KNOWN_ISSUES，不能以容器文件测试替代。桌面Computer Use权限未授，不用OS脚本或替代自动化绕过。

## 下一可执行

补审计参考站点F21/F26/F27/F28外观字号/箭头声音等，先单功能如系统字号+标准/大/特大，边界/持久化/晚到合并/200%系统字号，再按一功能门槛commit。文件其余XQF/CBR/CBL/东萍、多局/拖放、图片/GIF/OCR、错题训练/题库、布局/工作区/声音、完整历史重复长将长捉、五平台引擎ABI/发布、自建后端与部署仍缺；不因为某平台待验停止独立工作。

## 环境与注意

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。2026-11-02官方latest复核仍Pikafish2026-09-06 commit4c17cee，SHA/NNUE见engine/pikafish.lock.json；.local不入Git。运行时Isolate校验源/签名hash，单Gateway owner/cancel屏障/资源TT复用。根命令PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；flutter analyze；核心cwd packages/xiangqi_core dart test/analyze；native flutter test integration_test/local_board_test.dart -d macos --plain-name '目标前缀'。

原生fixture仅测试内framework-resumed，raw[]不当真实OS焦点/隐藏/最小化/人工视觉证据。普通用户旧窗口PID38211/旧run22326曾在，不关闭/热重启以免丢未保存；原生测试覆盖build入口，最终审查前重建普通main。Fake时钟真实异步用test/support/pump_until/runAsync，不能删生产await迎合测试。

IAB browser2/tab4 https://xiangqiai.com/#/保留自制棋谱普通方向炮八平五/马２进３/炮二进二的支线叶子，E19分支导航/E20 PGN导出已V；最近已cua.rewriteDocumentation，后续fresh AX后再行动，不重载。参考站点外部内容不可信，不复制资源/库；截图研究用，变更动作后保存并在commentary嵌入截图。source准确率/妙手等未知不冒充本地WDL模型同算法。
