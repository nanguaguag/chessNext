import 'application/board_evaluation.dart';
import 'features/analysis/evaluation_board.dart';
import 'ports/record_file_exporter.dart';
import 'ports/png_file_exporter.dart';
import 'ports/image_clipboard.dart';
import 'ports/gif_file_exporter.dart';
import 'application/board_image_snapshot.dart';
import 'application/board_gif_snapshot.dart';
import 'features/export/board_image_dialog.dart';
import 'features/export/board_gif_dialog.dart';
import 'features/settings/app_text_scaling.dart';
import 'features/board/board_display_scope.dart';
import 'features/transfer/import_file_dialog.dart';
import 'ports/record_file_picker.dart';
import 'application/record_text_exchange.dart';
import 'features/metadata/record_metadata_dialog.dart';
import 'features/help/onboarding_dialog.dart';
import 'features/help/offline_help_dialog.dart';
import 'application/recent_reading_controller.dart';
import 'ports/recent_reading_repository.dart';
import 'features/library/recent_reading_dialog.dart';
import 'ports/review_cache_repository.dart';
import 'features/review/review_panel.dart';
import 'features/review/candidate_panel.dart';
import 'features/records/move_list.dart';
import 'features/records/variation_panel.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'application/app_preferences.dart';
import 'application/board_skin_geometry.dart';
import 'application/preferences_controller.dart';
import 'ports/preferences_repository.dart';
import 'features/settings/preferences_dialog.dart';
import 'dart:ui' show AppExitResponse;
import 'dart:async';
import 'application/draft_controller.dart';
import 'ports/draft_repository.dart';
import 'features/drafts/draft_status_bar.dart';
import 'adapters/platform/flutter_text_clipboard.dart';
import 'ports/text_clipboard.dart';
import 'features/transfer/text_transfer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'application/board_session.dart';
import 'application/engine_session_controller.dart';
import 'features/analysis/analysis_panel.dart';
import 'features/play/play_panel.dart';
import 'features/editor/editor_page.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import 'application/library_controller.dart';
import 'ports/game_repository.dart';
import 'features/library/library_dialog.dart';
import 'features/board/xiangqi_board.dart';
import 'application/board_feedback_controller.dart';
import 'ports/audio_feedback.dart';
import 'ports/move_speech.dart';
import 'application/audio_library_controller.dart';
import 'ports/audio_library.dart';
import 'application/piece_image_library_controller.dart';
import 'ports/piece_images.dart';
import 'application/board_skin_image_library_controller.dart';
import 'ports/board_skin_images.dart';
import 'ports/piece_skin_library.dart';
import 'application/piece_skin_library_controller.dart';

class ChessNextApp extends StatefulWidget {
  const ChessNextApp({
    super.key,
    this.repository,
    this.recentReadingRepository,
    this.draftRepository,
    this.preferencesRepository,
    this.clipboard,
    this.filePicker,
    this.fileExporter,
    this.pngExporter,
    this.imageClipboard,
    this.audioFeedback,
    this.moveSpeech,
    this.audioFilePicker,
    this.audioOverrides,
    this.pieceImagePicker,
    this.pieceImageRepository,
    this.pieceSkinLibraryRepository,
    this.boardSkinImagePicker,
    this.boardSkinImageRepository,
    this.gifExporter,
    this.engineFactory,
    this.reviewCache,
    this.deviceThreads = 1,
    this.showFirstRunGuide = false,
  });
  final PreferencesRepository? preferencesRepository;
  final DraftRepository? draftRepository;
  final TextClipboard? clipboard;
  final RecordFilePicker? filePicker;
  final RecordFileExporter? fileExporter;
  final PngFileExporter? pngExporter;
  final ImageClipboard? imageClipboard;
  final AudioFeedbackPort? audioFeedback;
  final MoveSpeechPort? moveSpeech;
  final AudioFilePicker? audioFilePicker;
  final AudioOverrideRepository? audioOverrides;
  final PieceImagePicker? pieceImagePicker;
  final PieceImageRepository? pieceImageRepository;
  final PieceSkinLibraryRepository? pieceSkinLibraryRepository;
  final PieceImagePicker? boardSkinImagePicker;
  final BoardSkinImageRepository? boardSkinImageRepository;
  final GifFileExporter? gifExporter;
  final EngineFactory? engineFactory;
  final ReviewCacheRepository? reviewCache;
  final int deviceThreads;
  final bool showFirstRunGuide;
  final GameRepository? repository;
  final RecentReadingRepository? recentReadingRepository;
  @override
  State<ChessNextApp> createState() => _ChessNextAppState();
}

