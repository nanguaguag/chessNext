import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ports/preferences_repository.dart';
import 'app_preferences.dart';
import 'board_appearance.dart';
import 'board_skin_geometry.dart';
import 'review_models.dart';
import 'engine_session_controller.dart';

class PreferencesController extends ChangeNotifier {
  PreferencesController(this.engine, this.repository) {
    engine.addListener(_engineChanged);
  }
  final EngineSessionController engine;
  final PreferencesRepository repository;
  AppPreferences value = AppPreferences();
  bool loading = false;
  bool _initialized = false;
  bool _allowWrite = true;
  bool _disposed = false;
  bool _applying = false;
  bool get saving => _writing != null;
  bool get initialized => _initialized;
  String? error;
  String status = '使用默认设置';
  final Set<String> _edited = {};
  AppPreferences? _queued;
  AppPreferences? _persisted;
  Future<void>? _writing;
  Future<void>? _loadingTask;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  AppPreferences _bounded(AppPreferences next) {
    final threads = next.threads.clamp(1, engine.maxThreads);
    final hash = next.autoHash ? threads * 64 : next.hashMb;
    return next.copyWith(
      threads: threads,
      hashMb: hash.clamp(1, engine.maxHash),
      multiPv: next.multiPv.clamp(1, engine.maxPv),
    );
  }

  void _applyEngine() {
    final current = engine.settings;
    if (current.threads == value.threads &&
        current.hashMb == value.hashMb &&
        current.multiPv == value.multiPv &&
        engine.thinkTimeMs == value.thinkTimeMs) {
      return;
    }
    _applying = true;
    try {
      unawaited(
        engine.configureSession(
          AnalysisSettings(
            threads: value.threads,
            hashMb: value.hashMb,
            multiPv: value.multiPv,
          ),
          value.thinkTimeMs,
        ),
      );
    } finally {
      _applying = false;
    }
  }

