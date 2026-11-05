import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../application/audio_library_controller.dart';
import '../../application/board_appearance.dart';
import '../../ports/audio_feedback.dart';
import '../../ports/audio_library.dart';

class AudioOptionsDialog extends StatelessWidget {
  const AudioOptionsDialog({
    super.key,
    required this.kind,
    required this.title,
    required this.library,
    this.pieceSkin = PieceSkin.roundSeal,
  });

  final AudioFeedbackKind kind;
  final String title;
  final AudioLibraryController library;
  final PieceSkin pieceSkin;

  String _choiceLabel(AppLocalizations l10n, MoveSoundChoice choice) =>
      switch (choice) {
        MoveSoundChoice.sound1 => l10n.audioSoundChoice1,
        MoveSoundChoice.sound2 => l10n.audioSoundChoice2,
        MoveSoundChoice.followPieceSkin => l10n.audioFollowSkin,
      };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final busy = library.busyKind == kind;
      return AlertDialog(
        title: Text(l10n.audioSettingsTitle(title)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  library.hasCustom(kind)
                      ? l10n.audioCurrentCustom
                      : kind == AudioFeedbackKind.move
                      ? l10n.audioCurrentChoice(
                          _choiceLabel(l10n, library.moveChoice),
                          library.moveChoice == MoveSoundChoice.followPieceSkin
                              ? '（${pieceSkin == PieceSkin.roundSeal ? l10n.audioRoundSealSkin : l10n.audioSquareInkSkin}）'
                              : '',
                        )
                      : l10n.audioCurrentDefault,
                ),
                const SizedBox(height: 8),
                Text(l10n.audioReplaceHelp(title)),
                const SizedBox(height: 4),
                Text(l10n.audioFileLimits),
                if (kind == AudioFeedbackKind.move) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MoveSoundChoice>(
                    key: ValueKey(
                      'move-sound-choice-${library.moveChoice.name}',
                    ),
                    initialValue: library.moveChoice,
                    decoration: InputDecoration(labelText: l10n.audioPlan),
                    items: MoveSoundChoice.values
                        .map(
                          (choice) => DropdownMenuItem(
                            value: choice,
                            child: Text(_choiceLabel(l10n, choice)),
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
                  if (library.hasCustom(kind))
                    Text(l10n.audioResetToChoosePlan),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MoveSoundChoice.values
                        .map(
                          (choice) => OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => library.previewMoveSound(
                                    choice,
                                    followSkinChoice:
                                        pieceSkin == PieceSkin.roundSeal
                                        ? MoveSoundChoice.sound1
                                        : MoveSoundChoice.sound2,
                                  ),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              l10n.audioPreviewChoice(
                                _choiceLabel(l10n, choice),
                              ),
                            ),
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
            label: Text(l10n.audioPreviewCurrent),
          ),
          TextButton.icon(
            onPressed: busy ? null : () => library.importCustom(kind),
            icon: const Icon(Icons.file_open),
            label: Text(l10n.audioImportCustom),
          ),
          if (library.hasCustom(kind))
            TextButton(
              onPressed: busy ? null : () => library.reset(kind),
              child: Text(l10n.audioRestoreDefault),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}
