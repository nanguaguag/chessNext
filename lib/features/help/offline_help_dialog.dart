import 'dart:math' as math;
import 'package:flutter/material.dart';

enum HelpAction { guide }

class _HelpEntry {
  const _HelpEntry(this.id, this.icon, this.title, this.body);
  final String id, title, body;
  final IconData icon;
}

// Original help for the actual offline app; no engine, network or storage calls.
const _entries = [
  _HelpEntry(
    'board',
    Icons.grid_on,
    '走棋与读谱',
    '先选己方棋子，再点目标交点。棋盘会标出可走位置；自将、将帅照面等非法着法不会提交。将死或困毙时，对方获胜。\n'
        '着法列表可跳到过去或未来，同级变着可切换、提升主线或确认删除。前后按钮沿所选线路读谱，首尾按钮回到开始或所选线路末尾；双箭头先跳到前后最近分支点，没有其它分支则到首尾。翻转只改变观看方向。',
  ),
  _HelpEntry(
    'analysis',
    Icons.manage_search,
    '当前局面分析与胜和负',
    '在本地分析面板开始或停止 Pikafish。读谱时分析跟随当前局面；资源参数可调整线程、内存和多路变化。\n'
        '评分标明红黑视角，杀棋与上下界单独显示。胜、和、负来自引擎模型，预期得分按和棋半分计算；缺失统计不会补成零。模型估计不是实际胜负保证。\n'
        'PV历史保留当前局面的采样，停止后仍可查看，换局面清空。点击预览可逐步或用方向键查看小棋盘，播放后可随时暂停，关闭或应用失活会停止播放。预览不写入棋谱；每条最多保留128步，非法路径会整体拒绝。',
  ),
  _HelpEntry(
    'play',
    Icons.smart_toy_outlined,
    '与 AI 对弈',
    '选择引擎执红、执黑或双方，并设置每步思考用时。轮到 AI 时等待它落子；立即出招可结束本轮思考并采用当前最佳着法。\n'
        '变招会排除本次首选，尝试另一合法着法。对弈悔棋与普通读谱分开；读谱跳转会暂停自动对弈，恢复执方需主动选择。',
  ),
  _HelpEntry(
    'review',
    Icons.insights,
    '整谱复盘与模型评级',
    '分析整盘棋可选择当前线路或整棵棋树，按每局面或每候选的有限预算计算，取消后保留已完成结果。跳过已有只复用计算条件一致的缓存。\n'
        '曲线可点击或用方向键导航。着法评级报告展示预期得分损失，可筛选红黑方和问题着法；没有可靠数据的着法保持未评级，不当作正确或满分。报告是打开时的快照。',
  ),
  _HelpEntry(
    'candidate',
    Icons.alt_route,
    '单步候选与试走',
    '普通着法的单步候选分析针对它的父局面，根节点则分析下一着。不同候选逐个计算，预算按每个候选计。\n'
        '计算完成不会自动改谱。点击试走才创建或切换同级变着，原来的线路和注释保留；分析后若棋谱或读谱位置改变，需重新计算。',
  ),
  _HelpEntry(
    'editor',
    Icons.edit_outlined,
    '自由编辑局面',
    '编辑在独立草稿中进行，可从棋子盒放子、选择红黑先、清空或恢复初始局面，并作镜像、旋转或红黑互换。拖出棋盘或右键可移除棋子。\n'
        '完成前会检查可开局条件；无效局面保留在编辑器供修改。取消返回原对局，完成并确认替换后才开始新的局面分析。',
  ),
  _HelpEntry(
    'transfer',
    Icons.import_export,
    '文字导入与导出',
    '可粘贴 FEN、UCI、ICCS 或中文着法。先完整校验，再确认是否替换当前修改；解析失败不会覆盖棋谱。\n'
        '导出文字包含根局面到当前游标的路径，不包含全部分支、未来着法或注释。需要保留完整棋树时使用本地棋谱保存。剪贴板复制成功后才提示完成。',
  ),
  _HelpEntry(
    'library',
    Icons.history,
    '保存、草稿与最近阅读',
    '棋谱资料可填写赛事、棋手与记录结果；填写结果不会强行结束棋局。保存棋谱会将完整棋树、注释和资料写入本地棋谱库，下次可按名称搜索打开。新局或替换文档前会保护未保存的修改。\n'
        '自动草稿独立保存，恢复时成为未保存副本，不覆盖已保存棋谱。最近阅读最多记录50份已保存谱的位置；恢复会核对局面和着法路径。未保存的新分支仍需从草稿恢复。',
  ),
  _HelpEntry(
    'keyboard',
    Icons.keyboard_outlined,
    '键盘与显示设置',
    '棋盘获得焦点后，用方向键移动交点，Enter 或空格选子与落子，Escape 取消选择。评分曲线获得焦点后可用左右方向键、Home 和 End 读谱。\n'
        '应用设置可选择跟随系统、浅色或深色主题；引擎资源和 AI 用时会保存在本机。文字大小跟随系统。帮助窗口可搜索、展开主题和选择文字，Escape 或关闭按钮可返回。',
  ),
];

class OfflineHelpDialog extends StatefulWidget {
  const OfflineHelpDialog({super.key});
  @override
  State<OfflineHelpDialog> createState() => _OfflineHelpDialogState();
}

class _OfflineHelpDialogState extends State<OfflineHelpDialog> {
  final search = TextEditingController();
  String query = '';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = query.trim().toLowerCase();
    final matches = _entries
        .where((e) => '${e.title}\n${e.body}'.toLowerCase().contains(needle))
        .toList();
    return AlertDialog(
      title: const Text('离线使用帮助'),
      content: SizedBox(
        width: 560,
        height: math.min(520, MediaQuery.sizeOf(context).height * .6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('help-search'),
              controller: search,
              decoration: InputDecoration(
                labelText: '搜索功能或操作',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空帮助搜索',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          search.clear();
                          setState(() => query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 8),
            Semantics(liveRegion: true, child: Text('${matches.length} 个主题')),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('未找到匹配的帮助，请换个关键词。'))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final entry = matches[index];
                        return ExpansionTile(
                          key: ValueKey(
                            'help-${entry.id}-${needle.isNotEmpty}',
                          ),
                          leading: Icon(entry.icon),
                          title: Text(entry.title),
                          initiallyExpanded: needle.isNotEmpty,
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [SelectableText(entry.body)],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, HelpAction.guide),
          child: const Text('新手引导'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
