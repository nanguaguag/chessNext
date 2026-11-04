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
import '../../application/board_skin_image_library_controller.dart';
import '../../application/board_skin_library_controller.dart';
import 'board_skin_images_dialog.dart';
import 'board_skin_library_dialog.dart';
import '../../application/board_skin_geometry.dart';
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_skin_library.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/piece_skin_folder_picker.dart';
import 'piece_skin_library_dialog.dart';
import '../../ports/piece_skin_catalog.dart';

class BoardDisplayDialog extends StatelessWidget {
  const BoardDisplayDialog({
    super.key,
    required this.preferences,
    this.audioLibrary,
    this.pieceImages,
    this.boardSkinImages,
    this.boardSkins,
    this.pieceSkins,
    this.pieceSkinPackageExporter,
    this.pieceSkinPackagePicker,
    this.pieceSkinFolderPicker,
    this.pieceSkinCatalog,
    this.boardSkinPackageExporter,
    this.boardSkinPackagePicker,
  });
  final PreferencesController preferences;
  final AudioLibraryController? audioLibrary;
  final PieceImageLibraryController? pieceImages;
  final BoardSkinImageLibraryController? boardSkinImages;
  final BoardSkinLibraryController? boardSkins;
  final PieceSkinLibraryController? pieceSkins;
  final PieceSkinPackageExporter? pieceSkinPackageExporter;
  final PieceSkinPackagePicker? pieceSkinPackagePicker;
  final PieceSkinFolderPicker? pieceSkinFolderPicker;
  final PieceSkinCatalog? pieceSkinCatalog;
  final PieceSkinPackageExporter? boardSkinPackageExporter;
  final PieceSkinPackagePicker? boardSkinPackagePicker;

  PieceSkinDefinition? _activeProfile(PreferencesController preferences) =>
      pieceSkins?.definitionFor(preferences.value.selectedPieceSkinId);

  int _skinScale(PreferencesController preferences) =>
      _activeProfile(preferences)?.scalePercent ??
      (preferences.value.pieceSkin == PieceSkin.roundSeal
          ? preferences.value.roundSealPieceScalePercent
          : preferences.value.squareInkPieceScalePercent);

  int _skinOffsetX(PreferencesController preferences) =>
      _activeProfile(preferences)?.offsetXPercent ??
      (preferences.value.pieceSkin == PieceSkin.roundSeal
          ? preferences.value.roundSealPieceOffsetX
          : preferences.value.squareInkPieceOffsetX);

  int _skinOffsetY(PreferencesController preferences) =>
      _activeProfile(preferences)?.offsetYPercent ??
      (preferences.value.pieceSkin == PieceSkin.roundSeal
          ? preferences.value.roundSealPieceOffsetY
          : preferences.value.squareInkPieceOffsetY);

  Future<void> _setSkinScale(PreferencesController preferences, int value) {
    final profile = _activeProfile(preferences);
    return profile == null
        ? preferences.setPieceSkinScale(preferences.value.pieceSkin, value)
        : pieceSkins!.updateAppearance(profile.id, scalePercent: value);
  }

  Future<void> _setSkinOffset(
    PreferencesController preferences, {
    required int x,
    required int y,
  }) {
    final profile = _activeProfile(preferences);
    return profile == null
        ? preferences.setPieceSkinOffset(
            preferences.value.pieceSkin,
            x: x,
            y: y,
          )
        : pieceSkins!.updateAppearance(
            profile.id,
            offsetXPercent: x,
            offsetYPercent: y,
          );
  }

  Future<void> _setShadow(
    PreferencesController preferences,
    PieceSkinShadow shadow,
  ) {
    final profile = _activeProfile(preferences);
    return profile == null
        ? preferences.setPieceSkinShadow(preferences.value.pieceSkin, shadow)
        : pieceSkins!.updateAppearance(profile.id, shadow: shadow);
  }

  void _moveSkinPiece(
    PreferencesController preferences, {
    int x = 0,
    int y = 0,
  }) => unawaited(
    _setSkinOffset(
      preferences,
      x: (_skinOffsetX(preferences) + x).clamp(-8, 8),
      y: (_skinOffsetY(preferences) + y).clamp(-8, 8),
    ),
  );

  PieceSkinShadow _shadowPreset(
    PieceShadowStyle style,
    PieceSkinShadow current,
  ) => switch (style) {
    PieceShadowStyle.none => current.copyWith(style: style),
    PieceShadowStyle.soft => current.copyWith(
      style: style,
      angleDegrees: 138,
      distancePercent: 6.7,
      blurPercent: 2.4,
      opacityPercent: 50,
    ),
    PieceShadowStyle.prominent => current.copyWith(
      style: style,
      angleDegrees: 138,
      distancePercent: 9,
      blurPercent: 5,
      opacityPercent: 72,
    ),
  };

