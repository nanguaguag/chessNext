import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/board_session.dart';
import '../../application/metadata_editor.dart';

const _fields = {
  'Event': '赛事',
  'Site': '地点',
  'Date': '日期',
  'Round': '轮次',
  'Red': '红方',
  'Black': '黑方',
};
const _results = {'*': '未定', '1-0': '红方胜', '0-1': '黑方胜', '1/2-1/2': '和棋'};

class RecordMetadataDialog extends StatefulWidget {
  const RecordMetadataDialog({super.key, required this.session});
  final BoardSession session;
  @override
  State<RecordMetadataDialog> createState() => _RecordMetadataDialogState();
}

class _RecordMetadataDialogState extends State<RecordMetadataDialog> {
  late final editor = MetadataEditor(widget.session);
  late final controllers = {
    for (final key in _fields.keys)
      key: TextEditingController(text: editor.original.tags[key] ?? ''),
  };
  late String result = editor.original.result;
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _apply() {
    final updates = <String, String?>{};
    for (final entry in controllers.entries) {
      if (entry.value.text != (editor.original.tags[entry.key] ?? '')) {
        updates[entry.key] = entry.value.text.isEmpty ? null : entry.value.text;
      }
    }
    if (result != editor.original.result) updates['Result'] = result;
    if (editor.apply(updates)) {
      Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final extras = editor.original.tags.entries
        .where((e) => !_fields.containsKey(e.key) && e.key != 'Result')
        .toList();
    return AlertDialog(
      scrollable: true,
      title: const Text('棋谱资料'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('资料改动会标记为未保存，请保存棋谱以保留。记录结果不会强制结束棋局。'),
            for (final entry in _fields.entries)
              TextField(
                key: ValueKey('metadata-${entry.key}'),
                controller: controllers[entry.key],
                maxLength: 4096,
                decoration: InputDecoration(
                  labelText: entry.value,
                  hintText: entry.key == 'Date' ? '例如2026.11.02' : null,
                ),
              ),
            DropdownButtonFormField<String>(
              key: const ValueKey('metadata-Result'),
              initialValue: result,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '记录结果'),
              items: _results.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => result = value);
              },
            ),
            if (extras.isNotEmpty)
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('其它资料（保留）'),
                    content: SizedBox(
                      width: 480,
                      height: math.min(
                        400,
                        MediaQuery.sizeOf(context).height * .45,
                      ),
                      child: ListView.builder(
                        itemCount: extras.length,
                        itemBuilder: (context, index) {
                          final entry = extras[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                SelectableText(entry.value),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                ),
                child: Text('查看其它资料（${extras.length}项）'),
              ),
            if (editor.error != null)
              Text(
                editor.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _apply, child: const Text('应用资料')),
      ],
    );
  }
}
