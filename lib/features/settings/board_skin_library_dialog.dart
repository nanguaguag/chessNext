import 'package:flutter/material.dart';

import '../../application/board_skin_library_controller.dart';
import '../../application/board_skin_package_codec.dart';
import '../../ports/board_skin_images.dart';
import '../../ports/board_skin_library.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/record_file_exporter.dart';

final class BoardSkinLibraryDialog extends StatelessWidget {
  const BoardSkinLibraryDialog({
    super.key,
    required this.library,
    this.exporter,
    this.picker,
  });

  final BoardSkinLibraryController library;
  final PieceSkinPackageExporter? exporter;
  final PieceSkinPackagePicker? picker;

  Future<void> _export(BuildContext context, BoardSkinDefinition profile) async {
    if (exporter == null) return;
    try {
      final bytes = library.exportPackage(profile.id);
      final safeName = profile.name
          .replaceAll(RegExp(r'[^\p{L}\p{N}_-]+', unicode: true), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final result = await exporter!.saveZip(
        suggestedName: safeName.isEmpty ? 'xiangqi-board-skin' : safeName,
        bytes: bytes,
        cancellation: FileExportCancellation(),
      );
      if (!context.mounted || result == RecordFileExportResult.cancelled) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('棋盘皮肤包已导出。')),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('棋盘皮肤导出失败，请检查本机存储后重试。')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    if (picker == null) return;
    try {
      final bytes = await picker!.pickZip();
      if (bytes == null || !context.mounted) return;
      final package = BoardSkinPackageCodec.decode(bytes);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入棋盘皮肤包'),
          content: Text(
            '项目格式皮肤包：${package.profile.name}\n'
            '包含${package.images.length}张自定义图片和独立格网设置。导入后会新增并立即使用，不覆盖现有皮肤。',
          ),
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
      if (accepted != true || !context.mounted) return;
      final imported = await library.importPackage(package);
      if (!context.mounted) return;
      if (!imported) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(library.error ?? '棋盘皮肤导入失败。')),
        );
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('棋盘皮肤包无效或超过大小限制，本机皮肤未更改。')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('无法读取棋盘皮肤包，本机皮肤未更改。')),
        );
      }
    }
  }

  Future<String?> _name(
    BuildContext context, {
    required String title,
    String initial = '',
  }) => showDialog<String>(
    context: context,
    builder: (_) => _BoardSkinNameDialog(title: title, initial: initial),
  );

  Future<void> _create(BuildContext context) async {
    final name = await _name(context, title: '新建棋盘皮肤');
    if (name == null || !context.mounted) return;
    final saved = await library.create(name: name);
    if (!saved && context.mounted && library.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(library.error!)));
    }
  }

  Future<void> _rename(
    BuildContext context,
    BoardSkinDefinition profile,
  ) async {
    final name = await _name(context, title: '重命名棋盘皮肤', initial: profile.name);
    if (name == null || !context.mounted) return;
    final saved = await library.rename(profile.id, name);
    if (!saved && context.mounted && library.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(library.error!)));
    }
  }

  Future<void> _delete(
    BuildContext context,
    BoardSkinDefinition profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除棋盘皮肤'),
        content: Text('确定删除「${profile.name}」？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await library.delete(profile.id);
    if (!deleted && context.mounted && library.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(library.error!)));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => AlertDialog(
      title: const Text('棋盘皮肤库'),
      content: SizedBox(
        width: 480,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('内置皮肤', style: Theme.of(context).textTheme.titleSmall),
              for (final skin in BoardSkin.values)
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: Text(skin.label),
                  subtitle: const Text('内置配色'),
                  trailing:
                      library.preferences.value.selectedBoardSkinId == skin.name
                      ? const Icon(Icons.check_circle)
                      : TextButton(
                          onPressed: library.loading
                              ? null
                              : () => library.selectBuiltIn(skin),
                          child: const Text('使用'),
                        ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '我的棋盘',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: library.loading ? null : () => _create(context),
                    icon: const Icon(Icons.add),
                    label: const Text('新建并使用'),
                  ),
                  IconButton(
                    tooltip: '导入棋盘皮肤包',
                    onPressed: picker == null || library.loading
                        ? null
                        : () => _import(context),
                    icon: const Icon(Icons.archive_outlined),
                  ),
                ],
              ),
              if (library.profiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('还没有本机棋盘皮肤。新建时会复制当前棋盘的配色、格网和图片。'),
                ),
              for (final profile in library.profiles)
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: Text(profile.name),
                  subtitle: Text('基于${profile.baseSkin.label}'),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      if (library.preferences.value.selectedBoardSkinId ==
                          profile.id)
                        const Icon(Icons.check_circle)
                      else
                        TextButton(
                          onPressed: library.loading
                              ? null
                              : () => library.select(profile.id),
                          child: const Text('使用'),
                        ),
                      IconButton(
                        tooltip: '重命名${profile.name}',
                        onPressed: library.loading
                            ? null
                            : () => _rename(context, profile),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: '删除${profile.name}',
                        onPressed: library.loading
                            ? null
                            : () => _delete(context, profile),
                        icon: const Icon(Icons.delete_outline),
                      ),
                      IconButton(
                        tooltip: '导出${profile.name}',
                        onPressed: exporter == null || library.loading
                            ? null
                            : () => _export(context, profile),
                        icon: const Icon(Icons.file_upload_outlined),
                      ),
                    ],
                  ),
                ),
              if (library.loading) const LinearProgressIndicator(),
              if (library.error != null)
                Text(
                  library.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

final class _BoardSkinNameDialog extends StatefulWidget {
  const _BoardSkinNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_BoardSkinNameDialog> createState() => _BoardSkinNameDialogState();
}

final class _BoardSkinNameDialogState extends State<_BoardSkinNameDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: BoardSkinDefinition.maxNameRunes,
      decoration: const InputDecoration(labelText: '名称'),
      onSubmitted: (value) => Navigator.pop(context, value),
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
  );
}