  Widget _pieceShadowControls(BuildContext context) {
    final skin = preferences.value.pieceSkin;
    final profile = _activeProfile(preferences);
    final shadow = profile?.shadow ?? preferences.value.pieceSkinShadows[skin]!;
    final shadowKey = profile?.id ?? skin.name;
    Widget slider({
      required String key,
      required String label,
      required double value,
      required double max,
      required int divisions,
      required PieceSkinShadow Function(double) update,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${value.toStringAsFixed(label == '方向' ? 0 : 1)}${label == '方向' ? '°' : '%'}',
        ),
        Slider(
          key: ValueKey('piece-skin-shadow-$shadowKey-$key'),
          value: value,
          min: 0,
          max: max,
          divisions: divisions,
          label: '${value.toStringAsFixed(1)}${label == '方向' ? '°' : '%'}',
          semanticFormatterCallback: (v) =>
              '${v.toStringAsFixed(1)}${label == '方向' ? '°' : '%'}',
          onChanged:
              preferences.loading ||
                  (profile != null && (pieceSkins?.loading ?? false)) ||
                  shadow.style == PieceShadowStyle.none
              ? null
              : (next) => unawaited(_setShadow(preferences, update(next))),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<PieceShadowStyle>(
          key: ValueKey('piece-skin-shadow-style-$shadowKey-${shadow.style}'),
          initialValue: shadow.style,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '棋子阴影'),
          items: const [
            DropdownMenuItem(value: PieceShadowStyle.none, child: Text('无')),
            DropdownMenuItem(value: PieceShadowStyle.soft, child: Text('柔和')),
            DropdownMenuItem(
              value: PieceShadowStyle.prominent,
              child: Text('明显'),
            ),
          ],
          onChanged:
              preferences.loading ||
                  (profile != null && (pieceSkins?.loading ?? false))
              ? null
              : (style) {
                  if (style != null) {
                    unawaited(
                      _setShadow(preferences, _shadowPreset(style, shadow)),
                    );
                  }
                },
        ),
        slider(
          key: 'angle',
          label: '方向',
          value: shadow.angleDegrees.toDouble(),
          max: 359,
          divisions: 359,
          update: (v) => shadow.copyWith(angleDegrees: v.round()),
        ),
        slider(
          key: 'distance',
          label: '距离',
          value: shadow.distancePercent,
          max: 20,
          divisions: 200,
          update: (v) => shadow.copyWith(distancePercent: v),
        ),
        slider(
          key: 'blur',
          label: '模糊',
          value: shadow.blurPercent,
          max: 20,
          divisions: 200,
          update: (v) => shadow.copyWith(blurPercent: v),
        ),
        slider(
          key: 'opacity',
          label: '浓淡',
          value: shadow.opacityPercent.toDouble(),
          max: 100,
          divisions: 100,
          update: (v) => shadow.copyWith(opacityPercent: v.round()),
        ),
        const Text('方向0°向右，90°向下；距离、模糊按棋格宽计算，值域为本机设计。'),
      ],
    );
  }

  Widget _geometryControls(BuildContext context) {
    final skin = preferences.value.boardSkin;
    final skinId = preferences.value.selectedBoardSkinId;
    final geometry =
        boardSkins?.geometryFor(skinId) ??
        preferences.value.boardGeometries[skin] ??
        const BoardSkinGeometry.standard();
    Future<void> setGeometry(BoardSkinGeometry next) {
      if (boardSkins?.definitionFor(skinId) != null) {
        return boardSkins!.updateGeometry(skinId, next);
      }
      return preferences.setBoardSkinGeometry(skin, next);
    }

    Widget edge(
      String label,
      double value,
      double min,
      double max,
      BoardSkinGeometry Function(double) update,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${value.toStringAsFixed(1)}%'),
        Slider(
          key: ValueKey('board-geometry-$skinId-$label'),
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).round().clamp(1, 196),
          label: '${value.toStringAsFixed(1)}%',
          semanticFormatterCallback: (v) => '${v.toStringAsFixed(1)}%',
          onChanged: preferences.loading
              ? null
              : (next) => unawaited(setGeometry(update(next))),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('格点与边距', style: Theme.of(context).textTheme.titleSmall),
        const Text('按画布百分比调整格网四边；所有棋子、标记和交点点击共用此几何。'),
        edge(
          '左边距',
          geometry.leftPercent,
          BoardSkinGeometry.minEdgePercent,
          geometry.rightPercent - BoardSkinGeometry.minSpanPercent,
          (v) => geometry.copyWith(leftPercent: v),
        ),
        edge(
          '右边距',
          geometry.rightPercent,
          geometry.leftPercent + BoardSkinGeometry.minSpanPercent,
          BoardSkinGeometry.maxEdgePercent,
          (v) => geometry.copyWith(rightPercent: v),
        ),
        edge(
          '上边距',
          geometry.topPercent,
          BoardSkinGeometry.minEdgePercent,
          geometry.bottomPercent - BoardSkinGeometry.minSpanPercent,
          (v) => geometry.copyWith(topPercent: v),
        ),
        edge(
          '下边距',
          geometry.bottomPercent,
          geometry.topPercent + BoardSkinGeometry.minSpanPercent,
          BoardSkinGeometry.maxEdgePercent,
          (v) => geometry.copyWith(bottomPercent: v),
        ),
        Text('棋子缩放 ${geometry.pieceScalePercent}%'),
        Slider(
          key: ValueKey('board-geometry-${skin.name}-piece-scale'),
          value: geometry.pieceScalePercent.toDouble(),
          min: BoardSkinGeometry.minPieceScalePercent.toDouble(),
          max: BoardSkinGeometry.maxPieceScalePercent.toDouble(),
          divisions:
              BoardSkinGeometry.maxPieceScalePercent -
              BoardSkinGeometry.minPieceScalePercent,
          label: '${geometry.pieceScalePercent}%',
          semanticFormatterCallback: (v) => '${v.round()}%',
          onChanged: preferences.loading
              ? null
              : (next) => unawaited(
                  setGeometry(
                    geometry.copyWith(pieceScalePercent: next.round()),
                  ),
                ),
        ),
        const Text('棋子只改变面容尺寸，不改变格线间距或交点命中；与全局棋子尺寸、棋子样式比例相乘。'),
        SwitchListTile(
          key: ValueKey('board-geometry-$skinId-landing-rotation'),
          contentPadding: EdgeInsets.zero,
          title: const Text('落点标记图片旋转'),
          subtitle: const Text('每次换步时转一周后静止；系统减少动画或关闭动画速度时静止。'),
          value: geometry.rotateLandingMarker,
          onChanged: preferences.loading
              ? null
              : (enabled) => unawaited(
                  setGeometry(geometry.copyWith(rotateLandingMarker: enabled)),
                ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: preferences.loading
                ? null
                : () => unawaited(
                    setGeometry(const BoardSkinGeometry.standard()),
                  ),
            icon: const Icon(Icons.restart_alt),
            label: const Text('格网恢复默认'),
          ),
        ),
      ],
    );
  }

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
    listenable: Listenable.merge([preferences, ?pieceSkins, ?boardSkins]),
    builder: (context, _) {
      final skinScale = _skinScale(preferences);
      final skinOffsetX = _skinOffsetX(preferences);
      final skinOffsetY = _skinOffsetY(preferences);
      final skinBusy =
          pieceSkins?.loading == true && _activeProfile(preferences) != null;
      return AlertDialog(
        title: const Text('棋盘显示'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(preferences.value.selectedBoardSkinId),
                  initialValue: preferences.value.selectedBoardSkinId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '棋盘皮肤'),
                  items: [
                    DropdownMenuItem(
                      value: BoardSkin.parchment.name,
                      child: Text('宣纸木色'),
                    ),
                    DropdownMenuItem(
                      value: BoardSkin.jade.name,
                      child: Text('松石青'),
                    ),
                    for (final profile in boardSkins?.profiles ?? const [])
                      DropdownMenuItem(
                        value: profile.id,
                        child: Text(profile.name),
                      ),
                  ],
                  onChanged: preferences.loading || skinBusy
                      ? null
                      : (id) {
                          if (id == null) return;
                          final builtIn = BoardSkin.values
                              .where((item) => item.name == id)
                              .firstOrNull;
                          if (boardSkins != null) {
                            unawaited(boardSkins!.select(id));
                          } else if (builtIn != null) {
                            unawaited(preferences.setBoardSkin(builtIn));
                          }
                        },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: boardSkins == null || boardSkins!.loading
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                BoardSkinLibraryDialog(
                                  library: boardSkins!,
                                  exporter: boardSkinPackageExporter,
                                  picker: boardSkinPackagePicker,
                                ),
                          ),
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('管理棋盘皮肤库'),
                  ),
                ),
                const Text('棋盘与棋子皮肤均支持项目格式的ZIP导入/导出；站点皮肤ZIP及文件夹格式未确认。'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        boardSkinImages == null || boardSkinImages!.loading
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (_) => BoardSkinImagesDialog(
                              skinId: preferences.value.selectedBoardSkinId,
                              skinLabel:
                                  boardSkins?.selectedName ??
                                  preferences.value.boardSkin.label,
                              library: boardSkinImages!,
                            ),
                          ),
                    icon: const Icon(Icons.wallpaper_outlined),
                    label: const Text('编辑棋盘图片'),
                  ),
                ),
                _geometryControls(context),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(preferences.value.selectedPieceSkinId),
                  initialValue: preferences.value.selectedPieceSkinId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '棋子皮肤'),
                  items: [
                    const DropdownMenuItem(
                      value: 'roundSeal',
                      child: Text('传统圆章'),
                    ),
                    const DropdownMenuItem(
                      value: 'squareInk',
                      child: Text('方章墨韵'),
                    ),
                    for (final skin in pieceSkins?.profiles ?? const [])
                      DropdownMenuItem(value: skin.id, child: Text(skin.name)),
                  ],
                  onChanged: preferences.loading || skinBusy
                      ? null
                      : (skinId) {
                          if (skinId == null) return;
                          final custom = pieceSkins?.profiles
                              .where((p) => p.id == skinId)
                              .firstOrNull;
                          if (custom != null) {
                            unawaited(
                              preferences.selectPieceSkin(
                                custom.baseSkin,
                                custom.id,
                              ),
                            );
                          } else {
                            unawaited(
                              preferences.setPieceSkin(
                                PieceSkin.values.byName(skinId),
                              ),
                            );
                          }
                        },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: pieceSkins == null
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (_) => PieceSkinLibraryDialog(
                              library: pieceSkins!,
                              exporter: pieceSkinPackageExporter,
                              picker: pieceSkinPackagePicker,
                              folderPicker: pieceSkinFolderPicker,
                              catalog: pieceSkinCatalog,
                            ),
                          ),
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('管理皮肤库'),
                  ),
                ),
                const Text('棋子样式会同步决定“随棋子皮肤”的走棋音效。'),
                Text('当前棋子样式大小：$skinScale%'),
                Slider(
                  key: ValueKey(
                    'piece-skin-size-${preferences.value.selectedPieceSkinId}',
                  ),
                  value: skinScale.toDouble(),
                  min: 80,
                  max: 120,
                  divisions: 40,
                  label: '$skinScale%',
                  semanticFormatterCallback: (value) => '${value.round()}%',
                  onChanged: preferences.loading
                      ? null
                      : (value) => unawaited(
                          _setSkinScale(preferences, value.round()),
                        ),
                ),
                const Text('大小只对当前棋子样式生效，并与下方全局棋子大小相乘；默认100%，范围80%–120%。'),
                const SizedBox(height: 8),
                Text('当前棋子样式位置：横向$skinOffsetX%，纵向$skinOffsetY%'),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '棋子上移1%',
                        onPressed:
                            preferences.loading || skinBusy || skinOffsetY <= -8
                            ? null
                            : () => _moveSkinPiece(preferences, y: -1),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '棋子左移1%',
                            onPressed:
                                preferences.loading ||
                                    skinBusy ||
                                    skinOffsetX <= -8
                                ? null
                                : () => _moveSkinPiece(preferences, x: -1),
                            icon: const Icon(Icons.keyboard_arrow_left),
                          ),
                          IconButton(
                            key: const ValueKey('piece-skin-auto-align'),
                            tooltip: '棋子自动对正',
                            onPressed:
                                preferences.loading ||
                                    skinBusy ||
                                    (skinOffsetX == 0 && skinOffsetY == 0)
                                ? null
                                : () => unawaited(
                                    _setSkinOffset(preferences, x: 0, y: 0),
                                  ),
                            icon: const Icon(Icons.my_location),
                          ),
                          IconButton(
                            tooltip: '棋子右移1%',
                            onPressed:
                                preferences.loading ||
                                    skinBusy ||
                                    skinOffsetX >= 8
                                ? null
                                : () => _moveSkinPiece(preferences, x: 1),
                            icon: const Icon(Icons.keyboard_arrow_right),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: '棋子下移1%',
                        onPressed:
                            preferences.loading || skinBusy || skinOffsetY >= 8
                            ? null
                            : () => _moveSkinPiece(preferences, y: 1),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ),
                const Text('每次移动当前棋子样式1%格宽，最多±8%；位置仅影响棋子绘制。'),
                _pieceShadowControls(context),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: pieceImages == null || pieceImages!.loading
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (_) => PieceSkinImagesDialog(
                              skinId: preferences.value.selectedPieceSkinId,
                              skinLabel:
                                  pieceSkins?.selectedName ??
                                  (preferences.value.pieceSkin ==
                                          PieceSkin.roundSeal
                                      ? '传统圆章'
                                      : '方章墨韵'),
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
                const Text('动画速度控制棋子走动和自定义标记；系统减少动态效果时静止。'),
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
                      : (enabled) => unawaited(
                          preferences.setPlaySelectionSound(enabled),
                        ),
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
                        : (value) => unawaited(
                            preferences.setPieceSize(value.round()),
                          ),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
      );
    },
  );
}
