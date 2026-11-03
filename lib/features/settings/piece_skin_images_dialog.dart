import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../application/piece_image_library_controller.dart';
import '../../ports/piece_images.dart';
import 'piece_skin_batch_import_dialog.dart';

class PieceSkinImagesDialog extends StatelessWidget {
  const PieceSkinImagesDialog({
    super.key,
    required this.skin,
    required this.library,
  });

  final PieceSkin skin;
  final PieceImageLibraryController library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => AlertDialog(
      title: Text('编辑${skin == PieceSkin.roundSeal ? '传统圆章' : '方章墨韵'}图片'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          children: [
            const Text('仅替换选中的棋子，PNG/JPEG、512 KiB以内、最长边1024像素；文件保存在本机。'),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('batch-import-piece-images'),
                onPressed:
                    library.loading ||
                        library.busySlot != null ||
                        library.batchBusy
                    ? null
                    : () async {
                        final images = await library.pickBatchImages();
                        if (!context.mounted || images == null) return;
                        final imported = await showDialog<int>(
                          context: context,
                          builder: (_) => PieceSkinBatchImportDialog(
                            skin: skin,
                            images: images,
                            library: library,
                          ),
                        );
                        if (imported != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已导入$imported张棋子图片。')),
                          );
                        }
                      },
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('批量导入图片'),
              ),
            ),
            if (library.loading) const LinearProgressIndicator(),
            if (library.batchBusy) const LinearProgressIndicator(),
            if (library.error != null && library.errorSlot == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  library.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: PieceImageSlot.values.length,
                itemBuilder: (context, index) {
                  final slot = PieceImageSlot.values[index];
                  final bytes = library.imageFor(skin, slot);
                  final busy = library.busySlot == slot;
                  return _PieceImageRow(
                    slot: slot,
                    image: bytes,
                    busy: busy,
                    error: library.errorSlot == slot ? library.error : null,
                    canEdit:
                        !library.loading &&
                        library.busySlot == null &&
                        !library.batchBusy,
                    onReplace: () => library.replace(skin, slot),
                    onReset: bytes == null
                        ? null
                        : () => library.reset(skin, slot),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: library.busySlot == null && !library.batchBusy
              ? () => Navigator.pop(context)
              : null,
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

class _PieceImageRow extends StatelessWidget {
  const _PieceImageRow({
    required this.slot,
    required this.image,
    required this.busy,
    required this.error,
    required this.canEdit,
    required this.onReplace,
    required this.onReset,
  });

  final PieceImageSlot slot;
  final Uint8List? image;
  final bool busy;
  final String? error;
  final bool canEdit;
  final VoidCallback onReplace;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: image == null
                    ? Center(
                        child: Text(
                          slot.label.substring(1),
                          style: TextStyle(
                            fontSize: 30,
                            color: slot.name.startsWith('red')
                                ? const Color(0xffa12f29)
                                : const Color(0xff26362d),
                          ),
                        ),
                      )
                    : Image.memory(image!, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(slot.label)),
              TextButton.icon(
                key: ValueKey('replace-piece-image-${slot.name}'),
                onPressed: canEdit ? onReplace : null,
                icon: const Icon(Icons.image_outlined),
                label: const Text('替换'),
              ),
              TextButton(
                key: ValueKey('reset-piece-image-${slot.name}'),
                onPressed: canEdit ? onReset : null,
                child: const Text('恢复默认'),
              ),
            ],
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
