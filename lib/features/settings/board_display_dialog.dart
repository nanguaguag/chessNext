import 'dart:async';
import '../../application/board_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
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
import 'board_geometry_editor.dart';
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
    this.boardSkinCatalog,
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
  final BoardSkinCatalog? boardSkinCatalog;
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
    final l10n = AppLocalizations.of(context);
    final skin = preferences.value.pieceSkin;
    final profile = _activeProfile(preferences);
    final shadow = profile?.shadow ?? preferences.value.pieceSkinShadows[skin]!;
    final shadowKey = profile?.id ?? skin.name;
    Widget slider({
      required String key,
      required String label,
      bool degrees = false,
      required double value,
      required double max,
      required int divisions,
      required PieceSkinShadow Function(double) update,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${value.toStringAsFixed(degrees ? 0 : 1)}${degrees ? '°' : '%'}',
        ),
        Slider(
          key: ValueKey('piece-skin-shadow-$shadowKey-$key'),
          value: value,
          min: 0,
          max: max,
          divisions: divisions,
          label:
              '${value.toStringAsFixed(degrees ? 0 : 1)}${degrees ? '°' : '%'}',
          semanticFormatterCallback: (v) =>
              '${v.toStringAsFixed(degrees ? 0 : 1)}${degrees ? '°' : '%'}',
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
          decoration: InputDecoration(labelText: l10n.pieceShadowLabel),
          items: [
            DropdownMenuItem(
              value: PieceShadowStyle.none,
              child: Text(l10n.pieceShadowNone),
            ),
            DropdownMenuItem(
              value: PieceShadowStyle.soft,
              child: Text(l10n.pieceShadowSoft),
            ),
            DropdownMenuItem(
              value: PieceShadowStyle.prominent,
              child: Text(l10n.pieceShadowProminent),
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
          label: l10n.pieceShadowDirection,
          value: shadow.angleDegrees.toDouble(),
          max: 359,
          divisions: 359,
          degrees: true,
          update: (v) => shadow.copyWith(angleDegrees: v.round()),
        ),
        slider(
          key: 'distance',
          label: l10n.pieceShadowDistance,
          value: shadow.distancePercent,
          max: 20,
          divisions: 200,
          update: (v) => shadow.copyWith(distancePercent: v),
        ),
        slider(
          key: 'blur',
          label: l10n.pieceShadowBlur,
          value: shadow.blurPercent,
          max: 20,
          divisions: 200,
          update: (v) => shadow.copyWith(blurPercent: v),
        ),
        slider(
          key: 'opacity',
          label: l10n.pieceShadowOpacity,
          value: shadow.opacityPercent.toDouble(),
          max: 100,
          divisions: 100,
          update: (v) => shadow.copyWith(opacityPercent: v.round()),
        ),
        Text(l10n.pieceShadowHelp),
      ],
    );
  }

  Widget _geometryControls(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        Row(
          children: [
            Expanded(child: Text(label)),
            SizedBox(
              width: 100,
              child: _GeometryEdgeInput(
                key: ValueKey('board-geometry-input-$skinId-$label'),
                label: label,
                value: value,
                min: min,
                max: max,
                enabled: !preferences.loading,
                onChanged: (next) => unawaited(setGeometry(update(next))),
              ),
            ),
          ],
        ),
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
        Text(
          l10n.boardGeometryHeading,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(l10n.boardGeometryHelp),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: ValueKey('board-grid-editor-open-$skinId'),
            onPressed: preferences.loading
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.boardGeometryCalibrateTitle),
                      content: SizedBox(
                        width: 216,
                        child: BoardGeometryEditor(
                          key: ValueKey('board-grid-editor-$skinId'),
                          geometry: geometry,
                          enabled: !preferences.loading,
                          onChanged: (next) => unawaited(setGeometry(next)),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(l10n.done),
                        ),
                      ],
                    ),
                  ),
            icon: const Icon(Icons.open_with),
            label: Text(l10n.boardGeometryCalibrate),
          ),
        ),
        edge(
          l10n.leftMargin,
          geometry.leftPercent,
          BoardSkinGeometry.minEdgePercent,
          geometry.rightPercent - BoardSkinGeometry.minSpanPercent,
          (v) => geometry.copyWith(leftPercent: v),
        ),
        edge(
          l10n.rightMargin,
          geometry.rightPercent,
          geometry.leftPercent + BoardSkinGeometry.minSpanPercent,
          BoardSkinGeometry.maxEdgePercent,
          (v) => geometry.copyWith(rightPercent: v),
        ),
        edge(
          l10n.topMargin,
          geometry.topPercent,
          BoardSkinGeometry.minEdgePercent,
          geometry.bottomPercent - BoardSkinGeometry.minSpanPercent,
          (v) => geometry.copyWith(topPercent: v),
        ),
        edge(
          l10n.bottomMargin,
          geometry.bottomPercent,
          geometry.topPercent + BoardSkinGeometry.minSpanPercent,
          BoardSkinGeometry.maxEdgePercent,
          (v) => geometry.copyWith(bottomPercent: v),
        ),
        Text(l10n.boardSkinPieceScale(geometry.pieceScalePercent)),
        Slider(
          key: ValueKey('board-geometry-$skinId-piece-scale'),
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
        Text(l10n.boardSkinPieceScaleHelp),
        SwitchListTile(
          key: ValueKey('board-geometry-$skinId-landing-rotation'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.landingMarkerRotation),
          subtitle: Text(l10n.landingMarkerRotationHelp),
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
            label: Text(l10n.resetBoardGrid),
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
    final l10n = AppLocalizations.of(context);
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
        label: Text(l10n.replaceSound(label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([preferences, ?pieceSkins, ?boardSkins]),
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final skinScale = _skinScale(preferences);
      final skinOffsetX = _skinOffsetX(preferences);
      final skinOffsetY = _skinOffsetY(preferences);
      final skinBusy =
          pieceSkins?.loading == true && _activeProfile(preferences) != null;
      return AlertDialog(
        title: Text(l10n.boardDisplayTitle),
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
                  decoration: InputDecoration(labelText: l10n.boardSkinLabel),
                  items: [
                    DropdownMenuItem(
                      value: BoardSkin.parchment.name,
                      child: Text(l10n.boardSkinParchment),
                    ),
                    DropdownMenuItem(
                      value: BoardSkin.jade.name,
                      child: Text(l10n.boardSkinJade),
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
                            builder: (_) => BoardSkinLibraryDialog(
                              library: boardSkins!,
                              exporter: boardSkinPackageExporter,
                              picker: boardSkinPackagePicker,
                              catalog: boardSkinCatalog,
                            ),
                          ),
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: Text(l10n.manageBoardSkins),
                  ),
                ),
                Text(l10n.skinPackageHelp),
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
                    label: Text(l10n.editBoardImages),
                  ),
                ),
                _geometryControls(context),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(preferences.value.selectedPieceSkinId),
                  initialValue: preferences.value.selectedPieceSkinId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.pieceSkinLabel),
                  items: [
                    DropdownMenuItem(
                      value: 'roundSeal',
                      child: Text(l10n.roundSealPieceSkin),
                    ),
                    DropdownMenuItem(
                      value: 'squareInk',
                      child: Text(l10n.squareInkPieceSkin),
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
                    label: Text(l10n.managePieceSkins),
                  ),
                ),
                Text(l10n.pieceStyleMoveSoundHelp),
                Text(l10n.pieceSkinScaleCurrent(skinScale)),
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
                Text(l10n.pieceSkinScaleHelp),
                const SizedBox(height: 8),
                Text(l10n.pieceSkinPositionCurrent(skinOffsetX, skinOffsetY)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.skinPieceMoveUp,
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
                            tooltip: l10n.skinPieceMoveLeft,
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
                            tooltip: l10n.skinPieceAutoAlign,
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
                            tooltip: l10n.skinPieceMoveRight,
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
                        tooltip: l10n.skinPieceMoveDown,
                        onPressed:
                            preferences.loading || skinBusy || skinOffsetY >= 8
                            ? null
                            : () => _moveSkinPiece(preferences, y: 1),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ),
                Text(l10n.pieceSkinPositionHelp),
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
                                      ? l10n.roundSealPieceSkin
                                      : l10n.squareInkPieceSkin),
                              library: pieceImages!,
                            ),
                          ),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(l10n.editPieceImages),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LastMoveMarkerStyle>(
                  key: ValueKey(preferences.value.lastMoveMarker),
                  initialValue: preferences.value.lastMoveMarker,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.lastMoveMarker),
                  items: [
                    DropdownMenuItem(
                      value: LastMoveMarkerStyle.halo,
                      child: Text(l10n.lastMoveHalo),
                    ),
                    DropdownMenuItem(
                      value: LastMoveMarkerStyle.box,
                      child: Text(l10n.lastMoveBox),
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
                Text(l10n.lastMoveAnimationHelp),
                const SizedBox(height: 12),
                SegmentedButton<AnimationSpeed>(
                  key: const ValueKey('animation-speed'),
                  segments: [
                    ButtonSegment(
                      value: AnimationSpeed.off,
                      label: Text(l10n.animationOff),
                    ),
                    ButtonSegment(
                      value: AnimationSpeed.fast,
                      label: Text(l10n.animationFast),
                    ),
                    ButtonSegment(
                      value: AnimationSpeed.standard,
                      label: Text(l10n.animationStandard),
                    ),
                    ButtonSegment(
                      value: AnimationSpeed.slow,
                      label: Text(l10n.animationSlow),
                    ),
                  ],
                  selected: {preferences.value.animationSpeed},
                  onSelectionChanged: preferences.loading
                      ? null
                      : (selection) => unawaited(
                          preferences.setAnimationSpeed(selection.single),
                        ),
                ),
                Text(l10n.animationDurationHelp),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.moveSound),
                  subtitle: Text(l10n.moveSoundHelp),
                  value: preferences.value.playMoveSound,
                  onChanged: preferences.loading
                      ? null
                      : (enabled) =>
                            unawaited(preferences.setPlayMoveSound(enabled)),
                ),
                _soundOptions(context, AudioFeedbackKind.move, l10n.moveSound),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.captureSound),
                  subtitle: Text(l10n.captureSoundHelp),
                  value: preferences.value.playCaptureSound,
                  onChanged: preferences.loading
                      ? null
                      : (enabled) =>
                            unawaited(preferences.setPlayCaptureSound(enabled)),
                ),
                _soundOptions(
                  context,
                  AudioFeedbackKind.capture,
                  l10n.captureSound,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.checkSound),
                  subtitle: Text(l10n.checkSoundHelp),
                  value: preferences.value.playCheckSound,
                  onChanged: preferences.loading
                      ? null
                      : (enabled) =>
                            unawaited(preferences.setPlayCheckSound(enabled)),
                ),
                _soundOptions(
                  context,
                  AudioFeedbackKind.check,
                  l10n.checkSound,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.mateSound),
                  subtitle: Text(l10n.mateSoundHelp),
                  value: preferences.value.playMateSound,
                  onChanged: preferences.loading
                      ? null
                      : (enabled) =>
                            unawaited(preferences.setPlayMateSound(enabled)),
                ),
                _soundOptions(context, AudioFeedbackKind.mate, l10n.mateSound),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.selectionSound),
                  subtitle: Text(l10n.selectionSoundHelp),
                  value: preferences.value.playSelectionSound,
                  onChanged: preferences.loading
                      ? null
                      : (enabled) => unawaited(
                          preferences.setPlaySelectionSound(enabled),
                        ),
                ),
                _soundOptions(
                  context,
                  AudioFeedbackKind.select,
                  l10n.selectionSound,
                ),
                DropdownButtonFormField<SelectionStyle>(
                  key: ValueKey(preferences.value.selectionStyle),
                  initialValue: preferences.value.selectionStyle,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.selectionStyle),
                  items: [
                    DropdownMenuItem(
                      value: SelectionStyle.lift,
                      child: Text(l10n.selectionLift),
                    ),
                    DropdownMenuItem(
                      value: SelectionStyle.frame,
                      child: Text(l10n.selectionFrame),
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
                Text(l10n.selectionStyleHelp),
                const SizedBox(height: 12),
                Text(
                  l10n.pieceScalePercent(preferences.value.pieceSizePercent),
                ),
                Semantics(
                  label: l10n.pieceScalePercent(
                    preferences.value.pieceSizePercent,
                  ),
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
                  title: Text(l10n.speakMoves),
                  subtitle: Text(l10n.speakMovesHelp),
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
                  child: Text(l10n.resetPieceSize),
                ),
                Text(l10n.pieceSizeHelp),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.showCoordinates),
                  subtitle: Text(l10n.showCoordinatesHelp),
                  value: preferences.value.showCoordinates,
                  onChanged: preferences.loading
                      ? null
                      : (value) =>
                            unawaited(preferences.setShowCoordinates(value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.rotateOppositePieces),
                  subtitle: Text(l10n.rotateOppositePiecesHelp),
                  value: preferences.value.rotateOppositePieces,
                  onChanged: preferences.loading
                      ? null
                      : (enabled) => unawaited(
                          preferences.setRotateOppositePieces(enabled),
                        ),
                ),
                Text(l10n.boardDisplayPersistenceHelp),
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
}

class _GeometryEdgeInput extends StatefulWidget {
  const _GeometryEdgeInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_GeometryEdgeInput> createState() => _GeometryEdgeInputState();
}

class _GeometryEdgeInputState extends State<_GeometryEdgeInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.toStringAsFixed(1),
  );
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _GeometryEdgeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  void _submit(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || !parsed.isFinite) {
      _controller.text = widget.value.toStringAsFixed(1);
      return;
    }
    final next = parsed.clamp(widget.min, widget.max).toDouble();
    widget.onChanged(next);
    _controller.text = next.toStringAsFixed(1);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: ValueKey('geometry-value-${widget.label}'),
    controller: _controller,
    focusNode: _focusNode,
    enabled: widget.enabled,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(?:\.\d)?$')),
    ],
    textAlign: TextAlign.end,
    decoration: InputDecoration(
      isDense: true,
      suffixText: '%',
      labelText: widget.label,
      border: const OutlineInputBorder(),
    ),
    onSubmitted: _submit,
    onTapOutside: (_) => _focusNode.unfocus(),
  );
}