  Future<void> initialize() {
    if (_disposed) return Future.value();
    if (_loadingTask != null) return _loadingTask!;
    final task = _load();
    _loadingTask = task;
    return task.whenComplete(() => _loadingTask = null);
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    _notify();
    var shouldSave = false;
    try {
      final loaded = await repository.load();
      if (_disposed) return;
      _allowWrite = true;
      if (loaded != null) {
        final previous = value;
        final stored = loaded.value;
        value = _bounded(
          stored.copyWith(
            reviewMode: _edited.contains('reviewMode')
                ? previous.reviewMode
                : null,
            selectionStyle: _edited.contains('selectionStyle')
                ? previous.selectionStyle
                : null,
            lastMoveMarker: _edited.contains('lastMoveMarker')
                ? previous.lastMoveMarker
                : null,
            showMoveGrades: _edited.contains('showMoveGrades')
                ? previous.showMoveGrades
                : null,
            showEvaluationBar: _edited.contains('showEvaluationBar')
                ? previous.showEvaluationBar
                : null,
            showVariationArrows: _edited.contains('showVariationArrows')
                ? previous.showVariationArrows
                : null,
            showAnalysisArrows: _edited.contains('showAnalysisArrows')
                ? previous.showAnalysisArrows
                : null,
            arrowHead: _edited.contains('arrowHead')
                ? previous.arrowHead
                : null,
            theme: _edited.contains('theme') ? previous.theme : null,
            boardLayoutPreset: _edited.contains('boardLayoutPreset')
                ? previous.boardLayoutPreset
                : null,
            animationSpeed: _edited.contains('animationSpeed')
                ? previous.animationSpeed
                : null,
            playMoveSound: _edited.contains('playMoveSound')
                ? previous.playMoveSound
                : null,
            playSelectionSound: _edited.contains('playSelectionSound')
                ? previous.playSelectionSound
                : null,
            playCaptureSound: _edited.contains('playCaptureSound')
                ? previous.playCaptureSound
                : null,
            playCheckSound: _edited.contains('playCheckSound')
                ? previous.playCheckSound
                : null,
            playMateSound: _edited.contains('playMateSound')
                ? previous.playMateSound
                : null,
            speakMoves: _edited.contains('speakMoves')
                ? previous.speakMoves
                : null,
            textSize: _edited.contains('textSize') ? previous.textSize : null,
            pieceSizePercent: _edited.contains('pieceSizePercent')
                ? previous.pieceSizePercent
                : null,
            roundSealPieceScalePercent:
                _edited.contains('roundSealPieceScalePercent')
                ? previous.roundSealPieceScalePercent
                : null,
            squareInkPieceScalePercent:
                _edited.contains('squareInkPieceScalePercent')
                ? previous.squareInkPieceScalePercent
                : null,
            roundSealPieceOffsetX: _edited.contains('roundSealPieceOffsetX')
                ? previous.roundSealPieceOffsetX
                : null,
            roundSealPieceOffsetY: _edited.contains('roundSealPieceOffsetY')
                ? previous.roundSealPieceOffsetY
                : null,
            squareInkPieceOffsetX: _edited.contains('squareInkPieceOffsetX')
                ? previous.squareInkPieceOffsetX
                : null,
            squareInkPieceOffsetY: _edited.contains('squareInkPieceOffsetY')
                ? previous.squareInkPieceOffsetY
                : null,
            showCoordinates: _edited.contains('showCoordinates')
                ? previous.showCoordinates
                : null,
            rotateOppositePieces: _edited.contains('rotateOppositePieces')
                ? previous.rotateOppositePieces
                : null,
            boardSkin: _edited.contains('boardSkin')
                ? previous.boardSkin
                : null,
            selectedBoardSkinId: _edited.contains('selectedBoardSkinId')
                ? previous.selectedBoardSkinId
                : null,
            boardGeometries: _mergeBoardGeometries(
              stored.boardGeometries,
              previous.boardGeometries,
            ),
            pieceSkinShadows: _mergePieceSkinShadows(
              stored.pieceSkinShadows,
              previous.pieceSkinShadows,
            ),
            pieceSkin: _edited.contains('pieceSkin')
                ? previous.pieceSkin
                : null,
            selectedPieceSkinId: _edited.contains('selectedPieceSkinId')
                ? previous.selectedPieceSkinId
                : null,
            guideVersion: _edited.contains('guideVersion')
                ? previous.guideVersion
                : null,
            sidePanelOrder: _edited.contains('sidePanelOrder')
                ? previous.sidePanelOrder
                : null,
            visibleSidePanels: _edited.contains('visibleSidePanels')
                ? previous.visibleSidePanels
                : null,
            threads: _edited.contains('threads') ? previous.threads : null,
            autoHash: _edited.contains('autoHash') ? previous.autoHash : null,
            hashMb: _edited.contains('hashMb') ? previous.hashMb : null,
            multiPv: _edited.contains('multiPv') ? previous.multiPv : null,
            thinkTimeMs: _edited.contains('thinkTimeMs')
                ? previous.thinkTimeMs
                : null,
            aiWalkDifficulty: _edited.contains('aiWalkDifficulty')
                ? previous.aiWalkDifficulty
                : null,
            aiWalkTimeMs: _edited.contains('aiWalkTimeMs')
                ? previous.aiWalkTimeMs
                : null,
            aiWalkMaxDepth: _edited.contains('aiWalkMaxDepth')
                ? previous.aiWalkMaxDepth
                : null,
            openingBookMode: _edited.contains('openingBookMode')
                ? previous.openingBookMode
                : null,
            endgameBookEnabled: _edited.contains('endgameBookEnabled')
                ? previous.endgameBookEnabled
                : null,
            leaveBookMoves: _edited.contains('leaveBookMoves')
                ? previous.leaveBookMoves
                : null,
            bookServiceBaseUrl: _edited.contains('bookServiceBaseUrl')
                ? previous.bookServiceBaseUrl
                : null,
            recordPlaybackIntervalMs:
                _edited.contains('recordPlaybackIntervalMs')
                ? previous.recordPlaybackIntervalMs
                : null,
            showMoveList: _edited.contains('showMoveList')
                ? previous.showMoveList
                : null,
            showRecordPlaybackButton:
                _edited.contains('showRecordPlaybackButton')
                ? previous.showRecordPlaybackButton
                : null,
            showPanelSwitchBar: _edited.contains('showPanelSwitchBar')
                ? previous.showPanelSwitchBar
                : null,
            activeSidePanel: _edited.contains('activeSidePanel')
                ? previous.activeSidePanel
                : null,
            skinCatalogBaseUrl: _edited.contains('skinCatalogBaseUrl')
                ? previous.skinCatalogBaseUrl
                : null,
            boardContextActions: _edited.contains('boardContextActions')
                ? previous.boardContextActions
                : null,
          ),
        );
        _persisted = stored;
        _applyEngine();
        shouldSave = value != stored || loaded.recovered;
        status = loaded.recovered ? '已从备份恢复设置' : '设置已加载';
      }
      shouldSave = shouldSave || _edited.isNotEmpty;
    } catch (_) {
      if (!_disposed) error = '设置读取失败，使用安全默认值；原文件已保留';
      shouldSave = _edited.isNotEmpty;
      _allowWrite = shouldSave;
    } finally {
      loading = false;
      _initialized = true;
      _notify();
      if (!_disposed && shouldSave) unawaited(flush());
    }
  }

