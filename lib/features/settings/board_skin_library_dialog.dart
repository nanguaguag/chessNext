import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

import '../../application/board_skin_library_controller.dart';
import '../../application/board_skin_package_codec.dart';
import '../../ports/board_skin_images.dart';
import '../../ports/board_skin_library.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/record_file_exporter.dart';
import '../../ports/piece_skin_catalog.dart';
import 'board_skin_geometry_draft_dialog.dart';

final class BoardSkinLibraryDialog extends StatefulWidget {
  const BoardSkinLibraryDialog({
    super.key,
    required this.library,
    this.exporter,
    this.picker,
    this.catalog,
  });

  final BoardSkinLibraryController library;
  final PieceSkinPackageExporter? exporter;
  final PieceSkinPackagePicker? picker;
  final BoardSkinCatalog? catalog;

  @override
  State<BoardSkinLibraryDialog> createState() => _BoardSkinLibraryDialogState();
}

final class _BoardSkinLibraryDialogState extends State<BoardSkinLibraryDialog> {
  final _endpoint = TextEditingController();
  final _query = TextEditingController();
  PublicBoardSkinSort _sort = PublicBoardSkinSort.defaultOrder;
  List<PublicBoardSkin> _items = const [];
  bool _remoteLoading = false;
  String? _remoteError;
  String? _cacheStatus;
  int _page = 1;
  int _total = 0;

  BoardSkinLibraryController get library => widget.library;
  PieceSkinPackageExporter? get exporter => widget.exporter;
  PieceSkinPackagePicker? get picker => widget.picker;

  @override
  void initState() {
    super.initState();
    _endpoint.text = widget.library.preferences.value.skinCatalogBaseUrl;
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final raw = _endpoint.text.trim().replaceFirst(RegExp(r'/+$'), '');
    final endpoint = Uri.tryParse(raw);
    if (endpoint == null ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        (endpoint.scheme != 'https' &&
            !(endpoint.scheme == 'http' &&
                {'localhost', '127.0.0.1', '::1'}.contains(endpoint.host)))) {
      setState(() => _remoteError = '服务地址无效：远程地址必须使用HTTPS。');
      return;
    }
    await widget.library.preferences.setSkinCatalogBaseUrl(raw);
    if (!mounted) return;
    if (widget.library.preferences.error != null) {
      setState(() => _remoteError = '服务地址保存失败，可重试。');
      return;
    }
    await _loadRemote();
  }

  Future<void> _loadRemote({bool nextPage = false}) async {
    if (widget.catalog == null) return;
    final endpoint = Uri.tryParse(
      widget.library.preferences.value.skinCatalogBaseUrl,
    );
    if (endpoint == null || endpoint.host.isEmpty) {
      setState(() => _remoteError = '请先填写并连接自建目录服务。');
      return;
    }
    final requestedPage = nextPage ? _page + 1 : 1;
    setState(() {
      _remoteLoading = true;
      _remoteError = null;
      _cacheStatus = null;
      if (!nextPage) {
        _page = 1;
        _items = const [];
        _total = 0;
      }
    });
    try {
      final result = await widget.catalog!.search(
        endpoint: endpoint,
        query: _query.text.trim(),
        sort: _sort,
        page: requestedPage,
      );
      if (!mounted) return;
      setState(() {
        _items = nextPage ? [..._items, ...result.items] : result.items;
        _page = requestedPage;
        _total = result.total;
        _cacheStatus = result.isStale
            ? '离线缓存 · ${result.cachedAt?.toLocal().toString() ?? '时间未知'}'
            : null;
        _remoteError = result.items.isEmpty && !nextPage ? '目录当前没有棋盘皮肤。' : null;
      });
    } on PieceSkinCatalogUnavailable {
      if (mounted) setState(() => _remoteError = '无法连接自建棋盘目录，请检查网络和服务状态。');
    } on PieceSkinCatalogRejected catch (error) {
      if (mounted) {
        setState(() => _remoteError = '目录服务返回HTTP ${error.statusCode}。');
      }
    } on PieceSkinCatalogException {
      if (mounted) setState(() => _remoteError = '目录响应无效，未显示远程棋盘皮肤。');
    } catch (_) {
      if (mounted) setState(() => _remoteError = '目录请求失败，请检查服务地址。');
    } finally {
      if (mounted) setState(() => _remoteLoading = false);
    }
  }

