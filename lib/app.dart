import 'package:flutter/material.dart';
import 'application/board_session.dart';
import 'features/board/xiangqi_board.dart';

class ChessNextApp extends StatefulWidget {
  const ChessNextApp({super.key});
  @override
  State<ChessNextApp> createState() => _ChessNextAppState();
}

class _ChessNextAppState extends State<ChessNextApp> {
  final session = BoardSession();
  ThemeMode mode = ThemeMode.system;
  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
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
      session: session,
      toggleTheme: () => setState(
        () => mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      ),
    ),
  );
}

class _BoardPage extends StatelessWidget {
  const _BoardPage({required this.session, required this.toggleTheme});
  final BoardSession session;
  final VoidCallback toggleTheme;
  Future<void> _newGame(BuildContext context) async {
    if (session.canUndo) {
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
    session.newGame();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('chessNext'),
        actions: [
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
                    width: (constraints.maxWidth - 48)
                        .clamp(432, 540)
                        .toDouble(),
                    child: XiangqiBoard(session: session),
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
                        onPressed: session.canUndo ? session.undo : null,
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
                        for (var i = 0; i < session.moves.length; i++)
                          Chip(label: Text('${i + 1}. ${session.moves[i]}')),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    '当前对局未保存，关闭应用后不会保留。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: board,
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(width: 320, child: panel),
                          ],
                        )
                      : Column(
                          children: [board, const SizedBox(height: 24), panel],
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