  Future<bool> markGuideSeen() async {
    if (!_initialized || loading) await initialize();
    if (_disposed) return false;
    if (!_allowWrite) {
      error = '新手引导标记未保存，请先重试读取或恢复设置。原文件已保留。';
      _notify();
      return false;
    }
    final version = value.guideVersion < AppPreferences.currentGuideVersion
        ? AppPreferences.currentGuideVersion
        : value.guideVersion;
    await apply(value.copyWith(guideVersion: version));
    return !_disposed && error == null;
  }

  Future<void> setReviewMode(ReviewMode mode) =>
      apply(value.copyWith(reviewMode: mode));
  Future<void> setRecordPlaybackInterval(int milliseconds) =>
      apply(value.copyWith(recordPlaybackIntervalMs: milliseconds));
  Future<void> setShowMoveList(bool visible) =>
      apply(value.copyWith(showMoveList: visible));
  Future<void> setShowRecordPlaybackButton(bool visible) =>
      apply(value.copyWith(showRecordPlaybackButton: visible));
  Future<void> setShowPanelSwitchBar(bool visible) =>
      apply(value.copyWith(showPanelSwitchBar: visible));
  Future<void> setActiveSidePanel(SidePanel panel) =>
      apply(value.copyWith(activeSidePanel: panel));
  Future<void> setSkinCatalogBaseUrl(String baseUrl) async {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    try {
      final candidate = value.copyWith(skinCatalogBaseUrl: normalized);
      _edited.add('skinCatalogBaseUrl');
      await apply(candidate);
    } on ArgumentError {
      error = '服务地址须为HTTPS；本机测试可使用localhost HTTP。';
      _notify();
    }
  }

  Future<void> setBoardContextActions(List<BoardContextAction> actions) =>
      apply(value.copyWith(boardContextActions: actions));
  Future<void> setSidePanelOrder(List<SidePanel> order) =>
      apply(value.copyWith(sidePanelOrder: order));
  Future<void> setSidePanelVisibility(SidePanel panel, bool visible) {
    final panels = [...value.visibleSidePanels];
    if (visible && !panels.contains(panel)) panels.add(panel);
    if (!visible) panels.remove(panel);
    final ordered = value.sidePanelOrder.where(panels.contains).toList();
    return apply(value.copyWith(visibleSidePanels: ordered));
  }

  Future<void> setTheme(ThemePreference theme) =>
      apply(value.copyWith(theme: theme));
  Future<void> setBoardLayoutPreset(BoardLayoutPreset preset) =>
      apply(value.copyWith(boardLayoutPreset: preset));
  Future<void> setAnimationSpeed(AnimationSpeed speed) =>
      apply(value.copyWith(animationSpeed: speed));
  Future<void> setPlayMoveSound(bool enabled) =>
      apply(value.copyWith(playMoveSound: enabled));
  Future<void> setPlaySelectionSound(bool enabled) =>
      apply(value.copyWith(playSelectionSound: enabled));
  Future<void> setPlayCaptureSound(bool enabled) =>
      apply(value.copyWith(playCaptureSound: enabled));
  Future<void> setPlayCheckSound(bool enabled) =>
      apply(value.copyWith(playCheckSound: enabled));
  Future<void> setPlayMateSound(bool enabled) =>
      apply(value.copyWith(playMateSound: enabled));
  Future<void> setSpeakMoves(bool enabled) =>
      apply(value.copyWith(speakMoves: enabled));
  Future<void> setTextSize(TextSizePreference size) =>
      apply(value.copyWith(textSize: size));
  Future<void> setShowCoordinates(bool visible) =>
      apply(value.copyWith(showCoordinates: visible));
  Future<void> setRotateOppositePieces(bool enabled) =>
      apply(value.copyWith(rotateOppositePieces: enabled));
  Future<void> setBoardSkin(BoardSkin skin) => selectBoardSkin(skin, skin.name);
  Future<void> selectBoardSkin(BoardSkin skin, String profileId) {
    if (profileId != skin.name &&
        !RegExp(r'^custom-[a-z0-9-]{8,48}$').hasMatch(profileId)) {
      return Future.error(ArgumentError.value(profileId, 'profileId'));
    }
    return apply(
      value.copyWith(boardSkin: skin, selectedBoardSkinId: profileId),
    );
  }