  Future<void> _details(PublicBoardSkin item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Text(
            '${item.description}\n\n作者：${item.author}\n点赞：${item.likes}\n创建：${item.publishedAt.toLocal()}\n许可证：${item.license}\n署名：${item.attribution.isEmpty ? '无额外署名' : item.attribution}',
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _downloadAndImport(context, item),
            icon: const Icon(Icons.download_outlined),
            label: const Text('下载并确认导入'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndImport(
    BuildContext dialogContext,
    PublicBoardSkin item,
  ) async {
    try {
      final endpoint = Uri.parse(
        widget.library.preferences.value.skinCatalogBaseUrl,
      );
      final bytes = await widget.catalog!.downloadPackage(
        endpoint: endpoint,
        id: item.id,
        expectedSha256: item.packageSha256,
      );
      if (sha256.convert(bytes).toString() != item.packageSha256) {
        throw const PieceSkinCatalogInvalidResponse();
      }
      final package = BoardSkinPackageCodec.decode(bytes);
      if (package.profile.name != item.name) {
        throw const PieceSkinCatalogInvalidResponse();
      }
      if (!dialogContext.mounted) return;
      final accepted = await showDialog<bool>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: Text('确认导入${item.name}？'),
          content: SingleChildScrollView(
            child: Text(
              '下载包已通过SHA-256与本机棋盘皮肤ZIP格式校验。\n\n许可证：${item.license}\n署名：${item.attribution.isEmpty ? '无额外署名' : item.attribution}\n\n导入将新增并立即使用一套本机棋盘皮肤；许可义务由你自行遵守。',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('接受许可并导入'),
            ),
          ],
        ),
      );
      if (accepted != true || !dialogContext.mounted) return;
      final imported = await widget.library.importPackage(
        package,
        license: item.license,
        attribution: item.attribution,
      );
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.maybeOf(dialogContext)?.showSnackBar(
        SnackBar(
          content: Text(
            imported ? '已校验并导入${item.name}。' : widget.library.error ?? '导入失败。',
          ),
        ),
      );
      if (imported) Navigator.pop(dialogContext);
    } on PieceSkinCatalogUnavailable {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(
          dialogContext,
        )?.showSnackBar(const SnackBar(content: Text('下载失败，请检查网络；本机棋盘皮肤未更改。')));
      }
    } on PieceSkinCatalogException {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(dialogContext)?.showSnackBar(
          const SnackBar(content: Text('下载包校验失败或服务拒绝请求；本机棋盘皮肤未更改。')),
        );
      }
    } on FormatException {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(
          dialogContext,
        )?.showSnackBar(const SnackBar(content: Text('棋盘皮肤包格式无效；本机数据未更改。')));
      }
    } catch (_) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(
          dialogContext,
        )?.showSnackBar(const SnackBar(content: Text('无法导入该远程棋盘皮肤；本机数据未更改。')));
      }
    }
  }

  Future<void> _export(
    BuildContext context,
    BoardSkinDefinition profile,
  ) async {
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
      if (!context.mounted || result == RecordFileExportResult.cancelled) {
        return;
      }
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('棋盘皮肤包已导出。')));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('棋盘皮肤导出失败，请检查本机存储后重试。')));
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
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(library.error ?? '棋盘皮肤导入失败。')));
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('棋盘皮肤包无效或超过大小限制，本机皮肤未更改。')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('无法读取棋盘皮肤包，本机皮肤未更改。')));
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

  Future<void> _create(BuildContext context, {required bool apply}) async {
    final name = await _name(context, title: '新建棋盘皮肤');
    if (name == null || !context.mounted) return;
    final saved = await library.create(name: name, apply: apply);
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

  Future<void> _editGeometry(
    BuildContext context,
    BoardSkinDefinition profile,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => BoardSkinGeometryDraftDialog(
        profile: profile,
        onSave: (geometry) => library.updateGeometry(profile.id, geometry),
      ),
    );
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
              if (widget.catalog != null) ...[
                Text('自建在线棋盘目录', style: Theme.of(context).textTheme.titleSmall),
                TextField(
                  controller: _endpoint,
                  decoration: InputDecoration(
                    labelText: '自建目录服务地址',
                    hintText: 'https://skins.example.com',
                    helperText: '远程需HTTPS；localhost可用于本机部署。',
                    suffixIcon: IconButton(
                      tooltip: '保存服务地址并连接',
                      onPressed: _remoteLoading ? null : _connect,
                      icon: const Icon(Icons.cloud_sync_outlined),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _connect(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _query,
                        decoration: const InputDecoration(labelText: '搜索棋盘皮肤'),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _loadRemote(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: '搜索棋盘皮肤',
                      onPressed: _remoteLoading ? null : _loadRemote,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                DropdownButtonFormField<PublicBoardSkinSort>(
                  key: ValueKey('board-skin-catalog-sort-$_sort'),
                  initialValue: _sort,
                  decoration: const InputDecoration(labelText: '在线排序'),
                  items: const [
                    DropdownMenuItem(
                      value: PublicBoardSkinSort.defaultOrder,
                      child: Text('默认排序'),
                    ),
                    DropdownMenuItem(
                      value: PublicBoardSkinSort.likes,
                      child: Text('点赞'),
                    ),
                    DropdownMenuItem(
                      value: PublicBoardSkinSort.name,
                      child: Text('名称'),
                    ),
                    DropdownMenuItem(
                      value: PublicBoardSkinSort.author,
                      child: Text('作者'),
                    ),
                    DropdownMenuItem(
                      value: PublicBoardSkinSort.recent,
                      child: Text('最近创建'),
                    ),
                  ],
                  onChanged: _remoteLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _sort = value);
                          _loadRemote();
                        },
                ),
                if (_cacheStatus != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_cacheStatus!),
                  ),
                if (_remoteLoading) const LinearProgressIndicator(),
                if (_remoteError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _remoteError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                for (final item in _items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.author} · ${item.likes}人点赞 · ${item.license}',
                    ),
                    trailing: const Icon(Icons.info_outline),
                    onTap: () => _details(item),
                  ),
                if (_items.length < _total)
                  TextButton(
                    onPressed: _remoteLoading
                        ? null
                        : () => _loadRemote(nextPage: true),
                    child: const Text('加载更多棋盘皮肤'),
                  ),
                const Divider(),
              ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我的棋盘', style: Theme.of(context).textTheme.titleSmall),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('save-board-skin-without-use'),
                          onPressed: library.loading
                              ? null
                              : () => _create(context, apply: false),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('仅保存'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: library.loading
                              ? null
                              : () => _create(context, apply: true),
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
                        tooltip: '编辑${profile.name}',
                        onPressed: library.loading
                            ? null
                            : () => _editGeometry(context, profile),
                        icon: const Icon(Icons.tune),
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
