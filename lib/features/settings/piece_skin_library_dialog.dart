import 'package:flutter/material.dart';
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_images.dart';
import '../../ports/piece_skin_library.dart';

class PieceSkinLibraryDialog extends StatefulWidget {
  const PieceSkinLibraryDialog({super.key, required this.library});
  final PieceSkinLibraryController library;

  @override
  State<PieceSkinLibraryDialog> createState() => _PieceSkinLibraryDialogState();
}

enum _SkinSort { defaultOrder, name, newest }

class _PieceSkinLibraryDialogState extends State<PieceSkinLibraryDialog> {
  final _search = TextEditingController();
  String _query = '';
  _SkinSort _sort = _SkinSort.defaultOrder;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    listenable: widget.library,
    builder: (context, _) => AlertDialog(
      title: const Text('棋子皮肤库'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: '搜索本机皮肤',
                suffixIcon: IconButton(
                  tooltip: '清除搜索',
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onSubmitted: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<_SkinSort>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: '排序'),
              items: const [
                DropdownMenuItem(
                  value: _SkinSort.defaultOrder,
                  child: Text('默认排序'),
                ),
                DropdownMenuItem(value: _SkinSort.name, child: Text('按名称')),
                DropdownMenuItem(value: _SkinSort.newest, child: Text('最近创建')),
              ],
              onChanged: (value) =>
                  setState(() => _sort = value ?? _SkinSort.defaultOrder),
            ),
            if (widget.library.error != null)
              Text(
                widget.library.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (widget.library.loading) const LinearProgressIndicator(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final skin in PieceSkin.values.where(
                    (skin) =>
                        _query.isEmpty ||
                        (skin == PieceSkin.roundSeal ? '传统圆章' : '方章墨韵')
                            .contains(_query),
                  ))
                    ListTile(
                      leading: const Icon(Icons.style_outlined),
                      title: Text(
                        skin == PieceSkin.roundSeal ? '传统圆章' : '方章墨韵',
                      ),
                      subtitle: const Text('内置样式'),
                      selected:
                          widget
                              .library
                              .preferences
                              .value
                              .selectedPieceSkinId ==
                          skin.name,
                      onTap: () async {
                        await widget.library.select(skin.name);
                        if (context.mounted) Navigator.pop(context);
                      },
                      trailing: const Icon(Icons.lock_outline),
                    ),
                  for (final profile in _visibleProfiles())
                    ListTile(
                      leading: const Icon(Icons.folder_copy_outlined),
                      title: Text(profile.name),
                      subtitle: Text(
                        profile.baseSkin == PieceSkin.roundSeal
                            ? '基于传统圆章'
                            : '基于方章墨韵',
                      ),
                      selected:
                          widget
                              .library
                              .preferences
                              .value
                              .selectedPieceSkinId ==
                          profile.id,
                      onTap: () async {
                        await widget.library.select(profile.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: '重命名${profile.name}',
                            onPressed: widget.library.loading
                                ? null
                                : () async {
                                    final name = await _name(
                                      context,
                                      initial: profile.name,
                                    );
                                    if (name != null) {
                                      await widget.library.rename(
                                        profile.id,
                                        name,
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: '删除${profile.name}',
                            onPressed: widget.library.loading
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
                                      await widget.library.delete(profile.id);
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
          onPressed: widget.library.loading
              ? null
              : () async {
                  final name = await _name(context);
                  if (name != null) await widget.library.create(name: name);
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

  List<PieceSkinDefinition> _visibleProfiles() {
    var profiles = widget.library.profiles
        .where(
          (profile) =>
              profile.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    switch (_sort) {
      case _SkinSort.defaultOrder:
        break;
      case _SkinSort.name:
        profiles.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _SkinSort.newest:
        profiles = profiles.reversed.toList();
    }
    return profiles;
  }
}
