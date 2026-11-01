import 'package:flutter/material.dart';
import '../../application/record_text_exchange.dart';
import '../../ports/record_file_picker.dart';

class ImportFileDialog extends StatefulWidget {
  const ImportFileDialog({
    super.key,
    required this.picker,
    this.importer = RecordTextExchange.parseInWorker,
  });
  final RecordFilePicker picker;
  final TextImporter importer;
  @override
  State<ImportFileDialog> createState() => _ImportFileDialogState();
}

class _ImportFileDialogState extends State<ImportFileDialog> {
  ImportedRecord? record;
  String? name, error;
  bool busy = false, dismissed = false;
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
    super.dispose();
  }

  Future<void> _choose() async {
    final job = ++generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = await widget.picker.openText();
      if (!active || job != generation || file == null) return;
      setState(() {
        record = null;
        name = file.displayName;
      });
      final parsed = await widget.importer(file.text);
      if (active && job == generation) setState(() => record = parsed);
    } on RecordFileException catch (e) {
      if (active && job == generation) {
        setState(() {
          record = null;
          name = null;
          error = e.message;
        });
      }
    } on FormatException catch (e) {
      if (active && job == generation) setState(() => error = e.message);
    } catch (_) {
      if (active && job == generation) {
        setState(() {
          record = null;
          error = '文件导入失败，请重试；当前棋谱未被替换。';
        });
      }
    } finally {
      if (alive && job == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<ImportedRecord>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _dismiss();
    },
    child: AlertDialog(
      title: const Text('导入棋谱文件'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择单个UTF8文字文件（.pgn、.fen、.txt），最多256000字节及64000字符。支持单局PGN（ICCS或中文）、FEN与已有文字格式。暂不支持GBK、二进制棋谱、PGN括号变着或多局。源文件保持原样。',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: busy ? null : _choose,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择文件'),
              ),
              if (busy) ...[
                const LinearProgressIndicator(),
                const Text('正在选择、读取或解析文件…'),
              ],
              if (name != null) Text(name!),
              if (record != null)
                Text(
                  '${record!.source == TextSourceFormat.pgn ? 'PGN' : '文字棋谱'} · ${record!.tree.nodeCount - 1}着。确认后替换当前棋谱及资料。',
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
        TextButton(onPressed: _cancel, child: const Text('取消')),
        FilledButton(
          onPressed: busy || record == null
              ? null
              : () => Navigator.pop(context, record),
          child: const Text('导入'),
        ),
      ],
    ),
  );
}