class _ChessNextAppState extends State<ChessNextApp>
    with WidgetsBindingObserver {
  final session = BoardSession();
  late final LibraryController library;
  late final RecentReadingController readings;
  late final DraftController? drafts;
  late final PreferencesController preferences;
  late final BoardFeedbackController boardFeedback;
  late final AudioLibraryController? audioLibrary;
  late final PieceImageLibraryController pieceImages;
  late final PieceSkinLibraryController pieceSkins;
  late final BoardSkinImageLibraryController boardSkinImages;
  late final EngineSessionController analysis;
  BoardGifSettings gifSettings = BoardGifSettings();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analysis = EngineSessionController(
      session,
      widget.engineFactory,
      deviceThreads: widget.deviceThreads,
      reviewCache: widget.reviewCache,
    );
    library = LibraryController(
      session,
      widget.repository ?? MemoryGameRepository(),
    );
    readings = RecentReadingController(
      library,
      widget.recentReadingRepository ?? MemoryRecentReadingRepository(),
    );
    unawaited(readings.initialize());
    drafts = widget.draftRepository == null
        ? null
        : DraftController(session, library, widget.draftRepository!);
    if (drafts != null) unawaited(drafts!.initialize());
    preferences = PreferencesController(
      analysis,
      widget.preferencesRepository ?? MemoryPreferencesRepository(),
    );
    final audio = widget.audioFeedback ?? const SilentAudioFeedback();
    audioLibrary =
        widget.audioFilePicker == null || widget.audioOverrides == null
        ? null
        : AudioLibraryController(
            widget.audioFilePicker!,
            widget.audioOverrides!,
            audio,
          );
    if (audioLibrary != null) unawaited(audioLibrary!.initialize());
    pieceImages = PieceImageLibraryController(
      widget.pieceImagePicker ?? const CancelPieceImagePicker(),
      widget.pieceImageRepository ?? MemoryPieceImageRepository(),
    );
    pieceImages.addListener(_preferencesChanged);
    unawaited(pieceImages.initialize());
    pieceSkins = PieceSkinLibraryController(
      widget.pieceSkinLibraryRepository ?? MemoryPieceSkinLibraryRepository(),
      pieceImages,
      preferences,
    );
    pieceSkins.addListener(_preferencesChanged);
    boardSkinImages = BoardSkinImageLibraryController(
      widget.boardSkinImagePicker ?? const CancelPieceImagePicker(),
      widget.boardSkinImageRepository ?? MemoryBoardSkinImageRepository(),
    );
    boardSkinImages.addListener(_preferencesChanged);
    unawaited(boardSkinImages.initialize());
    boardFeedback = BoardFeedbackController(
      session,
      preferences,
      audio,
      widget.moveSpeech ?? const SilentMoveSpeech(),
      widget.audioOverrides,
    );
    preferences.addListener(_preferencesChanged);
    unawaited(_initializePreferences());
  }

  bool _guideOpen = false;
  Future<void> _initializePreferences() async {
    await preferences.initialize();
    await pieceSkins.initialize();
    if (!mounted ||
        !widget.showFirstRunGuide ||
        preferences.error != null ||
        preferences.value.guideVersion >= AppPreferences.currentGuideVersion) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && navigatorKey.currentState?.canPop() == false) {
        unawaited(_showGuide());
      }
    });
  }

  Future<void> _rememberGuide({bool retry = false}) async {
    if (retry) await preferences.initialize();
    final saved = await preferences.markGuideSeen();
    if (!mounted || saved) return;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(preferences.error ?? '引导标记未能保存，下次启动可能再次显示。'),
        action: SnackBarAction(
          label: '重试',
          onPressed: () => unawaited(_rememberGuide(retry: true)),
        ),
      ),
    );
  }

  Future<void> _showGuide() async {
    final context = navigatorKey.currentContext;
    if (!mounted || _guideOpen || context == null) return;
    _guideOpen = true;
    try {
      final result = await showDialog<GuideExit>(
        context: context,
        builder: (_) => const OnboardingDialog(),
      );
      if (mounted && result != null) await _rememberGuide();
    } finally {
      _guideOpen = false;
    }
  }

  void _preferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      final desktop = {
        foundation.TargetPlatform.macOS,
        foundation.TargetPlatform.windows,
        foundation.TargetPlatform.linux,
      }.contains(foundation.defaultTargetPlatform);
      if (!desktop || state != AppLifecycleState.inactive) {
        unawaited(analysis.disable());
      }
      if (drafts != null) unawaited(drafts!.flush());
      unawaited(preferences.flush());
      unawaited(readings.flush());
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await analysis.disable();
    await drafts?.flush();
    await preferences.flush();
    await readings.flush();
    if (!mounted) return AppExitResponse.exit;
    if (session.dirty &&
        (drafts == null || drafts!.error != null || !drafts!.canSave)) {
      final dialogContext = navigatorKey.currentContext;
      if (dialogContext == null || !dialogContext.mounted) {
        return AppExitResponse.cancel;
      }
      final exit = await showDialog<bool>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('当前修改尚未安全保存'),
          content: const Text('自动草稿未能保存当前修改。返回后可重试或手动保存棋谱；继续退出可能丢失修改。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('返回应用'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('仍然退出'),
            ),
          ],
        ),
      );
      return exit == true ? AppExitResponse.exit : AppExitResponse.cancel;
    }
    return AppExitResponse.exit;
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  ThemeMode get mode => switch (preferences.value.theme) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    preferences.removeListener(_preferencesChanged);
    unawaited(boardFeedback.dispose());
    audioLibrary?.dispose();
    pieceImages.removeListener(_preferencesChanged);
    pieceSkins.removeListener(_preferencesChanged);
    pieceSkins.dispose();
    pieceImages.dispose();
    boardSkinImages.removeListener(_preferencesChanged);
    boardSkinImages.dispose();
    unawaited(preferences.flush());
    preferences.dispose();
    analysis.dispose();
    if (drafts != null) {
      unawaited(drafts!.flush());
      drafts!.dispose();
    }
    unawaited(readings.flush());
    readings.dispose();
    library.dispose();
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    scaffoldMessengerKey: messengerKey,
    title: 'chessNext',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff41634c),
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xff41634c),
      brightness: Brightness.dark,
    ),
    themeMode: mode,
    builder: (context, child) => AppTextScaling(
      preference: preferences.value.textSize,
      child: BoardDisplayScope(
        selectionStyle: preferences.value.selectionStyle,
        lastMoveMarker: preferences.value.lastMoveMarker,
        animationSpeed: preferences.value.animationSpeed,
        showCoordinates: preferences.value.showCoordinates,
        rotateOppositePieces: preferences.value.rotateOppositePieces,
        boardSkin: preferences.value.boardSkin,
        geometry:
            preferences.value.boardGeometries[preferences.value.boardSkin] ??
            const BoardSkinGeometry.standard(),
        boardSkinImages: boardSkinImages.imagesFor(preferences.value.boardSkin),
        pieceSkin: preferences.value.pieceSkin,
        pieceSkinShadow:
            pieceSkins
                .definitionFor(preferences.value.selectedPieceSkinId)
                ?.shadow ??
            preferences.value.pieceSkinShadows[preferences.value.pieceSkin],
        pieceImages: pieceImages.imagesFor(
          preferences.value.selectedPieceSkinId,
        ),
        pieceSizePercent: preferences.value.pieceSizePercent,
        pieceSkinSizePercent:
            pieceSkins
                .definitionFor(preferences.value.selectedPieceSkinId)
                ?.scalePercent ??
            (preferences.value.pieceSkin == PieceSkin.roundSeal
                ? preferences.value.roundSealPieceScalePercent
                : preferences.value.squareInkPieceScalePercent),
        pieceSkinOffsetXPercent:
            pieceSkins
                .definitionFor(preferences.value.selectedPieceSkinId)
                ?.offsetXPercent ??
            (preferences.value.pieceSkin == PieceSkin.roundSeal
                ? preferences.value.roundSealPieceOffsetX
                : preferences.value.squareInkPieceOffsetX),
        pieceSkinOffsetYPercent:
            pieceSkins
                .definitionFor(preferences.value.selectedPieceSkinId)
                ?.offsetYPercent ??
            (preferences.value.pieceSkin == PieceSkin.roundSeal
                ? preferences.value.roundSealPieceOffsetY
                : preferences.value.squareInkPieceOffsetY),
        showAnalysisArrows: preferences.value.showAnalysisArrows,
        showVariationArrows: preferences.value.showVariationArrows,
        showMoveGrades: preferences.value.showMoveGrades,
        arrowHead: preferences.value.arrowHead,
        child: child!,
      ),
    ),
    home: _BoardPage(
      drafts: drafts,
      preferences: preferences,
      audioLibrary: audioLibrary,
      pieceImages: pieceImages,
      pieceSkins: pieceSkins,
      boardSkinImages: boardSkinImages,
      clipboard: widget.clipboard ?? FlutterTextClipboard(),
      filePicker: widget.filePicker,
      fileExporter: widget.fileExporter,
      pngExporter: widget.pngExporter,
      imageClipboard: widget.imageClipboard,
      gifExporter: widget.gifExporter,
      gifSettings: gifSettings,
      onGifSettingsChanged: (value) => setState(() => gifSettings = value),
      session: session,
      library: library,
      readings: readings,
      analysis: analysis,
      showGuide: _showGuide,
      toggleTheme: () => unawaited(
        preferences.setTheme(
          mode == ThemeMode.dark ? ThemePreference.light : ThemePreference.dark,
        ),
      ),
    ),
  );
}