  Future<void> setBoardSkinGeometry(
    BoardSkin skin,
    BoardSkinGeometry geometry,
  ) {
    final next = Map<BoardSkin, BoardSkinGeometry>.from(value.boardGeometries)
      ..[skin] = geometry;
    return apply(value.copyWith(boardGeometries: next));
  }

  Map<BoardSkin, BoardSkinGeometry> _mergeBoardGeometries(
    Map<BoardSkin, BoardSkinGeometry> stored,
    Map<BoardSkin, BoardSkinGeometry> current,
  ) => {
    for (final skin in BoardSkin.values)
      skin: _edited.contains('boardGeometry:${skin.name}')
          ? current[skin] ?? BoardSkinGeometry()
          : stored[skin] ?? BoardSkinGeometry(),
  };
  Map<PieceSkin, PieceSkinShadow> _mergePieceSkinShadows(
    Map<PieceSkin, PieceSkinShadow> stored,
    Map<PieceSkin, PieceSkinShadow> current,
  ) => {
    for (final skin in PieceSkin.values)
      skin: _edited.contains('pieceSkinShadow:${skin.name}')
          ? current[skin] ?? _defaultPieceSkinShadow(skin)
          : stored[skin] ?? _defaultPieceSkinShadow(skin),
  };
  PieceSkinShadow _defaultPieceSkinShadow(PieceSkin skin) =>
      skin == PieceSkin.roundSeal
      ? const PieceSkinShadow.roundSealDefault()
      : const PieceSkinShadow.standard();
  Future<void> setPieceSkin(PieceSkin skin) =>
      apply(value.copyWith(pieceSkin: skin, selectedPieceSkinId: skin.name));
  Future<void> selectPieceSkin(PieceSkin skin, String skinId) =>
      apply(value.copyWith(pieceSkin: skin, selectedPieceSkinId: skinId));
  Future<void> setPieceSkinShadow(PieceSkin skin, PieceSkinShadow shadow) {
    final next = Map<PieceSkin, PieceSkinShadow>.from(value.pieceSkinShadows)
      ..[skin] = shadow;
    return apply(value.copyWith(pieceSkinShadows: next));
  }

  Future<void> setPieceSize(int percent) =>
      apply(value.copyWith(pieceSizePercent: percent));
  Future<void> setPieceSkinScale(PieceSkin skin, int percent) => apply(
    value.copyWith(
      roundSealPieceScalePercent: skin == PieceSkin.roundSeal
          ? percent
          : value.roundSealPieceScalePercent,
      squareInkPieceScalePercent: skin == PieceSkin.squareInk
          ? percent
          : value.squareInkPieceScalePercent,
    ),
  );
  Future<void> setPieceSkinOffset(PieceSkin skin, {int? x, int? y}) => apply(
    value.copyWith(
      roundSealPieceOffsetX: skin == PieceSkin.roundSeal
          ? x ?? value.roundSealPieceOffsetX
          : value.roundSealPieceOffsetX,
      roundSealPieceOffsetY: skin == PieceSkin.roundSeal
          ? y ?? value.roundSealPieceOffsetY
          : value.roundSealPieceOffsetY,
      squareInkPieceOffsetX: skin == PieceSkin.squareInk
          ? x ?? value.squareInkPieceOffsetX
          : value.squareInkPieceOffsetX,
      squareInkPieceOffsetY: skin == PieceSkin.squareInk
          ? y ?? value.squareInkPieceOffsetY
          : value.squareInkPieceOffsetY,
    ),
  );
  Future<void> setAnalysisArrows(bool visible) =>
      apply(value.copyWith(showAnalysisArrows: visible));
  Future<void> setVariationArrows(bool visible) =>
      apply(value.copyWith(showVariationArrows: visible));
  Future<void> setMoveGrades(bool visible) =>
      apply(value.copyWith(showMoveGrades: visible));
  Future<void> setEvaluationBar(bool visible) =>
      apply(value.copyWith(showEvaluationBar: visible));
  Future<void> setSelectionStyle(SelectionStyle style) =>
      apply(value.copyWith(selectionStyle: style));
  Future<void> setLastMoveMarker(LastMoveMarkerStyle style) =>
      apply(value.copyWith(lastMoveMarker: style));
  Future<void> setArrowHead(ArrowHeadStyle style) =>
      apply(value.copyWith(arrowHead: style));
  Future<void> retryPersistence() =>
      _allowWrite ? flush(force: true) : initialize();
  Future<void> apply(AppPreferences next) {
    next = _bounded(next);
    _recordEdits(next);
    value = next;
    _applyEngine();
    _notify();
    return flush(force: true);
  }

