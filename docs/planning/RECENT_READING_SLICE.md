# F18 / B06,B19：本地最近阅读增量（P）

2026-11-02。E17只验证访客入口与空态，未验证网站自动记录成功。以下为离线优先的明确项目设计，不伪称网站内部实现。

范围：已保存/已打开本地棋谱，按最近实际读谱位置变化去重并前置，最多50条。独立ApplicationSupport/chessnext-reading schema1元数据，含棋谱ID/显示标题/最近阅读时间/根FEN/根到游标UCI路径；不存第二份棋谱，不写回棋谱modifiedAt，不自动记录未保存新局/导入副本。保存成功后可开始记录；导航不增加内容dirty。选子/引擎info不刷时间，单独300ms合并，后台/正常退出flush。

恢复不信任稳定节点ID：打开最新保存棋谱，根FEN一致且整条着法路径存在才恢复游标；根换/路径删则保留已保存默认位置并明确提示。未保存新分支只能由独立草稿恢复，阅读历史不承诺持有内容。已保存的未来线路锚点沿用现有GameTree规则，不在此新增未来分支元数据。打开前保护当前dirty，IO期间文档或游标变化拒绝覆盖；历史载入也不得造成旧数据晚到覆盖本轮读谱。

失败：历史坏主文件可备份恢复并提示；双坏保留原件且禁止自动覆盖，提供重试。写失败不阻止棋谱保存/走棋，状态可见且重试；缺失棋谱打开失败留历史可辨，不自动删用户内容。串行暂存+同目录rename、最多2MiB；只单窗口接受，不声称断电或跨进程并发事务。

模块：ports/recent_reading_repository.dart纯DTO+接口；application/recent_reading_controller.dart独立协调并监听LibraryController/BoardSession，存储适配器不进UI；RecentReadingDialog复用库的未保存保护逻辑或独立小共用入口。App仅装配与生命周期flush，LibraryController.open可选读取标记并在提交前恢复，不引入网络/第二引擎。

验收：顺序/去重/上限、导航不dirty不改存谱、late读取合并、已保存与未保存边界、根/路径失效/ID复用、IO失败重试/原件/备份/限额；组件空/错误/脏保护/200%字号与行打开；真实macOS文件存储新实例恢复读取位置。每功能根完整flutter test+flutter analyze后单独中文feat(library) commit，原生变更补macOS。核心无修改则沿用其已验证记录。
