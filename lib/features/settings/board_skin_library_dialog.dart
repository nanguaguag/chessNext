import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
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
      setState(() => _remoteError = l10n.invalidCatalogAddress);
      return;
    }
    await widget.library.preferences.setSkinCatalogBaseUrl(raw);
    if (!mounted) return;
    if (widget.library.preferences.error != null) {
      setState(() => _remoteError = l10n.catalogAddressSaveFailed);
      return;
    }
    await _loadRemote();
  }

  Future<void> _loadRemote({bool nextPage = false}) async {
    final l10n = AppLocalizations.of(context);
    if (widget.catalog == null) return;
    final endpoint = Uri.tryParse(
      widget.library.preferences.value.skinCatalogBaseUrl,
    );
    if (endpoint == null || endpoint.host.isEmpty) {
      setState(() => _remoteError = l10n.catalogNotConfigured);
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
            ? l10n.offlineCacheAt(
                result.cachedAt?.toLocal().toString() ?? l10n.unknownTime,
              )
            : null;
        _remoteError = result.items.isEmpty && !nextPage
            ? l10n.catalogEmpty
            : null;
      });
    } on PieceSkinCatalogUnavailable {
      if (mounted) setState(() => _remoteError = l10n.catalogUnavailable);
    } on PieceSkinCatalogRejected catch (error) {
      if (mounted) {
        setState(
          () => _remoteError = l10n.catalogHttpRejected(error.statusCode),
        );
      }
    } on PieceSkinCatalogException {
      if (mounted) setState(() => _remoteError = l10n.catalogInvalidResponse);
    } catch (_) {
      if (mounted) setState(() => _remoteError = l10n.catalogRequestFailed);
    } finally {
      if (mounted) setState(() => _remoteLoading = false);
    }
  }

  Future<void> _details(PublicBoardSkin item) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Text(
            '${item.description}\n\n${l10n.skinDetailsAuthor(item.author)}\n${l10n.skinDetailsLikes(item.likes)}\n${l10n.skinDetailsCreated(item.publishedAt.toLocal().toString())}\n${l10n.skinDetailsLicense(item.license)}\n${l10n.skinDetailsAttribution(item.attribution.isEmpty ? l10n.noExtraAttribution : item.attribution)}',
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _downloadAndImport(context, item),
            icon: const Icon(Icons.download_outlined),
            label: Text(l10n.downloadConfirmImport),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndImport(
    BuildContext dialogContext,
    PublicBoardSkin item,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);
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
          title: Text(l10n.confirmBoardSkinImport(item.name)),
          content: SingleChildScrollView(
            child: Text(
              l10n.boardSkinLicenseReview(
                item.license,
                item.attribution.isEmpty
                    ? l10n.noExtraAttribution
                    : item.attribution,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.acceptLicenseImport),
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
            imported
                ? l10n.boardSkinImported(item.name)
                : widget.library.error ?? l10n.boardSkinImportFailed,
          ),
        ),
      );
      if (imported) Navigator.pop(dialogContext);
    } on PieceSkinCatalogUnavailable {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(
          dialogContext,
        )?.showSnackBar(SnackBar(content: Text(l10n.remoteDownloadFailed)));
      }
    } on PieceSkinCatalogException {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(
          dialogContext,
        )?.showSnackBar(SnackBar(content: Text(l10n.remotePackageRejected)));
      }
    } on FormatException {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(
          dialogContext,
        )?.showSnackBar(SnackBar(content: Text(l10n.invalidBoardSkinPackage)));
      }
    } catch (_) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.maybeOf(dialogContext)?.showSnackBar(
          SnackBar(content: Text(l10n.remoteBoardSkinImportFailed)),
        );
      }
    }
  }

  Future<void> _export(
    BuildContext context,
    BoardSkinDefinition profile,
  ) async {
    final l10n = AppLocalizations.of(context);
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
      )?.showSnackBar(SnackBar(content: Text(l10n.boardSkinExported)));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(l10n.boardSkinExportFailed)));
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (picker == null) return;
    try {
      final bytes = await picker!.pickZip();
      if (bytes == null || !context.mounted) return;
      final package = BoardSkinPackageCodec.decode(bytes);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.importBoardSkinPackage),
          content: Text(
            l10n.boardSkinPackageSummary(
              package.profile.name,
              package.images.length,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.importAndUse),
            ),
          ],
        ),
      );
      if (accepted != true || !context.mounted) return;
      final imported = await library.importPackage(package);
      if (!context.mounted) return;
      if (!imported) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(library.error ?? l10n.boardSkinImportFailed)),
        );
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.invalidBoardSkinPackageSize)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.readBoardSkinPackageFailed)),
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

  Future<void> _create(BuildContext context, {required bool apply}) async {
    final name = await _name(
      context,
      title: AppLocalizations.of(context).newBoardSkin,
    );
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
    final name = await _name(
      context,
      title: AppLocalizations.of(context).renameBoardSkin,
      initial: profile.name,
    );
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBoardSkin),
        content: Text(l10n.confirmDeleteBoardSkin(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.manageBoardSkins),
        content: SizedBox(
          width: 480,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (widget.catalog != null) ...[
                  Text(
                    l10n.onlineBoardCatalog,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextField(
                    controller: _endpoint,
                    decoration: InputDecoration(
                      labelText: l10n.catalogServiceAddress,
                      hintText: 'https://skins.example.com',
                      helperText: l10n.catalogEndpointHelp,
                      suffixIcon: IconButton(
                        tooltip: l10n.saveAddressConnect,
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
                          decoration: InputDecoration(
                            labelText: l10n.searchBoardSkins,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _loadRemote(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l10n.searchBoardSkins,
                        onPressed: _remoteLoading ? null : _loadRemote,
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<PublicBoardSkinSort>(
                    key: ValueKey('board-skin-catalog-sort-$_sort'),
                    initialValue: _sort,
                    decoration: InputDecoration(labelText: l10n.onlineSort),
                    items: [
                      DropdownMenuItem(
                        value: PublicBoardSkinSort.defaultOrder,
                        child: Text(l10n.sortDefault),
                      ),
                      DropdownMenuItem(
                        value: PublicBoardSkinSort.likes,
                        child: Text(l10n.sortLikes),
                      ),
                      DropdownMenuItem(
                        value: PublicBoardSkinSort.name,
                        child: Text(l10n.sortName),
                      ),
                      DropdownMenuItem(
                        value: PublicBoardSkinSort.author,
                        child: Text(l10n.sortAuthor),
                      ),
                      DropdownMenuItem(
                        value: PublicBoardSkinSort.recent,
                        child: Text(l10n.sortRecent),
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
                        '${item.author} · ${l10n.skinDetailsLikes(item.likes)} · ${item.license}',
                      ),
                      trailing: const Icon(Icons.info_outline),
                      onTap: () => _details(item),
                    ),
                  if (_items.length < _total)
                    TextButton(
                      onPressed: _remoteLoading
                          ? null
                          : () => _loadRemote(nextPage: true),
                      child: Text(l10n.loadMore),
                    ),
                  const Divider(),
                ],
                Text(
                  l10n.builtInSkins,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final skin in BoardSkin.values)
                  ListTile(
                    leading: const Icon(Icons.grid_on),
                    title: Text(
                      skin == BoardSkin.parchment
                          ? l10n.boardSkinParchment
                          : l10n.boardSkinJade,
                    ),
                    subtitle: Text(l10n.builtInPalette),
                    trailing:
                        library.preferences.value.selectedBoardSkinId ==
                            skin.name
                        ? const Icon(Icons.check_circle)
                        : TextButton(
                            onPressed: library.loading
                                ? null
                                : () => library.selectBuiltIn(skin),
                            child: Text(l10n.use),
                          ),
                  ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myBoards,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
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
                            label: Text(l10n.saveOnly),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: library.loading
                                ? null
                                : () => _create(context, apply: true),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.createAndUse),
                          ),
                          IconButton(
                            tooltip: l10n.importBoardSkinPackage,
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
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.noLocalBoardSkins),
                  ),
                for (final profile in library.profiles)
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: Text(profile.name),
                    subtitle: Text(
                      l10n.basedOnSkin(
                        profile.baseSkin == BoardSkin.parchment
                            ? l10n.boardSkinParchment
                            : l10n.boardSkinJade,
                      ),
                    ),
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
                            child: Text(l10n.use),
                          ),
                        IconButton(
                          tooltip: l10n.editNamedBoardSkin(profile.name),
                          onPressed: library.loading
                              ? null
                              : () => _editGeometry(context, profile),
                          icon: const Icon(Icons.tune),
                        ),
                        IconButton(
                          tooltip: l10n.renameNamedBoardSkin(profile.name),
                          onPressed: library.loading
                              ? null
                              : () => _rename(context, profile),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: l10n.deleteNamedBoardSkin(profile.name),
                          onPressed: library.loading
                              ? null
                              : () => _delete(context, profile),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        IconButton(
                          tooltip: l10n.exportNamedBoardSkin(profile.name),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    },
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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).boardSkinName,
      ),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context).cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: Text(AppLocalizations.of(context).save),
      ),
    ],
  );
}
