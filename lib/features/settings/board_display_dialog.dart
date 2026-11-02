import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/preferences_controller.dart';

class BoardDisplayDialog extends StatelessWidget {
  const BoardDisplayDialog({super.key, required this.preferences});
  final PreferencesController preferences;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) => AlertDialog(
      title: const Text('棋盘显示'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('棋子大小：${preferences.value.pieceSizePercent}%'),
              Semantics(
                label: '棋子大小',
                child: Slider(
                  key: const ValueKey('piece-size-slider'),
                  value: preferences.value.pieceSizePercent.toDouble(),
                  min: 10,
                  max: 200,
                  divisions: 38,
                  label: '${preferences.value.pieceSizePercent}%',
                  semanticFormatterCallback: (value) => '${value.round()}%',
                  onChanged: preferences.loading
                      ? null
                      : (value) =>
                            unawaited(preferences.setPieceSize(value.round())),
                ),
              ),
              const Wrap(
                spacing: 16,
                children: [Text('10%'), Text('100%'), Text('200%')],
              ),
              TextButton(
                onPressed: preferences.loading
                    ? null
                    : () => unawaited(preferences.setPieceSize(100)),
                child: const Text('恢复默认大小'),
              ),
              const Text('大小只影响显示，点击仍按交点。较大值可能使棋子重叠。'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示坐标'),
                subtitle: const Text('棋盘上下边的红黑方路数'),
                value: preferences.value.showCoordinates,
                onChanged: preferences.loading
                    ? null
                    : (value) =>
                          unawaited(preferences.setShowCoordinates(value)),
              ),
              const Text('实时应用到主棋盘与局面编辑器并保存在本机。翻转或镜像时，路数随棋盘方向变化。'),
              if (preferences.loading || preferences.saving)
                const LinearProgressIndicator(),
              if (preferences.error != null) ...[
                Text(
                  preferences.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: preferences.loading || preferences.saving
                      ? null
                      : () => unawaited(preferences.retryPersistence()),
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