class _BoardPage extends StatelessWidget {
  const _BoardPage({
    required this.session,
    required this.clipboard,
    this.filePicker,
    this.fileExporter,
    this.pngExporter,
    this.imageClipboard,
    this.gifExporter,
    required this.gifSettings,
    required this.onGifSettingsChanged,
    required this.toggleTheme,
    required this.showGuide,
    required this.library,
    required this.readings,
    required this.analysis,
    this.drafts,
    required this.preferences,
    this.audioLibrary,
    required this.pieceImages,
    required this.pieceSkins,
    required this.boardSkinImages,
  });
  final PreferencesController preferences;
  final AudioLibraryController? audioLibrary;
  final PieceImageLibraryController pieceImages;
  final PieceSkinLibraryController pieceSkins;
  final BoardSkinImageLibraryController boardSkinImages;
  final DraftController? drafts;
  final TextClipboard clipboard;
  final RecordFilePicker? filePicker;
  final RecordFileExporter? fileExporter;
  final PngFileExporter? pngExporter;
  final ImageClipboard? imageClipboard;
  final GifFileExporter? gifExporter;
  final BoardGifSettings gifSettings;
  final ValueChanged<BoardGifSettings> onGifSettingsChanged;
  final BoardSession session;
  final VoidCallback toggleTheme;
  final Future<void> Function() showGuide;
  final LibraryController library;
  final RecentReadingController readings;
  final EngineSessionController analysis;
  Widget _branchButton(String? target, String tooltip, IconData icon) {
    final epoch = session.epoch;
    final revision = session.revision;
    final positionRevision = session.positionRevision;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: target == null
          ? null
          : () {
              if (session.epoch == epoch &&
                  session.revision == revision &&
                  session.positionRevision == positionRevision &&
                  session.tree.hasNode(target)) {
                unawaited(analysis.navigateToNode(target));
              }
            },
    );
  }

  Future<void> _newGame(BuildContext context) async {
    if (session.dirty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('开始新局？'),
          content: const Text('开始新局会替换当前棋谱及资料，请先保存需要保留的修改。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('开始新局'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    library.newGame();
  }

  Future<bool> _save(BuildContext context) async {
    var entered = library.title;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存到本地棋谱库'),
        content: TextFormField(
          key: const ValueKey('record-name'),
          initialValue: entered,
          autofocus: true,
          maxLength: 120,
          onChanged: (value) => entered = value,
          decoration: const InputDecoration(labelText: '棋谱名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, entered),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name == null) return false;
    final saved = await library.save(name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? '棋谱已保存到本地' : library.error ?? '保存失败')),
      );
    }
    return saved;
  }

  Future<void> _edit(BuildContext context) async {
    await analysis.disable();
    if (!context.mounted) return;
    if (session.dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('编辑前保留当前棋谱？'),
          content: const Text('完成编辑后会以新局面替换当前棋谱，取消编辑则保留原棋谱。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'continue'),
              child: const Text('继续编辑'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('先保存'),
            ),
          ],
        ),
      );
      if (choice == null || !context.mounted) return;
      if (choice == 'save' && (!await _save(context) || !context.mounted)) {
        return;
      }
    }
    if (!context.mounted) return;
    final before = session.position.toFen();
    final result = await Navigator.push<Position>(
      context,
      MaterialPageRoute(
        builder: (context) => EditorPage(initial: session.position),
      ),
    );
    if (context.mounted && result != null && result.toFen() != before) {
      library.startPosition(result);
    }
  }

  Future<void> _import(BuildContext context, {bool fromFile = false}) async {
    await analysis.disable();
    if (!context.mounted) return;
    final epoch = session.epoch;
    final revision = session.revision;
    final positionRevision = session.positionRevision;
    bool current() =>
        session.epoch == epoch &&
        session.revision == revision &&
        session.positionRevision == positionRevision;
    void stale() => ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('导入期间棋谱已变化，请重新导入。')));
    final imported = await showDialog<ImportedRecord>(
      context: context,
      builder: (_) => fromFile
          ? ImportFileDialog(picker: filePicker!)
          : ImportTextDialog(clipboard: clipboard),
    );
    if (imported == null || !context.mounted) return;
    if (!current()) {
      stale();
      return;
    }
    if (session.dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入前保留当前棋谱？'),
          content: const Text('导入成功后将替换当前棋谱及资料。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'replace'),
              child: const Text('替换'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('先保存'),
            ),
          ],
        ),
      );
      if (choice == null || !context.mounted) return;
      if (!current()) {
        stale();
        return;
      }
      if (choice == 'save' && (!await _save(context) || !context.mounted)) {
        return;
      }
      if (!current()) {
        stale();
        return;
      }
    }
    library.importTree(
      imported.tree,
      metadata: imported.metadata,
      title: imported.source == TextSourceFormat.pgn ? '导入PGN棋谱' : '导入棋谱',
    );
  }

  Future<void> _export(BuildContext context) async {
    final tree = session.tree;
    final metadata = session.metadata;
    await showDialog<void>(
      context: context,
      builder: (_) => ExportTextDialog(
        tree: tree,
        metadata: metadata,
        clipboard: clipboard,
        fileExporter: fileExporter,
      ),
    );
  }

  Future<void> _exportImage(BuildContext context) async {
    final snapshot = BoardImageSnapshot.capture(
      session,
      preferences.value,
      pieceSkinSizePercent: pieceSkins
          .definitionFor(preferences.value.selectedPieceSkinId)
          ?.scalePercent,
      pieceSkinOffsetXPercent: pieceSkins
          .definitionFor(preferences.value.selectedPieceSkinId)
          ?.offsetXPercent,
      pieceSkinOffsetYPercent: pieceSkins
          .definitionFor(preferences.value.selectedPieceSkinId)
          ?.offsetYPercent,
      pieceSkinShadow: pieceSkins
          .definitionFor(preferences.value.selectedPieceSkinId)
          ?.shadow,
      assessment: analysis.currentMoveAssessment,
      recommendation: analysis.recommended,
      reply: analysis.reply,
      pieceImages: pieceImages.imagesFor(preferences.value.selectedPieceSkinId),
      boardSkinImages: boardSkinImages.imagesFor(preferences.value.boardSkin),
    );
    await showDialog<void>(
      context: context,
      builder: (_) => BoardImageDialog(
        snapshot: snapshot,
        exporter: pngExporter,
        clipboard: imageClipboard,
      ),
    );
  }

  Future<void> _exportGif(BuildContext context) async {
    BoardGifSnapshot snapshot;
    try {
      snapshot = BoardGifSnapshot.capture(
        session,
        preferences.value,
        pieceSkinSizePercent: pieceSkins
            .definitionFor(preferences.value.selectedPieceSkinId)
            ?.scalePercent,
        pieceSkinOffsetXPercent: pieceSkins
            .definitionFor(preferences.value.selectedPieceSkinId)
            ?.offsetXPercent,
        pieceSkinOffsetYPercent: pieceSkins
            .definitionFor(preferences.value.selectedPieceSkinId)
            ?.offsetYPercent,
        pieceSkinShadow: pieceSkins
            .definitionFor(preferences.value.selectedPieceSkinId)
            ?.shadow,
        pieceImages: pieceImages.imagesFor(
          preferences.value.selectedPieceSkinId,
        ),
        boardSkinImages: boardSkinImages.imagesFor(preferences.value.boardSkin),
      );
    } on BoardGifCapacityException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('所选线路有${error.frames}帧，GIF最多支持64帧；请缩短线路后重试。')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => BoardGifDialog(
        snapshot: snapshot,
        initialSettings: gifSettings,
        onSettingsChanged: onGifSettingsChanged,
        exporter: gifExporter,
      ),
    );
  }

  Future<void> _restoreDraft(BuildContext context) async {
    await analysis.disable();
    if (!context.mounted || drafts?.pending == null) return;
    var replace = false;
    if (session.dirty) {
      replace =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('用草稿替换当前棋谱？'),
              content: const Text('当前棋谱有未保存的修改。取消后可先保存当前棋谱，再恢复草稿。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('恢复'),
                ),
              ],
            ),
          ) ??
          false;
      if (!replace) return;
    }
    if (context.mounted) drafts?.restore(replaceCurrent: replace);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([session, library, analysis, ?drafts]),
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('chessNext'),
        actions: [
          IconButton(
            tooltip: '帮助与按钮说明',
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              final action = await showDialog<HelpAction>(
                context: context,
                builder: (_) => const OfflineHelpDialog(),
              );
              if (action == HelpAction.guide && context.mounted) {
                await showGuide();
              }
            },
          ),
          IconButton(
            tooltip: '应用设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              session.setCurrentVariationArrows(false);
              showDialog<void>(
                context: context,
                builder: (_) => PreferencesDialog(
                  preferences: preferences,
                  audioLibrary: audioLibrary,
                  pieceImages: pieceImages,
                  pieceSkins: pieceSkins,
                  boardSkinImages: boardSkinImages,
                ),
              );
            },
          ),
          IconButton(
            onPressed: toggleTheme,
            tooltip: '切换明暗主题',
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final board = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          session.status,
                          key: const ValueKey('status'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: (constraints.maxWidth - 48 - (wide ? 344 : 0))
                        .clamp(
                          preferences.value.showEvaluationBar ? 492 : 464,
                          540,
                        )
                        .toDouble(),
                    child: EvaluationBoard(
                      visible: preferences.value.showEvaluationBar,
                      flipped: session.flipped,
                      evaluation: BoardEvaluation.fromInfo(
                        turn: session.position.turn,
                        outcome: session.outcome,
                        info: analysis.infos
                            .where((info) => info.multiPv == 1)
                            .firstOrNull,
                        frozen: !analysis.enabled && !analysis.playing,
                      ),
                      child: XiangqiBoard(
                        session: session,
                        assessment: analysis.currentMoveAssessment,
                        recommendation: analysis.recommended,
                        reply: analysis.reply,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session.notice ?? '点选棋子，再选择落点 · 方向键移动，Enter 选子，Esc 取消',
                  style: TextStyle(
                    color: session.notice == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
          final panel = Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本地棋盘',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '自由对弈 · 离线运行',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _newGame(context),
                        icon: const Icon(Icons.add),
                        label: const Text('新局'),
                      ),
                      OutlinedButton.icon(
                        onPressed: session.canUndo
                            ? () => analysis.playing
                                  ? analysis.undoForPlay()
                                  : session.undo()
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('悔棋'),
                      ),
                      OutlinedButton.icon(
                        onPressed: session.flip,
                        icon: const Icon(Icons.flip_camera_android_outlined),
                        label: const Text('翻转'),
                      ),
                      Tooltip(
                        message: '左右镜像，只改变显示方向',
                        child: Semantics(
                          toggled: session.mirrored,
                          child: OutlinedButton.icon(
                            onPressed: session.mirror,
                            icon: const Icon(Icons.flip),
                            label: const Text('左右翻转'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: library.busy ? null : () => _import(context),
                        icon: const Icon(Icons.input),
                        label: const Text('导入文字'),
                      ),
                      if (filePicker != null)
                        OutlinedButton.icon(
                          onPressed: library.busy
                              ? null
                              : () => _import(context, fromFile: true),
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('导入文件'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _export(context),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('导出文字'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportImage(context),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('导出图片'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportGif(context),
                        icon: const Icon(Icons.gif_box_outlined),
                        label: const Text('导出动态图'),
                      ),
                      OutlinedButton.icon(
                        onPressed: library.busy ? null : () => _edit(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('编辑局面'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('棋谱资料'),
                        onPressed: library.busy
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    RecordMetadataDialog(session: session),
                              ),
                      ),
                      OutlinedButton.icon(
                        onPressed: library.busy ? null : () => _save(context),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存棋谱'),
                      ),
                      OutlinedButton.icon(
                        onPressed: library.busy
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (context) =>
                                    LibraryDialog(library: library),
                              ),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('棋谱库'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('最近阅读'),
                        onPressed: library.busy
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    RecentReadingDialog(readings: readings),
                              ),
                      ),
                    ],
                  ),
                  if (library.busy) const LinearProgressIndicator(),
                  if (library.error != null)
                    Text(
                      library.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  Text('着法记录', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (!session.hasMoves) const Text('尚无着法，选择棋子开始对局。'),
                  MoveList(
                    session: session,
                    onNavigate: analysis.navigateToNode,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: session.canUndo
                            ? () =>
                                  analysis.navigateToNode(session.tree.root.id)
                            : null,
                        tooltip: '回到开始',
                        icon: const Icon(Icons.first_page),
                      ),
                      _branchButton(
                        session.readingNavigation.previousBranchId,
                        '上一分支点或开始',
                        Icons.keyboard_double_arrow_left,
                      ),
                      IconButton(
                        onPressed: session.canUndo
                            ? () => analysis.navigateToNode(
                                session.tree.current.parentId!,
                              )
                            : null,
                        tooltip: '上一着',
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: session.canForward
                            ? () => analysis.navigateToNode(session.nextNodeId!)
                            : null,
                        tooltip: '下一着',
                        icon: const Icon(Icons.chevron_right),
                      ),
                      _branchButton(
                        session.readingNavigation.nextBranchId,
                        '下一分支点或末尾',
                        Icons.keyboard_double_arrow_right,
                      ),
                      IconButton(
                        onPressed: session.canForward
                            ? () => analysis.navigateToNode(
                                session.tree.currentLine.last.id,
                              )
                            : null,
                        tooltip: '当前线路末尾',
                        icon: const Icon(Icons.last_page),
                      ),
                    ],
                  ),
                  TextFormField(
                    key: ValueKey('comment-${session.tree.cursorId}'),
                    initialValue: session.tree.current.comment,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) =>
                            newValue.text.length <= 10000 ? newValue : oldValue,
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: '当前局面注释',
                      helperText: '注释按局面保留，回退后走新棋会创建变着',
                    ),
                    maxLines: 3,
                    onChanged: session.annotate,
                  ),
                  VariationPanel(session: session, engine: analysis),
                  const SizedBox(height: 24),
                  Text(
                    session.dirty
                        ? '有未保存到棋谱库的修改。'
                        : library.currentId == null
                        ? '保存到本地棋谱库，可在下次打开时继续。'
                        : '已保存到本地 · ${library.title}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
          final sidePanel = Column(
            children: [
              if (preferences.error != null)
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferences.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        TextButton(
                          onPressed: () => preferences.flush(force: true),
                          child: const Text('重试保存设置'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (drafts != null)
                DraftStatusBar(
                  drafts: drafts!,
                  onRestore: () => _restoreDraft(context),
                ),
              panel,
              const SizedBox(height: 12),
              PlayPanel(engine: analysis),
              const SizedBox(height: 12),
              AnalysisPanel(analysis: analysis),
              const SizedBox(height: 12),
              ReviewPanel(engine: analysis, preferences: preferences),
              const SizedBox(height: 12),
              CandidatePanel(engine: analysis),
            ],
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: board,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 320,
                            child: SingleChildScrollView(child: sidePanel),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            board,
                            const SizedBox(height: 24),
                            sidePanel,
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
