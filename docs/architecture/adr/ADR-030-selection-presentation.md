# ADR-030：选子样式只改变面容，不改变命中

2026-11-02，E29实测抬起/选择框、再次点子取消与页间记忆。

SelectionStyle lift/frame可选稳定偏好，旧默认lift；严格解析与Controller逐字段合并/串行持久化/重试。BoardDisplayScope在Navigator外注入，BoardSurface可显式override，主棋盘及编辑器共享；具体selected仍由原会话/编辑草稿负责，显示层不造落子命令。

lift仅已选且非空piece面容向上格距8%并加阴影，Transform.translate在pieceSize缩放外且transformHitTests=false；frame为固定交点的绿色四角双描边，独立IgnorePointer画层，不随pieceSize伸缩。原90格、合法目标/焦点/selected语义与拖放命中保持；空位不画棋子框/不抬起，拖动反馈不带选子状态。无新增动画/ticker。

具体位移/阴影与编辑器共用为项目P，不声称原站精确算法。只修改独立偏好，不修改文档/修订或引擎任务；系统选择状态、真实OS及其它平台人工验证后续。F21素材仍缺。