  void _recordEdits(AppPreferences next) {
    if (next.reviewMode != value.reviewMode) _edited.add('reviewMode');
    if (next.selectionStyle != value.selectionStyle) {
      _edited.add('selectionStyle');
    }
    if (next.lastMoveMarker != value.lastMoveMarker) {
      _edited.add('lastMoveMarker');
    }
    if (next.showMoveGrades != value.showMoveGrades) {
      _edited.add('showMoveGrades');
    }
    if (next.showEvaluationBar != value.showEvaluationBar) {
      _edited.add('showEvaluationBar');
    }
    if (next.showVariationArrows != value.showVariationArrows) {
      _edited.add('showVariationArrows');
    }
    if (next.showAnalysisArrows != value.showAnalysisArrows) {
      _edited.add('showAnalysisArrows');
    }
    if (next.arrowHead != value.arrowHead) {
      _edited.add('arrowHead');
    }
    if (next.theme != value.theme) _edited.add('theme');
    if (next.boardLayoutPreset != value.boardLayoutPreset) {
      _edited.add('boardLayoutPreset');
    }
    if (next.animationSpeed != value.animationSpeed) {
      _edited.add('animationSpeed');
    }
    if (next.playMoveSound != value.playMoveSound) {
      _edited.add('playMoveSound');
    }
    if (next.playSelectionSound != value.playSelectionSound) {
      _edited.add('playSelectionSound');
    }
    if (next.playCaptureSound != value.playCaptureSound) {
      _edited.add('playCaptureSound');
    }
    if (next.playCheckSound != value.playCheckSound) {
      _edited.add('playCheckSound');
    }
    if (next.playMateSound != value.playMateSound) {
      _edited.add('playMateSound');
    }
    if (next.speakMoves != value.speakMoves) _edited.add('speakMoves');
    if (next.textSize != value.textSize) _edited.add('textSize');
    if (next.pieceSizePercent != value.pieceSizePercent) {
      _edited.add('pieceSizePercent');
    }
    if (next.roundSealPieceScalePercent != value.roundSealPieceScalePercent) {
      _edited.add('roundSealPieceScalePercent');
    }
    if (next.squareInkPieceScalePercent != value.squareInkPieceScalePercent) {
      _edited.add('squareInkPieceScalePercent');
    }
    if (next.roundSealPieceOffsetX != value.roundSealPieceOffsetX) {
      _edited.add('roundSealPieceOffsetX');
    }
    if (next.roundSealPieceOffsetY != value.roundSealPieceOffsetY) {
      _edited.add('roundSealPieceOffsetY');
    }
    if (next.squareInkPieceOffsetX != value.squareInkPieceOffsetX) {
      _edited.add('squareInkPieceOffsetX');
    }
    if (next.squareInkPieceOffsetY != value.squareInkPieceOffsetY) {
      _edited.add('squareInkPieceOffsetY');
    }
    if (next.showCoordinates != value.showCoordinates) {
      _edited.add('showCoordinates');
    }
    if (next.rotateOppositePieces != value.rotateOppositePieces) {
      _edited.add('rotateOppositePieces');
    }
    if (next.boardSkin != value.boardSkin) _edited.add('boardSkin');
    if (next.selectedBoardSkinId != value.selectedBoardSkinId) {
      _edited.add('selectedBoardSkinId');
    }
    for (final skin in BoardSkin.values) {
      if (next.boardGeometries[skin] != value.boardGeometries[skin]) {
        _edited.add('boardGeometry:${skin.name}');
      }
    }
    for (final skin in PieceSkin.values) {
      if (next.pieceSkinShadows[skin] != value.pieceSkinShadows[skin]) {
        _edited.add('pieceSkinShadow:${skin.name}');
      }
    }
    if (next.pieceSkin != value.pieceSkin) _edited.add('pieceSkin');
    if (next.selectedPieceSkinId != value.selectedPieceSkinId) {
      _edited.add('selectedPieceSkinId');
    }
    if (next.guideVersion != value.guideVersion) _edited.add('guideVersion');
    if (!listEquals(next.sidePanelOrder, value.sidePanelOrder)) {
      _edited.add('sidePanelOrder');
    }
    if (!listEquals(next.visibleSidePanels, value.visibleSidePanels)) {
      _edited.add('visibleSidePanels');
    }
    if (next.threads != value.threads) _edited.add('threads');
    if (next.autoHash != value.autoHash) _edited.add('autoHash');
    if (next.hashMb != value.hashMb) _edited.add('hashMb');
    if (next.multiPv != value.multiPv) _edited.add('multiPv');
    if (next.thinkTimeMs != value.thinkTimeMs) _edited.add('thinkTimeMs');
    if (next.aiWalkDifficulty != value.aiWalkDifficulty) {
      _edited.add('aiWalkDifficulty');
    }
    if (next.aiWalkTimeMs != value.aiWalkTimeMs) {
      _edited.add('aiWalkTimeMs');
    }
    if (next.aiWalkMaxDepth != value.aiWalkMaxDepth) {
      _edited.add('aiWalkMaxDepth');
    }
    if (next.openingBookMode != value.openingBookMode) {
      _edited.add('openingBookMode');
    }
    if (next.endgameBookEnabled != value.endgameBookEnabled) {
      _edited.add('endgameBookEnabled');
    }
    if (next.leaveBookMoves != value.leaveBookMoves) {
      _edited.add('leaveBookMoves');
    }
    if (next.bookServiceBaseUrl != value.bookServiceBaseUrl) {
      _edited.add('bookServiceBaseUrl');
    }
    if (next.recordPlaybackIntervalMs != value.recordPlaybackIntervalMs) {
      _edited.add('recordPlaybackIntervalMs');
    }
    if (next.showMoveList != value.showMoveList) _edited.add('showMoveList');
    if (next.showRecordPlaybackButton != value.showRecordPlaybackButton) {
      _edited.add('showRecordPlaybackButton');
    }
    if (next.showPanelSwitchBar != value.showPanelSwitchBar) {
      _edited.add('showPanelSwitchBar');
    }
    if (next.activeSidePanel != value.activeSidePanel) {
      _edited.add('activeSidePanel');
    }
    if (!listEquals(next.boardContextActions, value.boardContextActions)) {
      _edited.add('boardContextActions');
    }
  }

