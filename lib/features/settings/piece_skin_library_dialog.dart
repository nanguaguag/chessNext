import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../application/piece_skin_library_controller.dart';
import '../../ports/piece_images.dart';
import '../../ports/piece_skin_library.dart';
import '../../ports/piece_skin_package_exporter.dart';
import '../../ports/record_file_exporter.dart';
import '../../ports/piece_skin_package_picker.dart';
import '../../ports/piece_skin_folder_picker.dart';
import '../../ports/piece_skin_catalog.dart';
import '../../application/piece_skin_package_codec.dart';

class PieceSkinLibraryDialog extends StatefulWidget {
  const PieceSkinLibraryDialog({
    super.key,
    required this.library,
    this.exporter,
    this.picker,
    this.folderPicker,
    this.catalog,
  });
  final PieceSkinLibraryController library;
  final PieceSkinPackageExporter? exporter;
  final PieceSkinPackagePicker? picker;
  final PieceSkinFolderPicker? folderPicker;
  final PieceSkinCatalog? catalog;

  @override
  State<PieceSkinLibraryDialog> createState() => _PieceSkinLibraryDialogState();
}

enum _SkinSort { defaultOrder, name, newest }

class _PieceSkinLibraryDialogState extends State<PieceSkinLibraryDialog> {
  final _search = TextEditingController();
  String _query = '';
  _SkinSort _sort = _SkinSort.defaultOrder;
  final _server = TextEditingController();
  PublicPieceSkinSort _remoteSort = PublicPieceSkinSort.defaultOrder;
  List<PublicPieceSkin> _remoteItems = const [];
  bool _remoteLoading = false;
  String? _remoteError;
  String? _remoteCacheStatus;
  int _remotePage = 1;
  int _remoteTotal = 0;

  @override
  void initState() {
    super.initState();
    _server.text = widget.library.preferences.value.skinCatalogBaseUrl;
  }

