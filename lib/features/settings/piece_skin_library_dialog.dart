import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_images.dart';
import '../../ports/piece_skin_library.dart';
import '../../application/piece_skin_package_codec.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/record_file_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/piece_skin_folder_picker.dart';

class PieceSkinLibraryDialog extends StatefulWidget {
  const PieceSkinLibraryDialog({
    super.key,
    required this.library,
    this.exporter,
    this.picker,
    this.folderPicker,
  });
  final PieceSkinLibraryController library;
  final PieceSkinPackageExporter? exporter;
  final PieceSkinPackagePicker? picker;
  final PieceSkinFolderPicker? folderPicker;

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
                            tooltip: '导出${profile.name}',
                            onPressed:
                                widget.library.loading ||
                                    widget.exporter == null
                                ? null
                                : () => _export(context, profile),
                            icon: const Icon(Icons.download_outlined),
                          ),
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
          onPressed: widget.library.loading || widget.picker == null
              ? null
              : () => _import(context),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('导入ZIP'),
        ),
        TextButton.icon(
          onPressed: widget.library.loading || widget.folderPicker == null
              ? null
              : () => _importFolder(context),
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('导入文件夹'),
        ),
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

  Future<void> _export(
    BuildContext context,
    PieceSkinDefinition profile,
  ) async {
    try {
      final bytes = PieceSkinPackageCodec.encode(
        profile,
        widget.library.images.imagesFor(profile.id),
      );
      final safeName = profile.name
          .replaceAll(RegExp(r'[^\p{L}\p{N}_-]+', unicode: true), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final result = await widget.exporter!.saveZip(
        suggestedName: safeName.isEmpty ? 'xiangqi-skin' : safeName,
        bytes: bytes,
        cancellation: FileExportCancellation(),
      );
      if (!context.mounted || result == RecordFileExportResult.cancelled) {
        return;
      }
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('棋子皮肤包已导出。')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('皮肤包导出失败，请检查本机存储后重试。')));
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      await _importBytes(context, widget.picker!.pickZip());
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('皮肤包无效或无法读取，未写入本机数据。')));
    }
  }

  Future<void> _importFolder(BuildContext context) async {
    try {
      await _importBytes(context, widget.folderPicker!.pickFolderPackage());
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('文件夹结构无效或无法读取，未写入本机数据。')));
    }
  }

  Future<void> _importBytes(
    BuildContext context,
    Future<Uint8List?> pendingBytes,
  ) async {
    final bytes = await pendingBytes;
    if (bytes == null || !context.mounted) return;
    final skinPackage = PieceSkinPackageCodec.decode(bytes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('导入${skinPackage.profile.name}？'),
        content: Text('将新增一套本机皮肤，包含${skinPackage.images.length}张图片。导入后会选用该皮肤。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导入并使用'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final imported = await widget.library.importPackage(skinPackage);
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          imported ? '皮肤已导入并选用。' : widget.library.error ?? '皮肤导入失败。',
        ),
      ),
    );
  }
}
