# ADR-038：主盘双方向会话视图与预览快照

2026-11-02，E33。左右翻转是可验证的显示变换：主谱/PGN字节不变、视觉棋子/坐标/末步/徽标左右交换。PV小盘跟随主盘旋转和镜像。新局/重启/活动AI原站行为未知，项目用自身验收明确边界。

BoardSession.mirrored与flipped正交，仅会话视图；mirror通知不改GameTree、元资料、epoch/内容或局面revision、dirty、选子或引擎请求。与既有flip一致，新局/替换谱保留会话方向，退出不持久化（P）。主盘按钮48dp、toggled语义与只改显示Tooltip；正常按钮焦点导航，棋盘State/FocusNode保持。Editor镜像仍是独立编辑草稿操作，不继承主盘视图。

XiangqiBoard透传到BoardSurface既有mirrored映射，90格位置/键盘左右、数字坐标、全部只读箭层、末步和评级角徽共享逻辑坐标。不变换领域Square/Move，不从显示FEN重建谱。WDL局势条只受上下旋转，左右镜像不改变上下执方。

历史打开前捕获mirrored，与既有side取自session.flipped相同；PvHistoryDialog→PvPreviewDialog→只读BoardSurface透传。打开后方向与历史来源一起冻结，后续主盘视图变化不追随，重开取新值（P）；源Position/评分/worker重放与前缀来源保护不变。

组件验证四组合/实际像素点点击、键盘、200%文字/10与200%棋子、静态层、Editor初始90格不变、会话边界；应用验证normal分析token与AI思考中镜像仍落逻辑着。native验证实际NNUE计算不中断及真实worker预览组合方向。F12整条所选线路PGN未来导出差距另B19，不纳入本片。
