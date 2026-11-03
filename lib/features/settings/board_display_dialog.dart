import 'dart:async';
import '../../application/board_appearance.dart';
import 'package:flutter/material.dart';
import '../../application/preferences_controller.dart';
import '../../application/app_preferences.dart';

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
              DropdownButtonFormField<LastMoveMarkerStyle>(
                key: ValueKey(preferences.value.lastMoveMarker),
                initialValue: preferences.value.lastMoveMarker,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '落子标记'),
                items: const [
                  DropdownMenuItem(
                    value: LastMoveMarkerStyle.halo,
                    child: Text('旋转光圈'),
                  ),
                  DropdownMenuItem(
                    value: LastMoveMarkerStyle.box,
                    child: Text('方框'),
                  ),
                ],
                onChanged: preferences.loading
                    ? null
                    : (style) {
                        if (style != null) {
                          unawaited(preferences.setLastMoveMarker(style));
                        }
                      },
              ),
              const Text('标出最后一步的起点与终点。光圈在换步时旋转一周；系统减少动画时静止。'),
              const SizedBox(height: 12),
              SegmentedButton<AnimationSpeed>(
                key: const ValueKey('animation-speed'),
                segments: const [
                  ButtonSegment(value: AnimationSpeed.off, label: Text('关')),
                  ButtonSegment(value: AnimationSpeed.fast, label: Text('快')),
                  ButtonSegment(
                    value: AnimationSpeed.standard,
                    label: Text('标准'),
                  ),
                  ButtonSegment(value: AnimationSpeed.slow, label: Text('慢')),
                ],
                selected: {preferences.value.animationSpeed},
                onSelectionChanged: preferences.loading
                    ? null
                    : (selection) => unawaited(
                        preferences.setAnimationSpeed(selection.single),
                      ),
              ),
              const Text('控制落子光圈旋转一周的时长：关、300毫秒、600毫秒或1200毫秒。系统减少动画时始终静止。'),
              const SizedBox(height: 12),
              DropdownButtonFormField<SelectionStyle>(
                key: ValueKey(preferences.value.selectionStyle),
                initialValue: preferences.value.selectionStyle,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '选子样式'),
                items: const [
                  DropdownMenuItem(
                    value: SelectionStyle.lift,
                    child: Text('抬起'),
                  ),
                  DropdownMenuItem(
                    value: SelectionStyle.frame,
                    child: Text('选择框'),
                  ),
                ],
                onChanged: preferences.loading
                    ? null
                    : (style) {
                        if (style != null) {
                          unawaited(preferences.setSelectionStyle(style));
                        }
                      },
              ),
              const Text('只改变选中棋子的显示，点击区域保持在交点。'),
              const SizedBox(height: 12),
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
