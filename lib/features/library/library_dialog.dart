import 'package:flutter/material.dart';
import '../../application/library_controller.dart';

class LibraryDialog extends StatefulWidget {
  const LibraryDialog({super.key, required this.library});
  final LibraryController library;
  @override
  State<LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<LibraryDialog> {
  String query = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.library.refresh();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.library,
    builder: (context, _) {
      final library = widget.library;
      final games = library.snapshot.games
          .where((g) => g.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return AlertDialog(
        title: const Text('本地棋谱库'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '搜索棋谱名称',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
              if (library.busy) const LinearProgressIndicator(),
              if (library.error != null)
                Text(
                  library.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (library.snapshot.unreadable.isNotEmpty)
                Text('${library.snapshot.unreadable.length} 个棋谱文件无法读取，原文件未改动'),
              Expanded(
                child: games.isEmpty
                    ? Center(child: Text(library.busy ? '正在读取…' : '暂无匹配的本地棋谱'))
                    : ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          return ListTile(
                            title: Text(game.title),
                            subtitle: Text(
                              '${game.tree.nodeCount - 1} 着 · ${game.modifiedAt.toLocal().toString().substring(0, 16)}${game.recovered ? ' · 备份恢复' : ''}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            enabled: !library.busy,
                            onTap: () async {
                              if (library.session.dirty &&
                                  library.session.hasContent) {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('打开另一份棋谱？'),
                                    content: const Text('当前未保存的修改将被替换。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('放弃修改并打开'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                              }
                              if (await library.open(game.id) &&
                                  context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
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
