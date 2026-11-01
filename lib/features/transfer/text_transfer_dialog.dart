import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../ports/text_clipboard.dart';

class ImportTextDialog extends StatefulWidget {
  const ImportTextDialog({super.key, required this.clipboard});
  final TextClipboard clipboard;
  @override
  State<ImportTextDialog> createState() => _ImportTextDialogState();
}

class _ImportTextDialogState extends State<ImportTextDialog> {
  final text = TextEditingController();
  String? error;
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void _import() {
    try {
      Navigator.pop(context, TextRecord.parse(text.text));
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> _paste() async {
    setState(() {
      busy = true;
      error = null;
    });
    final before = text.text;
    try {
      final value = await widget.clipboard.read();
      if (!mounted) return;
      if (value == null || value.trim().isEmpty) {
        setState(() => error = '剪贴板中没有文字');
      } else if (value.length > TextRecord.maxLength) {
        setState(() => error = '剪贴板文字超过64000字符限制');
      } else if (text.text == before) {
        text.text = value;
      }
    } catch (_) {
      if (mounted) setState(() => error = '无法读取剪贴板，请手动粘贴');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('导入文字棋谱'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支持FEN、UCI/ICCS坐标及中文着法（如1. 炮二平五 马２进３）。自定义初始局面用FEN + moves + 着法。导入后建立新棋谱。',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: text,
              key: const ValueKey('import-text'),
              autofocus: true,
              minLines: 5,
              maxLines: 10,
              maxLength: TextRecord.maxLength,
              decoration: const InputDecoration(
                labelText: '局面与着法',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => error = null),
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: busy ? null : _paste, child: const Text('读取剪贴板')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: text.text.trim().isEmpty ? null : _import,
        child: const Text('导入'),
      ),
    ],
  );
}

class ExportTextDialog extends StatefulWidget {
  const ExportTextDialog({
    super.key,
    required this.tree,
    required this.clipboard,
  });
  final GameTree tree;
  final TextClipboard clipboard;
  @override
  State<ExportTextDialog> createState() => _ExportTextDialogState();
}

class _ExportTextDialogState extends State<ExportTextDialog> {
  String format = 'fen';
  bool busy = false;
  String? status;
  String get value => format == 'fen'
      ? widget.tree.current.position.toFen()
      : TextRecord.path(widget.tree, chinese: format == 'chinese');
  Future<void> _copy() async {
    final copy = value;
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await widget.clipboard.write(copy);
      if (mounted) setState(() => status = '已复制');
    } catch (_) {
      if (mounted) setState(() => status = '复制失败，请选中文字手动复制');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('导出文字'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fen', label: Text('当前局面FEN')),
                ButtonSegment(value: 'uci', label: Text('FEN + 着法')),
                ButtonSegment(value: 'chinese', label: Text('中文棋谱')),
              ],
              selected: {format},
              onSelectionChanged: (values) => setState(() {
                format = values.single;
                status = null;
              }),
            ),
            const SizedBox(height: 16),
            SelectableText(value, key: const ValueKey('export-text')),
            const SizedBox(height: 16),
            const Text(
              'FEN只包含当前局面；FEN + 着法只包含初始局面至当前着的路径。分支、后续着法和注释不在此格式内，请保存到本地库以保留完整棋谱。',
            ),
            if (status != null) Text(status!),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
      FilledButton(onPressed: busy ? null : _copy, child: const Text('复制')),
    ],
  );
}
