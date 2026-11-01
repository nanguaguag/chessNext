# M4-01c / F07,F12 / B19：App PGN文字交换（P）

2026-11-02，前置1558bbd格式层/52e696d资料保存已验收。此片接App文字/剪贴板，不等于系统PGN文件选择器/批量/拖放/分享已实现。

应用接口RecordTextExchange返回typed ImportedRecord(tree,metadata,sourceFormat)。以[开始自动识别PGN，否则沿既有TextRecord；PGN未知标签与根/逐着评注完整带入GameMetadata，纯文字新文档资料empty。解析在静态/顶层Isolate.run，只捕获String并传纯领域DTO/错误字符串，禁止捕获WidgetState或仓库/引擎。64000字符/1999着等既有限额不变。

ImportTextDialog解析中禁重复/文字编辑但可取消，错误保留原文；剪贴板读取仍允许修改文字并防晚到覆盖。取消后worker可完成但不得弹错/关闭其它路由或提交结果；App保留先解析再dirty替换保护，导入窗口/替换确认/先保存后均重验epoch+内容/位置修订，旧回调不覆盖新棋谱。结果声明不裁决，资料/评注同tree一次原子导入。

导出打开时捕获tree+metadata，五格式：当前FEN、FEN+UCI、中文路径、PGN ICCS/中文；格式选择适应200%字号。PGN派生Game/FEN/Format按当前根/选择格式生成，结果按记录保留；默认含所选路径评注，花括号无损失败要显示错误并禁复制，可由用户显式取消评注。仅根到游标，分支与未来不导出；非PGN不保留资料/注释，损失说明清楚。复制异步保持所选值，失败可手动选择文字。

验收：实际Isolate数据传输/错误/旧格式兼容，PGN资料注释合法性与完整路径、unsupported拒绝不改对局，dirty取消/保存/异步旧epoch/用户取消/剪贴板晚到，快照稳定/导出重算派生字段/评注选择/200%字号；根test+analyze、相关macOS旧文字回归与新PGN保存/复制/恢复通过，独立中文feat(notation)提交。核心本片不变则沿用65与analyze，不空跑无关引擎全套。
