# ADR-025：棋子尺寸仅缩放面容

2026-11-02；当前Flutter/macOS。E23有实际10–200%、步5、重叠及裁切证据。

沿BoardDisplayScope/可选schema1扩展pieceSizePercent（默认100，10–200且5倍数），字段合并/串行写与其它显示选项互不覆盖。即时滑块和重置只改此字段，不影响棋谱dirty、引擎请求或棋盘格距。

BoardSurface只有实际棋子的face使用Transform.scale，transformHitTests=false；90格InkWell/语义/目标提示/坐标/箭头几何保持，Draggable反馈复用face。200%允许视觉重叠并由内部Stack裁切，点击仍按逻辑交点；空位和边框不缩放，不让超大画面截获邻格。这个命中契约为项目P，未推断源站点击实现。

范围在AppPreferences验证，Widget显式override也断言；旧无字段仍100，坏存储值沿备份保护。其它外观/字体/资源和真实五平台视觉不由本片宣称完成。
