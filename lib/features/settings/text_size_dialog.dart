import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/app_preferences.dart';
import '../../application/preferences_controller.dart';
import '../../l10n/app_localizations.dart';
import 'app_text_scaling.dart';

class TextSizeDialog extends StatelessWidget {
  const TextSizeDialog({super.key, required this.preferences});
  final PreferencesController preferences;
  static const manual = [
    TextSizePreference.standard,
    TextSizePreference.large,
    TextSizePreference.extraLarge,
  ];
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final size = preferences.value.textSize;
      final system = size == TextSizePreference.system;
      final index = system ? 0 : manual.indexOf(size);
      final systemPercent =
          (AppTextScaling.systemOf(context).scale(16) / 16 * 100).round();
      return AlertDialog(
        title: Text(l10n.textSizeDialogTitle),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.followSystemTextSize),
                  subtitle: Text(l10n.systemTextSizePreview(systemPercent)),
                  value: system,
                  onChanged: preferences.loading
                      ? null
                      : (value) => unawaited(
                          preferences.setTextSize(
                            value
                                ? TextSizePreference.system
                                : TextSizePreference.standard,
                          ),
                        ),
                ),
                Text(
                  system
                      ? l10n.currentTextSizeFollowing
                      : l10n.currentTextSizeManual(_manualLabel(l10n, index)),
                ),
                Semantics(
                  label: l10n.textSizeDialogTitle,
                  child: Slider(
                    key: const ValueKey('text-size-slider'),
                    value: index.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    label: _manualLabel(l10n, index),
                    semanticFormatterCallback: (value) =>
                        _manualLabel(l10n, value.round()),
                    onChanged: preferences.loading
                        ? null
                        : (value) => unawaited(
                            preferences.setTextSize(manual[value.round()]),
                          ),
                  ),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(l10n.standardTextSize),
                    Text(l10n.largeTextSize),
                    Text(l10n.extraLargeTextSize),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.textSizePreviewLine,
                  key: ValueKey('text-size-preview'),
                ),
                const SizedBox(height: 12),
                Text(l10n.textSizePersistenceHelp),
                if (preferences.loading || preferences.saving)
                  const LinearProgressIndicator(),
                if (preferences.error != null) ...[
                  Text(
                    preferences.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: preferences.loading || preferences.saving
                        ? null
                        : () => unawaited(preferences.retryPersistence()),
                    child: Text(l10n.retry),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );

  String _manualLabel(AppLocalizations l10n, int index) => switch (index) {
    0 => l10n.standardTextSize,
    1 => l10n.largeTextSize,
    _ => l10n.extraLargeTextSize,
  };
}
