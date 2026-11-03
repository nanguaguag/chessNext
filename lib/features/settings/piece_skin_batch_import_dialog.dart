import 'package:flutter/material.dart';

import '../../application/piece_image_library_controller.dart';
import '../../ports/piece_images.dart';

class PieceSkinBatchImportDialog extends StatefulWidget {
  const PieceSkinBatchImportDialog({
    super.key,
    required this.skin,
    required this.images,
    required this.library,
  });

  final PieceSkin skin;
  final List<NamedPieceImage> images;
  final PieceImageLibraryController library;

  @override
  State<PieceSkinBatchImportDialog> createState() =>
      _PieceSkinBatchImportDialogState();
}

class _PieceSkinBatchImportDialogState
    extends State<PieceSkinBatchImportDialog> {
  late final List<PieceImageSlot?> slots = [
    for (final file in widget.images) _suggestSlot(file.name),
  ];

  PieceImageSlot? _suggestSlot(String name) {
    final base = name.split('/').last.split('\\').last.split('.').first;
    final normalized = base.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    for (final slot in PieceImageSlot.values) {
      if (normalized == slot.name.toLowerCase() ||
          normalized == slot.label.toLowerCase()) {
        return slot;
      }
    }
    return null;
  }

  bool get _validMapping {
    if (slots.any((slot) => slot == null)) return false;
    return slots.toSet().length == slots.length;
  }

  Future<void> _import() async {
    if (!_validMapping || widget.library.batchBusy) return;
    final mapping = <PieceImageSlot, SelectedPieceImage>{
      for (var i = 0; i < slots.length; i++) slots[i]!: widget.images[i].image,
    };
    final imported = await widget.library.importBatch(widget.skin, mapping);
    if (!mounted || imported == 0) return;
    if (imported == mapping.length) {
      Navigator.pop(context, imported);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.library,
    builder: (context, _) => AlertDialog(
      title: const Text('批量导入棋子图片'),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已选${widget.images.length}张。为每张图片选择目标棋子；未映射或重复槽位不能导入。'),
            const SizedBox(height: 8),
            if (widget.library.batchBusy) const LinearProgressIndicator(),
            if (widget.library.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.library.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final file = widget.images[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Image.memory(
                              file.image.bytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<PieceImageSlot?>(
                              key: ValueKey('batch-piece-slot-$index'),
                              initialValue: slots[index],
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: file.name,
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<PieceImageSlot?>(
                                  value: null,
                                  child: Text('请选择目标棋子'),
                                ),
                                for (final slot in PieceImageSlot.values)
                                  DropdownMenuItem<PieceImageSlot?>(
                                    value: slot,
                                    child: Text(slot.label),
                                  ),
                              ],
                              onChanged: widget.library.batchBusy
                                  ? null
                                  : (slot) =>
                                        setState(() => slots[index] = slot),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.library.batchBusy
              ? null
              : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          key: const ValueKey('apply-piece-image-batch'),
          onPressed: _validMapping && !widget.library.batchBusy
              ? _import
              : null,
          icon: const Icon(Icons.file_download_done),
          label: const Text('导入图片'),
        ),
      ],
    ),
  );
}
