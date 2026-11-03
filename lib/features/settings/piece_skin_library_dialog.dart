import 'package:flutter/material.dart';
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_images.dart';

class PieceSkinLibraryDialog extends StatelessWidget {
  const PieceSkinLibraryDialog({super.key, required this.library});
  final PieceSkinLibraryController library;

  Future<String?> _name(BuildContext context, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial.isEmpty ? '新建棋子皮肤' : '重命名棋子皮肤'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => AlertDialog(
      title: const Text('棋子皮肤库'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (library.error != null)
              Text(
                library.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (library.loading) const LinearProgressIndicator(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final skin in PieceSkin.values)
                    ListTile(
                      leading: const Icon(Icons.style_outlined),
                      title: Text(
                        skin == PieceSkin.roundSeal ? '传统圆章' : '方章墨韵',
                      ),
                      subtitle: const Text('内置样式'),
                      trailing: const Icon(Icons.lock_outline),
                    ),
                  for (final profile in library.profiles)
                    ListTile(
                      leading: const Icon(Icons.folder_copy_outlined),
                      title: Text(profile.name),
                      subtitle: Text(
                        profile.baseSkin == PieceSkin.roundSeal
                            ? '基于传统圆章'
                            : '基于方章墨韵',
                      ),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: '重命名${profile.name}',
                            onPressed: library.loading
                                ? null
                                : () async {
                                    final name = await _name(
                                      context,
                                      initial: profile.name,
                                    );
                                    if (name != null) {
                                      await library.rename(profile.id, name);
                                    }
                                  },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: '删除${profile.name}',
                            onPressed: library.loading
                                ? null
                                : () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('删除${profile.name}？'),
                                        content: const Text('此皮肤的本机图片也会删除。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('取消'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await library.delete(profile.id);
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: library.loading
              ? null
              : () async {
                  final name = await _name(context);
                  if (name != null) await library.create(name: name);
                },
          icon: const Icon(Icons.add),
          label: const Text('从当前样式复制'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
