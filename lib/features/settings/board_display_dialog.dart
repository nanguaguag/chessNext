import 'dart:async';
import '../../application/board_appearance.dart';
import 'package:flutter/material.dart';
import '../../application/preferences_controller.dart';
import '../../application/app_preferences.dart';
import '../../application/audio_library_controller.dart';
import '../../ports/audio_feedback.dart';
import 'audio_options_dialog.dart';
import '../../application/piece_image_library_controller.dart';
import 'piece_skin_images_dialog.dart';

class BoardDisplayDialog extends StatelessWidget {
  const BoardDisplayDialog({
    super.key,
    required this.preferences,
    this.audioLibrary,
    this.pieceImages,
  });
  final PreferencesController preferences;
  final AudioLibraryController? audioLibrary;
  final PieceImageLibraryController? pieceImages;

  Widget _soundOptions(
    BuildContext context,
    AudioFeedbackKind kind,
    String label,
  ) {
    final library = audioLibrary;
    if (library == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => AudioOptionsDialog(
            kind: kind,
            title: label,
            library: library,
            pieceSkin: preferences.value.pieceSkin,
          ),
        ),
        icon: const Icon(Icons.tune),
        label: Text('更换$label音效'),
      ),
    );
  }

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
              DropdownButtonFormField<BoardSkin>(
                key: ValueKey(preferences.value.boardSkin),
                initialValue: preferences.value.boardSkin,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '棋盘皮肤'),
                items: const [
                  DropdownMenuItem(
                    value: BoardSkin.parchment,
                    child: Text('宣纸木色'),
                  ),
                  DropdownMenuItem(value: BoardSkin.jade, child: Text('松石青')),
                ],
                onChanged: preferences.loading
                    ? null
                    : (skin) {
                        if (skin != null) {
                          unawaited(preferences.setBoardSkin(skin));
                        }
                      },
              ),
              const Text('原创配色，只保存在本机；皮肤图片导入与编辑仍待实现。'),
              const SizedBox(height: 12),
              DropdownButtonFormField<PieceSkin>(
                key: ValueKey(preferences.value.pieceSkin),
                initialValue: preferences.value.pieceSkin,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '棋子皮肤'),
                items: const [
                  DropdownMenuItem(
                    value: PieceSkin.roundSeal,
                    child: Text('传统圆章'),
                  ),
                  DropdownMenuItem(
                    value: PieceSkin.squareInk,
                    child: Text('方章墨韵'),
                  ),
                ],
                onChanged: preferences.loading
                    ? null
                    : (skin) {
                        if (skin != null) {
                          unawaited(preferences.setPieceSkin(skin));
                        }
                      },
              ),
              const Text('棋子样式会同步决定“随棋子皮肤”的走棋音效。'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: pieceImages == null || pieceImages!.loading
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (_) => PieceSkinImagesDialog(
                            skin: preferences.value.pieceSkin,
                            library: pieceImages!,
                          ),
                        ),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('编辑棋子图片'),
                ),
              ),
              const SizedBox(height: 12),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('走棋音效'),
                subtitle: const Text('落子后播放本机离线音效'),
                value: preferences.value.playMoveSound,
                onChanged: preferences.loading
                    ? null
                    : (enabled) =>
                          unawaited(preferences.setPlayMoveSound(enabled)),
              ),
              _soundOptions(context, AudioFeedbackKind.move, '走棋'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('吃子音效'),
                subtitle: const Text('吃掉对方棋子时播放本机离线音效'),
                value: preferences.value.playCaptureSound,
                onChanged: preferences.loading
                    ? null
                    : (enabled) =>
                          unawaited(preferences.setPlayCaptureSound(enabled)),
              ),
              _soundOptions(context, AudioFeedbackKind.capture, '吃子'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('将军音效'),
                subtitle: const Text('将军时播放；将死提示优先'),
                value: preferences.value.playCheckSound,
                onChanged: preferences.loading
                    ? null
                    : (enabled) =>
                          unawaited(preferences.setPlayCheckSound(enabled)),
              ),
              _soundOptions(context, AudioFeedbackKind.check, '将军'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('绝杀音效'),
                subtitle: const Text('将死时播放；与普通走棋音效互斥'),
                value: preferences.value.playMateSound,
                onChanged: preferences.loading
                    ? null
                    : (enabled) =>
                          unawaited(preferences.setPlayMateSound(enabled)),
              ),
              _soundOptions(context, AudioFeedbackKind.mate, '绝杀'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('选子音效'),
                subtitle: const Text('选中己方棋子时播放本机离线音效'),
                value: preferences.value.playSelectionSound,
                onChanged: preferences.loading
                    ? null
                    : (enabled) =>
                          unawaited(preferences.setPlaySelectionSound(enabled)),
              ),
              _soundOptions(context, AudioFeedbackKind.select, '选子'),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('着法朗读'),
                subtitle: const Text('使用本机已安装的中文系统语音，独立于走棋音效；无离线中文语音时不朗读'),
                value: preferences.value.speakMoves,
                onChanged: preferences.loading
                    ? null
                    : (enabled) =>
                          unawaited(preferences.setSpeakMoves(enabled)),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('对面一方的棋子倒置'),
                subtitle: const Text('上方那一方的棋子转180°，面对面摆棋时更顺眼。'),
                value: preferences.value.rotateOppositePieces,
                onChanged: preferences.loading
                    ? null
                    : (enabled) => unawaited(
                        preferences.setRotateOppositePieces(enabled),
                      ),
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
