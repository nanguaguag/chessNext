# 会话交接

2026-11-02 Asia/Shanghai。先AGENTS/README/CURRENT_STATE/DECISIONS与git status/log，再按模块文档恢复。旧交接保存在history/2026-11-02-before-reading-handoff.md，失败/中断/跳过见SESSION_LOG，不依赖聊天记忆。

## 授权及当前基线

持续业务实现直到可确认全站功能对齐；一功能全量flutter test+flutter analyze通过后独立中文Conventional Commit，macOS真实运行已授权。在线自建可替换后端+部署方案；许可决策暂缓不挡功能。完整对齐远未完成，不最终停下给审查。

最近已提交3c59834评级报告（native-wdl-loss-v1，非网站准确率）及e9cf7b1 E16/E17研究；此前ddbcc9b原生WDL，b429166已同步Agent协议实施范围。基线报告根172/原生15，核心49未改；当前F18 WIP如下。

## 当前F18 / M2-13 / B06,B19（已完成，提交见git log）

RecentReading DTO/端口、独立RecentReadingController与文件/内存适配器、RecentReadingDialog、App/main生命周期装配。已保存本地谱ID/documentEpoch绑定，最多50条去重前置/300ms/串行写，根FEN+整条UCI路径恢复，禁止只用节点ID。普通库沿用保存位置，最近阅读入口才用标记；不存未保存分支/新局、不写原谱，草稿独立。库刷新不能重绑外部替换文档，save绑定失效另建ID。dirty确认后再次查文档/位置修订，IO晚到保护保留。

正式main注入ApplicationSupport/chessnext-reading，schema1/2MiB/50条/1999着，备份/坏主归档；双坏禁止自动覆盖，重试合并本轮元数据；失败不挡棋谱保存。详planning/RECENT_READING_SLICE、ADR-017、IMPLEMENTED_MODULES。新增17测试（10应用/3文件/4组件），最终根真NNUE189/189、flutter analyze无问题；macOS完整16/16及双提示修订后最近阅读单项1/1通过。日志/tmp/chessnext-recent-{final,final-analyze,native,native-final}.log，无待等待验证命令。静态初7项大括号/原生夹具getter错误/末1项null-aware已修并如实记录。F18所有文件应已独立feat(library)中文提交，剩E18研究文件/研究文档分开docs提交。

## 研究与下一条

E16存题访客需登录V；E17最近阅读访客空态V，公开《事林广记》3/3只读标题出现但着法未载入/回历史仍空，记录/恢复仍U，不能当打开内容成功。E18按钮帮助和手动重放4步/跳过已观察，AX/截图已在docs/research已登记但待独立提交；与F18功能分开docs提交。说明声明首尾跳到前/后分支点，但本轮未操作验证，不能写V。IAB browser2 tab4停公开只读页已markHandoff；压缩恢复先cua.rewriteDocumentation再fresh AX，不重选browser。截图仅研究，不能作App资源。

下一F29离线按钮说明/使用帮助（单独功能），再手动新手引导、分支跳转、错题训练、文件格式/图片GIF、库完善/布局外观声音、自建后端部署、五平台及完整历史规则；每次一个功能通过再commit，不能到此最终停下。源站准确率/妙手/可接受候选公式仍未知，报告阈值/聚合明确是项目模型。

## 环境与复跑

Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0；2026-11-02官方latest仍Pikafish2026-09-06、commit4c17cee，NNUE/SHA见engine/pikafish.lock.json。.local不入Git。root真引擎门槛：PIKAFISH_EXECUTABLE="$PWD/.local/pikafish/Pikafish-MacOS-universal" PIKAFISH_NETWORK="$PWD/.local/pikafish/pikafish.nnue" flutter test --reporter expanded；再flutter analyze，原生flutter test integration_test/local_board_test.dart -d macos。FileReviewCache正式AppSupport注入；详engine/REVIEW_CACHE、ENGINE_IDENTITY/WDL_RESEARCH。

macOS integration_test仅测试内保持framework-resumed，生产无覆盖；真实OS焦点/最小化/人工视觉未验，Computer Use桌面权限未授，不绕过。其它四平台/移动FFI未验。普通用户窗口PID38211/旧run22326曾在，不主动关；原生测试覆盖build入口，最终审查前重建普通main。Fake engine清理需pump_until通过runAsync推进真实zone的subscription.cancel，不能删生产await。

E18研究独立提交见git log：按钮说明实际开关、引导首步重放/跳过已V；分支跳转只有文字O待操作。本轮后续F29先做独立可搜索离线帮助，不把帮助页当自动首次引导完成。当前F18提交5acdeda，根189/原生16+1，无验证命令运行。
