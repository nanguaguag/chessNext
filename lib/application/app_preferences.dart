import 'board_appearance.dart';
import 'board_skin_geometry.dart';
import 'review_models.dart';
import '../ports/piece_skin_library.dart';

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

enum ThemePreference { system, light, dark }

/// Project timing choices; the reference site does not expose numeric durations.
enum AnimationSpeed { off, fast, standard, slow }

extension AnimationSpeedTiming on AnimationSpeed {
  Duration get duration => switch (this) {
    AnimationSpeed.off => Duration.zero,
    AnimationSpeed.fast => const Duration(milliseconds: 300),
    AnimationSpeed.standard => const Duration(milliseconds: 600),
    AnimationSpeed.slow => const Duration(milliseconds: 1200),
  };
}

enum TextSizePreference { system, standard, large, extraLarge }

enum SidePanel { play, analysis, review, candidates }

const defaultSidePanelOrder = <SidePanel>[
  SidePanel.play,
  SidePanel.analysis,
  SidePanel.review,
  SidePanel.candidates,
];

extension TextSizeScale on TextSizePreference {
  double? get manualScale => switch (this) {
    TextSizePreference.system => null,
    TextSizePreference.standard => 1,
    TextSizePreference.large => 1.15,
    TextSizePreference.extraLarge => 1.3,
  };
}

