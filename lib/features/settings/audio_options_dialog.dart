import 'package:flutter/material.dart';

import '../../application/audio_library_controller.dart';
import '../../ports/audio_feedback.dart';
import '../../ports/audio_library.dart';

class AudioOptionsDialog extends StatelessWidget {
  const AudioOptionsDialog({
    super.key,
    required this.kind,
    required this.title,
    required this.library,
  });

  final AudioFeedbackKind kind;
  final String title;
  final AudioLibraryController library;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final busy = library.busyKind == kind;
      return AlertDialog(
        title: Text('$title音效'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  library.hasCustom(kind)
                      ? '当前：自定义音效'
                      : kind == AudioFeedbackKind.move
                      ? '当前：${library.moveChoice.label}'
                      : '当前：默认音效',
                ),
                const SizedBox(height: 8),
                Text('只替换$title音效。文件仅保存在本机，不上传。'),
                const SizedBox(height: 4),
                const Text('支持 WAV / MP3，最多512 KiB、5秒。'),
                if (kind == AudioFeedbackKind.move) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MoveSoundChoice>(
                    key: ValueKey(
                      'move-sound-choice-${library.moveChoice.name}',
                    ),
                    initialValue: library.moveChoice,
                    decoration: const InputDecoration(labelText: '音效方案'),
                    items: MoveSoundChoice.values
                        .map(
                          (choice) => DropdownMenuItem(
                            value: choice,
                            child: Text(
                              choice == MoveSoundChoice.followPieceSkin
                                  ? '随棋子皮肤（当前仅默认外观）'
                                  : choice.label,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: busy || library.hasCustom(kind)
                        ? null
                        : (choice) {
                            if (choice != null) {
                              library.selectMoveSoundChoice(choice);
                            }
                          },
                  ),
                  if (library.hasCustom(kind)) const Text('恢复默认音效后可选择内置方案。'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MoveSoundChoice.values
                        .map(
                          (choice) => OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => library.previewMoveSound(choice),
                            icon: const Icon(Icons.play_arrow),
                            label: Text('试听${choice.label}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (library.errorKind == kind && library.error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      library.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: busy ? null : () => library.preview(kind),
            icon: const Icon(Icons.play_arrow),
            label: const Text('试听当前音效'),
          ),
          TextButton.icon(
            onPressed: busy ? null : () => library.importCustom(kind),
            icon: const Icon(Icons.file_open),
            label: const Text('导入自定义音效'),
          ),
          if (library.hasCustom(kind))
            TextButton(
              onPressed: busy ? null : () => library.reset(kind),
              child: const Text('恢复默认音效'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    },
  );
}