  void _engineChanged() {
    if (_applying || _disposed) return;
    final settings = engine.settings;
    final next = value.copyWith(
      threads: settings.threads,
      hashMb: settings.hashMb,
      multiPv: settings.multiPv,
      thinkTimeMs: engine.thinkTimeMs,
    );
    if (value == next) return;
    _recordEdits(next);
    value = next;
    _allowWrite = true;
    _notify();
    unawaited(flush());
  }

  Future<void> flush({bool force = false}) {
    if (force) _allowWrite = true;
    if (_disposed) return Future.value();
    if (loading) {
      return _loadingTask?.then((_) => flush(force: force)) ?? Future.value();
    }
    if (!_initialized || !_allowWrite) return Future.value();
    if (value == _persisted && _writing == null) return Future.value();
    _queued = value;
    if (_writing != null) return _writing!;
    final completion = Completer<void>();
    _writing = completion.future;
    error = null;
    _notify();
    unawaited(_drain(completion));
    return completion.future;
  }

  Future<void> _drain(Completer<void> completion) async {
    try {
      while (_queued != null) {
        final next = _queued!;
        _queued = null;
        await repository.save(next);
        _persisted = next;
      }
      status = '设置已保存';
    } catch (_) {
      _queued = null;
      error = '设置保存失败，当前设置仍生效，请重试';
    } finally {
      _writing = null;
      completion.complete();
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    engine.removeListener(_engineChanged);
    super.dispose();
  }
}
