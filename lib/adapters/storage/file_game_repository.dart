import 'dart:convert';
import 'dart:io';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../ports/game_repository.dart';

/// Versioned per-document snapshots. Same-directory rename commits atomically on macOS.
class FileGameRepository implements GameRepository {
  FileGameRepository(this._directory, {this.folderName = 'chessnext-records'}) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(folderName)) {
      throw ArgumentError('Invalid snapshot folder');
    }
  }
  final String folderName;
  final Future<Directory> Function() _directory;
  static const maxBytes = 4 * 1024 * 1024;
  Future<Directory> _folder() async {
    final base = await _directory();
    return Directory('${base.path}/$folderName').create(recursive: true);
  }

  void _validateId(String id) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id)) {
      throw ArgumentError('Invalid record ID');
    }
  }

  Future<SavedGame> _read(
    File file,
    String id, {
    bool recovered = false,
  }) async {
    if (await file.length() > maxBytes) throw const FormatException('棋谱文件过大');
    final data = jsonDecode(await file.readAsString());
    if (data is! Map<String, dynamic> ||
        data['schema'] != 1 ||
        data['id'] != id ||
        data['title'] is! String ||
        (data['title'] as String).length > 120 ||
        data['modifiedAt'] is! String ||
        data['tree'] is! Map<String, dynamic>) {
      throw const FormatException('棋谱文件格式不正确');
    }
    return SavedGame(
      id: id,
      title: data['title'] as String,
      modifiedAt: DateTime.parse(data['modifiedAt'] as String),
      tree: GameTree.fromJson(data['tree'] as Map<String, dynamic>),
      recovered: recovered,
      metadata: data.containsKey('metadata')
          ? GameMetadata.fromJson(data['metadata'])
          : GameMetadata.empty,
    );
  }

  @override
  Future<SavedGame> load(String id) async {
    _validateId(id);
    final folder = await _folder();
    try {
      return await _read(File('${folder.path}/$id.json'), id);
    } on FileSystemException {
      return _read(File('${folder.path}/$id.bak'), id, recovered: true);
    } on FormatException {
      return _read(File('${folder.path}/$id.bak'), id, recovered: true);
    }
  }

  @override
  Future<LibrarySnapshot> list() async {
    final folder = await _folder();
    final games = <SavedGame>[];
    final unreadable = <String>[];
    final ids = <String>{};
    await for (final entity in folder.list(followLinks: false)) {
      if (entity is! File) continue;
      final filename = entity.uri.pathSegments.last;
      if (filename.endsWith('.json') || filename.endsWith('.bak')) {
        ids.add(filename.substring(0, filename.lastIndexOf('.')));
      }
    }
    for (final id in ids) {
      try {
        games.add(await load(id));
      } on FileSystemException {
        unreadable.add(id);
      } on FormatException {
        unreadable.add(id);
      } on ArgumentError {
        unreadable.add(id);
      }
    }
    games.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return LibrarySnapshot(
      List.unmodifiable(games),
      unreadable: List.unmodifiable(unreadable),
    );
  }

  @override
  Future<void> save(SavedGame game) async {
    _validateId(game.id);
    if (game.title.trim().isEmpty || game.title.length > 120) {
      throw ArgumentError('棋谱名称需要1至120个字符');
    }
    final data = utf8.encode(
      jsonEncode({
        'schema': 1,
        'id': game.id,
        'title': game.title,
        'modifiedAt': game.modifiedAt.toUtc().toIso8601String(),
        'tree': game.tree.toJson(),
        if (!game.metadata.isEmpty) 'metadata': game.metadata.toJson(),
      }),
    );
    if (data.length > maxBytes || game.tree.nodeCount > GameTree.maxNodes) {
      throw ArgumentError('棋谱超过当前存储限制');
    }
    final folder = await _folder();
    final target = File('${folder.path}/${game.id}.json');
    final temporary = await folder.createTemp('.save-');
    try {
      final pending = File('${temporary.path}/pending.json');
      await pending.writeAsBytes(data, flush: true);
      if (await target.exists()) {
        try {
          await _read(target, game.id);
          await target.copy('${folder.path}/${game.id}.bak');
        } on FormatException {
          // Keep the corrupt original as evidence without replacing a good backup.
          final archive = await folder.createTemp('.damaged-${game.id}-');
          await target.copy('${archive.path}/original.json');
        }
      }
      await pending.rename(target.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
