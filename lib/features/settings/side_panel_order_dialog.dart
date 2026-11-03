import 'package:flutter/material.dart';
import '../../application/app_preferences.dart';
import '../../application/preferences_controller.dart';

class SidePanelOrderDialog extends StatefulWidget {
  const SidePanelOrderDialog({super.key, required this.preferences});
  final PreferencesController preferences;

  @override
  State<SidePanelOrderDialog> createState() => _SidePanelOrderDialogState();
}

class _SidePanelOrderDialogState extends State<SidePanelOrderDialog> {
  late List<SidePanel> order;

  @override
  void initState() {
    super.initState();
    order = [...widget.preferences.value.sidePanelOrder];
  }

  String label(SidePanel panel) => switch (panel) {
    SidePanel.play => '对弈',
    SidePanel.analysis => '引擎分析',
    SidePanel.review => '棋谱复盘',
    SidePanel.candidates => '候选着法',
  };

  Future<void> reorder(int oldIndex, int newIndex) async {
    setState(() {
      final item = order.removeAt(oldIndex);
      order.insert(newIndex, item);
    });
    await widget.preferences.setSidePanelOrder(order);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.preferences,
    builder: (context, _) => AlertDialog(
      title: const Text('侧栏面板'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('拖动调整顺序，开关控制主界面侧栏显示；设置保存在本机。'),
            const SizedBox(height: 12),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: order.length,
                onReorderItem: reorder,
                itemBuilder: (context, index) {
                  final panel = order[index];
                  return ListTile(
                    key: ValueKey(panel),
                    title: Text(label(panel)),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    trailing: Switch(
                      value: widget.preferences.value.visibleSidePanels
                          .contains(panel),
                      onChanged: (visible) => widget.preferences
                          .setSidePanelVisibility(panel, visible),
                    ),
                  );
                },
              ),
            ),
            if (widget.preferences.error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