/// Versioned, platform-neutral settings. AI roles and active searches are excluded.
final class AppPreferences {
  AppPreferences({
    this.theme = ThemePreference.system,
    this.animationSpeed = AnimationSpeed.standard,
    this.playMoveSound = true,
    this.playSelectionSound = true,
    this.playCaptureSound = true,
    this.playCheckSound = true,
    this.playMateSound = true,
    this.speakMoves = false,
    this.reviewMode = ReviewMode.best,
    this.textSize = TextSizePreference.system,
    this.showCoordinates = true,
    this.rotateOppositePieces = false,
    this.boardSkin = BoardSkin.parchment,
    Map<BoardSkin, BoardSkinGeometry> boardGeometries = const {},
    Map<PieceSkin, PieceSkinShadow> pieceSkinShadows = const {},
    this.pieceSkin = PieceSkin.roundSeal,
    this.selectedPieceSkinId = 'roundSeal',
    this.pieceSizePercent = 100,
    this.roundSealPieceScalePercent = 100,
    this.squareInkPieceScalePercent = 100,
    this.roundSealPieceOffsetX = 0,
    this.roundSealPieceOffsetY = 0,
    this.squareInkPieceOffsetX = 0,
    this.squareInkPieceOffsetY = 0,
    this.showAnalysisArrows = true,
    this.showVariationArrows = true,
    this.showEvaluationBar = true,
    this.showMoveGrades = true,
    this.arrowHead = ArrowHeadStyle.standard,
    this.lastMoveMarker = LastMoveMarkerStyle.halo,
    this.selectionStyle = SelectionStyle.lift,
    this.threads = 1,
    this.hashMb = 16,
    this.multiPv = 1,
    this.thinkTimeMs = 1000,
    this.recordPlaybackIntervalMs = 2000,
    this.showMoveList = true,
    this.showRecordPlaybackButton = true,
    this.showPanelSwitchBar = false,
    this.activeSidePanel = SidePanel.play,
    this.guideVersion = 0,
    List<SidePanel> sidePanelOrder = defaultSidePanelOrder,
    List<SidePanel> visibleSidePanels = defaultSidePanelOrder,
  }) : boardGeometries = Map.unmodifiable({
         for (final skin in BoardSkin.values)
           skin: boardGeometries[skin] ?? BoardSkinGeometry(),
       }),
       pieceSkinShadows = Map.unmodifiable({
         for (final skin in PieceSkin.values)
           skin:
               pieceSkinShadows[skin] ??
               (skin == PieceSkin.roundSeal
                   ? const PieceSkinShadow.roundSealDefault()
                   : const PieceSkinShadow.standard()),
       }),
       sidePanelOrder = List.unmodifiable(sidePanelOrder),
       visibleSidePanels = List.unmodifiable(visibleSidePanels) {
    if (pieceSizePercent < 10 ||
        pieceSizePercent > 200 ||
        pieceSizePercent % 5 != 0 ||
        threads < 1 ||
        threads > 1024 ||
        hashMb < 1 ||
        hashMb > 1024 ||
        multiPv < 1 ||
        multiPv > 256 ||
        thinkTimeMs < 50 ||
        thinkTimeMs > 600000 ||
        recordPlaybackIntervalMs < 500 ||
        recordPlaybackIntervalMs > 30000 ||
        recordPlaybackIntervalMs % 100 != 0 ||
        guideVersion < 0 ||
        guideVersion > 1000000 ||
        roundSealPieceScalePercent < 80 ||
        roundSealPieceScalePercent > 120 ||
        squareInkPieceScalePercent < 80 ||
        squareInkPieceScalePercent > 120 ||
        roundSealPieceOffsetX < -8 ||
        roundSealPieceOffsetX > 8 ||
        roundSealPieceOffsetY < -8 ||
        roundSealPieceOffsetY > 8 ||
        squareInkPieceOffsetX < -8 ||
        squareInkPieceOffsetX > 8 ||
        squareInkPieceOffsetY < -8 ||
        squareInkPieceOffsetY > 8) {
      throw ArgumentError('Invalid preferences');
    }
    if (!(PieceSkin.values.any((skin) => skin.name == selectedPieceSkinId) ||
        PieceSkinDefinition.isValidId(selectedPieceSkinId))) {
      throw ArgumentError('Invalid selected piece skin');
    }
    if (this.sidePanelOrder.length != SidePanel.values.length ||
        this.sidePanelOrder.toSet().length != SidePanel.values.length ||
        !this.sidePanelOrder.toSet().containsAll(SidePanel.values)) {
      throw ArgumentError('Invalid side panel order');
    }
    if (this.visibleSidePanels.toSet().length !=
        this.visibleSidePanels.length) {
      throw ArgumentError('Invalid visible side panels');
    }
  }
  final ThemePreference theme;
  final AnimationSpeed animationSpeed;
  final bool playMoveSound;
  final bool playSelectionSound;
  final bool playCaptureSound;
  final bool playCheckSound;
  final bool playMateSound;
  final bool speakMoves;
  final ReviewMode reviewMode;
  final TextSizePreference textSize;
  final bool showCoordinates;
  final bool rotateOppositePieces;
  final BoardSkin boardSkin;
  final Map<BoardSkin, BoardSkinGeometry> boardGeometries;
  final Map<PieceSkin, PieceSkinShadow> pieceSkinShadows;
  final PieceSkin pieceSkin;
  final String selectedPieceSkinId;
  final int pieceSizePercent;
  final int roundSealPieceScalePercent;
  final int squareInkPieceScalePercent;
  final int roundSealPieceOffsetX, roundSealPieceOffsetY;
  final int squareInkPieceOffsetX, squareInkPieceOffsetY;
  final bool showAnalysisArrows;
  final bool showVariationArrows;
  final bool showEvaluationBar;
  final bool showMoveGrades;
  final ArrowHeadStyle arrowHead;
  final LastMoveMarkerStyle lastMoveMarker;
  final SelectionStyle selectionStyle;
  static const currentGuideVersion = 1;
  final int threads,
      hashMb,
      multiPv,
      thinkTimeMs,
      recordPlaybackIntervalMs,
      guideVersion;
  final bool showMoveList, showRecordPlaybackButton;
  final bool showPanelSwitchBar;
  final SidePanel activeSidePanel;
  final List<SidePanel> sidePanelOrder;
  final List<SidePanel> visibleSidePanels;
  AppPreferences copyWith({
    ThemePreference? theme,
    AnimationSpeed? animationSpeed,
    bool? playMoveSound,
    bool? playSelectionSound,
    bool? playCaptureSound,
    bool? playCheckSound,
    bool? playMateSound,
    bool? speakMoves,
    ReviewMode? reviewMode,
    TextSizePreference? textSize,
    bool? showCoordinates,
    bool? rotateOppositePieces,
    BoardSkin? boardSkin,
    Map<BoardSkin, BoardSkinGeometry>? boardGeometries,
    Map<PieceSkin, PieceSkinShadow>? pieceSkinShadows,
    PieceSkin? pieceSkin,
    String? selectedPieceSkinId,
    int? pieceSizePercent,
    int? roundSealPieceScalePercent,
    int? squareInkPieceScalePercent,
    int? roundSealPieceOffsetX,
    int? roundSealPieceOffsetY,
    int? squareInkPieceOffsetX,
    int? squareInkPieceOffsetY,
    bool? showAnalysisArrows,
    bool? showVariationArrows,
    bool? showEvaluationBar,
    bool? showMoveGrades,
    ArrowHeadStyle? arrowHead,
    LastMoveMarkerStyle? lastMoveMarker,
    SelectionStyle? selectionStyle,
    int? threads,
    int? hashMb,
    int? multiPv,
    int? thinkTimeMs,
    int? recordPlaybackIntervalMs,
    bool? showMoveList,
    bool? showRecordPlaybackButton,
    bool? showPanelSwitchBar,
    SidePanel? activeSidePanel,
    int? guideVersion,
    List<SidePanel>? sidePanelOrder,
    List<SidePanel>? visibleSidePanels,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    animationSpeed: animationSpeed ?? this.animationSpeed,
    playMoveSound: playMoveSound ?? this.playMoveSound,
    playSelectionSound: playSelectionSound ?? this.playSelectionSound,
    playCaptureSound: playCaptureSound ?? this.playCaptureSound,
    playCheckSound: playCheckSound ?? this.playCheckSound,
    playMateSound: playMateSound ?? this.playMateSound,
    speakMoves: speakMoves ?? this.speakMoves,
    reviewMode: reviewMode ?? this.reviewMode,
    textSize: textSize ?? this.textSize,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    rotateOppositePieces: rotateOppositePieces ?? this.rotateOppositePieces,
    boardSkin: boardSkin ?? this.boardSkin,
    boardGeometries: boardGeometries ?? this.boardGeometries,
    pieceSkinShadows: pieceSkinShadows ?? this.pieceSkinShadows,
    pieceSkin: pieceSkin ?? this.pieceSkin,
    selectedPieceSkinId: selectedPieceSkinId ?? this.selectedPieceSkinId,
    pieceSizePercent: pieceSizePercent ?? this.pieceSizePercent,
    roundSealPieceScalePercent:
        roundSealPieceScalePercent ?? this.roundSealPieceScalePercent,
    squareInkPieceScalePercent:
        squareInkPieceScalePercent ?? this.squareInkPieceScalePercent,
    roundSealPieceOffsetX: roundSealPieceOffsetX ?? this.roundSealPieceOffsetX,
    roundSealPieceOffsetY: roundSealPieceOffsetY ?? this.roundSealPieceOffsetY,
    squareInkPieceOffsetX: squareInkPieceOffsetX ?? this.squareInkPieceOffsetX,
    squareInkPieceOffsetY: squareInkPieceOffsetY ?? this.squareInkPieceOffsetY,
    showAnalysisArrows: showAnalysisArrows ?? this.showAnalysisArrows,
    showVariationArrows: showVariationArrows ?? this.showVariationArrows,
    showEvaluationBar: showEvaluationBar ?? this.showEvaluationBar,
    showMoveGrades: showMoveGrades ?? this.showMoveGrades,
    arrowHead: arrowHead ?? this.arrowHead,
    lastMoveMarker: lastMoveMarker ?? this.lastMoveMarker,
    selectionStyle: selectionStyle ?? this.selectionStyle,
    threads: threads ?? this.threads,
    hashMb: hashMb ?? this.hashMb,
    multiPv: multiPv ?? this.multiPv,
    thinkTimeMs: thinkTimeMs ?? this.thinkTimeMs,
    recordPlaybackIntervalMs:
        recordPlaybackIntervalMs ?? this.recordPlaybackIntervalMs,
    showMoveList: showMoveList ?? this.showMoveList,
    showRecordPlaybackButton:
        showRecordPlaybackButton ?? this.showRecordPlaybackButton,
    showPanelSwitchBar: showPanelSwitchBar ?? this.showPanelSwitchBar,
    activeSidePanel: activeSidePanel ?? this.activeSidePanel,
    guideVersion: guideVersion ?? this.guideVersion,
    sidePanelOrder: sidePanelOrder ?? this.sidePanelOrder,
    visibleSidePanels: visibleSidePanels ?? this.visibleSidePanels,
  );
  Map<String, Object> toJson() => {
    'schema': 1,
    if (reviewMode != ReviewMode.best) 'reviewMode': reviewMode.name,
    if (selectionStyle != SelectionStyle.lift)
      'selectionStyle': selectionStyle.name,
    if (lastMoveMarker != LastMoveMarkerStyle.halo)
      'lastMoveMarker': lastMoveMarker.name,
    'theme': theme.name,
    if (animationSpeed != AnimationSpeed.standard)
      'animationSpeed': animationSpeed.name,
    if (!playMoveSound) 'playMoveSound': false,
    if (!playSelectionSound) 'playSelectionSound': false,
    if (!playCaptureSound) 'playCaptureSound': false,
    if (!playCheckSound) 'playCheckSound': false,
    if (!playMateSound) 'playMateSound': false,
    if (speakMoves) 'speakMoves': true,
    if (textSize != TextSizePreference.system) 'textSize': textSize.name,
    if (!showCoordinates) 'showCoordinates': false,
    if (rotateOppositePieces) 'rotateOppositePieces': true,
    if (boardSkin != BoardSkin.parchment) 'boardSkin': boardSkin.name,
    if (boardGeometries.values.any(
      (geometry) => geometry != BoardSkinGeometry(),
    ))
      'boardGeometries': {
        for (final entry in boardGeometries.entries)
          if (entry.value != BoardSkinGeometry())
            entry.key.name: entry.value.toJson(),
      },
    if (pieceSkinShadows.entries.any(
      (entry) => entry.value != _defaultShadow(entry.key),
    ))
      'pieceSkinShadows': {
        for (final entry in pieceSkinShadows.entries)
          if (entry.value != _defaultShadow(entry.key))
            entry.key.name: entry.value.toJson(),
      },
    if (pieceSkin != PieceSkin.roundSeal) 'pieceSkin': pieceSkin.name,
    if (selectedPieceSkinId != pieceSkin.name)
      'selectedPieceSkinId': selectedPieceSkinId,
    if (pieceSizePercent != 100) 'pieceSizePercent': pieceSizePercent,
    if (roundSealPieceScalePercent != 100)
      'roundSealPieceScalePercent': roundSealPieceScalePercent,
    if (squareInkPieceScalePercent != 100)
      'squareInkPieceScalePercent': squareInkPieceScalePercent,
    if (roundSealPieceOffsetX != 0)
      'roundSealPieceOffsetX': roundSealPieceOffsetX,
    if (roundSealPieceOffsetY != 0)
      'roundSealPieceOffsetY': roundSealPieceOffsetY,
    if (squareInkPieceOffsetX != 0)
      'squareInkPieceOffsetX': squareInkPieceOffsetX,
    if (squareInkPieceOffsetY != 0)
      'squareInkPieceOffsetY': squareInkPieceOffsetY,
    if (!showAnalysisArrows) 'showAnalysisArrows': false,
    if (!showVariationArrows) 'showVariationArrows': false,
    if (!showEvaluationBar) 'showEvaluationBar': false,
    if (!showMoveGrades) 'showMoveGrades': false,
    if (arrowHead != ArrowHeadStyle.standard) 'arrowHead': arrowHead.name,
    'threads': threads,
    'hashMb': hashMb,
    'multiPv': multiPv,
    'thinkTimeMs': thinkTimeMs,
    if (recordPlaybackIntervalMs != 2000)
      'recordPlaybackIntervalMs': recordPlaybackIntervalMs,
    if (!showMoveList) 'showMoveList': false,
    if (!showRecordPlaybackButton) 'showRecordPlaybackButton': false,
    if (showPanelSwitchBar) 'showPanelSwitchBar': true,
    if (activeSidePanel != SidePanel.play)
      'activeSidePanel': activeSidePanel.name,
    if (guideVersion != 0) 'guideVersion': guideVersion,
    if (!_listEquals(sidePanelOrder, defaultSidePanelOrder))
      'sidePanelOrder': sidePanelOrder.map((panel) => panel.name).toList(),
    if (!_listEquals(visibleSidePanels, defaultSidePanelOrder))
      'visibleSidePanels': visibleSidePanels
          .map((panel) => panel.name)
          .toList(),
  };
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        (json.containsKey('reviewMode') && json['reviewMode'] is! String) ||
        (json.containsKey('selectionStyle') &&
            json['selectionStyle'] is! String) ||
        (json.containsKey('lastMoveMarker') &&
            json['lastMoveMarker'] is! String) ||
        (json.containsKey('showMoveGrades') &&
            json['showMoveGrades'] is! bool) ||
        (json.containsKey('showEvaluationBar') &&
            json['showEvaluationBar'] is! bool) ||
        (json.containsKey('showVariationArrows') &&
            json['showVariationArrows'] is! bool) ||
        (json.containsKey('showAnalysisArrows') &&
            json['showAnalysisArrows'] is! bool) ||
        (json.containsKey('arrowHead') && json['arrowHead'] is! String) ||
        json['theme'] is! String ||
        (json.containsKey('textSize') && json['textSize'] is! String) ||
        (json.containsKey('animationSpeed') &&
            json['animationSpeed'] is! String) ||
        (json.containsKey('playMoveSound') && json['playMoveSound'] is! bool) ||
        (json.containsKey('playSelectionSound') &&
            json['playSelectionSound'] is! bool) ||
        (json.containsKey('playCaptureSound') &&
            json['playCaptureSound'] is! bool) ||
        (json.containsKey('playCheckSound') &&
            json['playCheckSound'] is! bool) ||
        (json.containsKey('playMateSound') && json['playMateSound'] is! bool) ||
        (json.containsKey('speakMoves') && json['speakMoves'] is! bool) ||
        (json.containsKey('showCoordinates') &&
            json['showCoordinates'] is! bool) ||
        (json.containsKey('rotateOppositePieces') &&
            json['rotateOppositePieces'] is! bool) ||
        (json.containsKey('boardSkin') && json['boardSkin'] is! String) ||
        (json.containsKey('boardGeometries') &&
            json['boardGeometries'] is! Map) ||
        (json.containsKey('pieceSkinShadows') &&
            json['pieceSkinShadows'] is! Map) ||
        (json.containsKey('pieceSkin') && json['pieceSkin'] is! String) ||
        (json.containsKey('selectedPieceSkinId') &&
            json['selectedPieceSkinId'] is! String) ||
        (json.containsKey('guideVersion') && json['guideVersion'] is! int) ||
        (json.containsKey('recordPlaybackIntervalMs') &&
            json['recordPlaybackIntervalMs'] is! int) ||
        (json.containsKey('showMoveList') && json['showMoveList'] is! bool) ||
        (json.containsKey('showRecordPlaybackButton') &&
            json['showRecordPlaybackButton'] is! bool) ||
        (json.containsKey('showPanelSwitchBar') &&
            json['showPanelSwitchBar'] is! bool) ||
        (json.containsKey('activeSidePanel') &&
            (json['activeSidePanel'] is! String ||
                !SidePanel.values.any(
                  (panel) => panel.name == json['activeSidePanel'],
                ))) ||
        (json.containsKey('sidePanelOrder') &&
            (json['sidePanelOrder'] is! List ||
                (json['sidePanelOrder'] as List).any(
                  (item) => item is! String,
                ))) ||
        (json.containsKey('visibleSidePanels') &&
            (json['visibleSidePanels'] is! List ||
                (json['visibleSidePanels'] as List).any(
                  (item) => item is! String,
                ))) ||
        (json.containsKey('pieceSizePercent') &&
            json['pieceSizePercent'] is! int) ||
        (json.containsKey('roundSealPieceScalePercent') &&
            json['roundSealPieceScalePercent'] is! int) ||
        (json.containsKey('squareInkPieceScalePercent') &&
            json['squareInkPieceScalePercent'] is! int) ||
        (json.containsKey('roundSealPieceOffsetX') &&
            json['roundSealPieceOffsetX'] is! int) ||
        (json.containsKey('roundSealPieceOffsetY') &&
            json['roundSealPieceOffsetY'] is! int) ||
        (json.containsKey('squareInkPieceOffsetX') &&
            json['squareInkPieceOffsetX'] is! int) ||
        (json.containsKey('squareInkPieceOffsetY') &&
            json['squareInkPieceOffsetY'] is! int) ||
        ![
          'threads',
          'hashMb',
          'multiPv',
          'thinkTimeMs',
        ].every((key) => json[key] is int)) {
      throw const FormatException('Unsupported preferences schema');
    }
    try {
      return AppPreferences(
        reviewMode: ReviewMode.values.byName(
          json['reviewMode'] as String? ?? 'best',
        ),
        selectionStyle: SelectionStyle.values.byName(
          json['selectionStyle'] as String? ?? 'lift',
        ),
        lastMoveMarker: LastMoveMarkerStyle.values.byName(
          json['lastMoveMarker'] as String? ?? 'halo',
        ),
        showEvaluationBar: json['showEvaluationBar'] as bool? ?? true,
        showMoveGrades: json['showMoveGrades'] as bool? ?? true,
        showVariationArrows: json['showVariationArrows'] as bool? ?? true,
        showAnalysisArrows: json['showAnalysisArrows'] as bool? ?? true,
        arrowHead: ArrowHeadStyle.values.byName(
          json['arrowHead'] as String? ?? 'standard',
        ),
        theme: ThemePreference.values.byName(json['theme'] as String),
        animationSpeed: AnimationSpeed.values.byName(
          json['animationSpeed'] as String? ?? 'standard',
        ),
        playMoveSound: json['playMoveSound'] as bool? ?? true,
        playSelectionSound: json['playSelectionSound'] as bool? ?? true,
        playCaptureSound: json['playCaptureSound'] as bool? ?? true,
        playCheckSound: json['playCheckSound'] as bool? ?? true,
        playMateSound: json['playMateSound'] as bool? ?? true,
        speakMoves: json['speakMoves'] as bool? ?? false,
        textSize: TextSizePreference.values.byName(
          json['textSize'] as String? ?? 'system',
        ),
        threads: json['threads'] as int,
        showCoordinates: json['showCoordinates'] as bool? ?? true,
        rotateOppositePieces: json['rotateOppositePieces'] as bool? ?? false,
        boardSkin: BoardSkin.values.byName(
          json['boardSkin'] as String? ?? 'parchment',
        ),
        boardGeometries: _decodeBoardGeometries(json['boardGeometries']),
        pieceSkinShadows: _decodePieceSkinShadows(json['pieceSkinShadows']),
        pieceSkin: PieceSkin.values.byName(
          json['pieceSkin'] as String? ?? 'roundSeal',
        ),
        selectedPieceSkinId:
            json['selectedPieceSkinId'] as String? ??
            (json['pieceSkin'] as String? ?? 'roundSeal'),
        pieceSizePercent: json['pieceSizePercent'] as int? ?? 100,
        roundSealPieceScalePercent:
            json['roundSealPieceScalePercent'] as int? ?? 100,
        squareInkPieceScalePercent:
            json['squareInkPieceScalePercent'] as int? ?? 100,
        roundSealPieceOffsetX: json['roundSealPieceOffsetX'] as int? ?? 0,
        roundSealPieceOffsetY: json['roundSealPieceOffsetY'] as int? ?? 0,
        squareInkPieceOffsetX: json['squareInkPieceOffsetX'] as int? ?? 0,
        squareInkPieceOffsetY: json['squareInkPieceOffsetY'] as int? ?? 0,
        hashMb: json['hashMb'] as int,
        multiPv: json['multiPv'] as int,
        thinkTimeMs: json['thinkTimeMs'] as int,
        recordPlaybackIntervalMs:
            json['recordPlaybackIntervalMs'] as int? ?? 2000,
        showMoveList: json['showMoveList'] as bool? ?? true,
        showRecordPlaybackButton:
            json['showRecordPlaybackButton'] as bool? ?? true,
        showPanelSwitchBar: json['showPanelSwitchBar'] as bool? ?? false,
        activeSidePanel: SidePanel.values.firstWhere(
          (panel) => panel.name == json['activeSidePanel'],
          orElse: () => SidePanel.play,
        ),
        guideVersion: json['guideVersion'] as int? ?? 0,
        sidePanelOrder:
            (json['sidePanelOrder'] as List?)
                ?.map((item) => SidePanel.values.byName(item as String))
                .toList() ??
            defaultSidePanelOrder,
        visibleSidePanels:
            (json['visibleSidePanels'] as List?)
                ?.map((item) => SidePanel.values.byName(item as String))
                .toList() ??
            defaultSidePanelOrder,
      );
    } on ArgumentError {
      throw const FormatException('Invalid preference value');
    }
  }

  static Map<BoardSkin, BoardSkinGeometry> _decodeBoardGeometries(
    Object? value,
  ) {
    if (value == null) return const {};
    final result = <BoardSkin, BoardSkinGeometry>{};
    for (final entry in (value as Map).entries) {
      if (entry.key is! String ||
          entry.value is! Map ||
          (entry.value as Map).keys.any((key) => key is! String)) {
        throw const FormatException('Invalid board geometry map');
      }
      final skin = BoardSkin.values.byName(entry.key as String);
      result[skin] = BoardSkinGeometry.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return result;
  }

  static PieceSkinShadow _defaultShadow(PieceSkin skin) =>
      skin == PieceSkin.roundSeal
      ? const PieceSkinShadow.roundSealDefault()
      : const PieceSkinShadow.standard();

  static Map<PieceSkin, PieceSkinShadow> _decodePieceSkinShadows(
    Object? value,
  ) {
    if (value == null) return const {};
    final result = <PieceSkin, PieceSkinShadow>{};
    for (final entry in (value as Map).entries) {
      if (entry.key is! String ||
          entry.value is! Map ||
          (entry.value as Map).keys.any((key) => key is! String)) {
        throw const FormatException('Invalid piece skin shadow map');
      }
      final skin = PieceSkin.values.byName(entry.key as String);
      result[skin] = PieceSkinShadow.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      reviewMode == other.reviewMode &&
      selectionStyle == other.selectionStyle &&
      lastMoveMarker == other.lastMoveMarker &&
      showEvaluationBar == other.showEvaluationBar &&
      showMoveGrades == other.showMoveGrades &&
      showVariationArrows == other.showVariationArrows &&
      showAnalysisArrows == other.showAnalysisArrows &&
      arrowHead == other.arrowHead &&
      theme == other.theme &&
      animationSpeed == other.animationSpeed &&
      playMoveSound == other.playMoveSound &&
      playSelectionSound == other.playSelectionSound &&
      playCaptureSound == other.playCaptureSound &&
      playCheckSound == other.playCheckSound &&
      playMateSound == other.playMateSound &&
      speakMoves == other.speakMoves &&
      textSize == other.textSize &&
      showCoordinates == other.showCoordinates &&
      rotateOppositePieces == other.rotateOppositePieces &&
      boardSkin == other.boardSkin &&
      _mapEquals(boardGeometries, other.boardGeometries) &&
      _mapEquals(pieceSkinShadows, other.pieceSkinShadows) &&
      pieceSkin == other.pieceSkin &&
      selectedPieceSkinId == other.selectedPieceSkinId &&
      pieceSizePercent == other.pieceSizePercent &&
      roundSealPieceScalePercent == other.roundSealPieceScalePercent &&
      squareInkPieceScalePercent == other.squareInkPieceScalePercent &&
      roundSealPieceOffsetX == other.roundSealPieceOffsetX &&
      roundSealPieceOffsetY == other.roundSealPieceOffsetY &&
      squareInkPieceOffsetX == other.squareInkPieceOffsetX &&
      squareInkPieceOffsetY == other.squareInkPieceOffsetY &&
      threads == other.threads &&
      hashMb == other.hashMb &&
      multiPv == other.multiPv &&
      thinkTimeMs == other.thinkTimeMs &&
      guideVersion == other.guideVersion &&
      recordPlaybackIntervalMs == other.recordPlaybackIntervalMs &&
      showMoveList == other.showMoveList &&
      showRecordPlaybackButton == other.showRecordPlaybackButton &&
      showPanelSwitchBar == other.showPanelSwitchBar &&
      activeSidePanel == other.activeSidePanel &&
      _listEquals(sidePanelOrder, other.sidePanelOrder) &&
      _listEquals(visibleSidePanels, other.visibleSidePanels);
  @override
  int get hashCode => Object.hashAll([
    reviewMode,
    selectionStyle,
    lastMoveMarker,
    showEvaluationBar,
    showMoveGrades,
    showVariationArrows,
    showAnalysisArrows,
    arrowHead,
    theme,
    animationSpeed,
    playMoveSound,
    playSelectionSound,
    playCaptureSound,
    playCheckSound,
    playMateSound,
    speakMoves,
    textSize,
    showCoordinates,
    rotateOppositePieces,
    boardSkin,
    Object.hashAll(
      boardGeometries.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(
      pieceSkinShadows.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    pieceSkin,
    selectedPieceSkinId,
    pieceSizePercent,
    roundSealPieceScalePercent,
    squareInkPieceScalePercent,
    roundSealPieceOffsetX,
    roundSealPieceOffsetY,
    squareInkPieceOffsetX,
    squareInkPieceOffsetY,
    threads,
    hashMb,
    multiPv,
    thinkTimeMs,
    guideVersion,
    recordPlaybackIntervalMs,
    showMoveList,
    showRecordPlaybackButton,
    showPanelSwitchBar,
    activeSidePanel,
    Object.hashAll(sidePanelOrder),
    Object.hashAll(visibleSidePanels),
  ]);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
