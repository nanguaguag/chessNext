import 'package:flutter/material.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/record_text_exchange.dart';
import '../../ports/text_clipboard.dart';

class ImportTextDialog extends StatefulWidget {
  const ImportTextDialog({
    super.key,
    required this.clipboard,
    this.importer = RecordTextExchange.parseInWorker,
  });
  final TextClipboard clipboard;
  final TextImporter importer;
  @override
  State<ImportTextDialog> createState() => _ImportTextDialogState();
}

class _ImportTextDialogState extends State<ImportTextDialog> {
  final text = TextEditingController();
  String? error;
  bool busy = false, parsing = false;
  bool dismissed = false;
  int generation = 0;
  bool get alive => mounted && !dismissed;
  bool get active => alive && ModalRoute.of(context)?.isCurrent == true;
  void _dismiss() {
    dismissed = true;
    generation++;
  }

  void _cancel() {
    _dismiss();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _dismiss();
    text.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final input = text.text;
    final job = ++generation;
    setState(() {
      busy = true;
      parsing = true;
      error = null;
    });
    try {
      final imported = await widget.importer(input);
      if (mounted && active && job == generation) {
        Navigator.pop(context, imported);
      }
    } on FormatException catch (e) {
      if (active && job == generation) setState(() => error = e.message);
    } catch (_) {
      if (active && job == generation) {
        setState(() => error = '棋谱解析失败，请重试；当前棋谱未被替换。');
      }
    } finally {
      if (alive && job == generation) {
        setState(() {
          busy = false;
          parsing = false;
        });
      }
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
      if (!active) return;
      if (value == null || value.trim().isEmpty) {
        setState(() => error = '剪贴板中没有文字');
      } else if (value.length > TextRecord.maxLength) {
        setState(() => error = '剪贴板文字超过64000字符限制');
      } else if (text.text == before) {
        text.text = value;
      }
    } catch (_) {
      if (active) setState(() => error = '无法读取剪贴板，请手动粘贴');
    } finally {
      if (alive) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<ImportedRecord>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _dismiss();
    },
    child: AlertDialog(
      title: const Text('导入文字棋谱'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '支持FEN、UCI/ICCS坐标、中文着法，以及单局PGN（ICCS或中文，保留资料与评注）。自定义普通文字用FEN + moves + 着法。暂不支持PGN括号变着、WXF或多局。',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                enabled: !parsing,
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
              if (parsing) ...[
                const LinearProgressIndicator(),
                const Text('正在解析棋谱…'),
              ],
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
        TextButton(onPressed: _cancel, child: const Text('取消')),
        FilledButton(
          onPressed: busy || text.text.trim().isEmpty ? null : _import,
          child: const Text('导入'),
        ),
      ],
    ),
  );
}

const _formats = {
  TextExportFormat.fen: '当前局面FEN',
  TextExportFormat.uci: 'FEN + 着法',
  TextExportFormat.chinese: '中文棋谱',
  TextExportFormat.pgnIccs: 'PGN（ICCS）',
  TextExportFormat.pgnChinese: 'PGN（中文）',
};

class ExportTextDialog extends StatefulWidget {
  const ExportTextDialog({
    super.key,
    required this.tree,
    required this.clipboard,
    this.metadata = GameMetadata.empty,
  });
  final GameTree tree;
  final GameMetadata metadata;
  final TextClipboard clipboard;
  @override
  State<ExportTextDialog> createState() => _ExportTextDialogState();
}

class _ExportTextDialogState extends State<ExportTextDialog> {
  TextExportFormat format = TextExportFormat.fen;
  bool busy = false, includeComments = true;
  String? status;
  ({String? text, String? error}) get rendering {
    try {
      return (
        text: RecordTextExchange.exportText(
          widget.tree,
          widget.metadata,
          format,
          includeComments: includeComments,
        ),
        error: null,
      );
    } on FormatException catch (e) {
      return (text: null, error: e.message);
    } on ArgumentError catch (e) {
      return (text: null, error: e.message?.toString() ?? '无法生成此格式');
    }
  }

  Future<void> _copy() async {
    final copy = rendering.text;
    if (copy == null) return;
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
  Widget build(BuildContext context) {
    final rendered = rendering;
    return AlertDialog(
      title: const Text('导出文字'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('导出打开窗口时的棋谱快照。'),
              DropdownButtonFormField<TextExportFormat>(
                key: const ValueKey('export-format'),
                initialValue: format,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '导出格式'),
                items: _formats.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            format = value;
                            status = null;
                          });
                        }
                      },
              ),
              if (format.isPgn)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('包含路径评注'),
                  value: includeComments,
                  onChanged: busy
                      ? null
                      : (value) => setState(() {
                          includeComments = value ?? false;
                          status = null;
                        }),
                ),
              const SizedBox(height: 16),
              if (rendered.text != null)
                SelectableText(
                  rendered.text!,
                  key: const ValueKey('export-text'),
                ),
              if (rendered.error != null)
                Text(
                  rendered.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              Text(
                format.isPgn
                    ? 'PGN保留棋谱资料与所选评注，仅含初始局面至当前着。其它分支及后续着法不会导出；完整棋树请保存到本地库。'
                    : 'FEN只含当前局面；其它普通文字格式只含初始局面至当前着。分支、后续、评注和资料不在这些格式内，完整内容请保存到本地库。',
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
        FilledButton(
          onPressed: busy || rendered.text == null ? null : _copy,
          child: const Text('复制'),
        ),
      ],
    );
  }
}
