import 'package:flutter/material.dart';

import '../../application/board_skin_image_library_controller.dart';
import '../../ports/board_skin_images.dart';

class BoardSkinImagesDialog extends StatelessWidget {
  const BoardSkinImagesDialog({
    super.key,
    required this.skinId,
    required this.skinLabel,
    required this.library,
  });

  final String skinId;
  final String skinLabel;
  final BoardSkinImageLibraryController library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => AlertDialog(
      title: Text('编辑$skinLabel棋盘图片'),
      content: SizedBox(
        width: 520,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('仅保存在本机；支持 PNG/JPEG，单张不超过512 KiB。'),
              for (final slot in BoardSkinImageSlot.values)
                _slot(context, slot),
              if (library.error != null && library.errorSlot == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    library.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: library.busySlot == null
              ? () => Navigator.pop(context)
              : null,
          child: const Text('关闭'),
        ),
      ],
    ),
  );

  Widget _slot(BuildContext context, BoardSkinImageSlot slot) {
    final image = library.imageFor(skinId, slot);
    final busy = library.busySlot == slot;
    final error = library.errorSlot == slot ? library.error : null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: slot == BoardSkinImageSlot.boardBackground ? 140 : 72,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: image == null
                      ? Center(
                          child: Text(
                            slot == BoardSkinImageSlot.boardBackground
                                ? '使用棋盘配色默认背景'
                                : '使用默认${slot.label}',
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(image, fit: BoxFit.contain),
                        ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed:
                        library.loading || busy || library.busySlot != null
                        ? null
                        : () => library.replace(skinId, slot),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image_outlined),
                    label: Text(image == null ? '选择图片' : '替换图片'),
                  ),
                  TextButton(
                    onPressed:
                        library.loading ||
                            busy ||
                            image == null ||
                            library.busySlot != null
                        ? null
                        : () => library.reset(skinId, slot),
                    child: const Text('恢复默认'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
