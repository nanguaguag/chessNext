# M3-29 / F02,F13 / B08,B17,B22：所选PV前缀原子应用（P）

E31证实2/N只应用两步、原其它变化保留、已有可见前缀重复应用不复制，返回主棋盘。AI/分析活动下行为及不同新分支未在原站实测。项目先显式暂停所有计算，再应用；跨局面历史下片，不偷偷改ADR-031历史。

打开预览时创建新鲜应用快照：entry来源epoch/node/FEN须匹配当前；捕获当前完整tree对象/epoch/内容与位置revision。允许同来源旧历史在重开时绑定新快照（如已有后续/改评注），但打开后任何位置/内容/换谱变化均使操作过期，翻转与显示不失效。UI传应用动作与源状态Listenable，不传IO；Worker仅捕获纯GameTree/复制前缀，不捕获Controller/Widget/action闭包。

动作校验1..已保留PV步数/128、cancel，调用现有disable/stop屏障，检查generation/stop失败/源快照，后台构建整个续谱（保留注释、分支、稳定ID/主线顺序，最多现schema2000节点），再次验证cancel+源+generation，一次提交。Session只发布准备结果，epoch/metadata/库绑定不变；新节点内容revision+1，选已有路径只位置revision+1，单次notify/无中间草稿。非法后缀/容量/取消/过期/stop失败均不部分修改。2000是既有序列化边界，普通手工走棋同门槛另记录差距。

预览提供0禁用的“走到棋盘上”，说明暂停计算/仅所选前缀；busy禁重复并停播放，Close仍可取消尚未提交操作；来源变化即时禁用并提示。成功按类型化结果关闭预览及原历史route，防迟到误关新route。失败保留预览及可解释错误；原子提交已发生后Close不撤销已提交结果。

验收：多步只通知一次/保留原未来与评注/ID/dirty/已有复用，非法尾与2000边界，真实worker；控制器停止迟到/换文档复用ID/内容或游标变化/新engine intent/取消/stop失败；组件成功路由/0/源失效/忙态关闭迟到/200%与键盘；根真实NNUEflutter test+analyze、macOS真实NNUE+worker应用/保存恢复后独立中文commit。来源不同旧历史、跨文档/平台和OS人工仍另验。
