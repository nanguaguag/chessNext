import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../ports/audio_feedback.dart';
import '../../ports/audio_library.dart';

class FileAudioOverrideRepository implements AudioOverrideRepository {
  FileAudioOverrideRepository(this.directory);

  final Future<Directory> Function() directory;

  Future<Directory> _folder() async => Directory(
    '${(await directory()).path}/chessnext-audio',
  ).create(recursive: true);

  File _manifest(Directory folder, AudioFeedbackKind kind) =>
      File('${folder.path}/${kind.name}.json');

  File _moveChoice(Directory folder) => File('${folder.path}/move-choice.json');

  @override
  Future<MoveSoundChoice> moveSoundChoice() async {
    final folder = await _folder();
    final file = _moveChoice(folder);
    if (!await file.exists() || await file.length() > 128) {
      return MoveSoundChoice.sound1;
    }
    try {
      final value = jsonDecode(await file.readAsString());
      if (value is Map<String, dynamic> && value['schema'] == 1) {
        return MoveSoundChoice.values.firstWhere(
          (choice) => choice.name == value['choice'],
          orElse: () => MoveSoundChoice.sound1,
        );
      }
    } catch (_) {
      // Corrupt preferences fall back to the first built-in sound.
    }
    return MoveSoundChoice.sound1;
  }

  @override
  Future<void> setMoveSoundChoice(MoveSoundChoice choice) async {
    final folder = await _folder();
    final stage = await folder.createTemp('.move-choice-');
    try {
      final pending = File('${stage.path}/move-choice.json');
      await pending.writeAsString(
        jsonEncode({'schema': 1, 'choice': choice.name}),
        flush: true,
      );
      await pending.rename(_moveChoice(folder).path);
    } finally {
      if (await stage.exists()) await stage.delete(recursive: true);
    }
  }

  Future<Map<String, dynamic>?> _readManifest(
    Directory folder,
    AudioFeedbackKind kind,
  ) async {
    final file = _manifest(folder, kind);
    if (!await file.exists() || await file.length() > 256) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final extension = decoded is Map<String, dynamic>
          ? decoded['extension']
          : null;
      final fileName = decoded is Map<String, dynamic> ? decoded['file'] : null;
      if (decoded is! Map<String, dynamic> ||
          decoded['schema'] != 1 ||
          !const {'wav', 'mp3'}.contains(extension) ||
          fileName is! String ||
          !RegExp('^${kind.name}-[0-9]+\\.$extension\$').hasMatch(fileName)) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> pathFor(AudioFeedbackKind kind) async {
    final folder = await _folder();
    final manifest = await _readManifest(folder, kind);
    if (manifest == null) return null;
    final file = File('${folder.path}/${manifest['file']}');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    if (await file.length() > AudioLibraryLimits.maxBytes) return null;
    return file.path;
  }

  @override
  Future<void> save(
    AudioFeedbackKind kind,
    String extension,
    Uint8List bytes,
  ) async {
    if (!const {'wav', 'mp3'}.contains(extension) ||
        bytes.isEmpty ||
        bytes.length > AudioLibraryLimits.maxBytes) {
      throw const AudioLibraryException(AudioLibraryFailure.write);
    }
    final folder = await _folder();
    final stage = await folder.createTemp('.${kind.name}-pending-');
    final fileName =
        '${kind.name}-${DateTime.now().microsecondsSinceEpoch}.$extension';
    final previous = await _readManifest(folder, kind);
    try {
      final pendingAudio = File('${stage.path}/$fileName');
      await pendingAudio.writeAsBytes(bytes, flush: true);
      final pendingManifest = File('${stage.path}/${kind.name}.json');
      await pendingManifest.writeAsString(
        jsonEncode({'schema': 1, 'extension': extension, 'file': fileName}),
        flush: true,
      );
      await pendingAudio.rename('${folder.path}/$fileName');
      await pendingManifest.rename(_manifest(folder, kind).path);
      if (previous != null && previous['file'] != fileName) {
        final old = File('${folder.path}/${previous['file']}');
        if (await old.exists()) await old.delete();
      }
    } finally {
      if (await stage.exists()) await stage.delete(recursive: true);
    }
  }

  @override
  Future<void> remove(AudioFeedbackKind kind) async {
    final folder = await _folder();
    final manifest = _manifest(folder, kind);
    final previous = await _readManifest(folder, kind);
    if (await manifest.exists()) await manifest.delete();
    if (previous != null) {
      final audio = File('${folder.path}/${previous['file']}');
      if (await audio.exists()) await audio.delete();
    }
  }
}
