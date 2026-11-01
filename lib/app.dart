import 'package:flutter/foundation.dart' as foundation;
import 'application/app_preferences.dart';
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

class ChessNextApp extends StatefulWidget {
  const ChessNextApp({
    super.key,
    this.repository,
    this.draftRepository,
    this.preferencesRepository,
    this.clipboard,
    this.engineFactory,
    this.deviceThreads = 1,
  });
  final PreferencesRepository? preferencesRepository;
  final DraftRepository? draftRepository;
  final TextClipboard? clipboard;
  final EngineFactory? engineFactory;
  final int deviceThreads;
  final GameRepository? repository;
  @override
  State<ChessNextApp> createState() => _ChessNextAppState();
}

class _ChessNextAppState extends State<ChessNextApp>
    with WidgetsBindingObserver {
  final session = BoardSession();
  late final LibraryController library;
  late final DraftController? drafts;
  late final PreferencesController preferences;
  late final EngineSessionController analysis;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    analysis = EngineSessionController(
      session,
      widget.engineFactory,
      deviceThreads: widget.deviceThreads,
    );
    library = LibraryController(
      session,
      widget.repository ?? MemoryGameRepository(),
    );
    drafts = widget.draftRepository == null
        ? null
        : DraftController(session, library, widget.draftRepository!);
    if (drafts != null) unawaited(drafts!.initialize());
    preferences = PreferencesController(
      analysis,
      widget.preferencesRepository ?? MemoryPreferencesRepository(),
    );
    preferences.addListener(_preferencesChanged);
    unawaited(preferences.initialize());
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
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await analysis.disable();
    await drafts?.flush();
    await preferences.flush();
    if (!mounted) return AppExitResponse.exit;
    if (session.dirty &&
        session.hasContent &&
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
  ThemeMode get mode => switch (preferences.value.theme) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    preferences.removeListener(_preferencesChanged);
    unawaited(preferences.flush());
    preferences.dispose();
    analysis.dispose();
    if (drafts != null) {
      unawaited(drafts!.flush());
      drafts!.dispose();
    }
    library.dispose();
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
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
    home: _BoardPage(
      drafts: drafts,
      preferences: preferences,
      clipboard: widget.clipboard ?? FlutterTextClipboard(),
      session: session,
      library: library,
      analysis: analysis,
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
    required this.toggleTheme,
    required this.library,
    required this.analysis,
    this.drafts,
    required this.preferences,
  });
  final PreferencesController preferences;
  final DraftController? drafts;
  final TextClipboard clipboard;
  final BoardSession session;
  final VoidCallback toggleTheme;
  final LibraryController library;
  final EngineSessionController analysis;
  Future<void> _newGame(BuildContext context) async {
    if (session.dirty && session.hasContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('开始新局？'),
          content: const Text('当前对局仅保存在内存中，开始新局将清除着法。'),
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
    if (session.dirty && session.hasContent) {
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

  Future<void> _import(BuildContext context) async {
    await analysis.disable();
    if (!context.mounted) return;
    final epoch = session.epoch;
    final revision = session.revision;
    final tree = await showDialog<GameTree>(
      context: context,
      builder: (_) => ImportTextDialog(clipboard: clipboard),
    );
    if (tree == null || !context.mounted) return;
    if (session.epoch != epoch || session.revision != revision) return;
    if (session.dirty && session.hasContent) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入前保留当前棋谱？'),
          content: const Text('导入成功后将替换当前棋谱。'),
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
      if (choice == 'save' && (!await _save(context) || !context.mounted)) {
        return;
      }
    }
    library.importTree(tree);
  }

  Future<void> _restoreDraft(BuildContext context) async {
    await analysis.disable();
    if (!context.mounted || drafts?.pending == null) return;
    var replace = false;
    if (session.dirty && session.hasContent) {
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
            tooltip: '应用设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PreferencesDialog(preferences: preferences),
            ),
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
                        .clamp(432, 540)
                        .toDouble(),
                    child: XiangqiBoard(
                      session: session,
                      recommendation: analysis.recommended,
                      reply: analysis.reply,
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
                      OutlinedButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => ExportTextDialog(
                            tree: session.tree,
                            clipboard: clipboard,
                          ),
                        ),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('导出文字'),
                      ),
                      OutlinedButton.icon(
                        onPressed: library.busy ? null : () => _edit(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('编辑局面'),
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
                  if (session.moves.isEmpty)
                    const Text('走出第一步，开始一盘新棋。')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (i, node)
                            in session.tree.path.skip(1).indexed)
                          Tooltip(
                            message: node.move.toString(),
                            child: Chip(
                              label: Text(
                                '${i + 1}. ${ChineseNotation.format(session.tree.node(node.parentId!).position, node.move!)}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: session.canUndo ? session.first : null,
                        tooltip: '回到开始',
                        icon: const Icon(Icons.first_page),
                      ),
                      IconButton(
                        onPressed: session.canUndo
                            ? () => analysis.playing
                                  ? analysis.undoForPlay()
                                  : session.undo()
                            : null,
                        tooltip: '上一着',
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: session.canForward ? session.forward : null,
                        tooltip: '下一着',
                        icon: const Icon(Icons.chevron_right),
                      ),
                      IconButton(
                        onPressed: session.canForward ? session.last : null,
                        tooltip: '主线末尾',
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
                  for (final id in session.tree.current.children)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Tooltip(
                        message: session.tree.node(id).move.toString(),
                        child: Text(
                          '继续 ${ChineseNotation.format(session.position, session.tree.node(id).move!)}',
                        ),
                      ),
                      subtitle: Text(
                        id == session.tree.current.children.first ? '主线' : '变着',
                      ),
                      onTap: () => session.navigate(id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'main') {
                            session.promote(id);
                            return;
                          }
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('删除这条变着？'),
                              content: const Text('包含其后续着法和注释。'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) session.deleteBranch(id);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'main', child: Text('提升为主线')),
                          PopupMenuItem(value: 'delete', child: Text('删除变着')),
                        ],
                      ),
                    ),
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