  @override
  void dispose() {
    _search.dispose();
    _server.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.catalog != null) ...[
                TextField(
                  controller: _server,
                  decoration: InputDecoration(
                    labelText: '自建目录服务地址',
                    hintText: 'https://skins.example.com',
                    helperText: '远程需HTTPS；localhost可用于本机部署。',
                    suffixIcon: IconButton(
                      tooltip: '保存服务地址并连接',
                      onPressed: _remoteLoading ? null : _saveEndpoint,
                      icon: const Icon(Icons.cloud_sync_outlined),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveEndpoint(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PublicPieceSkinSort>(
                        initialValue: _remoteSort,
                        decoration: const InputDecoration(labelText: '在线排序'),
                        items: const [
                          DropdownMenuItem(
                            value: PublicPieceSkinSort.defaultOrder,
                            child: Text('默认排序'),
                          ),
                          DropdownMenuItem(
                            value: PublicPieceSkinSort.likes,
                            child: Text('点赞最多'),
                          ),
                          DropdownMenuItem(
                            value: PublicPieceSkinSort.name,
                            child: Text('按名称'),
                          ),
                          DropdownMenuItem(
                            value: PublicPieceSkinSort.author,
                            child: Text('按作者'),
                          ),
                          DropdownMenuItem(
                            value: PublicPieceSkinSort.recent,
                            child: Text('最新导入'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(
                            () => _remoteSort =
                                value ?? PublicPieceSkinSort.defaultOrder,
                          );
                          _loadRemote();
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: '刷新在线目录',
                      onPressed: _remoteLoading ? null : _loadRemote,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('$_remoteTotal 项'),
                    IconButton(
                      tooltip: '上一页',
                      onPressed: _remotePage <= 1 || _remoteLoading
                          ? null
                          : () {
                              setState(() => _remotePage--);
                              _loadRemote();
                            },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('$_remotePage'),
                    IconButton(
                      tooltip: '下一页',
                      onPressed:
                          _remotePage * 24 >= _remoteTotal || _remoteLoading
                          ? null
                          : () {
                              setState(() => _remotePage++);
                              _loadRemote();
                            },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                if (_remoteLoading) const LinearProgressIndicator(),
                if (_remoteCacheStatus != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _remoteCacheStatus!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_remoteError != null)
                  Text(
                    _remoteError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_remoteItems.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in _remoteItems)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.cloud_outlined),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.author} · ♥ ${item.likes}\n许可：${item.license}\n署名：${item.attribution.isEmpty ? '无额外署名' : item.attribution}',
                              ),
                              isThreeLine: true,
                              onTap: () => _showRemoteDetails(context, item),
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(),
              ],
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
                      _remotePage = 1;
                      _loadRemote();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _query = value.trim();
                    _remotePage = 1;
                  });
                  _loadRemote();
                },
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
                  DropdownMenuItem(
                    value: _SkinSort.newest,
                    child: Text('最近创建'),
                  ),
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
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
            ],
          ),
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

  Future<void> _saveEndpoint() async {
    final raw = _server.text.trim().replaceFirst(RegExp(r'/+$'), '');
    final endpoint = Uri.tryParse(raw);
    final valid =
        endpoint != null &&
        endpoint.host.isNotEmpty &&
        endpoint.userInfo.isEmpty &&
        !endpoint.hasQuery &&
        !endpoint.hasFragment &&
        (endpoint.scheme == 'https' ||
            (endpoint.scheme == 'http' &&
                (endpoint.host == 'localhost' ||
                    endpoint.host == '127.0.0.1' ||
                    endpoint.host == '::1')));
    if (!valid) {
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

  Future<void> _loadRemote() async {
    final endpoint = Uri.tryParse(
      widget.library.preferences.value.skinCatalogBaseUrl,
    );
    if (endpoint == null || endpoint.host.isEmpty || widget.catalog == null) {
      setState(() {
        _remoteItems = const [];
        _remoteError = '请先填写并保存自建目录服务地址。';
      });
      return;
    }
    setState(() {
      _remoteLoading = true;
      _remoteError = null;
      _remoteCacheStatus = null;
    });
    try {
      final result = await widget.catalog!.search(
        endpoint: endpoint,
        query: _query,
        sort: _remoteSort,
        page: _remotePage,
      );
      if (!mounted) return;
      setState(() {
        _remoteItems = result.items;
        _remoteTotal = result.total;
        _remoteCacheStatus = result.isStale
            ? '离线缓存 · ${result.cachedAt?.toLocal().toString() ?? '时间未知'}'
            : null;
        _remoteError = result.items.isEmpty ? '目录当前没有公开皮肤。' : null;
      });
    } on PieceSkinCatalogUnavailable {
      if (mounted) setState(() => _remoteError = '无法连接自建皮肤目录，请检查网络和服务状态。');
    } on PieceSkinCatalogRejected catch (error) {
      if (mounted) {
        setState(() => _remoteError = '目录服务返回HTTP ${error.statusCode}。');
      }
    } on PieceSkinCatalogException {
      if (mounted) setState(() => _remoteError = '目录响应无效，未显示远程条目。');
    } catch (_) {
      if (mounted) setState(() => _remoteError = '目录请求失败，请检查服务地址。');
    } finally {
      if (mounted) setState(() => _remoteLoading = false);
    }
  }

  Future<void> _showRemoteDetails(
    BuildContext context,
    PublicPieceSkin item,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item.name),
      content: SingleChildScrollView(
        child: Text(
          '${item.description}\n\n作者：${item.author}\n点赞：${item.likes}\n导入日期：${item.publishedAt.toLocal()}\n许可证：${item.license}\n署名：${item.attribution.isEmpty ? '无额外署名' : item.attribution}\n\n下载后仍需确认许可，当前不会自动写入本机。',
        ),
      ),
      actions: [
        if (widget.catalog != null)
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

  Future<void> _downloadAndImport(
    BuildContext context,
    PublicPieceSkin item,
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
      final package = PieceSkinPackageCodec.decode(bytes);
      if (package.profile.name != item.name) {
        throw const PieceSkinCatalogInvalidResponse();
      }
      if (!context.mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('确认导入${item.name}？'),
          content: SingleChildScrollView(
            child: Text(
              '下载包已通过SHA-256和本机皮肤包格式校验。\n\n许可证：${item.license}\n署名：${item.attribution.isEmpty ? '无额外署名' : item.attribution}\n\n导入后会新增并选用一套本机皮肤；许可义务由你自行遵守。',
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
      if (accepted != true || !context.mounted) return;
      final imported = await widget.library.importPackage(
        package,
        license: item.license,
        attribution: item.attribution,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            imported ? '已校验并导入${item.name}。' : widget.library.error ?? '导入失败。',
          ),
        ),
      );
    } on PieceSkinCatalogUnavailable {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('下载失败，请检查网络后重试；本机皮肤未更改。')),
        );
      }
    } on PieceSkinCatalogException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('下载包校验失败或服务拒绝请求，本机皮肤未更改。')),
        );
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('皮肤包格式无效，本机皮肤未更改。')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('无法导入该远程皮肤，本机皮肤未更改。')));
      }
    }
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
